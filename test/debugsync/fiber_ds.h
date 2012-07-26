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


/************************************************************************
 * Fiber Debug Synchronization framework allows to introduce syncpoints
 * into the fiber-driven code.
 *
 * A syncpoint has the following behavior traits:
 *
 *	1. Any other fiber can *wait* for it to be reached;
 *	2. Once reached, it will *wake up* all fibers waiting for it;
 *	3. Will *hold* for the waiting fibers, once they've woken up,
 *	   until they have *unlocked* the syncpoint.
 *	4. Proceed once *unlocked*.
 *
 * Read on the rationale for syncpoints here:
 * http://forge.mysql.com/wiki/MySQL_Internals_Test_Synchronization#Debug_Sync_Facility
 *
 ************************************************************************/

#ifndef FIBERDS_H_20120703
#define FIBERDS_H_20120703

#include <sys/types.h>
#include <stdbool.h>

#include "util.h"


/** Add any new syncpoint := (sync_point_name, is_enabled) here: */
/* TODO: replace with REAL (non-test) syncpoints */
#define SYNCPT_LIST(_)			\
	_(SYNCPT_txn_foo1, false)	\
	_(SYNCPT_txn_foo2, false)	\
	_(SYNCPT_txn_commit, true)	\
	_(SYNCPT_txn_foo3, true)
ENUM0(syncpt_enum, SYNCPT_LIST);


/** Use this macro to insert a synchronization point. */
#define	FDSYNC_SET(name)	(void)fds_exec(name)

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Initialize debug syncpoint framework, allocate resources.
 *
 * @param activate if false leaves all debug sync operations disabled.
 *
 * @return 0 if framework initialized, non-zero otherwise.
 */
void fds_init(bool activate);

/**
 * Release all resources allocated for debug sync framework.
 */
void fds_destroy();

/**
 * Toggle the framework's active/disabled status.
 *
 * @param active enables/disables debug sync framework.
 */
int fds_activate(bool activate);

/**
 * Enable or disable an existing sync point.
 *
 * @param point_name name of the sync point.
 * @param enable enable or disable sync point's execution.
 *
 * @return 0 if the sync point's statue was successfully changed.
 */
int fds_enable(const char *point_name, bool enable);

/**
 * Disable all known sync points.
 */
void fds_disable_all();

/**
 * Execute (pass through) a sync point.
 *
 * @param point_id numeric ID of the sync point.
 *
 * @return 0 if the sync point has been executed successfully.
 */
int fds_exec(int point_id);

/**
 * Wait for a sync point to be reached.
 *
 * @param point_name name of the sync point.
 *
 * @return 0 if the sync point was reached in a valid state.
 */
int fds_wait(const char *point_name);

/**
 * Attempt to unlock a sync point (holding for its waiters).
 *
 * @param point_name name of the sync point.
 *
 * @return 0 if 'unblock' event has been raised successfully.
 */
int fds_unlock(const char *point_name);

/**
 * Output (into a buffer) framework info/statistics in human-readable form.
 *
 * @param out destination buffer.
 */
void fds_info(struct tbuf *out);

#ifdef __cplusplus
}
#endif

#endif /* DEBUGSYNC_H_20120703 */
/* __EOF__ */

