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


int
smaps_print_region(struct smap_region *region)
{
	return
		printf("%p-%p (%c%c%c%c)\n",
			region->from,
			region->to,
			(region->flags & SMAP_REGION_R) ? 'r' : '-',
			(region->flags & SMAP_REGION_W) ? 'w' : '-',
			(region->flags & SMAP_REGION_X) ? 'x' : '-',
			(region->flags & SMAP_REGION_P) ? 'p' : '-'
		);
}

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
		const char *afrom = NULL;
		const char *ato = NULL;

		%%{
			action clean_address {
				afrom = NULL;
				ato = NULL;
				address = 0;
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

				rlist_add_entry(head, region, list);


			}

			hx	=	"0" | "1" | "2" | "3" | "4" |
					"5" | "6" | "7" | "8" | "9" |
					"a" | "b" | "c" | "d" | "e" | "f" |
					"A" | "B" | "C" | "D" | "E" | "F";

			eol	=	'\n' %clean_address;
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
						eol %clean_address
					);
			trash	=	((any - eol)* - region) eol;


			main := (region | trash )+;
			write init;
			write exec;
		}%%
	}

	free(buf);
}

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

/* vim: set ft=ragel : */
