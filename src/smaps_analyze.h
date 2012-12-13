#ifndef INCLUDES_TARANTOOL_SMAPS_ANALYZE_H
#define INCLUDES_TARANTOOL_SMAPS_ANALYZE_H
/*
 * Redistribution and use in source and binary forms, with or
 * without modification, are permitted provided that the following
 * conditions are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the
 *    following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * <COPYRIGHT HOLDER> OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
#include <rlist.h>
#include <stdlib.h>

#define SMAP_REGION_W	(1 << 0)
#define SMAP_REGION_R	(1 << 1)
#define SMAP_REGION_P	(1 << 2)
#define SMAP_REGION_X	(1 << 3)

struct smap_region {
	const char *from;
	const char *to;
	int flags;
	struct rlist list;

	size_t private_dirty;
	size_t shared_dirty;
};


size_t smaps_compare(struct rlist *smap_from, struct rlist *smap_to);
void smaps_analyze(struct rlist *head);
void smaps_free(struct rlist *head);

#endif /* INCLUDES_TARANTOOL_SMAPS_ANALYZE_H */
