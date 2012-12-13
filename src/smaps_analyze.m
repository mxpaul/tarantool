
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
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

#define SMAPS_FILE "/proc/self/smaps"



#line 44 "src/smaps_analyze.m"
static const int smaps_start = 0;
static const int smaps_first_final = 138;
static const int smaps_error = -1;

static const int smaps_en_main = 0;


#line 44 "src/smaps_analyze.rl"


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

		
#line 143 "src/smaps_analyze.m"
	{
	cs = smaps_start;
	}

#line 148 "src/smaps_analyze.m"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 0:
	switch( (*p) ) {
		case 10: goto st138;
		case 80: goto st29;
		case 83: goto st42;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr2;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr2;
	} else
		goto tr2;
	goto st1;
tr17:
#line 184 "src/smaps_analyze.rl"
	{
				struct smap_region *region =
					malloc(sizeof(struct smap_region));
				if (!region)
					{p++; cs = 1; goto _out;}

				region->private_dirty	= 0;
				region->shared_dirty	= 0;
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

				rlist_add_tail_entry(head, region, list);
			}
	goto st1;
tr149:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st1;
st1:
	if ( ++p == pe )
		goto _test_eof1;
case 1:
#line 207 "src/smaps_analyze.m"
	if ( (*p) == 10 )
		goto st138;
	goto st1;
tr42:
#line 217 "src/smaps_analyze.rl"
	{
				if (!rlist_empty(head)) {
					struct smap_region *region =
						rlist_last_entry(head,
							struct smap_region,
							list);
					region->private_dirty = pval;
				}
			}
	goto st138;
tr74:
#line 207 "src/smaps_analyze.rl"
	{
				if (!rlist_empty(head)) {
					struct smap_region *region =
						rlist_last_entry(head,
							struct smap_region,
							list);
					region->shared_dirty = pval;
				}
			}
	goto st138;
tr150:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st138;
st138:
	if ( ++p == pe )
		goto _test_eof138;
case 138:
#line 248 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr150;
		case 80: goto tr152;
		case 83: goto tr153;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr151;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr151;
	} else
		goto tr151;
	goto tr149;
tr2:
#line 140 "src/smaps_analyze.rl"
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
tr151:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
#line 140 "src/smaps_analyze.rl"
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
#line 304 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr6;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr6;
	} else
		goto tr6;
	goto st1;
tr5:
#line 176 "src/smaps_analyze.rl"
	{
				afrom = (typeof(afrom))address;
				address = 0;
			}
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 329 "src/smaps_analyze.m"
	if ( (*p) == 10 )
		goto st138;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr7;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr7;
	} else
		goto tr7;
	goto st1;
tr7:
#line 140 "src/smaps_analyze.rl"
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
#line 360 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr10;
		} else if ( (*p) >= 65 )
			goto tr10;
	} else
		goto tr10;
	goto st1;
tr8:
#line 180 "src/smaps_analyze.rl"
	{
				ato = (typeof(ato))address;

			}
	goto st5;
tr154:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st5;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
#line 397 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st139;
		case 32: goto st5;
		case 45: goto st6;
		case 114: goto st6;
	}
	if ( 9 <= (*p) && (*p) <= 13 )
		goto st5;
	goto st1;
tr9:
#line 180 "src/smaps_analyze.rl"
	{
				ato = (typeof(ato))address;

			}
	goto st139;
tr155:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st139;
st139:
	if ( ++p == pe )
		goto _test_eof139;
case 139:
#line 427 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr155;
		case 32: goto tr154;
		case 45: goto tr156;
		case 80: goto tr152;
		case 83: goto tr153;
		case 114: goto tr156;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr154;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr151;
		} else if ( (*p) >= 65 )
			goto tr151;
	} else
		goto tr151;
	goto tr149;
tr156:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st6;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
#line 461 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto st7;
		case 119: goto st7;
	}
	goto st1;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto st8;
		case 120: goto st8;
	}
	goto st1;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto st9;
		case 112: goto st9;
	}
	goto st1;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
	switch( (*p) ) {
		case 10: goto tr18;
		case 32: goto tr17;
	}
	if ( 9 <= (*p) && (*p) <= 13 )
		goto tr17;
	goto st1;
tr18:
#line 184 "src/smaps_analyze.rl"
	{
				struct smap_region *region =
					malloc(sizeof(struct smap_region));
				if (!region)
					{p++; cs = 140; goto _out;}

				region->private_dirty	= 0;
				region->shared_dirty	= 0;
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

				rlist_add_tail_entry(head, region, list);
			}
	goto st140;
st140:
	if ( ++p == pe )
		goto _test_eof140;
case 140:
#line 528 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr150;
		case 80: goto tr157;
		case 83: goto tr158;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr151;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr151;
	} else
		goto tr151;
	goto tr149;
tr157:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 556 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 114: goto st11;
	}
	goto st1;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
	switch( (*p) ) {
		case 10: goto st138;
		case 105: goto st12;
	}
	goto st1;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
	switch( (*p) ) {
		case 10: goto st138;
		case 118: goto st13;
	}
	goto st1;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
	switch( (*p) ) {
		case 10: goto st138;
		case 97: goto st14;
	}
	goto st1;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
	switch( (*p) ) {
		case 10: goto st138;
		case 116: goto st15;
	}
	goto st1;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
	switch( (*p) ) {
		case 10: goto st138;
		case 101: goto st16;
	}
	goto st1;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
	switch( (*p) ) {
		case 10: goto st138;
		case 95: goto st17;
	}
	goto st1;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
	switch( (*p) ) {
		case 10: goto st138;
		case 68: goto st18;
	}
	goto st1;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
	switch( (*p) ) {
		case 10: goto st138;
		case 105: goto st19;
	}
	goto st1;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
	switch( (*p) ) {
		case 10: goto st138;
		case 114: goto st20;
	}
	goto st1;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
	switch( (*p) ) {
		case 10: goto st138;
		case 116: goto st21;
	}
	goto st1;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
	switch( (*p) ) {
		case 10: goto st138;
		case 121: goto st22;
	}
	goto st1;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	switch( (*p) ) {
		case 10: goto st138;
		case 58: goto st23;
	}
	goto st1;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	switch( (*p) ) {
		case 10: goto st141;
		case 32: goto st23;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr33;
	} else if ( (*p) >= 9 )
		goto st23;
	goto st1;
st141:
	if ( ++p == pe )
		goto _test_eof141;
case 141:
	switch( (*p) ) {
		case 10: goto tr160;
		case 32: goto tr159;
		case 80: goto tr152;
		case 83: goto tr153;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr159;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr151;
		} else if ( (*p) >= 65 )
			goto tr151;
	} else
		goto tr161;
	goto tr149;
tr159:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st24;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
#line 719 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st142;
		case 32: goto st24;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr36;
	} else if ( (*p) >= 9 )
		goto st24;
	goto st1;
tr160:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st142;
st142:
	if ( ++p == pe )
		goto _test_eof142;
case 142:
#line 743 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr160;
		case 32: goto tr159;
		case 80: goto tr152;
		case 83: goto tr153;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr159;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr151;
		} else if ( (*p) >= 65 )
			goto tr151;
	} else
		goto tr162;
	goto tr149;
tr161:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
#line 140 "src/smaps_analyze.rl"
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
tr162:
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
#line 140 "src/smaps_analyze.rl"
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
#line 820 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr6;
		} else if ( (*p) >= 65 )
			goto tr6;
	} else
		goto tr39;
	goto st1;
tr163:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st26;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
#line 851 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 71: goto tr40;
		case 75: goto tr40;
		case 77: goto tr40;
		case 103: goto tr40;
		case 107: goto tr40;
		case 109: goto tr40;
	}
	if ( 9 <= (*p) && (*p) <= 13 )
		goto st26;
	goto st1;
tr164:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st143;
st143:
	if ( ++p == pe )
		goto _test_eof143;
case 143:
#line 878 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr164;
		case 32: goto tr163;
		case 71: goto tr165;
		case 75: goto tr165;
		case 77: goto tr165;
		case 80: goto tr152;
		case 83: goto tr153;
		case 103: goto tr165;
		case 107: goto tr165;
		case 109: goto tr165;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr163;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr151;
		} else if ( (*p) >= 65 )
			goto tr151;
	} else
		goto tr151;
	goto tr149;
tr40:
#line 158 "src/smaps_analyze.rl"
	{
				switch((*p)) {
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
	goto st27;
tr165:
#line 158 "src/smaps_analyze.rl"
	{
				switch((*p)) {
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
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st27;
tr172:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
#line 158 "src/smaps_analyze.rl"
	{
				switch((*p)) {
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
	goto st27;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
#line 981 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 66: goto st28;
		case 98: goto st28;
	}
	goto st1;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
	if ( (*p) == 10 )
		goto tr42;
	goto st1;
tr152:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st29;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
#line 1008 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 114: goto st30;
	}
	goto st1;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
	switch( (*p) ) {
		case 10: goto st138;
		case 105: goto st31;
	}
	goto st1;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
	switch( (*p) ) {
		case 10: goto st138;
		case 118: goto st32;
	}
	goto st1;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
	switch( (*p) ) {
		case 10: goto st138;
		case 97: goto st33;
	}
	goto st1;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	switch( (*p) ) {
		case 10: goto st138;
		case 116: goto st34;
	}
	goto st1;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	switch( (*p) ) {
		case 10: goto st138;
		case 101: goto st35;
	}
	goto st1;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
	switch( (*p) ) {
		case 10: goto st138;
		case 95: goto st36;
	}
	goto st1;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
	switch( (*p) ) {
		case 10: goto st138;
		case 68: goto st37;
	}
	goto st1;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
	switch( (*p) ) {
		case 10: goto st138;
		case 105: goto st38;
	}
	goto st1;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	switch( (*p) ) {
		case 10: goto st138;
		case 114: goto st39;
	}
	goto st1;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
	switch( (*p) ) {
		case 10: goto st138;
		case 116: goto st40;
	}
	goto st1;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
	switch( (*p) ) {
		case 10: goto st138;
		case 121: goto st41;
	}
	goto st1;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	switch( (*p) ) {
		case 10: goto st138;
		case 58: goto st24;
	}
	goto st1;
tr153:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st42;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
#line 1135 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 104: goto st43;
	}
	goto st1;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	switch( (*p) ) {
		case 10: goto st138;
		case 97: goto st44;
	}
	goto st1;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
	switch( (*p) ) {
		case 10: goto st138;
		case 114: goto st45;
	}
	goto st1;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
	switch( (*p) ) {
		case 10: goto st138;
		case 101: goto st46;
	}
	goto st1;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
	switch( (*p) ) {
		case 10: goto st138;
		case 100: goto st47;
	}
	goto st1;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
	switch( (*p) ) {
		case 10: goto st138;
		case 95: goto st48;
	}
	goto st1;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
	switch( (*p) ) {
		case 10: goto st138;
		case 68: goto st49;
	}
	goto st1;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	switch( (*p) ) {
		case 10: goto st138;
		case 105: goto st50;
	}
	goto st1;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	switch( (*p) ) {
		case 10: goto st138;
		case 114: goto st51;
	}
	goto st1;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
	switch( (*p) ) {
		case 10: goto st138;
		case 116: goto st52;
	}
	goto st1;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	switch( (*p) ) {
		case 10: goto st138;
		case 121: goto st53;
	}
	goto st1;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	switch( (*p) ) {
		case 10: goto st138;
		case 58: goto st54;
	}
	goto st1;
tr166:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st54;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
#line 1253 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st144;
		case 32: goto st54;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr68;
	} else if ( (*p) >= 9 )
		goto st54;
	goto st1;
tr167:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st144;
st144:
	if ( ++p == pe )
		goto _test_eof144;
case 144:
#line 1277 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr167;
		case 32: goto tr166;
		case 80: goto tr152;
		case 83: goto tr153;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr166;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr151;
		} else if ( (*p) >= 65 )
			goto tr151;
	} else
		goto tr168;
	goto tr149;
tr173:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
#line 140 "src/smaps_analyze.rl"
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
	goto st55;
tr168:
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
#line 140 "src/smaps_analyze.rl"
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
	goto st55;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
#line 1354 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr6;
		} else if ( (*p) >= 65 )
			goto tr6;
	} else
		goto tr71;
	goto st1;
tr169:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st56;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
#line 1385 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 71: goto tr72;
		case 75: goto tr72;
		case 77: goto tr72;
		case 103: goto tr72;
		case 107: goto tr72;
		case 109: goto tr72;
	}
	if ( 9 <= (*p) && (*p) <= 13 )
		goto st56;
	goto st1;
tr170:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st145;
st145:
	if ( ++p == pe )
		goto _test_eof145;
case 145:
#line 1412 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr170;
		case 32: goto tr169;
		case 71: goto tr171;
		case 75: goto tr171;
		case 77: goto tr171;
		case 80: goto tr152;
		case 83: goto tr153;
		case 103: goto tr171;
		case 107: goto tr171;
		case 109: goto tr171;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr169;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr151;
		} else if ( (*p) >= 65 )
			goto tr151;
	} else
		goto tr151;
	goto tr149;
tr72:
#line 158 "src/smaps_analyze.rl"
	{
				switch((*p)) {
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
	goto st57;
tr171:
#line 158 "src/smaps_analyze.rl"
	{
				switch((*p)) {
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
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st57;
tr174:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
#line 158 "src/smaps_analyze.rl"
	{
				switch((*p)) {
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
	goto st57;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
#line 1515 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 66: goto st58;
		case 98: goto st58;
	}
	goto st1;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	if ( (*p) == 10 )
		goto tr74;
	goto st1;
tr71:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st59;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
#line 1553 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr76;
		} else if ( (*p) >= 65 )
			goto tr76;
	} else
		goto tr75;
	goto st1;
tr75:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st60;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
#line 1595 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr78;
		} else if ( (*p) >= 65 )
			goto tr78;
	} else
		goto tr77;
	goto st1;
tr77:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st61;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
#line 1637 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr80;
		} else if ( (*p) >= 65 )
			goto tr80;
	} else
		goto tr79;
	goto st1;
tr79:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st62;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
#line 1679 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr82;
		} else if ( (*p) >= 65 )
			goto tr82;
	} else
		goto tr81;
	goto st1;
tr81:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st63;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
#line 1721 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr84;
		} else if ( (*p) >= 65 )
			goto tr84;
	} else
		goto tr83;
	goto st1;
tr83:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st64;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
#line 1763 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr86;
		} else if ( (*p) >= 65 )
			goto tr86;
	} else
		goto tr85;
	goto st1;
tr85:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st65;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
#line 1805 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr88;
		} else if ( (*p) >= 65 )
			goto tr88;
	} else
		goto tr87;
	goto st1;
tr87:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st66;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
#line 1847 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr90;
		} else if ( (*p) >= 65 )
			goto tr90;
	} else
		goto tr89;
	goto st1;
tr89:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st67;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
#line 1889 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr92;
		} else if ( (*p) >= 65 )
			goto tr92;
	} else
		goto tr91;
	goto st1;
tr91:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st68;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
#line 1931 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr94;
		} else if ( (*p) >= 65 )
			goto tr94;
	} else
		goto tr93;
	goto st1;
tr93:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st69;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
#line 1973 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr96;
		} else if ( (*p) >= 65 )
			goto tr96;
	} else
		goto tr95;
	goto st1;
tr95:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st70;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
#line 2015 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr98;
		} else if ( (*p) >= 65 )
			goto tr98;
	} else
		goto tr97;
	goto st1;
tr97:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st71;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
#line 2057 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr100;
		} else if ( (*p) >= 65 )
			goto tr100;
	} else
		goto tr99;
	goto st1;
tr99:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st72;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
#line 2099 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st56;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr102;
		} else if ( (*p) >= 65 )
			goto tr102;
	} else
		goto tr101;
	goto st1;
tr101:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st73;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
#line 2141 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
		case 45: goto tr5;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr68;
	} else if ( (*p) >= 9 )
		goto st56;
	goto st1;
tr68:
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st74;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
#line 2164 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st145;
		case 32: goto st56;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr68;
	} else if ( (*p) >= 9 )
		goto st56;
	goto st1;
tr102:
#line 140 "src/smaps_analyze.rl"
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
	goto st75;
st75:
	if ( ++p == pe )
		goto _test_eof75;
case 75:
#line 2194 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	goto st1;
tr100:
#line 140 "src/smaps_analyze.rl"
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
	goto st76;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
#line 2219 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr102;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr102;
	} else
		goto tr102;
	goto st1;
tr98:
#line 140 "src/smaps_analyze.rl"
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
	goto st77;
st77:
	if ( ++p == pe )
		goto _test_eof77;
case 77:
#line 2252 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr100;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr100;
	} else
		goto tr100;
	goto st1;
tr96:
#line 140 "src/smaps_analyze.rl"
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
	goto st78;
st78:
	if ( ++p == pe )
		goto _test_eof78;
case 78:
#line 2285 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr98;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr98;
	} else
		goto tr98;
	goto st1;
tr94:
#line 140 "src/smaps_analyze.rl"
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
	goto st79;
st79:
	if ( ++p == pe )
		goto _test_eof79;
case 79:
#line 2318 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr96;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr96;
	} else
		goto tr96;
	goto st1;
tr92:
#line 140 "src/smaps_analyze.rl"
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
	goto st80;
st80:
	if ( ++p == pe )
		goto _test_eof80;
case 80:
#line 2351 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr94;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr94;
	} else
		goto tr94;
	goto st1;
tr90:
#line 140 "src/smaps_analyze.rl"
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
	goto st81;
st81:
	if ( ++p == pe )
		goto _test_eof81;
case 81:
#line 2384 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr92;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr92;
	} else
		goto tr92;
	goto st1;
tr88:
#line 140 "src/smaps_analyze.rl"
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
	goto st82;
st82:
	if ( ++p == pe )
		goto _test_eof82;
case 82:
#line 2417 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr90;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr90;
	} else
		goto tr90;
	goto st1;
tr86:
#line 140 "src/smaps_analyze.rl"
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
	goto st83;
st83:
	if ( ++p == pe )
		goto _test_eof83;
case 83:
#line 2450 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr88;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr88;
	} else
		goto tr88;
	goto st1;
tr84:
#line 140 "src/smaps_analyze.rl"
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
	goto st84;
st84:
	if ( ++p == pe )
		goto _test_eof84;
case 84:
#line 2483 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr86;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr86;
	} else
		goto tr86;
	goto st1;
tr82:
#line 140 "src/smaps_analyze.rl"
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
	goto st85;
st85:
	if ( ++p == pe )
		goto _test_eof85;
case 85:
#line 2516 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr84;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr84;
	} else
		goto tr84;
	goto st1;
tr80:
#line 140 "src/smaps_analyze.rl"
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
	goto st86;
st86:
	if ( ++p == pe )
		goto _test_eof86;
case 86:
#line 2549 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr82;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr82;
	} else
		goto tr82;
	goto st1;
tr78:
#line 140 "src/smaps_analyze.rl"
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
	goto st87;
st87:
	if ( ++p == pe )
		goto _test_eof87;
case 87:
#line 2582 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr80;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr80;
	} else
		goto tr80;
	goto st1;
tr76:
#line 140 "src/smaps_analyze.rl"
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
	goto st88;
st88:
	if ( ++p == pe )
		goto _test_eof88;
case 88:
#line 2615 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr78;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr78;
	} else
		goto tr78;
	goto st1;
tr6:
#line 140 "src/smaps_analyze.rl"
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
	goto st89;
st89:
	if ( ++p == pe )
		goto _test_eof89;
case 89:
#line 2648 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 45: goto tr5;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr76;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto tr76;
	} else
		goto tr76;
	goto st1;
tr39:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st90;
st90:
	if ( ++p == pe )
		goto _test_eof90;
case 90:
#line 2686 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr76;
		} else if ( (*p) >= 65 )
			goto tr76;
	} else
		goto tr103;
	goto st1;
tr103:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st91;
st91:
	if ( ++p == pe )
		goto _test_eof91;
case 91:
#line 2728 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr78;
		} else if ( (*p) >= 65 )
			goto tr78;
	} else
		goto tr104;
	goto st1;
tr104:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st92;
st92:
	if ( ++p == pe )
		goto _test_eof92;
case 92:
#line 2770 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr80;
		} else if ( (*p) >= 65 )
			goto tr80;
	} else
		goto tr105;
	goto st1;
tr105:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st93;
st93:
	if ( ++p == pe )
		goto _test_eof93;
case 93:
#line 2812 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr82;
		} else if ( (*p) >= 65 )
			goto tr82;
	} else
		goto tr106;
	goto st1;
tr106:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st94;
st94:
	if ( ++p == pe )
		goto _test_eof94;
case 94:
#line 2854 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr84;
		} else if ( (*p) >= 65 )
			goto tr84;
	} else
		goto tr107;
	goto st1;
tr107:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st95;
st95:
	if ( ++p == pe )
		goto _test_eof95;
case 95:
#line 2896 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr86;
		} else if ( (*p) >= 65 )
			goto tr86;
	} else
		goto tr108;
	goto st1;
tr108:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st96;
st96:
	if ( ++p == pe )
		goto _test_eof96;
case 96:
#line 2938 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr88;
		} else if ( (*p) >= 65 )
			goto tr88;
	} else
		goto tr109;
	goto st1;
tr109:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st97;
st97:
	if ( ++p == pe )
		goto _test_eof97;
case 97:
#line 2980 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr90;
		} else if ( (*p) >= 65 )
			goto tr90;
	} else
		goto tr110;
	goto st1;
tr110:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st98;
st98:
	if ( ++p == pe )
		goto _test_eof98;
case 98:
#line 3022 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr92;
		} else if ( (*p) >= 65 )
			goto tr92;
	} else
		goto tr111;
	goto st1;
tr111:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st99;
st99:
	if ( ++p == pe )
		goto _test_eof99;
case 99:
#line 3064 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr94;
		} else if ( (*p) >= 65 )
			goto tr94;
	} else
		goto tr112;
	goto st1;
tr112:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st100;
st100:
	if ( ++p == pe )
		goto _test_eof100;
case 100:
#line 3106 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr96;
		} else if ( (*p) >= 65 )
			goto tr96;
	} else
		goto tr113;
	goto st1;
tr113:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st101;
st101:
	if ( ++p == pe )
		goto _test_eof101;
case 101:
#line 3148 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr98;
		} else if ( (*p) >= 65 )
			goto tr98;
	} else
		goto tr114;
	goto st1;
tr114:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st102;
st102:
	if ( ++p == pe )
		goto _test_eof102;
case 102:
#line 3190 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr100;
		} else if ( (*p) >= 65 )
			goto tr100;
	} else
		goto tr115;
	goto st1;
tr115:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st103;
st103:
	if ( ++p == pe )
		goto _test_eof103;
case 103:
#line 3232 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto st26;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr102;
		} else if ( (*p) >= 65 )
			goto tr102;
	} else
		goto tr116;
	goto st1;
tr116:
#line 140 "src/smaps_analyze.rl"
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
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st104;
st104:
	if ( ++p == pe )
		goto _test_eof104;
case 104:
#line 3274 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
		case 45: goto tr5;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr36;
	} else if ( (*p) >= 9 )
		goto st26;
	goto st1;
tr36:
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st105;
st105:
	if ( ++p == pe )
		goto _test_eof105;
case 105:
#line 3297 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st143;
		case 32: goto st26;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr36;
	} else if ( (*p) >= 9 )
		goto st26;
	goto st1;
tr33:
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st106;
st106:
	if ( ++p == pe )
		goto _test_eof106;
case 106:
#line 3319 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st146;
		case 32: goto st107;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr33;
	} else if ( (*p) >= 9 )
		goto st107;
	goto st1;
st107:
	if ( ++p == pe )
		goto _test_eof107;
case 107:
	switch( (*p) ) {
		case 10: goto st146;
		case 32: goto st107;
		case 71: goto tr40;
		case 75: goto tr40;
		case 77: goto tr40;
		case 103: goto tr40;
		case 107: goto tr40;
		case 109: goto tr40;
	}
	if ( 9 <= (*p) && (*p) <= 13 )
		goto st107;
	goto st1;
st146:
	if ( ++p == pe )
		goto _test_eof146;
case 146:
	switch( (*p) ) {
		case 10: goto tr164;
		case 32: goto tr163;
		case 71: goto tr172;
		case 75: goto tr172;
		case 77: goto tr172;
		case 80: goto tr152;
		case 83: goto tr153;
		case 103: goto tr172;
		case 107: goto tr172;
		case 109: goto tr172;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr163;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr151;
		} else if ( (*p) >= 65 )
			goto tr151;
	} else
		goto tr151;
	goto tr149;
tr158:
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	goto st108;
st108:
	if ( ++p == pe )
		goto _test_eof108;
case 108:
#line 3388 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st138;
		case 104: goto st109;
	}
	goto st1;
st109:
	if ( ++p == pe )
		goto _test_eof109;
case 109:
	switch( (*p) ) {
		case 10: goto st138;
		case 97: goto st110;
	}
	goto st1;
st110:
	if ( ++p == pe )
		goto _test_eof110;
case 110:
	switch( (*p) ) {
		case 10: goto st138;
		case 114: goto st111;
	}
	goto st1;
st111:
	if ( ++p == pe )
		goto _test_eof111;
case 111:
	switch( (*p) ) {
		case 10: goto st138;
		case 101: goto st112;
	}
	goto st1;
st112:
	if ( ++p == pe )
		goto _test_eof112;
case 112:
	switch( (*p) ) {
		case 10: goto st138;
		case 100: goto st113;
	}
	goto st1;
st113:
	if ( ++p == pe )
		goto _test_eof113;
case 113:
	switch( (*p) ) {
		case 10: goto st138;
		case 95: goto st114;
	}
	goto st1;
st114:
	if ( ++p == pe )
		goto _test_eof114;
case 114:
	switch( (*p) ) {
		case 10: goto st138;
		case 68: goto st115;
	}
	goto st1;
st115:
	if ( ++p == pe )
		goto _test_eof115;
case 115:
	switch( (*p) ) {
		case 10: goto st138;
		case 105: goto st116;
	}
	goto st1;
st116:
	if ( ++p == pe )
		goto _test_eof116;
case 116:
	switch( (*p) ) {
		case 10: goto st138;
		case 114: goto st117;
	}
	goto st1;
st117:
	if ( ++p == pe )
		goto _test_eof117;
case 117:
	switch( (*p) ) {
		case 10: goto st138;
		case 116: goto st118;
	}
	goto st1;
st118:
	if ( ++p == pe )
		goto _test_eof118;
case 118:
	switch( (*p) ) {
		case 10: goto st138;
		case 121: goto st119;
	}
	goto st1;
st119:
	if ( ++p == pe )
		goto _test_eof119;
case 119:
	switch( (*p) ) {
		case 10: goto st138;
		case 58: goto st120;
	}
	goto st1;
st120:
	if ( ++p == pe )
		goto _test_eof120;
case 120:
	switch( (*p) ) {
		case 10: goto st147;
		case 32: goto st120;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr132;
	} else if ( (*p) >= 9 )
		goto st120;
	goto st1;
st147:
	if ( ++p == pe )
		goto _test_eof147;
case 147:
	switch( (*p) ) {
		case 10: goto tr167;
		case 32: goto tr166;
		case 80: goto tr152;
		case 83: goto tr153;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr166;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr151;
		} else if ( (*p) >= 65 )
			goto tr151;
	} else
		goto tr173;
	goto tr149;
tr132:
#line 153 "src/smaps_analyze.rl"
	{
				pval *= 10;
				pval += (*p) - '0';
			}
	goto st121;
st121:
	if ( ++p == pe )
		goto _test_eof121;
case 121:
#line 3540 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto st148;
		case 32: goto st122;
	}
	if ( (*p) > 13 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr132;
	} else if ( (*p) >= 9 )
		goto st122;
	goto st1;
st122:
	if ( ++p == pe )
		goto _test_eof122;
case 122:
	switch( (*p) ) {
		case 10: goto st148;
		case 32: goto st122;
		case 71: goto tr72;
		case 75: goto tr72;
		case 77: goto tr72;
		case 103: goto tr72;
		case 107: goto tr72;
		case 109: goto tr72;
	}
	if ( 9 <= (*p) && (*p) <= 13 )
		goto st122;
	goto st1;
st148:
	if ( ++p == pe )
		goto _test_eof148;
case 148:
	switch( (*p) ) {
		case 10: goto tr170;
		case 32: goto tr169;
		case 71: goto tr174;
		case 75: goto tr174;
		case 77: goto tr174;
		case 80: goto tr152;
		case 83: goto tr153;
		case 103: goto tr174;
		case 107: goto tr174;
		case 109: goto tr174;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr169;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr151;
		} else if ( (*p) >= 65 )
			goto tr151;
	} else
		goto tr151;
	goto tr149;
tr10:
#line 140 "src/smaps_analyze.rl"
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
	goto st123;
st123:
	if ( ++p == pe )
		goto _test_eof123;
case 123:
#line 3615 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr135;
		} else if ( (*p) >= 65 )
			goto tr135;
	} else
		goto tr135;
	goto st1;
tr135:
#line 140 "src/smaps_analyze.rl"
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
	goto st124;
st124:
	if ( ++p == pe )
		goto _test_eof124;
case 124:
#line 3651 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr136;
		} else if ( (*p) >= 65 )
			goto tr136;
	} else
		goto tr136;
	goto st1;
tr136:
#line 140 "src/smaps_analyze.rl"
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
	goto st125;
st125:
	if ( ++p == pe )
		goto _test_eof125;
case 125:
#line 3687 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr137;
		} else if ( (*p) >= 65 )
			goto tr137;
	} else
		goto tr137;
	goto st1;
tr137:
#line 140 "src/smaps_analyze.rl"
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
	goto st126;
st126:
	if ( ++p == pe )
		goto _test_eof126;
case 126:
#line 3723 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr138;
		} else if ( (*p) >= 65 )
			goto tr138;
	} else
		goto tr138;
	goto st1;
tr138:
#line 140 "src/smaps_analyze.rl"
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
	goto st127;
st127:
	if ( ++p == pe )
		goto _test_eof127;
case 127:
#line 3759 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr139;
		} else if ( (*p) >= 65 )
			goto tr139;
	} else
		goto tr139;
	goto st1;
tr139:
#line 140 "src/smaps_analyze.rl"
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
	goto st128;
st128:
	if ( ++p == pe )
		goto _test_eof128;
case 128:
#line 3795 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr140;
		} else if ( (*p) >= 65 )
			goto tr140;
	} else
		goto tr140;
	goto st1;
tr140:
#line 140 "src/smaps_analyze.rl"
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
	goto st129;
st129:
	if ( ++p == pe )
		goto _test_eof129;
case 129:
#line 3831 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr141;
		} else if ( (*p) >= 65 )
			goto tr141;
	} else
		goto tr141;
	goto st1;
tr141:
#line 140 "src/smaps_analyze.rl"
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
	goto st130;
st130:
	if ( ++p == pe )
		goto _test_eof130;
case 130:
#line 3867 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr142;
		} else if ( (*p) >= 65 )
			goto tr142;
	} else
		goto tr142;
	goto st1;
tr142:
#line 140 "src/smaps_analyze.rl"
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
	goto st131;
st131:
	if ( ++p == pe )
		goto _test_eof131;
case 131:
#line 3903 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr143;
		} else if ( (*p) >= 65 )
			goto tr143;
	} else
		goto tr143;
	goto st1;
tr143:
#line 140 "src/smaps_analyze.rl"
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
	goto st132;
st132:
	if ( ++p == pe )
		goto _test_eof132;
case 132:
#line 3939 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr144;
		} else if ( (*p) >= 65 )
			goto tr144;
	} else
		goto tr144;
	goto st1;
tr144:
#line 140 "src/smaps_analyze.rl"
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
	goto st133;
st133:
	if ( ++p == pe )
		goto _test_eof133;
case 133:
#line 3975 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr145;
		} else if ( (*p) >= 65 )
			goto tr145;
	} else
		goto tr145;
	goto st1;
tr145:
#line 140 "src/smaps_analyze.rl"
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
	goto st134;
st134:
	if ( ++p == pe )
		goto _test_eof134;
case 134:
#line 4011 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr146;
		} else if ( (*p) >= 65 )
			goto tr146;
	} else
		goto tr146;
	goto st1;
tr146:
#line 140 "src/smaps_analyze.rl"
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
	goto st135;
st135:
	if ( ++p == pe )
		goto _test_eof135;
case 135:
#line 4047 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr147;
		} else if ( (*p) >= 65 )
			goto tr147;
	} else
		goto tr147;
	goto st1;
tr147:
#line 140 "src/smaps_analyze.rl"
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
	goto st136;
st136:
	if ( ++p == pe )
		goto _test_eof136;
case 136:
#line 4083 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( (*p) < 48 ) {
		if ( 9 <= (*p) && (*p) <= 13 )
			goto tr8;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto tr148;
		} else if ( (*p) >= 65 )
			goto tr148;
	} else
		goto tr148;
	goto st1;
tr148:
#line 140 "src/smaps_analyze.rl"
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
	goto st137;
st137:
	if ( ++p == pe )
		goto _test_eof137;
case 137:
#line 4119 "src/smaps_analyze.m"
	switch( (*p) ) {
		case 10: goto tr9;
		case 32: goto tr8;
	}
	if ( 9 <= (*p) && (*p) <= 13 )
		goto tr8;
	goto st1;
	}
	_test_eof1: cs = 1; goto _test_eof; 
	_test_eof138: cs = 138; goto _test_eof; 
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof139: cs = 139; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof9: cs = 9; goto _test_eof; 
	_test_eof140: cs = 140; goto _test_eof; 
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
	_test_eof141: cs = 141; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof142: cs = 142; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof143: cs = 143; goto _test_eof; 
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
	_test_eof40: cs = 40; goto _test_eof; 
	_test_eof41: cs = 41; goto _test_eof; 
	_test_eof42: cs = 42; goto _test_eof; 
	_test_eof43: cs = 43; goto _test_eof; 
	_test_eof44: cs = 44; goto _test_eof; 
	_test_eof45: cs = 45; goto _test_eof; 
	_test_eof46: cs = 46; goto _test_eof; 
	_test_eof47: cs = 47; goto _test_eof; 
	_test_eof48: cs = 48; goto _test_eof; 
	_test_eof49: cs = 49; goto _test_eof; 
	_test_eof50: cs = 50; goto _test_eof; 
	_test_eof51: cs = 51; goto _test_eof; 
	_test_eof52: cs = 52; goto _test_eof; 
	_test_eof53: cs = 53; goto _test_eof; 
	_test_eof54: cs = 54; goto _test_eof; 
	_test_eof144: cs = 144; goto _test_eof; 
	_test_eof55: cs = 55; goto _test_eof; 
	_test_eof56: cs = 56; goto _test_eof; 
	_test_eof145: cs = 145; goto _test_eof; 
	_test_eof57: cs = 57; goto _test_eof; 
	_test_eof58: cs = 58; goto _test_eof; 
	_test_eof59: cs = 59; goto _test_eof; 
	_test_eof60: cs = 60; goto _test_eof; 
	_test_eof61: cs = 61; goto _test_eof; 
	_test_eof62: cs = 62; goto _test_eof; 
	_test_eof63: cs = 63; goto _test_eof; 
	_test_eof64: cs = 64; goto _test_eof; 
	_test_eof65: cs = 65; goto _test_eof; 
	_test_eof66: cs = 66; goto _test_eof; 
	_test_eof67: cs = 67; goto _test_eof; 
	_test_eof68: cs = 68; goto _test_eof; 
	_test_eof69: cs = 69; goto _test_eof; 
	_test_eof70: cs = 70; goto _test_eof; 
	_test_eof71: cs = 71; goto _test_eof; 
	_test_eof72: cs = 72; goto _test_eof; 
	_test_eof73: cs = 73; goto _test_eof; 
	_test_eof74: cs = 74; goto _test_eof; 
	_test_eof75: cs = 75; goto _test_eof; 
	_test_eof76: cs = 76; goto _test_eof; 
	_test_eof77: cs = 77; goto _test_eof; 
	_test_eof78: cs = 78; goto _test_eof; 
	_test_eof79: cs = 79; goto _test_eof; 
	_test_eof80: cs = 80; goto _test_eof; 
	_test_eof81: cs = 81; goto _test_eof; 
	_test_eof82: cs = 82; goto _test_eof; 
	_test_eof83: cs = 83; goto _test_eof; 
	_test_eof84: cs = 84; goto _test_eof; 
	_test_eof85: cs = 85; goto _test_eof; 
	_test_eof86: cs = 86; goto _test_eof; 
	_test_eof87: cs = 87; goto _test_eof; 
	_test_eof88: cs = 88; goto _test_eof; 
	_test_eof89: cs = 89; goto _test_eof; 
	_test_eof90: cs = 90; goto _test_eof; 
	_test_eof91: cs = 91; goto _test_eof; 
	_test_eof92: cs = 92; goto _test_eof; 
	_test_eof93: cs = 93; goto _test_eof; 
	_test_eof94: cs = 94; goto _test_eof; 
	_test_eof95: cs = 95; goto _test_eof; 
	_test_eof96: cs = 96; goto _test_eof; 
	_test_eof97: cs = 97; goto _test_eof; 
	_test_eof98: cs = 98; goto _test_eof; 
	_test_eof99: cs = 99; goto _test_eof; 
	_test_eof100: cs = 100; goto _test_eof; 
	_test_eof101: cs = 101; goto _test_eof; 
	_test_eof102: cs = 102; goto _test_eof; 
	_test_eof103: cs = 103; goto _test_eof; 
	_test_eof104: cs = 104; goto _test_eof; 
	_test_eof105: cs = 105; goto _test_eof; 
	_test_eof106: cs = 106; goto _test_eof; 
	_test_eof107: cs = 107; goto _test_eof; 
	_test_eof146: cs = 146; goto _test_eof; 
	_test_eof108: cs = 108; goto _test_eof; 
	_test_eof109: cs = 109; goto _test_eof; 
	_test_eof110: cs = 110; goto _test_eof; 
	_test_eof111: cs = 111; goto _test_eof; 
	_test_eof112: cs = 112; goto _test_eof; 
	_test_eof113: cs = 113; goto _test_eof; 
	_test_eof114: cs = 114; goto _test_eof; 
	_test_eof115: cs = 115; goto _test_eof; 
	_test_eof116: cs = 116; goto _test_eof; 
	_test_eof117: cs = 117; goto _test_eof; 
	_test_eof118: cs = 118; goto _test_eof; 
	_test_eof119: cs = 119; goto _test_eof; 
	_test_eof120: cs = 120; goto _test_eof; 
	_test_eof147: cs = 147; goto _test_eof; 
	_test_eof121: cs = 121; goto _test_eof; 
	_test_eof122: cs = 122; goto _test_eof; 
	_test_eof148: cs = 148; goto _test_eof; 
	_test_eof123: cs = 123; goto _test_eof; 
	_test_eof124: cs = 124; goto _test_eof; 
	_test_eof125: cs = 125; goto _test_eof; 
	_test_eof126: cs = 126; goto _test_eof; 
	_test_eof127: cs = 127; goto _test_eof; 
	_test_eof128: cs = 128; goto _test_eof; 
	_test_eof129: cs = 129; goto _test_eof; 
	_test_eof130: cs = 130; goto _test_eof; 
	_test_eof131: cs = 131; goto _test_eof; 
	_test_eof132: cs = 132; goto _test_eof; 
	_test_eof133: cs = 133; goto _test_eof; 
	_test_eof134: cs = 134; goto _test_eof; 
	_test_eof135: cs = 135; goto _test_eof; 
	_test_eof136: cs = 136; goto _test_eof; 
	_test_eof137: cs = 137; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 138: 
	case 139: 
	case 140: 
	case 141: 
	case 142: 
	case 143: 
	case 144: 
	case 145: 
	case 146: 
	case 147: 
	case 148: 
#line 134 "src/smaps_analyze.rl"
	{
				afrom = NULL;
				ato = NULL;
				address = 0;
				pval = 0;
			}
	break;
#line 4300 "src/smaps_analyze.m"
	}
	}

	_out: {}
	}

#line 285 "src/smaps_analyze.rl"

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
