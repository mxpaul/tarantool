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
#include "fiber_cond.h"


struct fiber_ref {
	struct fiber		*target;
	struct fiber_ref	*next;
};

struct fiber_cond {
	/** Index in the registry + 1; 0 = unused. */
	int				index;
	/** Fibers blocked on the variable. */
	struct fiber_ref		*blocked;
};


enum {
	/** Hard limit on # of cond vars. */
	MAX_FIBER_COND = 255
};


static struct cond_registry {
	ev_io			io;
	int			pipefd[2];
	struct	fiber_cond	cond[MAX_FIBER_COND];
} fcond_registry;


struct cond_dgram {
	char	op;
	int	index;
};



static inline bool
valid_dgram(struct cond_dgram *dgram)
{
	do {
		if (dgram->op != 'B' && dgram->op != 'S')
			break;
	
		if (dgram->index <= 0 || dgram->index > MAX_FIBER_COND)
			break;

		if (fcond_registry.cond[dgram->index - 1].index != dgram->index)
			break;

		return true;
	} while(0);

	say_error("Datagram verification failed: D=[op=%c, index=%d], cond.index=%d\n",
		dgram->op, dgram->index, fcond_registry.cond[dgram->index - 1].index);
	return false;
}


static void
fiber_cond_cb(ev_watcher *watcher __attribute__((unused)), int event __attribute__((unused)))
{
	struct cond_dgram dgram = {'\0', 0};
	ssize_t nrd = -1;

	say_debug("Fiber condition event: watcher=%p, event=%d", (void*)watcher, event);
	assert(fiber == &sched);

	while (1) {
		nrd = read(fcond_registry.pipefd[0], &dgram, sizeof(dgram));
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
		
		struct fiber_cond *fcond = &fcond_registry.cond[dgram.index - 1];
		say_debug("%s: [%c] condition=%p", __func__, dgram.op, (void*)fcond);

		if (!fcond->blocked) {
			say_debug("%s: no fibers are blocked on condition %p, skipping.",
				__func__, (void*)fcond);
			continue;
		}

		if (dgram.op == 'B') {
			/* Call all blocked fibers, mark the refs processed. */
			struct fiber_ref *head = fcond->blocked,
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
					__func__, (void*)ref->target, (void*)fcond);
				struct fiber_ref *tmp = ref->next;
				free(ref); /* TODO */
				ref = tmp;
			}

			/* Trim the list. */
			if (prev)
				prev->next = NULL;
			else
				fcond->blocked = NULL;
		}
		else if (dgram.op == 'S') {
			/* Grab the current head and call the referenced fiber. */
			struct fiber_ref *head = fcond->blocked;

			say_debug("%s: waking up fiber %p (signal)",
					__func__, (void*)head->target);
			fiber_call(head->target);

			/* Find the element preceding the head
			   (head before fiber_call). */
			struct fiber_ref *prev = NULL;
			for(struct fiber_ref *ref = fcond->blocked;
				ref && ref != head; prev = ref, ref = ref->next);

			/* Trim the list. */
			if (prev)
				prev->next = head->next;
			else
				fcond->blocked = NULL;

			/* Remove the (former) head. */
			free(head);
		}

		say_debug("%s: %s more fibers blocked on cond %p",
			__func__, fcond->blocked ? "still" : "no",
			(void*)fcond);

	} /* while */

	return;
}


void
fiber_cond_global_init()
{
	if (pipe(fcond_registry.pipefd) != 0 ||
	     set_nonblock(fcond_registry.pipefd[0]) != 0 ||
	     set_nonblock(fcond_registry.pipefd[0]) != 0)
			panic("Error setting up fiber-condition "
				"event pipe");

	ev_io_init(&fcond_registry.io, (void*)&fiber_cond_cb,
		fcond_registry.pipefd[0], EV_READ);

	/* We could maintain a usage counter and enable the read-pipe fd
	 * only as needed, but to simplify things *right now* we won't.
	 */
	 ev_io_start(&fcond_registry.io);

	 say_debug("%s: done", __func__);
}


void
fiber_cond_global_destroy()
{
	ev_io_stop(&fcond_registry.io);

	fiber_cond_destroy_all();

	(void) close(fcond_registry.pipefd[0]);
	(void) close(fcond_registry.pipefd[1]);

	say_debug("%s: done", __func__);
}


int
fiber_cond_init(struct fiber_cond **fcond)
{
	size_t i = 0;
	for(;; ++i) {
		if (i >= MAX_FIBER_COND) {
			say_error("Failed to create new fiber condition.");
			return -1;
		}
		else if (fcond_registry.cond[i].index <= 0)
			break;
	}

	fcond_registry.cond[i].index = i + 1;
	fcond_registry.cond[i].blocked = NULL;

	*fcond = &fcond_registry.cond[i];

	say_debug("%s: condition %p [index=%d] created", __func__, (void*)*fcond,
		fcond_registry.cond[i].index);
	return 0;
}


int
fiber_cond_destroy(struct fiber_cond *fcond)
{
	assert(fcond->index > 0);

	if (fcond->blocked != NULL) {
		say_warn("Destroying fiber condition %p with waiting fibers.",
			(void*)fcond);
		/* TODO: what do we do in such a case? wake fibers up or not? */

		for (struct fiber_ref *ref = fcond->blocked; ref != NULL; ) {
			struct fiber_ref *tmp = ref->next;

			say_debug("%s: fiber %p will be detached from condition %p",
				__func__, (void*)ref->target, (void*)fcond);

			free(ref); /* TODO: malloc/free */
			ref = tmp;
		}
	}

	say_debug("%s: destroyed condition %p [index=%d]", __func__,
		(void*)fcond, fcond->index);

	fcond->index  = 0; /* Unused now. */
	return 0;
}


void
fiber_cond_destroy_all()
{
	for(size_t i = 0; i < MAX_FIBER_COND; ++i)
		if (fcond_registry.cond[i].index > 0)
			(void) fiber_cond_destroy(&fcond_registry.cond[i]);
}


int
fiber_cond_wait(struct fiber_cond *fcond)
{
	assert(fcond->index > 0);

	struct fiber_ref *ref = calloc(1, sizeof(ref)); /* TODO: malloc */
	if (ref == NULL)
		panic("%s: failed to create fiber condition reference", __func__);

	ref->target = fiber; /* Current fiber. */

	/* Head insert. */
	ref->next = fcond->blocked;
	fcond->blocked = ref;

	say_debug("%s: fiber %p will now block on condition %p",
		__func__, (void*)fiber, (void*)fcond);

	fiber_yield();
	fiber_testcancel();

	say_debug("%s: fiber %p woke up on condition %p",
		__func__, (void*)fiber, (void*)fcond);
	return 0;
}


static int
fiber_cond_raise(char op, struct fiber_cond *fcond)
{
	struct cond_dgram dgram = {'\0', 0};

	assert(op == 'B' || op == 'S');
	dgram.op = op;

	assert(fcond->index > 0);
	dgram.index = fcond->index;

	say_debug("%s: raising [%c] condition %p", __func__, op, (void*)fcond);

	ssize_t nwr = write(fcond_registry.pipefd[1], &dgram, sizeof(dgram));
	if (nwr != sizeof(dgram)) {
		say_error("Error writing to fiber-condition pipe, nwr=%ld",
			(long)nwr);
		return -1;
	}
	return 0;
}


int
fiber_cond_signal(struct fiber_cond *fcond)
{
	return fiber_cond_raise('S', fcond);
}


int
fiber_cond_broadcast(struct fiber_cond *fcond)
{
	return fiber_cond_raise('B', fcond);
}


