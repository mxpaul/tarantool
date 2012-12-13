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

#include "smaps_analyze.h"
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

#define SMAPS_FILE "/proc/self/smaps"


%%{
	machine smaps;

	write data;
}%%

/**
 * print one map region
 */
int
smaps_print_region(struct smap_region *region)
{
	int res =
		printf("%p-%p (%c%c%c%c)\n",
			region->from,
			region->to,
			(region->flags & SMAP_REGION_R) ? 'r' : '-',
			(region->flags & SMAP_REGION_W) ? 'w' : '-',
			(region->flags & SMAP_REGION_X) ? 'x' : '-',
			(region->flags & SMAP_REGION_P) ? 'p' : '-'
		);

	if (region->shared_dirty > 0) {
		res += printf("Shared_Dirty: %zu b\n", region->shared_dirty);
	}
	if (region->private_dirty > 0) {
		res += printf("Private_Dirty: %zu b\n", region->private_dirty);
	}

	return res;
}


/**
 * print all map regions
 */
int
smaps_print(struct rlist *head)
{
	int res = 0;
	struct smap_region *region;
	rlist_foreach_entry(region, head, list) {
		res += smaps_print_region(region);
	}
	return res;
	(void)head;
	return 1;
}


/**
 * read information from /proc/self/smaps (if it exists)
 */
void
smaps_analyze(struct rlist *head)
{
	rlist_init(head);
	if (access(SMAPS_FILE, R_OK) != 0)
		return;

	char *buf = NULL;
	size_t bsize = 0;
	size_t read = 0;
	FILE *fh = fopen(SMAPS_FILE, "r");
	if (!fh)
		return;

	while(1) {
		if (bsize >= read) {
			char *nbuf = realloc(buf, bsize + 256);
			if (!nbuf)
				break;
			buf = nbuf;
			bsize += 256;
		}
		size_t len = fread(buf + read, 1, bsize - read, fh);
		if (len <= 0)
			break;
		read += len;
	}

	fclose(fh);

	if (bsize) {
		char *p = buf;
		char *pe = buf + read;
		char *eof = NULL;
		int cs;
		uint64_t address = 0;
		size_t pval = 0;
		const char *afrom = NULL;
		const char *ato = NULL;

		%%{
			action clean_address {
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
			action address_symbol {
				if (fc >= 'a' && fc <= 'f') {
					address <<= 4;
					address |= (fc - 'a' + 10) & 0x0F;
				} else if (fc >= 'A' && fc <= 'F') {
					address <<= 4;
					address |= (fc - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( fc - '0') & 0x0F;
				}
			}

			action pval_update {
				pval *= 10;
				pval += fc - '0';
			}

			action pval_update_scale {
				switch(fc) {
					case 'g':
					case 'G':
						pval *= 1024;
					case 'm':
					case 'M':
						pval *= 1024;
					case 'k':
					case 'K':
						pval *= 1024;
						break;
					default:
						pval = 0;
				}

			}

			action from_address {
				afrom = (typeof(afrom))address;
				address = 0;
			}
			action to_address {
				ato = (typeof(ato))address;

			}
			action attrs_found {
				struct smap_region *region =
					malloc(sizeof(struct smap_region));
				if (!region)
					fbreak;

				region->private_dirty	= 0;
				region->shared_dirty	= 0;
				region->from = afrom;
				region->to = ato;
				region->flags = 0;
				if (fpc[-1] == 'p')
					region->flags |= SMAP_REGION_P;
				if (fpc[-2] == 'x')
					region->flags |= SMAP_REGION_X;
				if (fpc[-3] == 'w')
					region->flags |= SMAP_REGION_W;
				if (fpc[-4] == 'r')
					region->flags |= SMAP_REGION_R;

				rlist_add_tail_entry(head, region, list);
			}

			action update_sdirty {
				if (!rlist_empty(head)) {
					struct smap_region *region =
						rlist_last_entry(head,
							struct smap_region,
							list);
					region->shared_dirty = pval;
				}
			}

			action update_pdirty {
				if (!rlist_empty(head)) {
					struct smap_region *region =
						rlist_last_entry(head,
							struct smap_region,
							list);
					region->private_dirty = pval;
				}
			}

			eol	=	'\n' %clean_address;

			hv	=	(digit+) $pval_update
					space+
					("k" | "K" | "m" | "M" | "g" | "G")
						$pval_update_scale
					( "b" | "B" )
			;

			hx	=	"0" | "1" | "2" | "3" | "4" |
					"5" | "6" | "7" | "8" | "9" |
					"a" | "b" | "c" | "d" | "e" | "f" |
					"A" | "B" | "C" | "D" | "E" | "F";

			address	=	hx{1,16};
			attrs	=
					("r" | "-")
					("w" | "-")
					("x" | "-")
					("p" | "-");
			text	=	(any - eol)+;

			afrom	=	address $address_symbol %from_address;
			ato	=	address $address_symbol %to_address;





			region	=	(
						afrom
						'-'
						ato
						space+
						attrs	%attrs_found
						space
						text
						eol
					);

			pdirty	=	"Private_Dirty:"
					space*
					hv %update_pdirty
					eol
			;

			sdirty	=	"Shared_Dirty:"
					space*
					hv %update_sdirty
					eol
			;

			trash	=	((any - eol)* - region) eol;
			

			main := ( region | pdirty | sdirty | trash )+;
			write init;
			write exec;
		}%%
	}

	free(buf);
}


/**
 * free memory
 */
void
smaps_free(struct rlist *head)
{
	while(!rlist_empty(head)) {
		struct smap_region *r =
			rlist_first_entry(head, struct smap_region, list);
		rlist_del_entry(r, list);
		free(r);
	}
}

/**
 * compare two smaps (return size(smap_to - smap_from)) 
 */
size_t
smaps_compare(struct rlist *smap_from, struct rlist *smap_to)
{
	if (rlist_empty(smap_from))
		return 0;
	if (rlist_empty(smap_to))
		return 0;
	struct smap_region *rf, *rt;


	size_t res = 0;
	rlist_foreach_entry(rt, smap_to, list) {
		/* new regions */
		size_t add_size = rt->to - rt->from;
		rlist_foreach_entry(rf, smap_from, list) {
			if(rf->from > rt->to || rf->to < rt->from)
				continue;
			add_size = 0;
			break;
		}
		res += add_size;

		/* overlapped regions */
		rlist_foreach_entry(rf, smap_from, list) {
			if (rf->from == rt->from && rf->to == rt->to) {
				if (rt->private_dirty > rf->private_dirty) {
					res += rt->private_dirty;
					res -= rf->private_dirty;
				}
			}
		}
	}

	return res;
}
/* vim: set ft=ragel : */
