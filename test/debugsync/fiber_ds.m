/*
 * Copyright (C) 2010 Mail.RU
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


#include <unistd.h>
#include <sys/types.h>
#include <errno.h>

#include <tarantool.h>
#include <tarantool_ev.h>
#include <say.h>

#include "fiber.h"
#include "fiber_ds.h"


/** Syncpoint specification (as seen from the client side). */
struct syncpt_spec {
	/** Syncpoint name (to reference from test/console). */
	char	*name;
	/** Should it be initially enabled? */
	bool	is_enabled;
};

#define SYNCPT_MEMBER(n, s) { .name = #n, .is_enabled = s },

/** Syncpoints defined for the application: */
static const struct syncpt_spec spec[syncpt_enum_MAX] = {
        SYNCPT_LIST(SYNCPT_MEMBER)
};


/** Element of a list of fibers. */
struct fiber_ref {
	/** Referenced fiber. */
	struct fiber		*target;
	/** Next element. */
	struct fiber_ref	*next;
};


struct syncpt {
	/** Unique name to use as ID. */
	char			*name;
	/** Enabled state indicator. */
	bool			is_enabled;
	/** Sync point is locked. */
	bool			is_locked;
	/** The fiber where the syncpt is being run. */
	struct fiber		*host_fiber;
	/** List of fibers waiting on the syncpt. */
	struct fiber_ref	*waiting;
	/** Number of fibers waiting on the syncpt. */
	ssize_t			waiting_count;
	/** List of fibers syncpt is holding (being locked) for. */
	struct fiber_ref	*locking;
	/** Number of fibers holding locks on syncpt. */
	ssize_t			lock_count;
};


/** Module-scope variables in one structure. */
static struct syncpt_ds {
	/** libev IO handle to raise events through. */
	ev_io			io;
	/** Event notification pipe. */
	int			pipefd[2];
	/**  Activation control flags (see header for details). */
	bool			is_active;
	/** Synchronization points. */
	struct	syncpt		point[syncpt_enum_MAX];
} ds;


/** Event datagram to pass between fibers (when raising events). */
struct syncpt_dgram {
	/** Event operation code. */
	char	op;
	/** Index of the target sync point in ds.point[]. */
	int	index;
};


/** Forward declaration: atexit handler for participating fibers. */
static void atexit_syncpt();


/** True if the framework is inactive. */
inline static bool inactive() { return ds.is_active == false; }


/**
 * Wait for sync point to execute.
 *
 * @param pt syncpoint to wait on.
 * @return 0 if the syncpoint has been reached in a valid state.
 */
static int
syncpt_wait(struct syncpt *pt)
{
	struct fiber_ref *ref = calloc(1, sizeof(ref));
	if (ref == NULL)
		panic("%s: failed to create fiber reference", __func__);

	ref->target = fiber;

	/* Head insert. */
	ref->next = pt->waiting;
	pt->waiting = ref;
	pt->waiting_count++;

	say_debug("%s: fiber %p will now block on syncpoint %s",
		__func__, (void*)fiber, pt->name);

	fiber_yield();
	fiber_testcancel();

	say_debug("%s: fiber %p woke up on syncpoint %s [%s]",
		__func__, (void*)fiber, pt->name,
		pt->is_enabled ? "OK" : "disabled");
	return pt->is_enabled ? 0 : -1;
}


/**
 * Hold control at the sync point until unlocked by waiters.
 *
 * @param pt syncpoint holding.
 * @return 0 if unlocked by all waiters in a valid state.
 */
static int
syncpt_hold(struct syncpt *pt)
{
	pt->host_fiber = fiber;

	say_debug("%s: host fiber %p will now hold at syncpoint %s",
		__func__, (void*)fiber, pt->name);

	fiber_yield();
	fiber_testcancel();

	say_debug("%s: fiber %p woke up on syncpoint %s (%s,)",
		__func__, (void*)fiber, pt->name,
		pt->is_enabled ? "enabled" : "disabled",
		pt->is_locked ? "locked" : "idle");

	pt->host_fiber = NULL;

	return 0;
}


/**
 * Raise (signal) event for a syncpoint.
 *
 * @param op operation code, specifying event type.
 * @param pt syncpoint the event is for.
 * @return 0 if event has been raised successfully.
 */
static int
syncpt_raise(char op, struct syncpt *pt)
{
	struct syncpt_dgram dgram;

	dgram.op = op;
	dgram.index = pt - &ds.point[0];

	say_debug("%s: raising [%c] syncpoint %s [index=%d]",
		__func__, op, pt->name, dgram.index);

	ssize_t nwr = write(ds.pipefd[1], &dgram, sizeof(dgram));
	if (nwr != sizeof(dgram)) {
		say_error("Error writing to fiber-condition pipe, nwr=%ld",
			(long)nwr);
		return -1;
	}

	return 0;
}

/** Raise 'broadcast' event: signal to wake up all syncpoint's waiters. */
inline static int
syncpt_wakeup(struct syncpt *pt) { return syncpt_raise('B', pt); }


/** Raise 'unlock' event: signal to unlock the syncpoint's host fiber. */
inline static int
syncpt_unlock(struct syncpt *pt) { return syncpt_raise('U', pt); }


/** Locate a sync point by name.
 *
 * @param point_name Name of the sync point.
 * @param caller symbolic tag for the caller function.
 *
 * @return pointer to the named sync point, if found, otherwise - NULL.
 */
static struct syncpt*
look_up(const char *point_name, const char *caller)
{
	for(size_t i = 0; i < syncpt_enum_MAX; ++i)
		if (strcmp(point_name, ds.point[i].name) == 0)
			return &ds.point[i];

	say_error("%p:%s sync point [%s] does not exist",
		(void*)fiber, caller, point_name);
	return NULL;
}
#define LOOK_UP(name)	look_up(name, __func__)

/**
 * Check if the syncpoint is enabled, output an error message otherwise.
 *
 * @param point_name Name of the sync point.
 * @param caller symbolic tag for the caller function.
 *
 * @return true if the sync point is enabled.
 */
static inline bool
verify_enabled(const struct syncpt *pt, const char *caller)
{
	if (!pt->is_enabled) {
		say_error("%p:%s sync point [%s] is disabled",
			(void*)fiber, caller, pt->name);
	}
	return pt->is_enabled;
}
#define VERIFY_ENABLED(pt)	verify_enabled(pt, __func__)


/**
 * Wake up all 'waiters' (fibers) blocked on a syncpoint.
 *
 * @param pt the syncpoint waited on.
 */
static void
wakeup_blocked(struct syncpt *pt)
{
	/* Iteratively pass control to the fibers blocked on the syncpoint;
	 * save pointer to the head of the list.
	 */
	struct fiber_ref *head = pt->waiting, *ref = NULL;
	ssize_t waiting_count = pt->waiting_count;

	for(ref = head; ref != NULL; ref = ref->next) {
		say_debug("%s: waking up fiber %p",
				__func__, (void*)ref->target);
		fiber_call(ref->target);
		pt->waiting_count--;
	}

	/* Find the item preceding the (possibly former) head. */
	struct fiber_ref *prev = NULL;
	for(ref = pt->waiting; ref && ref != head; prev = ref, ref = ref->next);

	assert(ref == head && pt->locking == NULL);

	/* Former waiting fibers become the locking ones. */
	pt->locking = head;
	pt->lock_count = waiting_count;

	if (prev)
		prev->next = NULL;
	else
		pt->waiting = NULL;

	return;
}


/**
 * Process libio's syncpoint-related IO event(s).
 */
static void
syncpt_cb(ev_watcher *watcher __attribute__((unused)), int event __attribute__((unused)))
{
	struct syncpt_dgram dgram = {'\0', 0};
	ssize_t nrd = -1;

	say_debug("Fiber condition event: watcher=%p, event=%d", (void*)watcher, event);

	while (1) {
		nrd = read(ds.pipefd[0], &dgram, sizeof(dgram));
		if (nrd == -1 && (errno == EAGAIN || errno == EWOULDBLOCK))
			break;
		if (nrd != (ssize_t)sizeof(dgram)) {
			say_error("Read %ld bytes, expected to get %ld\n", (long)nrd,
				(long)sizeof(dgram));
			break;
		}
		say_debug("datagram read: op=%c, index=%d", dgram.op, dgram.index);

		struct syncpt *pt = &ds.point[dgram.index];
		say_debug("%s: [%c] point=%s", __func__, dgram.op, pt->name);

		if (!pt->waiting && !pt->host_fiber) {
			say_debug("%s: no fibers are waiting on point %s, skipping.",
				__func__, pt->name);
			continue;
		}

		switch (dgram.op) {
			case 'B':
				wakeup_blocked(pt);
				break;
			case 'U':
				fiber_call(pt->host_fiber);
				pt->host_fiber = NULL;
				break;
			default:
				say_error("Illegal syncpoint operation code: %c",
					dgram.op);
				break;
		}
		say_debug("%s: %s more fibers waiting on syncpoint %s",
			__func__, pt->waiting ? "still" : "no", pt->name);
	}

	return;
}


void
fds_init(bool activate)
{
	ds.is_active = activate;

	struct syncpt *pt = &ds.point[0];
	for (size_t i = 0; i < syncpt_enum_MAX; ++i, ++pt) {
		pt->name	= spec[i].name;
		pt->is_enabled	= spec[i].is_enabled;
		pt->is_locked	= false;
		pt->host_fiber	= NULL;
		pt->waiting	= NULL;
		pt->waiting_count = 0;
		pt->locking	= NULL;
		pt->lock_count	= 0;
	}

	if (pipe(ds.pipefd) != 0 ||
	     set_nonblock(ds.pipefd[0]) == -1 ||
	     set_nonblock(ds.pipefd[1]) == -1)
			panic("Error setting up fiber-syncpoint "
				"event pipe");

	ev_io_init(&ds.io, (void*)&syncpt_cb,
		ds.pipefd[0], EV_READ);
	ev_io_start(&ds.io);

	say_debug("%s: done", __func__);
}


void
fds_destroy()
{
	ev_io_stop(&ds.io);

	for(size_t i = 0; i < syncpt_enum_MAX; ++i) {
		for(struct fiber_ref *p = ds.point[i].waiting, *tmp; p;) {
			tmp = p->next;
			free(p);
			p = tmp;
		}
	}

	(void) close(ds.pipefd[0]);
	(void) close(ds.pipefd[1]);

	say_debug("%s: done", __func__);
}


int
fds_activate(bool activate)
{
	if (activate == ds.is_active)
		return 0;

	if (!activate) {
		for (size_t i = 0; i < syncpt_enum_MAX; ++i)
			if (ds.point[i].host_fiber || ds.point[i].waiting) {
				say_error("%s(%d): syncpoint %s is still active",
					__func__, (int)activate, ds.point[i].name);
				return -1;
			}
	}

	ds.is_active = activate;
	say_debug("%s: debug syncpoint framework %s", __func__,
		activate ? "activated" : "disabled");

	return 0;
}


int
fds_wait(const char *point_name)
{
	if (inactive())
		return -1;

	struct syncpt *pt = LOOK_UP(point_name);
	if (pt == NULL || VERIFY_ENABLED(pt) == false)
		return -1;

	fiber_atexit(&atexit_syncpt);

	int rc = syncpt_wait(pt);

	fiber_testcancel();

	return rc;
}


int
fds_exec(int point_id)
{
	if (inactive())
		return 0;

	assert(point_id >= 0 && point_id < syncpt_enum_MAX);

	fiber_atexit(&atexit_syncpt);

	struct syncpt *pt = &ds.point[point_id];

	say_debug("%p:%s syncpoint [%s], %s/%s ENTER",
		(void*)fiber, __func__, pt->name,
		pt->is_enabled ? "enabled" : "disabled",
		pt->is_locked ? "locked" : "idle");

	if (!pt->is_enabled)
		return 0;

	if (pt->is_locked) {
		say_debug("%p:%s [%s] is LOCKED\n",
			(void*)fiber, __func__, pt->name);
		return -1;
	}

	if (pt->waiting == NULL) {
		say_debug("%p:%s [%s] has no waiters, skipping",
			(void*)fiber, __func__, pt->name);
		return 0;
	}

	pt->is_locked = true;
	int rc = 0;
	do {
		rc = syncpt_wakeup(pt);
		if (rc) break;

		if (pt->lock_count > 0)
			rc = syncpt_hold(pt);
		else
			say_debug("%p:%s no lockers to hold for at [%s]",
				(void*)fiber, __func__, pt->name);
	} while(0);
	pt->is_locked = false;

	fiber_testcancel();

	say_debug("%p:%s syncpoint [%s], %s/%s DONE (%d)",
		(void*)fiber, __func__, pt->name,
		pt->is_enabled ? "enabled" : "disabled",
		pt->is_locked ? "locked" : "idle", rc);

	return rc;
}


/* Find and remove the calling fiber from the locker list.
 */
static int
release_lock(struct syncpt *pt, bool must_find)
{
	struct fiber_ref *ref = pt->locking, *prev = NULL;
	for (; ref && ref->target != fiber; prev = ref, ref = ref->next);
	if (ref == NULL) {
		if (must_find)
			say_error("%p:%s is not holding a lock on [%s]",
				(void*)fiber, __func__, pt->name);

		return -1;
	}
	if (prev)
		prev->next = ref->next;
	else
		pt->locking = ref->next;

	free(ref);
	return 0;
}


/**
 * Remove current fiber's lock from the given syncpt.
 */
static int
do_unlock(struct syncpt *pt, bool must_find)
{
	if (release_lock(pt, must_find) == -1)
		return -1;

	say_debug("%p:%s lock released for [%s], %ld locks left",
		(void*)fiber, __func__, pt->name, (long)pt->lock_count);

	/* If all locks are gone, wake up the holding fiber. */
	if (--pt->lock_count == 0) {
		say_debug("%p:%s [%s] has %ld locks - must UNLOCK",
			(void*)fiber, __func__, pt->name,
			(long)pt->lock_count);

		return syncpt_unlock(pt);
	}

	return 0;
}


int
fds_unlock(const char *point_name)
{
	if (inactive())
		return -1;

	struct syncpt *pt = LOOK_UP(point_name);
	if (pt == NULL || VERIFY_ENABLED(pt) == false)
		return -1;

	if (pt->lock_count <= 0) {
		say_error("%p:%s no locks held on [%s], cannot unlock",
			(void*)fiber, __func__, point_name);

		pt->lock_count = 0;
		return -1;
	}

	return do_unlock(pt, true);
}


/**
 * Remove current fiber from the waiting list.
 */
static int
remove_waiting_fiber(struct syncpt *pt)
{
	struct fiber_ref *ref = pt->waiting, *prev = NULL;
	for(; ref && ref->target != fiber; prev = ref, ref = ref->next);
	if (!ref || ref->target != fiber)
		return -1;

	if (prev)
		prev->next = ref->next;
	else
		pt->waiting = ref->next;

	pt->waiting_count--;

	free(ref);

	say_debug("%p:%s waiting fiber removed from [%s]",
		(void*)fiber, __func__, pt->name);
	return 0;
}


inline static void
remove_locks(struct syncpt *pt)
{
	struct fiber_ref *ref = pt->locking;
	while (ref) {
		struct fiber_ref *tmp = ref->next;
		free(ref);
		pt->lock_count--;
		ref = tmp;
	}
	assert(pt->lock_count == 0);
	say_debug("%p:%s all locks removed from [%s]",
		(void*)fiber, __func__, pt->name);
}


static void
atexit_syncpt()
{
	if (inactive())
		return;

	struct syncpt *pt = &ds.point[0];
	for (size_t i = 0; i < syncpt_enum_MAX; ++i, ++pt) {
		if (!pt->is_enabled)
			continue;
		/* Is this the syncpoint's host? */
		if (pt->host_fiber == fiber) {
			remove_locks(pt);
			return;
		}
		/* Is this fiber waiting on the syncpt? */
		if (pt->waiting && remove_waiting_fiber(pt) == 0)
			return;
		/* Is this fiber locked on the syncpt? */
		if (pt->locking && do_unlock(pt, false) == 0)
			return;
	}
}


/**
 * Enable or disable a syncpoint.
 *
 * @param pt syncpoint to enable/disable.
 * @param enable if true, enable syncpoint, otherwise disable.
 */
static int
enable_syncpt(struct syncpt *pt, bool enable)
{
	if (enable == pt->is_enabled)
		return 0;

	pt->is_enabled = enable;

	int rc = 0;
	if (!pt->is_enabled) {
		if (pt->waiting != NULL)
			rc = syncpt_wakeup(pt);

		if (rc == 0 && pt->host_fiber != NULL) {
			pt->lock_count = 0;
			rc = syncpt_unlock(pt);
		}
	}

	return rc;
}


int
fds_enable(const char *point_name, bool enable)
{
	if (inactive())
		return 0;

	struct syncpt *pt = LOOK_UP(point_name);
	if (pt == NULL)
		return -1;

	return enable_syncpt(pt, enable);
}


void
fds_disable_all()
{
	if (inactive())
		return;

	for (size_t i = 0; i < syncpt_enum_MAX; ++i)
		if (ds.point[i].is_enabled)
			enable_syncpt(&ds.point[i], false);
}


void
fds_info(struct tbuf *out)
{
	if (inactive()) {
		tbuf_printf(out, "Syncronization framework is DISABLED" CRLF);
		return;
	}

	tbuf_printf(out, "Syncronization framework: %ld sync points" CRLF,
			(long)syncpt_enum_MAX);
	for(size_t i = 0; i < syncpt_enum_MAX; ++i)
		tbuf_printf(out, "  - %s: %s, %s, waiting: %ld, host: %p locks: %ld" CRLF,
			ds.point[i].name,
			ds.point[i].is_enabled ? "enabled" : "disabled",
			ds.point[i].is_locked ? "locked" : "idle",
			(long)ds.point[i].waiting_count,
			(void*)ds.point[i].host_fiber,
			(long)ds.point[i].lock_count);
}

