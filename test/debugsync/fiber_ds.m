/*
 * Copyright (C) 2010 Mail.RU
 * Copyright (C) 2010 Yuriy Vostrikov
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

/** Define syncpoints using the attributes below. */
struct syncpt_spec {
	char	*name;
	bool	is_enabled;
};

#define SYNCPT_MEMBER(n, s) { .name = #n, .is_enabled = s },

/** Syncpoints defined for the application: */
static const struct syncpt_spec spec[syncpt_enum_MAX] = {
        SYNCPT_LIST(SYNCPT_MEMBER)
};


/** Fiber-list element */
struct fiber_ref {
	struct fiber		*target;
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
	/** Number of fibers holding locks on syncpt. */
	ssize_t			host_locks;
	/** List of fibers waiting on the syncpt. */
	struct fiber_ref	*waiting;
	/** Number of fibers waiting on the syncpt. */
	ssize_t			wait_count;
};


static struct syncpt_ds {
	/** libev IO handle. */
	ev_io			io;
	/** Event notification pipe. */
	int			pipefd[2];
	/**  Activation control flags (see header for details). */
	bool			is_active;
	/** Synchronization points. */
	struct	syncpt		point[syncpt_enum_MAX];
} ds;


struct syncpt_dgram {
	char	op;
	int	index;
};


inline static bool inactive() { return ds.is_active == false; }


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


static int
syncpt_wait(struct syncpt *pt)
{
	struct fiber_ref *ref = calloc(1, sizeof(ref)); /* TODO: malloc */
	if (ref == NULL)
		panic("%s: failed to create fiber reference", __func__);

	ref->target = fiber;

	/* Head insert. */
	ref->next = pt->waiting;
	pt->waiting = ref;
	pt->wait_count++;

	say_debug("%s: fiber %p will now block on syncpoint %s",
		__func__, (void*)fiber, pt->name);

	fiber_yield();
	fiber_testcancel();

	say_debug("%s: fiber %p woke up on syncpoint %s [%s]",
		__func__, (void*)fiber, pt->name,
		pt->is_enabled ? "OK" : "disabled");
	return pt->is_enabled ? 0 : -1;
}


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


inline static int
syncpt_wakeup(struct syncpt *pt) { return syncpt_raise('B', pt); }

inline static int
syncpt_unlock(struct syncpt *pt) { return syncpt_raise('U', pt); }



/** Locate a sync point by name.
 *
 * @param point_name Name of the sync point.
 *
 * @return pointer to the named sync point, if found, otherwise - NULL.
 */
static struct syncpt*
look_up(const char *point_name)
{
	for(size_t i = 0; i < syncpt_enum_MAX; ++i)
		if (strcmp(point_name, ds.point[i].name) == 0)
			return &ds.point[i];
	return NULL;
}


static void
wakeup_blocked(struct syncpt *pt)
{
	/* Iteratively pass control to the fibers blocked on the syncpoint;
	 * save pointer to the head of the list.
	 */
	struct fiber_ref *head = pt->waiting, *ref = NULL;

	for(ref = head; ref != NULL; ref = ref->next) {
		say_debug("%s: waking up fiber %p (broadcast)",
				__func__, (void*)ref->target);
		fiber_call(ref->target);
		pt->wait_count--;
	}

	/* Find the item preceding the former (saved) head. */
	struct fiber_ref *prev = NULL;
	for(ref = pt->waiting; ref && ref != head; prev = ref, ref = ref->next);

	/* Remove all after the first marked ref. */
	while(ref) {
		say_debug("%s: removing fiber %p from syncpoint %s",
			__func__, (void*)ref->target, pt->name);
		struct fiber_ref *tmp = ref->next;
		free(ref); /* TODO */
		ref = tmp;
	}

	/* Trim the list. */
	if (prev)
		prev->next = NULL;
	else
		pt->waiting = NULL;
	return;
}


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
				say_error("Illegal operation code: %c", dgram.op);
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
	ds.is_active	= activate;

	struct syncpt *pt = &ds.point[0];
	for (size_t i = 0; i < syncpt_enum_MAX; ++i, ++pt) {
		pt->name	= spec[i].name;
		pt->is_enabled 	= spec[i].is_enabled;
		pt->is_locked 	= false;
		pt->host_fiber	= NULL;
		pt->waiting	= NULL;
		pt->wait_count	= 0;

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
fds_wait(const char *point_name)
{
	if (inactive())
		return -1;

	struct syncpt *pt = look_up(point_name);
	if (pt == NULL) {
		say_error("%p:%s sync point [%s] does not exist\n",
			(void*)fiber, __func__, point_name);
		return -1;
	}

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
		say_debug("%p:%s [%s] has no waiters, skipping\n",
			(void*)fiber, __func__, pt->name);
		return 0;
	}

	pt->is_locked = true;
	int rc = 0;
	do {
		ssize_t count = pt->wait_count;

		rc = syncpt_wakeup(pt);
		if (rc) break;

		/* Waiters become locks after the wake-up. */
		pt->host_locks = count;

		if (pt->host_locks > 0)
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


int
fds_unlock(const char *point_name)
{
	if (inactive())
		return -1;

	struct syncpt *pt = look_up(point_name);
	if (pt == NULL) {
		say_error("%p:%s sync point [%s] does not exist\n",
			(void*)fiber, __func__, point_name);
		return -1;
	}

	if (pt->host_locks <= 0) {
		say_error("%p:%s no locks held on [%s], cannot unlock",
			(void*)fiber, __func__, point_name);

		pt->host_locks = 0;
		return -1;
	}

	
	if (--pt->host_locks == 0) {
		say_debug("%p:%s [%s] has %ld locks - must UNLOCK",
			(void*)fiber, __func__, pt->name,
			(long)pt->host_locks);

		return syncpt_unlock(pt);
	}

	return 0;
}


static int
enable_syncpt(struct syncpt *pt, bool enable)
{
	int rc = 0;
	bool was_enabled = pt->is_enabled;
	pt->is_enabled = enable;

	if (was_enabled && !pt->is_enabled) {
		if (pt->waiting != NULL)
			rc = syncpt_wakeup(pt);

		if (rc == 0 && pt->host_fiber != NULL) {
			pt->host_locks = 0;
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

	struct syncpt *pt = look_up(point_name);
	if (pt == NULL) {
		say_error("%p:%s sync point [%s] does not exist\n",
			(void*)fiber, __func__, point_name);
		return -1;
	}

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
		tbuf_printf(out, "Debug syncronization is DISABLED" CRLF);
		return;
	}

	tbuf_printf(out, "Debug syncronization - %ld sync points" CRLF,
			(long)syncpt_enum_MAX);
	for(size_t i = 0; i < syncpt_enum_MAX; ++i)
		tbuf_printf(out, "  - %s: %s, %s, waiting: %ld, host: %p locks: %ld" CRLF,
			ds.point[i].name,
			ds.point[i].is_enabled ? "enabled" : "disabled",
			ds.point[i].is_locked ? "locked" : "idle",
			(long)ds.point[i].wait_count,
			(void*)ds.point[i].host_fiber,
			(long)ds.point[i].host_locks);
}

