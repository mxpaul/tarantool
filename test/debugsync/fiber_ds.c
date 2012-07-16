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
#include TARANTOOL_CONFIG
#include <tarantool_ev.h>
#include <say.h>

#include "fiber.h"
#include "fiber_syncpt.h"


struct fiber_ref {
	struct fiber		*target;
	struct fiber_ref	*next;
};


struct fiber_syncpt {
	/** Unique name to use as ID. */
	char			*name;
	/** Enabled state indicator. */
	bool			is_enabled;

	/** Sync point is locked. */
	bool			is_busy;

	/** The fiber where the syncpt is being run. */
	struct fiber		*host_fiber;

	/** Number of fibers holding locks on syncpt. */
	size_t			host_locks;

	/** Fibers waiting on the variable. */
	struct fiber_ref	*waiting;
};


enum {
	/** Hard limit on # of cond vars. */
	MAX_FIBER_SYNCPT = 255
};


static struct syncpt_ds {
	/** libev IO handle. */
	ev_io			io;

	/** Event notification pipe. */
	int			pipefd[2];

	/**  Activation control flags (see header for details). */
	u_int32_t		activation;

	/** Declared synchronization points. */
	struct	fiber_syncpt	point[MAX_FIBER_SYNCPT];
	size_t 			point_count;
} ds;


struct ds_dgram {
	char	op;
	int	index;
};



/** True if debug sync is inactive.
 * @return true if the framework is disabled (inactive).
 */
inline static bool inactive() { return (ds.activation & DS_ACTIVE) == 0; }


/** Set the activation flag.
 * @param activate Activate if true, disable if false.
 */
inline static void
do_activate(bool activate)
{
	if (activate)
		ds.activation |= DS_ACTIVE;
	else
		ds.activation &= ~DS_ACTIVE;
}


/* --- */

static int
fiber_syncpt_wait(struct fiber_syncpt *pt)
{
	struct fiber_ref *ref = calloc(1, sizeof(ref)); /* TODO: malloc */
	if (ref == NULL)
		panic("%s: failed to create fiber condition reference", __func__);

	assert(pt->index > 0);
	ref->target = fiber; /* Current fiber. */

	/* Head insert. */
	ref->next = pt->waiting;
	pt->waiting = ref;

	say_debug("%s: fiber %p will now block on syncpoint %s",
		__func__, (void*)fiber, pt->name);

	fiber_yield();
	fiber_testcancel();

	say_debug("%s: fiber %p woke up on syncpoint %s",
		__func__, (void*)fiber, pt->name);
	return 0;
}


static int
fiber_syncpt_hold(struct fiber_syncpt *pt)
{
	pt->host_fiber = fiber;
	say_debug("%s: host fiber %p will now hold at syncpoint %s",
		__func__, (void*)fiber, pt->name);

	fiber_yield();
	fiber_testcancel();

	say_debug("%s: fiber %p woke up on syncpoint %s",
		__func__, (void*)fiber, pt->name);
	return 0;
}


static int
fiber_syncpt_raise(char op, struct fiber_syncpt *pt)
{
	struct cond_dgram dgram = {'\0', 0};

	assert(op == 'B' || op == 'U');
	/* TODO: implement 'U' == unlock */
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
fiber_syncpt_broadcast(struct fiber_syncpt *pt)
{
	return fiber_syncpt_raise('B', pt);
}

inline static int
fiber_syncpt_unlock(struct fiber_syncpt *pt)
{
	return fiber_syncpt_raise('U', pt);
}

/** Create a new sync point.
 *
 * @param point_name Name of the new sync point.
 *
 * @return pointer to the newly-created sync point or NULL.
 */
static struct fiber_syncpt*
create_new(const char *point_name)
{
	if (ds.point_count >= DS_MAX_POINT_COUNT)
		return NULL;

	size_t i = ds.point_count;

	ds.point[i].name = strndup(point_name,
				DS_MAX_POINT_NAME_LEN);
	if (ds.point[i].name == NULL)
		return NULL;

	ds.point[i].is_enabled = true;

	ds.point[i].is_busy = false;
	ds.point[i].waiting = NULL;

	ds.point[i].host_fiber = NULL;
	ds.point[i].host_locks = 0;

	++ds.point_count;

	return &ds.point[i];
}



/** Locate a sync point by name.
 *
 * @param point_name Name of the sync point.
 *
 * @return pointer to the named sync point, if found, otherwise - NULL.
 */
static struct fiber_syncpt*
look_up(const char *point_name)
{
	/* NB: This does not scale to large ds.count, but neither
	 * is ds.count expected to be large enough to need a faster
	 * lookup.
	 */
	for(size_t i = 0; i < ds.count; ++i)
		if (strcmp(point_name, ds.point[i].name) == 0)
			return &ds.point[i];
	return NULL;
}


/** Locate a sync point by name, create it if not found.
 *
 * @param point_name Name of the sync point.
 *
 * @return pointer to the named sync point, or NULL if error.
 */
static struct fiber_synct*
acquire(const char *point_name)
{
	struct ds_point *pt = look_up(point_name);
	if (pt == NULL)
		pt = create_new(point_name);

	if (pt == NULL) {
		say_debug("%p:%s failed to get [%s]\n",
			(void*)fiber, __func__, point_name);
	}

	return pt;
}


static void
wakeup_all_blocked(struct fiber_syncpt *pt)
{
	/* Iteratively pass control to the fibers blocked on the syncpoint;
	 * save pointer to the head of the list.
	 */
	struct fiber_ref *head = pt->waiting, *ref = NULL;

	for(ref = head; ref != NULL; ref = ref->next) {
		say_debug("%s: waking up fiber %p (broadcast)",
				__func__, (void*)ref->target);
		fiber_call(ref->target);
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
		fsync->waiting = NULL;
	return;
}


static void
fiber_syncpt_cb(ev_watcher *watcher __attribute__((unused)), int event __attribute__((unused)))
{
	struct ds_dgram dgram = {'\0', 0};
	ssize_t nrd = -1;

	say_debug("Fiber condition event: watcher=%p, event=%d", (void*)watcher, event);
	assert(fiber == &sched);

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

		struct fiber_syncpt *fsync = &ds.point[dgram.index];
		say_debug("%s: [%c] point=%s", __func__, dgram.op, pt->name);

		if (!fsync->waiting) {
			say_debug("%s: no fibers are waiting on point %s, skipping.",
				__func__, pt->name);
			continue;
		}

		switch (dgram.op) {
			case 'B':
				wakeup_all_blocked(pt);
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
	} /* while */

	return;
}


/* --------------------- */

void
fds_init()
{
	ds.activation	= activation_flags;
	ds.point_count	= 0;

	if (pipe(ds.pipefd) != 0 ||
	     set_nonblock(ds.pipefd[0]) != 0 ||
	     set_nonblock(ds.pipefd[0]) != 0)
			panic("Error setting up fiber-syncpoint "
				"event pipe");

	ev_io_init(&ds.io, (void*)&fiber_syncpt_cb,
		ds.pipefd[0], EV_READ);

	 ev_io_start(&ds.io);

	 say_debug("%s: done", __func__);
}


void
fds_destroy()
{
	ev_io_stop(&ds.io);

	for(size_t i = 0; i < point_count; ++i) {
		for(struct fiber_ref *p = ds.point[i].waiting, *tmp; p;) {
			tmp = p->next;
			free();
			p = tmp;
		}

		free(ds.point[i].name);
	}

	(void) close(ds.pipefd[0]);
	(void) close(ds.pipefd[1]);

	say_debug("%s: done", __func__);
}


int
fds_wait(const char *point_name)
{
	if (inactive())
		return 0;

	struct fiber_syncpt *pt = acquire(point_name); /* TODO */
	if (pt == NULL)
		return -1;

	rc = fiber_syncpt_wait(pt);	/* TODO: must inc nwaiting */
	if (rc)
		return rc;

	/* Woke up: can we still go? */
	if (!pt->is_enabled)
		return -1;

	return 0;
}


int
fs_exec(const char *point_name)
{
	if (inactive())
		return 0;

	struct fiber_syncpt *pt = acquire(point_name);
	if (pt == NULL)
		return -1;

	if (pt->is_enabled && pt->is_busy) {
		say_debug("%p:%s [%s] is BUSY\n",
			(void*)fiber, __func__, point_name);
		return -1;
	}

	/* No waiters - bail out. */
	if (pt->waiting == NULL) {
		say_debug("%p:%s [%s] is IDLE\n",
			(void*)fiber, __func__, point_name);
		return 0;
	}

	/* Lock the sync point. */
	pt->is_busy = true;

	/* Wake up all fibers wating on the point. */
	rc = fiber_syncpt_broadcast(pt);
	if (rc)
		return rc;

	/* TODO: make sure we wake up if disabled or syncwait ended;
	 * 	 we sure should not wake up SPORADICALLY
	 */

	/* Sleep until all waiting fibers have unlocked us. */
	if (pt->host_locks > 0) 
		rc = fiber_syncpt_hold(pt); /* TODO: implement */
	
	say_debug("%p:%s UNLOCK [%s] %s %s\n",
			(void*)fiber, __func__, pt->name,
			pt->is_enabled ? "enabled" : "disabled",
			pt->is_busy ? "+S" : "-S");

	/* Sync point unlocked. */
	pt->is_busy = false;

	if (!pt->is_enabled) {
		 say_debug("%p:%s [%s] has been DISABLED\n",
			(void*)fiber, __func__, pt->name);
		return -1;
	}

	return 0;
}


int
fs_unlock(const char *point_name)
{
	if (inactive())
		return 0;

	struct fiber_syncpt *pt = look_up(point_name);
	if (pt == NULL) {
		say_debug("%p:%s [%s] does not exist\n",
			(void*)fiber, __func__, point_name);
		return -1;
	}

	assert(pt->host_locks > 0);

	if (--pt->host_locks == 0) {
		say_debug("%p:%s [%s] - must UNLOCK\n",
			(void*)fiber, __func__, pt->name);

		rc = fiber_syncpt_unlock(pt);
	}

	return rc;
}


int
fs_enable(const char *point_name, bool enable)
{
	if (inactive())
		return 0;

	struct fiber_syncpt *pt = look_up(point_name);
	if (pt == NULL)
		return -1;

	pt->is_enabled = enable;

	/* If disabled - err out pending waits. */
	return (!pt->is_enabled && pt->nwaiting > 0)
		? fiber_syncpt_broadcast(pt) : 0;
}


/** Disable all sync points, wake up pending wait sections. */
void
fs_disable_all()
{
	for (size_t i = 0; i < ds.point_count; ++i) {
		if (!ds.point[i].is_enabled)
			continue;

		ds.point[i].is_enabled = false;
		if (ds.point[i].nwaiting > 0)
			fiber_syncpt_broadcast(&ds.point[i]);
	}
}


void
fs_info(struct tbuf *out)
{
	if (inactive()) {
		tbuf_printf(out, "Debug syncronization is DISABLED", CRLF);
		return;
	}

	tbuf_printf(out, "Debug syncronization - %lu sync points:" CRLF,
		(unsigned long)ds.point_count);
	for(size_t i = 0; i < ds.point_count; ++i)
		tbuf_printf(out, "  - %s: %s, %s, %lu blocks" CRLF,
			ds.point[i].name,
			ds.point[i].is_enabled ? "enabled" : "disabled",
			ds.point[i].is_busy ? "BUSY" : "IDLE", 
			(unsigned long)ds.point[i].nwaiting);
}

