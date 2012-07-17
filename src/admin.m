
#line 1 "src/admin.rl"
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

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <stdlib.h>

#include <fiber.h>
#include <palloc.h>
#include <salloc.h>
#include <say.h>
#include <stat.h>
#include <tarantool.h>
#include <tarantool_lua.h>
#include <recovery.h>
#include TARANTOOL_CONFIG
#include <tbuf.h>
#include <util.h>
#include <errinj.h>
#include <test/debugsync/fiber_ds.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static const char *help =
	"available commands:" CRLF
	" - help" CRLF
	" - exit" CRLF
	" - show info" CRLF
	" - show fiber" CRLF
	" - show configuration" CRLF
	" - show slab" CRLF
	" - show palloc" CRLF
	" - show stat" CRLF
	" - save coredump" CRLF
	" - save snapshot" CRLF
	" - lua command" CRLF
	" - reload configuration" CRLF
	" - show injections (debug mode only)" CRLF
	" - set injection <name> <state> (debug mode only)" CRLF
	" - show debugsync" CRLF
	" - debugsync <state>" CRLF
	" - debugsync <syncpoint> <state>" CRLF
	" - debugsync wait <syncpoint>" CRLF
	" - debugsync unlock <syncpoint>" CRLF;

static const char *unknown_command = "unknown command. try typing help." CRLF;


#line 79 "src/admin.m"
static const int admin_start = 1;
static const int admin_first_final = 186;
static const int admin_error = 0;

static const int admin_en_main = 1;


#line 78 "src/admin.rl"



static void
end(struct tbuf *out)
{
	tbuf_printf(out, "..." CRLF);
}

static void
start(struct tbuf *out)
{
	tbuf_printf(out, "---" CRLF);
}

static void
ok(struct tbuf *out)
{
	start(out);
	tbuf_printf(out, "ok" CRLF);
	end(out);
}

static void
fail(struct tbuf *out, struct tbuf *err)
{
	start(out);
	tbuf_printf(out, "fail:%.*s" CRLF, err->size, (char *)err->data);
	end(out);
}

static void
tarantool_info(struct tbuf *out)
{
	tbuf_printf(out, "info:" CRLF);
	tbuf_printf(out, "  version: \"%s\"" CRLF, tarantool_version());
	tbuf_printf(out, "  uptime: %i" CRLF, (int)tarantool_uptime());
	tbuf_printf(out, "  pid: %i" CRLF, getpid());
	tbuf_printf(out, "  logger_pid: %i" CRLF, logger_pid);
	tbuf_printf(out, "  lsn: %" PRIi64 CRLF,
		    recovery_state->confirmed_lsn);
	tbuf_printf(out, "  recovery_lag: %.3f" CRLF,
		    recovery_state->remote ? 
		    recovery_state->remote->recovery_lag : 0);
	tbuf_printf(out, "  recovery_last_update: %.3f" CRLF,
		    recovery_state->remote ?
		    recovery_state->remote->recovery_last_update_tstamp :0);
	mod_info(out);
	const char *path = cfg_filename_fullpath;
	if (path == NULL)
		path = cfg_filename;
	tbuf_printf(out, "  config: \"%s\"" CRLF, path);
}

static int
admin_dispatch(lua_State *L)
{
	struct tbuf *out = tbuf_alloc(fiber->gc_pool);
	struct tbuf *err = tbuf_alloc(fiber->gc_pool);
	int cs;
	char *p, *pe;
	char *strstart, *strend;
	bool state;

	while ((pe = memchr(fiber->rbuf->data, '\n', fiber->rbuf->size)) == NULL) {
		if (fiber_bread(fiber->rbuf, 1) <= 0)
			return 0;
	}

	pe++;
	p = fiber->rbuf->data;

	
#line 161 "src/admin.m"
	{
	cs = admin_start;
	}

#line 166 "src/admin.m"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	switch( (*p) ) {
		case 99: goto st2;
		case 100: goto st13;
		case 101: goto st55;
		case 104: goto st59;
		case 108: goto st63;
		case 113: goto st69;
		case 114: goto st70;
		case 115: goto st90;
	}
	goto st0;
st0:
cs = 0;
	goto _out;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
	if ( (*p) == 104 )
		goto st3;
	goto st0;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
	switch( (*p) ) {
		case 32: goto st4;
		case 101: goto st10;
	}
	goto st0;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	switch( (*p) ) {
		case 32: goto st4;
		case 115: goto st5;
	}
	goto st0;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
	if ( (*p) == 108 )
		goto st6;
	goto st0;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
	switch( (*p) ) {
		case 10: goto tr14;
		case 13: goto tr15;
		case 97: goto st8;
	}
	goto st0;
tr14:
#line 311 "src/admin.rl"
	{slab_validate(); ok(out);}
	goto st186;
tr37:
#line 295 "src/admin.rl"
	{ state = false; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
	goto st186;
tr40:
#line 294 "src/admin.rl"
	{ state = true; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
	goto st186;
tr44:
#line 295 "src/admin.rl"
	{ state = false; }
#line 231 "src/admin.rl"
	{
			int rc = fds_activate(state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sactivate debug sync framework [%d]",
					state ? "" : "de-", rc);
				fail(out, err);
			}
		}
	goto st186;
tr47:
#line 294 "src/admin.rl"
	{ state = true; }
#line 231 "src/admin.rl"
	{
			int rc = fds_activate(state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sactivate debug sync framework [%d]",
					state ? "" : "de-", rc);
				fail(out, err);
			}
		}
	goto st186;
tr59:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 254 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_unlock(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to unlock debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st186;
tr64:
#line 295 "src/admin.rl"
	{ state = false; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
#line 293 "src/admin.rl"
	{ strend = p; }
#line 254 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_unlock(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to unlock debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st186;
tr67:
#line 294 "src/admin.rl"
	{ state = true; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
#line 293 "src/admin.rl"
	{ strend = p; }
#line 254 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_unlock(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to unlock debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st186;
tr77:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 242 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_wait(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to wait on debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st186;
tr82:
#line 295 "src/admin.rl"
	{ state = false; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
#line 293 "src/admin.rl"
	{ strend = p; }
#line 242 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_wait(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to wait on debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st186;
tr85:
#line 294 "src/admin.rl"
	{ state = true; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
#line 293 "src/admin.rl"
	{ strend = p; }
#line 242 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_wait(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to wait on debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st186;
tr90:
#line 299 "src/admin.rl"
	{return 0;}
	goto st186;
tr95:
#line 175 "src/admin.rl"
	{
			start(out);
			tbuf_append(out, help, strlen(help));
			end(out);
		}
	goto st186;
tr106:
#line 285 "src/admin.rl"
	{strend = p;}
#line 181 "src/admin.rl"
	{
			strstart[strend-strstart]='\0';
			start(out);
			tarantool_lua(L, out, strstart);
			end(out);
		}
	goto st186;
tr113:
#line 188 "src/admin.rl"
	{
			if (reload_cfg(err))
				fail(out, err);
			else
				ok(out);
		}
	goto st186;
tr137:
#line 309 "src/admin.rl"
	{coredump(60); ok(out);}
	goto st186;
tr146:
#line 195 "src/admin.rl"
	{
			int ret = snapshot(NULL, 0);

			if (ret == 0)
				ok(out);
			else {
				tbuf_printf(err, " can't save snapshot, errno %d (%s)",
					    ret, strerror(ret));

				fail(out, err);
			}
		}
	goto st186;
tr168:
#line 295 "src/admin.rl"
	{ state = false; }
#line 208 "src/admin.rl"
	{
			strstart[strend-strstart] = '\0';
			if (errinj_set_byname(strstart, state)) {
				tbuf_printf(err, "can't find error injection '%s'", strstart);
				fail(out, err);
			} else {
				ok(out);
			}
		}
	goto st186;
tr171:
#line 294 "src/admin.rl"
	{ state = true; }
#line 208 "src/admin.rl"
	{
			strstart[strend-strstart] = '\0';
			if (errinj_set_byname(strstart, state)) {
				tbuf_printf(err, "can't find error injection '%s'", strstart);
				fail(out, err);
			} else {
				ok(out);
			}
		}
	goto st186;
tr188:
#line 151 "src/admin.rl"
	{
			tarantool_cfg_iterator_t *i;
			char *key, *value;

			start(out);
			tbuf_printf(out, "configuration:" CRLF);
			i = tarantool_cfg_iterator_init();
			while ((key = tarantool_cfg_iterator_next(i, &cfg, &value)) != NULL) {
				if (value) {
					tbuf_printf(out, "  %s: \"%s\"" CRLF, key, value);
					free(value);
				} else {
					tbuf_printf(out, "  %s: (null)" CRLF, key);
				}
			}
			end(out);
		}
	goto st186;
tr205:
#line 312 "src/admin.rl"
	{start(out); fds_info(out); end(out);}
	goto st186;
tr212:
#line 302 "src/admin.rl"
	{start(out); fiber_info(out); end(out);}
	goto st186;
tr218:
#line 301 "src/admin.rl"
	{start(out); tarantool_info(out); end(out);}
	goto st186;
tr227:
#line 169 "src/admin.rl"
	{
			start(out);
			errinj_info(out);
			end(out);
		}
	goto st186;
tr233:
#line 305 "src/admin.rl"
	{start(out); palloc_stat(out); end(out);}
	goto st186;
tr241:
#line 304 "src/admin.rl"
	{start(out); slab_stat(out); end(out);}
	goto st186;
tr245:
#line 306 "src/admin.rl"
	{start(out); stat_print(out);end(out);}
	goto st186;
st186:
	if ( ++p == pe )
		goto _test_eof186;
case 186:
#line 588 "src/admin.m"
	goto st0;
tr15:
#line 311 "src/admin.rl"
	{slab_validate(); ok(out);}
	goto st7;
tr38:
#line 295 "src/admin.rl"
	{ state = false; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
	goto st7;
tr41:
#line 294 "src/admin.rl"
	{ state = true; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
	goto st7;
tr45:
#line 295 "src/admin.rl"
	{ state = false; }
#line 231 "src/admin.rl"
	{
			int rc = fds_activate(state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sactivate debug sync framework [%d]",
					state ? "" : "de-", rc);
				fail(out, err);
			}
		}
	goto st7;
tr48:
#line 294 "src/admin.rl"
	{ state = true; }
#line 231 "src/admin.rl"
	{
			int rc = fds_activate(state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sactivate debug sync framework [%d]",
					state ? "" : "de-", rc);
				fail(out, err);
			}
		}
	goto st7;
tr60:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 254 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_unlock(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to unlock debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st7;
tr65:
#line 295 "src/admin.rl"
	{ state = false; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
#line 293 "src/admin.rl"
	{ strend = p; }
#line 254 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_unlock(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to unlock debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st7;
tr68:
#line 294 "src/admin.rl"
	{ state = true; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
#line 293 "src/admin.rl"
	{ strend = p; }
#line 254 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_unlock(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to unlock debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st7;
tr78:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 242 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_wait(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to wait on debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st7;
tr83:
#line 295 "src/admin.rl"
	{ state = false; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
#line 293 "src/admin.rl"
	{ strend = p; }
#line 242 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_wait(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to wait on debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st7;
tr86:
#line 294 "src/admin.rl"
	{ state = true; }
#line 218 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_enable(strstart, state);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to %sable debug syncpoint %s [%d]",
					state ? "en" : "dis", strstart, rc);
				fail(out, err);
			}

		}
#line 293 "src/admin.rl"
	{ strend = p; }
#line 242 "src/admin.rl"
	{
			strstart[strend - strstart] = '\0';
			int rc = fds_wait(strstart);
			if (rc == 0)
				ok(out);
			else {
				tbuf_printf(err, "failed to wait on debug syncpoint %s [%d]",
					strstart, rc);
				fail(out, err);
			}
		}
	goto st7;
tr91:
#line 299 "src/admin.rl"
	{return 0;}
	goto st7;
tr96:
#line 175 "src/admin.rl"
	{
			start(out);
			tbuf_append(out, help, strlen(help));
			end(out);
		}
	goto st7;
tr107:
#line 285 "src/admin.rl"
	{strend = p;}
#line 181 "src/admin.rl"
	{
			strstart[strend-strstart]='\0';
			start(out);
			tarantool_lua(L, out, strstart);
			end(out);
		}
	goto st7;
tr114:
#line 188 "src/admin.rl"
	{
			if (reload_cfg(err))
				fail(out, err);
			else
				ok(out);
		}
	goto st7;
tr138:
#line 309 "src/admin.rl"
	{coredump(60); ok(out);}
	goto st7;
tr147:
#line 195 "src/admin.rl"
	{
			int ret = snapshot(NULL, 0);

			if (ret == 0)
				ok(out);
			else {
				tbuf_printf(err, " can't save snapshot, errno %d (%s)",
					    ret, strerror(ret));

				fail(out, err);
			}
		}
	goto st7;
tr169:
#line 295 "src/admin.rl"
	{ state = false; }
#line 208 "src/admin.rl"
	{
			strstart[strend-strstart] = '\0';
			if (errinj_set_byname(strstart, state)) {
				tbuf_printf(err, "can't find error injection '%s'", strstart);
				fail(out, err);
			} else {
				ok(out);
			}
		}
	goto st7;
tr172:
#line 294 "src/admin.rl"
	{ state = true; }
#line 208 "src/admin.rl"
	{
			strstart[strend-strstart] = '\0';
			if (errinj_set_byname(strstart, state)) {
				tbuf_printf(err, "can't find error injection '%s'", strstart);
				fail(out, err);
			} else {
				ok(out);
			}
		}
	goto st7;
tr189:
#line 151 "src/admin.rl"
	{
			tarantool_cfg_iterator_t *i;
			char *key, *value;

			start(out);
			tbuf_printf(out, "configuration:" CRLF);
			i = tarantool_cfg_iterator_init();
			while ((key = tarantool_cfg_iterator_next(i, &cfg, &value)) != NULL) {
				if (value) {
					tbuf_printf(out, "  %s: \"%s\"" CRLF, key, value);
					free(value);
				} else {
					tbuf_printf(out, "  %s: (null)" CRLF, key);
				}
			}
			end(out);
		}
	goto st7;
tr206:
#line 312 "src/admin.rl"
	{start(out); fds_info(out); end(out);}
	goto st7;
tr213:
#line 302 "src/admin.rl"
	{start(out); fiber_info(out); end(out);}
	goto st7;
tr219:
#line 301 "src/admin.rl"
	{start(out); tarantool_info(out); end(out);}
	goto st7;
tr228:
#line 169 "src/admin.rl"
	{
			start(out);
			errinj_info(out);
			end(out);
		}
	goto st7;
tr234:
#line 305 "src/admin.rl"
	{start(out); palloc_stat(out); end(out);}
	goto st7;
tr242:
#line 304 "src/admin.rl"
	{start(out); slab_stat(out); end(out);}
	goto st7;
tr246:
#line 306 "src/admin.rl"
	{start(out); stat_print(out);end(out);}
	goto st7;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
#line 949 "src/admin.m"
	if ( (*p) == 10 )
		goto st186;
	goto st0;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	switch( (*p) ) {
		case 10: goto tr14;
		case 13: goto tr15;
		case 98: goto st9;
	}
	goto st0;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
	switch( (*p) ) {
		case 10: goto tr14;
		case 13: goto tr15;
	}
	goto st0;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
	switch( (*p) ) {
		case 32: goto st4;
		case 99: goto st11;
	}
	goto st0;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
	switch( (*p) ) {
		case 32: goto st4;
		case 107: goto st12;
	}
	goto st0;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
	if ( (*p) == 32 )
		goto st4;
	goto st0;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
	if ( (*p) == 101 )
		goto st14;
	goto st0;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
	if ( (*p) == 98 )
		goto st15;
	goto st0;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
	if ( (*p) == 117 )
		goto st16;
	goto st0;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
	if ( (*p) == 103 )
		goto st17;
	goto st0;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
	switch( (*p) ) {
		case 32: goto st18;
		case 115: goto st51;
	}
	goto st0;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
	switch( (*p) ) {
		case 32: goto st18;
		case 111: goto tr28;
		case 117: goto tr29;
		case 119: goto tr30;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr27;
	goto st0;
tr27:
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st19;
tr32:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 1061 "src/admin.m"
	if ( (*p) == 32 )
		goto tr31;
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr31:
#line 293 "src/admin.rl"
	{ strend = p; }
	goto st20;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
#line 1075 "src/admin.m"
	switch( (*p) ) {
		case 32: goto st20;
		case 111: goto st21;
	}
	goto st0;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
	switch( (*p) ) {
		case 102: goto st22;
		case 110: goto st24;
	}
	goto st0;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	switch( (*p) ) {
		case 10: goto tr37;
		case 13: goto tr38;
		case 102: goto st23;
	}
	goto st0;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	switch( (*p) ) {
		case 10: goto tr37;
		case 13: goto tr38;
	}
	goto st0;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
	switch( (*p) ) {
		case 10: goto tr40;
		case 13: goto tr41;
	}
	goto st0;
tr28:
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st25;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
#line 1126 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr31;
		case 102: goto tr42;
		case 110: goto tr43;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr42:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st26;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
#line 1145 "src/admin.m"
	switch( (*p) ) {
		case 10: goto tr44;
		case 13: goto tr45;
		case 32: goto tr31;
		case 102: goto tr46;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr46:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st27;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
#line 1165 "src/admin.m"
	switch( (*p) ) {
		case 10: goto tr44;
		case 13: goto tr45;
		case 32: goto tr31;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr43:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st28;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
#line 1184 "src/admin.m"
	switch( (*p) ) {
		case 10: goto tr47;
		case 13: goto tr48;
		case 32: goto tr31;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr29:
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st29;
tr55:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st29;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
#line 1207 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr31;
		case 110: goto tr49;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr49:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st30;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
#line 1225 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr31;
		case 108: goto tr50;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr50:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st31;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
#line 1243 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr31;
		case 111: goto tr51;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr51:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st32;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
#line 1261 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr31;
		case 99: goto tr52;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr52:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st33;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
#line 1279 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr31;
		case 107: goto tr53;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr53:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st34;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
#line 1297 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr54;
		case 117: goto tr55;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr54:
#line 293 "src/admin.rl"
	{ strend = p; }
	goto st35;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
#line 1313 "src/admin.m"
	switch( (*p) ) {
		case 32: goto st35;
		case 111: goto tr58;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr57;
	goto st0;
tr57:
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st36;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
#line 1329 "src/admin.m"
	switch( (*p) ) {
		case 10: goto tr59;
		case 13: goto tr60;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st36;
	goto st0;
tr58:
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st37;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
#line 1345 "src/admin.m"
	switch( (*p) ) {
		case 10: goto tr59;
		case 13: goto tr60;
		case 102: goto st38;
		case 110: goto st40;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st36;
	goto st0;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	switch( (*p) ) {
		case 10: goto tr64;
		case 13: goto tr65;
		case 102: goto st39;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st36;
	goto st0;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
	switch( (*p) ) {
		case 10: goto tr64;
		case 13: goto tr65;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st36;
	goto st0;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
	switch( (*p) ) {
		case 10: goto tr67;
		case 13: goto tr68;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st36;
	goto st0;
tr30:
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st41;
tr73:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st41;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
#line 1403 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr31;
		case 97: goto tr69;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr69:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st42;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
#line 1421 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr31;
		case 105: goto tr70;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr70:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st43;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
#line 1439 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr31;
		case 116: goto tr71;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr71:
#line 293 "src/admin.rl"
	{ strend = p; }
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st44;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
#line 1457 "src/admin.m"
	switch( (*p) ) {
		case 32: goto tr72;
		case 119: goto tr73;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr32;
	goto st0;
tr72:
#line 293 "src/admin.rl"
	{ strend = p; }
	goto st45;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
#line 1473 "src/admin.m"
	switch( (*p) ) {
		case 32: goto st45;
		case 111: goto tr76;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr75;
	goto st0;
tr75:
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st46;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
#line 1489 "src/admin.m"
	switch( (*p) ) {
		case 10: goto tr77;
		case 13: goto tr78;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st46;
	goto st0;
tr76:
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st47;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
#line 1505 "src/admin.m"
	switch( (*p) ) {
		case 10: goto tr77;
		case 13: goto tr78;
		case 102: goto st48;
		case 110: goto st50;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st46;
	goto st0;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
	switch( (*p) ) {
		case 10: goto tr82;
		case 13: goto tr83;
		case 102: goto st49;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st46;
	goto st0;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	switch( (*p) ) {
		case 10: goto tr82;
		case 13: goto tr83;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st46;
	goto st0;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	switch( (*p) ) {
		case 10: goto tr85;
		case 13: goto tr86;
	}
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st46;
	goto st0;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
	switch( (*p) ) {
		case 32: goto st18;
		case 121: goto st52;
	}
	goto st0;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	switch( (*p) ) {
		case 32: goto st18;
		case 110: goto st53;
	}
	goto st0;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	switch( (*p) ) {
		case 32: goto st18;
		case 99: goto st54;
	}
	goto st0;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
	if ( (*p) == 32 )
		goto st18;
	goto st0;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
	switch( (*p) ) {
		case 10: goto tr90;
		case 13: goto tr91;
		case 120: goto st56;
	}
	goto st0;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	switch( (*p) ) {
		case 10: goto tr90;
		case 13: goto tr91;
		case 105: goto st57;
	}
	goto st0;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
	switch( (*p) ) {
		case 10: goto tr90;
		case 13: goto tr91;
		case 116: goto st58;
	}
	goto st0;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	switch( (*p) ) {
		case 10: goto tr90;
		case 13: goto tr91;
	}
	goto st0;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
	switch( (*p) ) {
		case 10: goto tr95;
		case 13: goto tr96;
		case 101: goto st60;
	}
	goto st0;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
	switch( (*p) ) {
		case 10: goto tr95;
		case 13: goto tr96;
		case 108: goto st61;
	}
	goto st0;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	switch( (*p) ) {
		case 10: goto tr95;
		case 13: goto tr96;
		case 112: goto st62;
	}
	goto st0;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
	switch( (*p) ) {
		case 10: goto tr95;
		case 13: goto tr96;
	}
	goto st0;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
	if ( (*p) == 117 )
		goto st64;
	goto st0;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
	switch( (*p) ) {
		case 32: goto st65;
		case 97: goto st68;
	}
	goto st0;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
	switch( (*p) ) {
		case 10: goto st0;
		case 13: goto st0;
		case 32: goto tr104;
	}
	goto tr103;
tr103:
#line 285 "src/admin.rl"
	{strstart = p;}
	goto st66;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
#line 1695 "src/admin.m"
	switch( (*p) ) {
		case 10: goto tr106;
		case 13: goto tr107;
	}
	goto st66;
tr104:
#line 285 "src/admin.rl"
	{strstart = p;}
	goto st67;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
#line 1709 "src/admin.m"
	switch( (*p) ) {
		case 10: goto tr106;
		case 13: goto tr107;
		case 32: goto tr104;
	}
	goto tr103;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
	if ( (*p) == 32 )
		goto st65;
	goto st0;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
	switch( (*p) ) {
		case 10: goto tr90;
		case 13: goto tr91;
		case 117: goto st56;
	}
	goto st0;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
	if ( (*p) == 101 )
		goto st71;
	goto st0;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
	switch( (*p) ) {
		case 32: goto st72;
		case 108: goto st86;
	}
	goto st0;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
	switch( (*p) ) {
		case 32: goto st72;
		case 99: goto st73;
	}
	goto st0;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
	if ( (*p) == 111 )
		goto st74;
	goto st0;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 110: goto st75;
	}
	goto st0;
st75:
	if ( ++p == pe )
		goto _test_eof75;
case 75:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 102: goto st76;
	}
	goto st0;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 105: goto st77;
	}
	goto st0;
st77:
	if ( ++p == pe )
		goto _test_eof77;
case 77:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 103: goto st78;
	}
	goto st0;
st78:
	if ( ++p == pe )
		goto _test_eof78;
case 78:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 117: goto st79;
	}
	goto st0;
st79:
	if ( ++p == pe )
		goto _test_eof79;
case 79:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 114: goto st80;
	}
	goto st0;
st80:
	if ( ++p == pe )
		goto _test_eof80;
case 80:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 97: goto st81;
	}
	goto st0;
st81:
	if ( ++p == pe )
		goto _test_eof81;
case 81:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 116: goto st82;
	}
	goto st0;
st82:
	if ( ++p == pe )
		goto _test_eof82;
case 82:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 105: goto st83;
	}
	goto st0;
st83:
	if ( ++p == pe )
		goto _test_eof83;
case 83:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 111: goto st84;
	}
	goto st0;
st84:
	if ( ++p == pe )
		goto _test_eof84;
case 84:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
		case 110: goto st85;
	}
	goto st0;
st85:
	if ( ++p == pe )
		goto _test_eof85;
case 85:
	switch( (*p) ) {
		case 10: goto tr113;
		case 13: goto tr114;
	}
	goto st0;
st86:
	if ( ++p == pe )
		goto _test_eof86;
case 86:
	switch( (*p) ) {
		case 32: goto st72;
		case 111: goto st87;
	}
	goto st0;
st87:
	if ( ++p == pe )
		goto _test_eof87;
case 87:
	switch( (*p) ) {
		case 32: goto st72;
		case 97: goto st88;
	}
	goto st0;
st88:
	if ( ++p == pe )
		goto _test_eof88;
case 88:
	switch( (*p) ) {
		case 32: goto st72;
		case 100: goto st89;
	}
	goto st0;
st89:
	if ( ++p == pe )
		goto _test_eof89;
case 89:
	if ( (*p) == 32 )
		goto st72;
	goto st0;
st90:
	if ( ++p == pe )
		goto _test_eof90;
case 90:
	switch( (*p) ) {
		case 97: goto st91;
		case 101: goto st111;
		case 104: goto st130;
	}
	goto st0;
st91:
	if ( ++p == pe )
		goto _test_eof91;
case 91:
	switch( (*p) ) {
		case 32: goto st92;
		case 118: goto st109;
	}
	goto st0;
st92:
	if ( ++p == pe )
		goto _test_eof92;
case 92:
	switch( (*p) ) {
		case 32: goto st92;
		case 99: goto st93;
		case 115: goto st101;
	}
	goto st0;
st93:
	if ( ++p == pe )
		goto _test_eof93;
case 93:
	if ( (*p) == 111 )
		goto st94;
	goto st0;
st94:
	if ( ++p == pe )
		goto _test_eof94;
case 94:
	switch( (*p) ) {
		case 10: goto tr137;
		case 13: goto tr138;
		case 114: goto st95;
	}
	goto st0;
st95:
	if ( ++p == pe )
		goto _test_eof95;
case 95:
	switch( (*p) ) {
		case 10: goto tr137;
		case 13: goto tr138;
		case 101: goto st96;
	}
	goto st0;
st96:
	if ( ++p == pe )
		goto _test_eof96;
case 96:
	switch( (*p) ) {
		case 10: goto tr137;
		case 13: goto tr138;
		case 100: goto st97;
	}
	goto st0;
st97:
	if ( ++p == pe )
		goto _test_eof97;
case 97:
	switch( (*p) ) {
		case 10: goto tr137;
		case 13: goto tr138;
		case 117: goto st98;
	}
	goto st0;
st98:
	if ( ++p == pe )
		goto _test_eof98;
case 98:
	switch( (*p) ) {
		case 10: goto tr137;
		case 13: goto tr138;
		case 109: goto st99;
	}
	goto st0;
st99:
	if ( ++p == pe )
		goto _test_eof99;
case 99:
	switch( (*p) ) {
		case 10: goto tr137;
		case 13: goto tr138;
		case 112: goto st100;
	}
	goto st0;
st100:
	if ( ++p == pe )
		goto _test_eof100;
case 100:
	switch( (*p) ) {
		case 10: goto tr137;
		case 13: goto tr138;
	}
	goto st0;
st101:
	if ( ++p == pe )
		goto _test_eof101;
case 101:
	if ( (*p) == 110 )
		goto st102;
	goto st0;
st102:
	if ( ++p == pe )
		goto _test_eof102;
case 102:
	switch( (*p) ) {
		case 10: goto tr146;
		case 13: goto tr147;
		case 97: goto st103;
	}
	goto st0;
st103:
	if ( ++p == pe )
		goto _test_eof103;
case 103:
	switch( (*p) ) {
		case 10: goto tr146;
		case 13: goto tr147;
		case 112: goto st104;
	}
	goto st0;
st104:
	if ( ++p == pe )
		goto _test_eof104;
case 104:
	switch( (*p) ) {
		case 10: goto tr146;
		case 13: goto tr147;
		case 115: goto st105;
	}
	goto st0;
st105:
	if ( ++p == pe )
		goto _test_eof105;
case 105:
	switch( (*p) ) {
		case 10: goto tr146;
		case 13: goto tr147;
		case 104: goto st106;
	}
	goto st0;
st106:
	if ( ++p == pe )
		goto _test_eof106;
case 106:
	switch( (*p) ) {
		case 10: goto tr146;
		case 13: goto tr147;
		case 111: goto st107;
	}
	goto st0;
st107:
	if ( ++p == pe )
		goto _test_eof107;
case 107:
	switch( (*p) ) {
		case 10: goto tr146;
		case 13: goto tr147;
		case 116: goto st108;
	}
	goto st0;
st108:
	if ( ++p == pe )
		goto _test_eof108;
case 108:
	switch( (*p) ) {
		case 10: goto tr146;
		case 13: goto tr147;
	}
	goto st0;
st109:
	if ( ++p == pe )
		goto _test_eof109;
case 109:
	switch( (*p) ) {
		case 32: goto st92;
		case 101: goto st110;
	}
	goto st0;
st110:
	if ( ++p == pe )
		goto _test_eof110;
case 110:
	if ( (*p) == 32 )
		goto st92;
	goto st0;
st111:
	if ( ++p == pe )
		goto _test_eof111;
case 111:
	switch( (*p) ) {
		case 32: goto st112;
		case 116: goto st129;
	}
	goto st0;
st112:
	if ( ++p == pe )
		goto _test_eof112;
case 112:
	switch( (*p) ) {
		case 32: goto st112;
		case 105: goto st113;
	}
	goto st0;
st113:
	if ( ++p == pe )
		goto _test_eof113;
case 113:
	if ( (*p) == 110 )
		goto st114;
	goto st0;
st114:
	if ( ++p == pe )
		goto _test_eof114;
case 114:
	switch( (*p) ) {
		case 32: goto st115;
		case 106: goto st122;
	}
	goto st0;
st115:
	if ( ++p == pe )
		goto _test_eof115;
case 115:
	if ( (*p) == 32 )
		goto st115;
	if ( 33 <= (*p) && (*p) <= 126 )
		goto tr161;
	goto st0;
tr161:
#line 293 "src/admin.rl"
	{ strstart = p; }
	goto st116;
st116:
	if ( ++p == pe )
		goto _test_eof116;
case 116:
#line 2166 "src/admin.m"
	if ( (*p) == 32 )
		goto tr162;
	if ( 33 <= (*p) && (*p) <= 126 )
		goto st116;
	goto st0;
tr162:
#line 293 "src/admin.rl"
	{ strend = p; }
	goto st117;
st117:
	if ( ++p == pe )
		goto _test_eof117;
case 117:
#line 2180 "src/admin.m"
	switch( (*p) ) {
		case 32: goto st117;
		case 111: goto st118;
	}
	goto st0;
st118:
	if ( ++p == pe )
		goto _test_eof118;
case 118:
	switch( (*p) ) {
		case 102: goto st119;
		case 110: goto st121;
	}
	goto st0;
st119:
	if ( ++p == pe )
		goto _test_eof119;
case 119:
	switch( (*p) ) {
		case 10: goto tr168;
		case 13: goto tr169;
		case 102: goto st120;
	}
	goto st0;
st120:
	if ( ++p == pe )
		goto _test_eof120;
case 120:
	switch( (*p) ) {
		case 10: goto tr168;
		case 13: goto tr169;
	}
	goto st0;
st121:
	if ( ++p == pe )
		goto _test_eof121;
case 121:
	switch( (*p) ) {
		case 10: goto tr171;
		case 13: goto tr172;
	}
	goto st0;
st122:
	if ( ++p == pe )
		goto _test_eof122;
case 122:
	switch( (*p) ) {
		case 32: goto st115;
		case 101: goto st123;
	}
	goto st0;
st123:
	if ( ++p == pe )
		goto _test_eof123;
case 123:
	switch( (*p) ) {
		case 32: goto st115;
		case 99: goto st124;
	}
	goto st0;
st124:
	if ( ++p == pe )
		goto _test_eof124;
case 124:
	switch( (*p) ) {
		case 32: goto st115;
		case 116: goto st125;
	}
	goto st0;
st125:
	if ( ++p == pe )
		goto _test_eof125;
case 125:
	switch( (*p) ) {
		case 32: goto st115;
		case 105: goto st126;
	}
	goto st0;
st126:
	if ( ++p == pe )
		goto _test_eof126;
case 126:
	switch( (*p) ) {
		case 32: goto st115;
		case 111: goto st127;
	}
	goto st0;
st127:
	if ( ++p == pe )
		goto _test_eof127;
case 127:
	switch( (*p) ) {
		case 32: goto st115;
		case 110: goto st128;
	}
	goto st0;
st128:
	if ( ++p == pe )
		goto _test_eof128;
case 128:
	if ( (*p) == 32 )
		goto st115;
	goto st0;
st129:
	if ( ++p == pe )
		goto _test_eof129;
case 129:
	if ( (*p) == 32 )
		goto st112;
	goto st0;
st130:
	if ( ++p == pe )
		goto _test_eof130;
case 130:
	switch( (*p) ) {
		case 32: goto st131;
		case 111: goto st184;
	}
	goto st0;
st131:
	if ( ++p == pe )
		goto _test_eof131;
case 131:
	switch( (*p) ) {
		case 32: goto st131;
		case 99: goto st132;
		case 100: goto st145;
		case 102: goto st154;
		case 105: goto st159;
		case 112: goto st171;
		case 115: goto st177;
	}
	goto st0;
st132:
	if ( ++p == pe )
		goto _test_eof132;
case 132:
	if ( (*p) == 111 )
		goto st133;
	goto st0;
st133:
	if ( ++p == pe )
		goto _test_eof133;
case 133:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 110: goto st134;
	}
	goto st0;
st134:
	if ( ++p == pe )
		goto _test_eof134;
case 134:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 102: goto st135;
	}
	goto st0;
st135:
	if ( ++p == pe )
		goto _test_eof135;
case 135:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 105: goto st136;
	}
	goto st0;
st136:
	if ( ++p == pe )
		goto _test_eof136;
case 136:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 103: goto st137;
	}
	goto st0;
st137:
	if ( ++p == pe )
		goto _test_eof137;
case 137:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 117: goto st138;
	}
	goto st0;
st138:
	if ( ++p == pe )
		goto _test_eof138;
case 138:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 114: goto st139;
	}
	goto st0;
st139:
	if ( ++p == pe )
		goto _test_eof139;
case 139:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 97: goto st140;
	}
	goto st0;
st140:
	if ( ++p == pe )
		goto _test_eof140;
case 140:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 116: goto st141;
	}
	goto st0;
st141:
	if ( ++p == pe )
		goto _test_eof141;
case 141:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 105: goto st142;
	}
	goto st0;
st142:
	if ( ++p == pe )
		goto _test_eof142;
case 142:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 111: goto st143;
	}
	goto st0;
st143:
	if ( ++p == pe )
		goto _test_eof143;
case 143:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
		case 110: goto st144;
	}
	goto st0;
st144:
	if ( ++p == pe )
		goto _test_eof144;
case 144:
	switch( (*p) ) {
		case 10: goto tr188;
		case 13: goto tr189;
	}
	goto st0;
st145:
	if ( ++p == pe )
		goto _test_eof145;
case 145:
	if ( (*p) == 101 )
		goto st146;
	goto st0;
st146:
	if ( ++p == pe )
		goto _test_eof146;
case 146:
	if ( (*p) == 98 )
		goto st147;
	goto st0;
st147:
	if ( ++p == pe )
		goto _test_eof147;
case 147:
	if ( (*p) == 117 )
		goto st148;
	goto st0;
st148:
	if ( ++p == pe )
		goto _test_eof148;
case 148:
	if ( (*p) == 103 )
		goto st149;
	goto st0;
st149:
	if ( ++p == pe )
		goto _test_eof149;
case 149:
	switch( (*p) ) {
		case 10: goto tr205;
		case 13: goto tr206;
		case 115: goto st150;
	}
	goto st0;
st150:
	if ( ++p == pe )
		goto _test_eof150;
case 150:
	switch( (*p) ) {
		case 10: goto tr205;
		case 13: goto tr206;
		case 121: goto st151;
	}
	goto st0;
st151:
	if ( ++p == pe )
		goto _test_eof151;
case 151:
	switch( (*p) ) {
		case 10: goto tr205;
		case 13: goto tr206;
		case 110: goto st152;
	}
	goto st0;
st152:
	if ( ++p == pe )
		goto _test_eof152;
case 152:
	switch( (*p) ) {
		case 10: goto tr205;
		case 13: goto tr206;
		case 99: goto st153;
	}
	goto st0;
st153:
	if ( ++p == pe )
		goto _test_eof153;
case 153:
	switch( (*p) ) {
		case 10: goto tr205;
		case 13: goto tr206;
	}
	goto st0;
st154:
	if ( ++p == pe )
		goto _test_eof154;
case 154:
	if ( (*p) == 105 )
		goto st155;
	goto st0;
st155:
	if ( ++p == pe )
		goto _test_eof155;
case 155:
	switch( (*p) ) {
		case 10: goto tr212;
		case 13: goto tr213;
		case 98: goto st156;
	}
	goto st0;
st156:
	if ( ++p == pe )
		goto _test_eof156;
case 156:
	switch( (*p) ) {
		case 10: goto tr212;
		case 13: goto tr213;
		case 101: goto st157;
	}
	goto st0;
st157:
	if ( ++p == pe )
		goto _test_eof157;
case 157:
	switch( (*p) ) {
		case 10: goto tr212;
		case 13: goto tr213;
		case 114: goto st158;
	}
	goto st0;
st158:
	if ( ++p == pe )
		goto _test_eof158;
case 158:
	switch( (*p) ) {
		case 10: goto tr212;
		case 13: goto tr213;
	}
	goto st0;
st159:
	if ( ++p == pe )
		goto _test_eof159;
case 159:
	if ( (*p) == 110 )
		goto st160;
	goto st0;
st160:
	if ( ++p == pe )
		goto _test_eof160;
case 160:
	switch( (*p) ) {
		case 10: goto tr218;
		case 13: goto tr219;
		case 102: goto st161;
		case 106: goto st163;
		case 115: goto st166;
	}
	goto st0;
st161:
	if ( ++p == pe )
		goto _test_eof161;
case 161:
	switch( (*p) ) {
		case 10: goto tr218;
		case 13: goto tr219;
		case 111: goto st162;
	}
	goto st0;
st162:
	if ( ++p == pe )
		goto _test_eof162;
case 162:
	switch( (*p) ) {
		case 10: goto tr218;
		case 13: goto tr219;
	}
	goto st0;
st163:
	if ( ++p == pe )
		goto _test_eof163;
case 163:
	switch( (*p) ) {
		case 101: goto st164;
		case 115: goto st166;
	}
	goto st0;
st164:
	if ( ++p == pe )
		goto _test_eof164;
case 164:
	switch( (*p) ) {
		case 99: goto st165;
		case 115: goto st166;
	}
	goto st0;
st165:
	if ( ++p == pe )
		goto _test_eof165;
case 165:
	switch( (*p) ) {
		case 115: goto st166;
		case 116: goto st167;
	}
	goto st0;
st166:
	if ( ++p == pe )
		goto _test_eof166;
case 166:
	switch( (*p) ) {
		case 10: goto tr227;
		case 13: goto tr228;
	}
	goto st0;
st167:
	if ( ++p == pe )
		goto _test_eof167;
case 167:
	switch( (*p) ) {
		case 105: goto st168;
		case 115: goto st166;
	}
	goto st0;
st168:
	if ( ++p == pe )
		goto _test_eof168;
case 168:
	switch( (*p) ) {
		case 111: goto st169;
		case 115: goto st166;
	}
	goto st0;
st169:
	if ( ++p == pe )
		goto _test_eof169;
case 169:
	switch( (*p) ) {
		case 110: goto st170;
		case 115: goto st166;
	}
	goto st0;
st170:
	if ( ++p == pe )
		goto _test_eof170;
case 170:
	if ( (*p) == 115 )
		goto st166;
	goto st0;
st171:
	if ( ++p == pe )
		goto _test_eof171;
case 171:
	if ( (*p) == 97 )
		goto st172;
	goto st0;
st172:
	if ( ++p == pe )
		goto _test_eof172;
case 172:
	switch( (*p) ) {
		case 10: goto tr233;
		case 13: goto tr234;
		case 108: goto st173;
	}
	goto st0;
st173:
	if ( ++p == pe )
		goto _test_eof173;
case 173:
	switch( (*p) ) {
		case 10: goto tr233;
		case 13: goto tr234;
		case 108: goto st174;
	}
	goto st0;
st174:
	if ( ++p == pe )
		goto _test_eof174;
case 174:
	switch( (*p) ) {
		case 10: goto tr233;
		case 13: goto tr234;
		case 111: goto st175;
	}
	goto st0;
st175:
	if ( ++p == pe )
		goto _test_eof175;
case 175:
	switch( (*p) ) {
		case 10: goto tr233;
		case 13: goto tr234;
		case 99: goto st176;
	}
	goto st0;
st176:
	if ( ++p == pe )
		goto _test_eof176;
case 176:
	switch( (*p) ) {
		case 10: goto tr233;
		case 13: goto tr234;
	}
	goto st0;
st177:
	if ( ++p == pe )
		goto _test_eof177;
case 177:
	switch( (*p) ) {
		case 108: goto st178;
		case 116: goto st181;
	}
	goto st0;
st178:
	if ( ++p == pe )
		goto _test_eof178;
case 178:
	switch( (*p) ) {
		case 10: goto tr241;
		case 13: goto tr242;
		case 97: goto st179;
	}
	goto st0;
st179:
	if ( ++p == pe )
		goto _test_eof179;
case 179:
	switch( (*p) ) {
		case 10: goto tr241;
		case 13: goto tr242;
		case 98: goto st180;
	}
	goto st0;
st180:
	if ( ++p == pe )
		goto _test_eof180;
case 180:
	switch( (*p) ) {
		case 10: goto tr241;
		case 13: goto tr242;
	}
	goto st0;
st181:
	if ( ++p == pe )
		goto _test_eof181;
case 181:
	switch( (*p) ) {
		case 10: goto tr245;
		case 13: goto tr246;
		case 97: goto st182;
	}
	goto st0;
st182:
	if ( ++p == pe )
		goto _test_eof182;
case 182:
	switch( (*p) ) {
		case 10: goto tr245;
		case 13: goto tr246;
		case 116: goto st183;
	}
	goto st0;
st183:
	if ( ++p == pe )
		goto _test_eof183;
case 183:
	switch( (*p) ) {
		case 10: goto tr245;
		case 13: goto tr246;
	}
	goto st0;
st184:
	if ( ++p == pe )
		goto _test_eof184;
case 184:
	switch( (*p) ) {
		case 32: goto st131;
		case 119: goto st185;
	}
	goto st0;
st185:
	if ( ++p == pe )
		goto _test_eof185;
case 185:
	if ( (*p) == 32 )
		goto st131;
	goto st0;
	}
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof186: cs = 186; goto _test_eof; 
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
	_test_eof55: cs = 55; goto _test_eof; 
	_test_eof56: cs = 56; goto _test_eof; 
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
	_test_eof121: cs = 121; goto _test_eof; 
	_test_eof122: cs = 122; goto _test_eof; 
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
	_test_eof138: cs = 138; goto _test_eof; 
	_test_eof139: cs = 139; goto _test_eof; 
	_test_eof140: cs = 140; goto _test_eof; 
	_test_eof141: cs = 141; goto _test_eof; 
	_test_eof142: cs = 142; goto _test_eof; 
	_test_eof143: cs = 143; goto _test_eof; 
	_test_eof144: cs = 144; goto _test_eof; 
	_test_eof145: cs = 145; goto _test_eof; 
	_test_eof146: cs = 146; goto _test_eof; 
	_test_eof147: cs = 147; goto _test_eof; 
	_test_eof148: cs = 148; goto _test_eof; 
	_test_eof149: cs = 149; goto _test_eof; 
	_test_eof150: cs = 150; goto _test_eof; 
	_test_eof151: cs = 151; goto _test_eof; 
	_test_eof152: cs = 152; goto _test_eof; 
	_test_eof153: cs = 153; goto _test_eof; 
	_test_eof154: cs = 154; goto _test_eof; 
	_test_eof155: cs = 155; goto _test_eof; 
	_test_eof156: cs = 156; goto _test_eof; 
	_test_eof157: cs = 157; goto _test_eof; 
	_test_eof158: cs = 158; goto _test_eof; 
	_test_eof159: cs = 159; goto _test_eof; 
	_test_eof160: cs = 160; goto _test_eof; 
	_test_eof161: cs = 161; goto _test_eof; 
	_test_eof162: cs = 162; goto _test_eof; 
	_test_eof163: cs = 163; goto _test_eof; 
	_test_eof164: cs = 164; goto _test_eof; 
	_test_eof165: cs = 165; goto _test_eof; 
	_test_eof166: cs = 166; goto _test_eof; 
	_test_eof167: cs = 167; goto _test_eof; 
	_test_eof168: cs = 168; goto _test_eof; 
	_test_eof169: cs = 169; goto _test_eof; 
	_test_eof170: cs = 170; goto _test_eof; 
	_test_eof171: cs = 171; goto _test_eof; 
	_test_eof172: cs = 172; goto _test_eof; 
	_test_eof173: cs = 173; goto _test_eof; 
	_test_eof174: cs = 174; goto _test_eof; 
	_test_eof175: cs = 175; goto _test_eof; 
	_test_eof176: cs = 176; goto _test_eof; 
	_test_eof177: cs = 177; goto _test_eof; 
	_test_eof178: cs = 178; goto _test_eof; 
	_test_eof179: cs = 179; goto _test_eof; 
	_test_eof180: cs = 180; goto _test_eof; 
	_test_eof181: cs = 181; goto _test_eof; 
	_test_eof182: cs = 182; goto _test_eof; 
	_test_eof183: cs = 183; goto _test_eof; 
	_test_eof184: cs = 184; goto _test_eof; 
	_test_eof185: cs = 185; goto _test_eof; 

	_test_eof: {}
	_out: {}
	}

#line 322 "src/admin.rl"


	tbuf_ltrim(fiber->rbuf, (void *)pe - (void *)fiber->rbuf->data);

	if (p != pe) {
		start(out);
		tbuf_append(out, unknown_command, strlen(unknown_command));
		end(out);
	}

	return fiber_write(out->data, out->size);
}

static void
admin_handler(void *data __attribute__((unused)))
{
	lua_State *L = lua_newthread(tarantool_L);
	int coro_ref = luaL_ref(tarantool_L, LUA_REGISTRYINDEX);
	/** Allow to interrupt/kill administrative connections. */
	fiber_setcancelstate(true);
	@try {
		for (;;) {
			if (admin_dispatch(L) <= 0)
				return;
			fiber_gc();
		}
	} @finally {
		luaL_unref(tarantool_L, LUA_REGISTRYINDEX, coro_ref);
	}
}

int
admin_init(void)
{
	if (fiber_server("admin", cfg.admin_port, admin_handler, NULL, NULL) == NULL) {
		say_syserror("can't bind to %d", cfg.admin_port);
		return -1;
	}
	return 0;
}



/*
 * Local Variables:
 * mode: c
 * End:
 * vim: syntax=objc
 */
