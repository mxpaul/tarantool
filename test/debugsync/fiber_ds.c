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
	/** Index in the ds + 1; 0 = unused. */
	int			index;
	/** Fibers blocked on the variable. */
	struct fiber_ref	*blocked;
	/** # of active waiting sections. */
	size_t 			nblocked;
};


enum {
	/** Hard limit on # of cond vars. */
	MAX_FIBER_SYNCPT = 255
};


static struct syncpt_ds {
	ev_io			io;
	int			pipefd[2];

	/**  Activation control flags (see header for details). */
	u_int32_t		activation;

	struct	fiber_syncpt	point[MAX_FIBER_SYNCPT];
	size_t 			count;
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


void
fds_init()
{
	ds.activation	= activation_flags;
	ds.count	= 0;

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

	destroy_all(); /* TODO: */

	(void) close(ds.pipefd[0]);
	(void) close(ds.pipefd[1]);

	say_debug("%s: done", __func__);
}


int
fds_wait(const char *point_name)
{
	int rc = 0;

	if (inactive())
		return 0;

	struct fiber_syncpt *pt = NULL;
	do {
		pt = acquire(point_name); /* TODO */
		if (pt == NULL)
			return -1;

		rc = fiber_syncpt_wait(pt);	/* TODO: must inc nblocked */
		if (rc)
			break;

		if (!pt->is_enabled) {
			rc = -1;
			break;
		}
	} while(0);

	return rc;
}


/* ==================================== */


static inline bool
valid_dgram(struct ds_dgram *dgram)
{
	do {
		if (dgram->op != 'B' && dgram->op != 'S')
			break;
	
		if (dgram->index <= 0 || dgram->index > MAX_FIBER_SYNCPT)
			break;

		if (ds.point[dgram->index - 1].index != dgram->index)
			break;

		return true;
	} while(0);

	say_error("Datagram verification failed: D=[op=%c, index=%d], cond.index=%d\n",
		dgram->op, dgram->index, ds.point[dgram->index - 1].index);
	return false;
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

		if (!valid_dgram(&dgram)) /* TODO: corrupt structure is a fatal error. */
			break;
		
		struct fiber_syncpt *fsync = &ds.point[dgram.index - 1];
		say_debug("%s: [%c] condition=%p", __func__, dgram.op, (void*)fsync);

		if (!fsync->blocked) {
			say_debug("%s: no fibers are blocked on condition %p, skipping.",
				__func__, (void*)fsync);
			continue;
		}

		if (dgram.op == 'B') {
			/* Call all blocked fibers, mark the refs processed. */
			struct fiber_ref *head = fsync->blocked,
					*ref = NULL;

			for(ref = head; ref != NULL; ref = ref->next) {
				say_debug("%s: waking up fiber %p (broadcast)",
					__func__, (void*)ref->target);
				fiber_call(ref->target);

				ref->target = NULL; /* Mark it. */
				say_debug("%s: marking up fiber %p", __func__, (void*)ref->target);
			}

			/* Find the first ref with ref->target == NULL, save the preceding ref. */
			struct fiber_ref *prev = NULL;
			for(ref = head; ref && ref->target != NULL; prev = ref, ref = ref->next);

			/* Remove all after the first marked ref. */
			while(ref) {
				assert(ref->target);
				say_debug("%s: removing fiber %p from condition %p",
					__func__, (void*)ref->target, (void*)fsync);
				struct fiber_ref *tmp = ref->next;
				free(ref); /* TODO */
				ref = tmp;
			}

			/* Trim the list. */
			if (prev)
				prev->next = NULL;
			else
				fsync->blocked = NULL;
		}
		else if (dgram.op == 'S') {
			/* Grab the current head and call the referenced fiber. */
			struct fiber_ref *head = fsync->blocked;

			say_debug("%s: waking up fiber %p (signal)",
					__func__, (void*)head->target);
			fiber_call(head->target);

			/* Find the element preceding the head
			   (head before fiber_call). */
			struct fiber_ref *prev = NULL;
			for(struct fiber_ref *ref = fsync->blocked;
				ref && ref != head; prev = ref, ref = ref->next);

			/* Trim the list. */
			if (prev)
				prev->next = head->next;
			else
				fsync->blocked = NULL;

			/* Remove the (former) head. */
			free(head);
		}

		say_debug("%s: %s more fibers blocked on cond %p",
			__func__, fsync->blocked ? "still" : "no",
			(void*)fsync);

	} /* while */

	return;
}



int
fiber_syncpt_init(struct fiber_syncpt **fsync)
{
	size_t i = 0;
	for(;; ++i) {
		if (i >= MAX_FIBER_SYNCPT) {
			say_error("Failed to create new fiber condition.");
			return -1;
		}
		else if (ds.point[i].index <= 0)
			break;
	}

	ds.point[i].index = i + 1;
	ds.point[i].blocked = NULL;

	*fsync = &ds.point[i];

	say_debug("%s: condition %p [index=%d] created", __func__, (void*)*fsync,
		ds.point[i].index);
	return 0;
}


int
fiber_syncpt_destroy(struct fiber_syncpt *fsync)
{
	assert(fsync->index > 0);

	if (fsync->blocked != NULL) {
		say_warn("Destroying fiber condition %p with waiting fibers.",
			(void*)fsync);
		/* TODO: what do we do in such a case? wake fibers up or not? */

		for (struct fiber_ref *ref = fsync->blocked; ref != NULL; ) {
			struct fiber_ref *tmp = ref->next;

			say_debug("%s: fiber %p will be detached from condition %p",
				__func__, (void*)ref->target, (void*)fsync);

			free(ref); /* TODO: malloc/free */
			ref = tmp;
		}
	}

	say_debug("%s: destroyed condition %p [index=%d]", __func__,
		(void*)fsync, fsync->index);

	fsync->index  = 0; /* Unused now. */
	return 0;
}


void
fiber_syncpt_destroy_all()
{
	for(size_t i = 0; i < MAX_FIBER_SYNCPT; ++i)
		if (ds.point[i].index > 0)
			(void) fiber_syncpt_destroy(&ds.point[i]);
}


int
fiber_syncpt_wait(struct fiber_syncpt *fsync)
{
	assert(fsync->index > 0);

	struct fiber_ref *ref = calloc(1, sizeof(ref)); /* TODO: malloc */
	if (ref == NULL)
		panic("%s: failed to create fiber condition reference", __func__);

	ref->target = fiber; /* Current fiber. */

	/* Head insert. */
	ref->next = fsync->blocked;
	fsync->blocked = ref;

	say_debug("%s: fiber %p will now block on condition %p",
		__func__, (void*)fiber, (void*)fsync);

	fiber_yield();
	fiber_testcancel();

	say_debug("%s: fiber %p woke up on condition %p",
		__func__, (void*)fiber, (void*)fsync);
	return 0;
}


static int
fiber_syncpt_raise(char op, struct fiber_syncpt *fsync)
{
	struct ds_dgram dgram = {'\0', 0};

	assert(op == 'B' || op == 'S');
	dgram.op = op;

	assert(fsync->index > 0);
	dgram.index = fsync->index;

	say_debug("%s: raising [%c] condition %p", __func__, op, (void*)fsync);

	ssize_t nwr = write(ds.pipefd[1], &dgram, sizeof(dgram));
	if (nwr != sizeof(dgram)) {
		say_error("Error writing to fiber-condition pipe, nwr=%ld",
			(long)nwr);
		return -1;
	}
	return 0;
}


int
fiber_syncpt_signal(struct fiber_syncpt *fsync)
{
	return fiber_syncpt_raise('S', fsync);
}


int
fiber_syncpt_broadcast(struct fiber_syncpt *fsync)
{
	return fiber_syncpt_raise('B', fsync);
}


