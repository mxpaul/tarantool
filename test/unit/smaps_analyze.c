#include <stdio.h>
#include <unistd.h>
#include "../../src/smaps_analyze.h"
#include "test.h"
#include <rlist.h>
#define PLAN 9

int
main(void)
{
	plan(PLAN);

	struct smap_region *region;
	struct rlist stat;
	stat.next = NULL;

	int aok = access("/proc/self/smaps", R_OK) == 0;

	ok(access("/proc/self/smaps", R_OK) == 0, "smaps were found");
	smaps_analyze(&stat);
	isnt(stat.next, NULL, "head was initialized");
	ok(!rlist_empty(&stat), "regions were found");

	int pfound = 0, xfound = 0, rfound = 0, wfound = 0, wrong_fromto = 0;
	int dfound = 0;
	rlist_foreach_entry(region, &stat, list) {
		if (region->flags & SMAP_REGION_R)
			rfound++;
		if (region->flags & SMAP_REGION_W)
			wfound++;
		if (region->flags & SMAP_REGION_X)
			xfound++;
		if (region->flags & SMAP_REGION_P)
			pfound++;
		if (region->to < region->from)
			wrong_fromto++;
		if (region->private_dirty)
			dfound++;
		if (region->shared_dirty)
			dfound++;
	}

	ok(rfound, "read  flag");
	ok(wfound, "write flag");
	ok(xfound, "exec  flag");
	ok(pfound, "priv  flag");
	is(wrong_fromto, 0, "wrong regions");

	smaps_free(&stat);
	ok(rlist_empty(&stat), "list was cleanup");
	return check_plan();
}
