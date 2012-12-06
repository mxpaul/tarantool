
#line 1 "src/smaps_analyze.rl"
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
#include "smaps_analyze.h"
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

#define SMAPS_FILE "/proc/self/smaps"



#line 45 "src/smaps_analyze.m"
static const int smaps_start = 0;
static const int smaps_first_final = 40;
static const int smaps_error = -1;

static const int smaps_en_main = 0;


#line 45 "src/smaps_analyze.rl"



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

		
#line 111 "src/smaps_analyze.m"
	{
	cs = smaps_start;
	}

#line 116 "src/smaps_analyze.m"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 0:
	if ( (*p) == 10 )
		goto st40;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr2;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr2;
	} else
		goto tr2;
	goto st1;
tr15:
#line 128 "src/smaps_analyze.rl"
	{
				struct smap_region *region =
					malloc(sizeof(struct smap_region));
				if (!region)
					{p++; cs = 1; goto _out;}

				region->from = afrom;
				region->to = ato;
				region->flags = 0;
				if (p[-1] == 'p')
					region->flags |= SMAP_REGION_P;
				if (p[-2] == 'x')
					region->flags |= SMAP_REGION_X;
				if (p[-3] == 'w')
					region->flags |= SMAP_REGION_W;
				if (p[-4] == 'r')
					region->flags |= SMAP_REGION_R;

				rlist_add_entry(head, region, list);


			}
	goto st1;
tr45:
#line 102 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
			}
	goto st1;
st1:
	if ( ++p == pe )
		goto _test_eof1;
case 1:
#line 171 "src/smaps_analyze.m"
	if ( (*p) == 10 )
		goto st40;
	goto st1;
tr16:
#line 128 "src/smaps_analyze.rl"
	{
				struct smap_region *region =
					malloc(sizeof(struct smap_region));
				if (!region)
					{p++; cs = 40; goto _out;}

				region->from = afrom;
				region->to = ato;
				region->flags = 0;
				if (p[-1] == 'p')
					region->flags |= SMAP_REGION_P;
				if (p[-2] == 'x')
					region->flags |= SMAP_REGION_X;
				if (p[-3] == 'w')
					region->flags |= SMAP_REGION_W;
				if (p[-4] == 'r')
					region->flags |= SMAP_REGION_R;

				rlist_add_entry(head, region, list);


			}
	goto st40;
tr46:
#line 102 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
			}
	goto st40;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
#line 212 "src/smaps_analyze.m"
	if ( (*p) == 10 )
		goto tr46;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr47;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr47;
	} else
		goto tr47;
	goto tr45;
tr2:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st2;
tr47:
#line 102 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
			}
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st2;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
#line 264 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr4;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr4;
	} else
		goto tr4;
	goto st1;
tr3:
#line 120 "src/smaps_analyze.rl"
	{
				afrom = (typeof(afrom))address;
				address = 0;
			}
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 289 "src/smaps_analyze.m"
	if ( (*p) == 10 )
		goto st40;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr5;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr5;
	} else
		goto tr5;
	goto st1;
tr5:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st4;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
#line 320 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr8;
		} else if ( (*p) >= 65 )
			goto tr8;
	} else
		goto tr8;
	goto st1;
tr6:
#line 124 "src/smaps_analyze.rl"
	{
				ato = (typeof(ato))address;

			}
	goto st5;
tr48:
#line 102 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
			}
	goto st5;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
#line 356 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st41;
		case 32: goto st5;
		case 45: goto st6;
		case 114: goto st6;
	}
	if ( 9 <= (*p) && (*p) <= 13 )
		goto st5;
	goto st1;
tr7:
#line 124 "src/smaps_analyze.rl"
	{
				ato = (typeof(ato))address;

			}
	goto st41;
tr49:
#line 102 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
			}
	goto st41;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
#line 385 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr49;
		case 32: goto tr48;
		case 45: goto tr50;
		case 114: goto tr50;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr48;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr47;
		} else if ( (*p) >= 65 )
			goto tr47;
	} else
		goto tr47;
	goto tr45;
tr50:
#line 102 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
			}
	goto st6;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
#line 416 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto st7;
		case 119: goto st7;
	}
	goto st1;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto st8;
		case 120: goto st8;
	}
	goto st1;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto st9;
		case 112: goto st9;
	}
	goto st1;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
	switch( (*p) ) {
		case 10: goto tr16;
		case 32: goto tr15;
	}
	if ( 9 <= (*p) && (*p) <= 13 )
		goto tr15;
	goto st1;
tr8:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 473 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr17;
		} else if ( (*p) >= 65 )
			goto tr17;
	} else
		goto tr17;
	goto st1;
tr17:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st11;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
#line 509 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr18;
		} else if ( (*p) >= 65 )
			goto tr18;
	} else
		goto tr18;
	goto st1;
tr18:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st12;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
#line 545 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr19;
		} else if ( (*p) >= 65 )
			goto tr19;
	} else
		goto tr19;
	goto st1;
tr19:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 581 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr20;
		} else if ( (*p) >= 65 )
			goto tr20;
	} else
		goto tr20;
	goto st1;
tr20:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st14;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
#line 617 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr21;
		} else if ( (*p) >= 65 )
			goto tr21;
	} else
		goto tr21;
	goto st1;
tr21:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st15;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
#line 653 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr22;
		} else if ( (*p) >= 65 )
			goto tr22;
	} else
		goto tr22;
	goto st1;
tr22:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 689 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr23;
		} else if ( (*p) >= 65 )
			goto tr23;
	} else
		goto tr23;
	goto st1;
tr23:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st17;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
#line 725 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr24;
		} else if ( (*p) >= 65 )
			goto tr24;
	} else
		goto tr24;
	goto st1;
tr24:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st18;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
#line 761 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr25;
		} else if ( (*p) >= 65 )
			goto tr25;
	} else
		goto tr25;
	goto st1;
tr25:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 797 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr26;
		} else if ( (*p) >= 65 )
			goto tr26;
	} else
		goto tr26;
	goto st1;
tr26:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st20;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
#line 833 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr27;
		} else if ( (*p) >= 65 )
			goto tr27;
	} else
		goto tr27;
	goto st1;
tr27:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st21;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
#line 869 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr28;
		} else if ( (*p) >= 65 )
			goto tr28;
	} else
		goto tr28;
	goto st1;
tr28:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st22;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
#line 905 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr29;
		} else if ( (*p) >= 65 )
			goto tr29;
	} else
		goto tr29;
	goto st1;
tr29:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st23;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
#line 941 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr6;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr30;
		} else if ( (*p) >= 65 )
			goto tr30;
	} else
		goto tr30;
	goto st1;
tr30:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st24;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
#line 977 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr7;
		case 32: goto tr6;
	}
	if ( 9 <= (*p) && (*p) <= 13 )
		goto tr6;
	goto st1;
tr4:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st25;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
#line 1004 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr31;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr31;
	} else
		goto tr31;
	goto st1;
tr31:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st26;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
#line 1037 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr32;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr32;
	} else
		goto tr32;
	goto st1;
tr32:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st27;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
#line 1070 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr33;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr33;
	} else
		goto tr33;
	goto st1;
tr33:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st28;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
#line 1103 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr34;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr34;
	} else
		goto tr34;
	goto st1;
tr34:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st29;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
#line 1136 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr35;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr35;
	} else
		goto tr35;
	goto st1;
tr35:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st30;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
#line 1169 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr36;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr36;
	} else
		goto tr36;
	goto st1;
tr36:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st31;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
#line 1202 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr37;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr37;
	} else
		goto tr37;
	goto st1;
tr37:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st32;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
#line 1235 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr38;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr38;
	} else
		goto tr38;
	goto st1;
tr38:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st33;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
#line 1268 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr39;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr39;
	} else
		goto tr39;
	goto st1;
tr39:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st34;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
#line 1301 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr40;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr40;
	} else
		goto tr40;
	goto st1;
tr40:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st35;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
#line 1334 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr41;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr41;
	} else
		goto tr41;
	goto st1;
tr41:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st36;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
#line 1367 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr42;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr42;
	} else
		goto tr42;
	goto st1;
tr42:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st37;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
#line 1400 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr43;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr43;
	} else
		goto tr43;
	goto st1;
tr43:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st38;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
#line 1433 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr44;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr44;
	} else
		goto tr44;
	goto st1;
tr44:
#line 107 "src/smaps_analyze.rl"
	{
				if ((*p) >= 'a' && (*p) <= 'f') {
					address <<= 4;
					address |= ((*p) - 'a' + 10) & 0x0F;
				} else if ((*p) >= 'A' && (*p) <= 'F') {
					address <<= 4;
					address |= ((*p) - 'A' + 10) & 0x0F;
				} else {
					address <<= 4;
					address |= ( (*p) - '0') & 0x0F;
				}
			}
	goto st39;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
#line 1466 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st40;
		case 45: goto tr3;
	}
	goto st1;
	}
	_test_eof1: cs = 1; goto _test_eof; 
	_test_eof40: cs = 40; goto _test_eof; 
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof41: cs = 41; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof9: cs = 9; goto _test_eof; 
	_test_eof10: cs = 10; goto _test_eof; 
	_test_eof11: cs = 11; goto _test_eof; 
	_test_eof12: cs = 12; goto _test_eof; 
	_test_eof13: cs = 13; goto _test_eof; 
	_test_eof14: cs = 14; goto _test_eof; 
	_test_eof15: cs = 15; goto _test_eof; 
	_test_eof16: cs = 16; goto _test_eof; 
	_test_eof17: cs = 17; goto _test_eof; 
	_test_eof18: cs = 18; goto _test_eof; 
	_test_eof19: cs = 19; goto _test_eof; 
	_test_eof20: cs = 20; goto _test_eof; 
	_test_eof21: cs = 21; goto _test_eof; 
	_test_eof22: cs = 22; goto _test_eof; 
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof28: cs = 28; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof31: cs = 31; goto _test_eof; 
	_test_eof32: cs = 32; goto _test_eof; 
	_test_eof33: cs = 33; goto _test_eof; 
	_test_eof34: cs = 34; goto _test_eof; 
	_test_eof35: cs = 35; goto _test_eof; 
	_test_eof36: cs = 36; goto _test_eof; 
	_test_eof37: cs = 37; goto _test_eof; 
	_test_eof38: cs = 38; goto _test_eof; 
	_test_eof39: cs = 39; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 40: 
	case 41: 
#line 102 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
			}
	break;
#line 1528 "src/smaps_analyze.m"
	}
	}

	_out: {}
	}

#line 185 "src/smaps_analyze.rl"

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
