#ifndef TARANTOOL_PICKLE_H_INCLUDED
#define TARANTOOL_PICKLE_H_INCLUDED
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
#include <stdbool.h>
#include <stdint.h>
#include "exception.h"

#include <lib/bit/bit.h>
#include <tarantool/types.h>

/**
 * pickle (pick-little-endian) -- serialize/de-serialize data from
 * tuple and iproto binary formats.
 *
 * load_* - no boundary checking
 * pick_* - throws exception if no data in the buffer
 */

static inline uint32_t
load_u32(const char **data)
{
	const uint32_t *b = (const uint32_t *) *data;
	*data += sizeof(uint32_t);
	return *b;
}

#define pick_u(bits)						\
static inline uint##bits##_t					\
pick_u##bits(const char **begin, const char *end)		\
{								\
	if (end - *begin < (bits)/8)				\
		tnt_raise(IllegalParams,			\
			  "packet too short (expected "#bits" bits)");\
	uint##bits##_t r = *(uint##bits##_t *)*begin;		\
	*begin += (bits)/8;					\
	return r;						\
}

pick_u(8)
pick_u(16)
pick_u(32)
pick_u(64)

static inline const char *
pick_str(const char **data, const char *end, uint32_t size)
{
	const char *str = *data;
	if (str + size > end)
		tnt_raise(IllegalParams,
			  "packet too short (expected a field)");
	*data += size;
	return str;
}

#define pack_u(bits)						\
static inline char *						\
pack_u##bits(char *data, uint##bits##_t val)			\
{								\
	*(uint##bits##_t *) data = val;				\
	return data + sizeof(uint##bits##_t);			\
}

pack_u(8)
pack_u(16)
pack_u(32)
pack_u(64)

#if defined(__cplusplus)
extern "C" {
#endif /* defined(__cplusplus) */

#define MSGPACK 1

#define mp_unreachable() (assert(false), __builtin_unreachable())

inline enum mp_type
mp_typeof(const char c)
{
	switch ((unsigned char) c) {
	case 0x00 ... 0x7f:
		return MP_UINT;
	case 0x80 ... 0x8f:
		return MP_MAP;
	case 0x90 ... 0x9f:
		return MP_ARRAY;
	case 0xa0 ... 0xbf:
		return MP_STR;
	case 0xc0:
		return MP_NIL;
	case 0xc1:
		return MP_EXT; /* (never used) */
	case 0xc2 ... 0xc3:
		return MP_BOOL;
	case 0xc4 ... 0xc6:
		return MP_BIN;
	case 0xc7 ... 0xc9:
		return MP_EXT;
	case 0xca:
		return MP_FLOAT;
	case 0xcb:
		return MP_DOUBLE;
	case 0xcc ... 0xcf:
		return MP_UINT;
	case 0xd0 ... 0xd3:
		return MP_INT;
	case 0xd4 ... 	0xd8:
		return MP_EXT;
	case 0xd9 ... 0xdb:
		return MP_STR;
	case 0xdc ... 	0xdd:
		return MP_ARRAY;
	case 0xde ... 0xde:
		return MP_MAP;
	case 0xe0 ... 0xff:
		return MP_INT;
	default:
		return MP_EXT;
	}
}

inline uint32_t
mp_array_sizeof(uint32_t size)
{
	if (size <= 15) {
		return 1;
	} else if (size <= UINT16_MAX) {
		return 3;
	} else {
		return 5;
	}
}

inline char *
mp_array_pack(char *data, uint32_t size)
{
	if (size <= 15) {
		*(unsigned char *) (data++) = 0x90 | size;
		return data;
	} else if (size <= UINT16_MAX) {
		*(data++) = 0xdc;
		*(uint16_t *) data = bswap_u16(size);
		return data + sizeof(uint16_t);
	} else {
		*(data++) = 0xdd;
		*(uint32_t *) data = bswap_u32(size);
		return data + sizeof(uint32_t);
	}
}

inline uint32_t
mp_array_pick(const char **data, const char *end)
{
	if (unlikely(*data >= end))
		tnt_raise(IllegalParams, "invalid MsgPack array 1");

	unsigned const char c = **data;
	*data += 1;
	uint32_t size;
	switch (c) {
	case 0x90 ... 0x9f:
		return c & 0xf;
	case 0xdc:
		if (unlikely(*data + sizeof(uint16_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack array 2");
		size = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		return size;
	case 0xdd:
		if (unlikely(*data + sizeof(uint32_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack array 3");
		size = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		return size;
	default:
		tnt_raise(IllegalParams, "invalid MsgPack array 4");
		return 0;
	}
}

inline uint32_t
mp_array_load(const char **data)
{
	unsigned const char c = **data;
	*data += 1;
	uint32_t size;

	if (likely((c & 0xf0) == 0x90))
		return (c & 0xf);

	switch (c) {
	case 0xdc:
		size = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		return size;
	case 0xdd:
		size = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		return size;
	}

	mp_unreachable();
}

inline uint32_t
mp_map_sizeof(uint32_t size)
{
	if (size <= 15) {
		return 1;
	} else if (size <= UINT16_MAX) {
		return 1 + sizeof(uint16_t);
	} else {
		return 1 + sizeof(uint32_t);
	}
}

inline char *
mp_map_pack(char *data, uint32_t size)
{
	if (size <= 15) {
		*(data++) = 0x80 | (char) size;
		return data;
	} else if (size <= UINT16_MAX) {
		*(data++) = 0xde;
		*(uint16_t *) data = bswap_u16(size);
		return data + sizeof(uint16_t);
	} else {
		*(data++) = 0xdf;
		*(uint32_t *) data = bswap_u32(size);
		return data + sizeof(uint32_t);
	}
}

inline uint32_t
mp_map_pick(const char **data, const char *end)
{
	if (unlikely(*data >= end))
		tnt_raise(IllegalParams, "invalid MsgPack map");

	unsigned const char c = **data;
	*data += 1;
	uint32_t size;
	switch (c) {
	case 0x80 ... 0x8f:
		return c & 0xf;
	case 0xde:
		if (unlikely(*data + sizeof(uint16_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack map");
		size = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		return size;
	case 0xdf:
		if (unlikely(*data + sizeof(uint32_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack map");
		size = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		return size;
	default:
		tnt_raise(IllegalParams, "invalid MsgPack map");
		return 0;
	}
}

inline uint32_t
mp_map_load(const char **data)
{
	unsigned const char c = **data;
	*data += 1;
	uint32_t size;
	switch (c) {
	case 0x80 ... 0x8f:
		return c & 0xf;
	case 0xde:
		size = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		return size;
	case 0xdf:
		size = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		return size;
	}

	mp_unreachable();
}

inline uint32_t
mp_uint_sizeof(uint64_t num)
{
	if (num <= 127) {
		return 1;
	} else if (num <= UINT8_MAX) {
		return 1 + sizeof(uint8_t);
	} else if (num <= UINT16_MAX) {
		return 1 + sizeof(uint16_t);
	} else if (num <= UINT32_MAX) {
		return 1 + sizeof(uint32_t);
	} else {
		return 1 + sizeof(uint64_t);
	}
}

inline uint32_t
mp_int_sizeof(int64_t num)
{
	if (num <= 31) {
		return 1;
	} else if (num >= INT8_MIN && num <= INT8_MAX) {
		return 1 + sizeof(int8_t);
	} else if (num >= INT16_MIN && num <= UINT16_MAX) {
		return 1 + sizeof(int16_t);
	} else if (num >= INT32_MIN && num <= UINT32_MAX) {
		return 1 + sizeof(int32_t);
	} else {
		return 1 + sizeof(int64_t);
	}
}

inline char *
mp_uint_pack(char *data, uint64_t num)
{
	if (num <= 127) {
		*data = num;
		return data + 1;
	} else if (num <= UINT8_MAX) {
		*data = 0xcc;
		data++;
		*(uint8_t *) data = num;
		return data + sizeof(uint8_t);
	} else if (num <= UINT16_MAX) {
		*data = 0xcd;
		data++;
		*(uint16_t *) data = bswap_u16(num);
		return data + sizeof(uint16_t);
	} else if (num <= UINT32_MAX) {
		*data = 0xce;
		data++;
		*(uint32_t *) data = bswap_u32(num);
		return data + sizeof(uint32_t);
	} else {
		*data = 0xcf;
		data++;
		*(uint64_t *) data = bswap_u64(num);
		return data + sizeof(uint64_t);
	}
}

inline char *
mp_int_pack(char *data, int64_t num)
{
	if (num >= 0) {
		return mp_uint_pack(data, num);
	} else if (num >= -31) {
		*data = (0xe0 | num);
		return data + 1;
	} else if (num >= INT8_MIN) {
		*data = 0xd0;
		data++;
		*(int8_t *) data = num;
		return data + sizeof(int8_t);
	} else if (num >= INT16_MIN) {
		*data = 0xd1;
		data++;
		*(int16_t *) data = bswap_u16(num);
		return data + sizeof(int16_t);
	} else if (num >= INT32_MIN) {
		*data = 0xd2;
		data++;
		*(int32_t *) data = bswap_u32(num);
		return data + sizeof(int32_t);
	} else {
		*data = 0xd3;
		data++;
		*(int64_t *) data = bswap_u64(num);
		return data + sizeof(int64_t);
	}
}


inline uint64_t
mp_uint_pick(const char **data, const char *end)
{
	if (unlikely(*data >= end))
		tnt_raise(IllegalParams, "invalid MsgPack uint");

	unsigned const char c = **data;
	*data += 1;
	uint64_t val;
	switch (c) {
	case 0x00 ... 0x7f:
		return c;
	case 0xcc:
		if (unlikely(*data + sizeof(uint8_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack uint");
		val = *(uint8_t *) *data;
		*data += sizeof(uint8_t);
		return val;
	case 0xcd:
		if (unlikely(*data + sizeof(uint16_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack uint");
		val = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		return val;
	case 0xce:
		if (unlikely(*data + sizeof(uint32_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack uint");
		val = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		return val;
	case 0xcf:
		if (unlikely(*data + sizeof(uint64_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack uint");
		val = bswap_u64(*(uint64_t *) *data);
		*data += sizeof(uint64_t);
		return val;
	default:
		tnt_raise(IllegalParams, "invalid MsgPack uint");
		return 0;
	}
}

inline int64_t
mp_int_pick(const char **data, const char *end)
{
	if (unlikely(*data >= end))
		tnt_raise(IllegalParams, "invalid MsgPack int");

	unsigned const char c = **data;
	*data += 1;
	int64_t val;
	switch (c) {
	case 0xe0 ... 0xff:
		return (c & 0x1f); /* signed and < 0 */
	case 0xd0:
		if (unlikely(*data + sizeof(uint8_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack int");
		val = *(int8_t *) *data;
		*data += sizeof(int8_t);
		return val;
	case 0xd1:
		if (unlikely(*data + sizeof(uint16_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack int");
		val = bswap_u16(*(int16_t *) *data);
		*data += sizeof(int16_t);
		return val;
	case 0xd2:
		if (unlikely(*data + sizeof(int32_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack int");
		val = bswap_u32(*(int32_t *) *data);
		*data += sizeof(int32_t);
		return val;
	case 0xd3:
		if (unlikely(*data + sizeof(int64_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack int");
		val = bswap_u64(*(int64_t *) *data);
		*data += sizeof(int64_t);
		return val;
	default:
		tnt_raise(IllegalParams, "invalid MsgPack int");
		return 0;
	}
}

inline uint64_t
mp_uint_load(const char **data)
{
	unsigned const char c = **data;
	*data += 1;
	uint64_t val;

	switch (c) {
	case 0x00 ... 0x7f:
		return c;
	case 0xcc:
		val = *(uint8_t *) *data;
		*data += sizeof(uint8_t);
		return val;
	case 0xcd:
		val = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		return val;
	case 0xce:
		val = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		return val;
	case 0xcf:
		val = bswap_u64(*(uint64_t *) *data);
		*data += sizeof(uint64_t);
		return val;
	}

	mp_unreachable();
}

inline int64_t
mp_int_load(const char **data)
{
	unsigned const char c = **data;
	*data += 1;
	int64_t val;
	switch (c) {
	case 0xe0 ... 0xff:
		return (c & 0x1f);
	case 0xd0:
		val = *(int8_t *) *data;
		*data += sizeof(uint8_t);
		return val;
	case 0xd1:
		val = bswap_u16(*(int16_t *) *data);
		*data += sizeof(uint16_t);
		return val;
	case 0xd2:
		val = bswap_u32(*(int32_t *) *data);
		*data += sizeof(uint32_t);
		return val;
	case 0xd3:
		val = bswap_u64(*(int64_t *) *data);
		*data += sizeof(int64_t);
		return val;
	}

	mp_unreachable();
}

inline uint32_t
mp_float_sizeof(float num)
{
	(void) num;
	return 1 + sizeof(float);
}

inline uint32_t
mp_double_sizeof(double num)
{
	(void) num;
	return 1 + sizeof(double);
}

inline char *
mp_float_pack(char *data, float num)
{
	*data = 0xca;
	data++;
	*(float *) data = num;
	return data + sizeof(float);
}

inline char *
mp_double_pack(char *data, double num)
{
	*data = 0xcb;
	data++;
	*(double *) data = num;
	return data + sizeof(double);
}

inline float
mp_float_pick(const char **data, const char *end)
{
	if (unlikely(*data + sizeof(float) >= end ||
	    *(unsigned const char *) *data != 0xca))
		tnt_raise(IllegalParams, "invalid MsgPack float");

	*data += 1;
	float val = *(float *) *data;
	*data += sizeof(float);
	return val;
}

inline double
mp_double_pick(const char **data, const char *end)
{
	if (unlikely(*data + sizeof(double) > end ||
	    *(unsigned const char *) *data != 0xcb))
		tnt_raise(IllegalParams, "invalid MsgPack double");

	*data += 1;
	double val = *(double *) *data;
	*data += sizeof(double);
	return val;
}

inline float
mp_float_load(const char **data)
{
	unsigned const char c = **data;
	assert(c == 0xca);
	(void) c;
	*data += 1;
	float val = *(float *) *data;
	*data += sizeof(float);
	return val;
}

inline double
mp_double_load(const char **data)
{
	unsigned const char c = **data;
	assert(c == 0xcb);
	(void) c;
	*data += 1;
	double val = *(double *) *data;
	*data += sizeof(double);
	return val;
}

inline uint32_t
mp_str_sizeof(uint32_t len)
{
	if (len <= 31) {
		return 1 + len;
#if defined(MSGPACK_NEW_SPEC)
	} else if (len <= UINT8_MAX) {
		return 1 + sizeof(uint8_t) + len;
#endif /* defined(MSGPACK_NEW_SPEC) */
	} else if (len <= UINT16_MAX) {
		return 1 + sizeof(uint16_t) + len;
	} else {
		return 1 + sizeof(uint32_t) + len;
	}
}

inline uint32_t
mp_bin_sizeof(uint32_t len)
{
	if (len <= UINT8_MAX) {
		return 1 + sizeof(uint8_t) + len;
	} else if (len <= UINT16_MAX) {
		return 1 + sizeof(uint16_t) + len;
	} else {
		return 1 + sizeof(uint32_t) + len;
	}
}

inline char *
mp_str_pack_size(char *data, uint32_t len)
{
	if (len <= 31) {
		*data = 0xa0 | (unsigned char) len;
		data += 1;
#if defined(MSGPACK_NEW_SPEC)
	} else if (len <= UINT8_MAX) {
		*data = 0xd9;
		data += 1;
		*(uint8_t *) data = len;
		data += sizeof(uint8_t);
#endif /* defined(MSGPACK_NEW_SPEC) */
	} else if (len <= UINT16_MAX) {
		*data = 0xda;
		data += 1;
		*(uint16_t *) data = bswap_u16(len);
		data += sizeof(uint16_t);
	} else {
		*data = 0xdb;
		data += 1;
		*(uint32_t *) data = bswap_u32(len);
		data += sizeof(uint32_t);
	}

	return data;
}

inline char *
mp_str_pack(char *data, const char *str, uint32_t len)
{
	data = mp_str_pack_size(data, len);
	memcpy(data, str, len);
	return data + len;
}

inline char *
mp_bin_pack(char *data, const char *str, uint32_t len)
{
	if (len <= UINT8_MAX) {
		*data = 0xc4;
		data += 1;
		*(uint8_t *) data = len;
		data += sizeof(uint8_t);
	} else if (len <= UINT16_MAX) {
		*data = 0xc5;
		data += 1;
		*(uint16_t *) data = bswap_u16(len);
		data += sizeof(uint16_t);
	} else {
		*data = 0xc6;
		data += 1;
		*(uint32_t *) data = bswap_u32(len);
		data += sizeof(uint32_t);
	}

	memcpy(data, str, len);
	return data + len;
}
inline const char *
mp_str_load(const char **data, uint32_t *len)
{
	assert(len != NULL);

	unsigned const char c = **data;
	*data += 1;
	const char *str;
	switch (c) {
	case 0xa0 ... 0xbf:
		*len = c & 0x1f;
		str = *data;
		*data += *len;
		return str;
	case 0xd9:
		*len = *(uint8_t *) *data;
		*data += sizeof(uint8_t);
		str = *data;
		*data += *len;
		return str;
	case 0xda:
		*len = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		str = *data;
		*data += *len;
		return str;
	case 0xdb:
		*len = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		str = *data;
		*data += *len;
		return str;
	}

	mp_unreachable();
}

inline const char *
mp_str_pick(const char **data, const char *end, uint32_t *len)
{
	assert(len != NULL);

	if (unlikely(*data >= end))
		tnt_raise(IllegalParams, "invalid MsgPack str");

	unsigned const char c = **data;
	*data += 1;
	switch (c) {
	case 0xa0 ... 0xbf:
		*len = (c & 0x1f);
		break;
	case 0xd9:
		if (unlikely(*data + sizeof(uint8_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack str");
		*len = *(uint8_t *) *data;
		*data += sizeof(uint8_t);
		break;
	case 0xda:
		if (unlikely(*data + sizeof(uint16_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack str");
		*len = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		break;
	case 0xdb:
		if (unlikely(*data + sizeof(uint32_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack str");
		*len = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		break;
	default:
		tnt_raise(IllegalParams, "invalid MsgPack str");
		return NULL;
	}

	if (unlikely(*data + *len > end))
		tnt_raise(IllegalParams, "invalid MsgPack str");
	const char *str = *data;
	*data += *len;
	return str;
}

inline const char *
mp_bin_pick(const char **data, const char *end, uint32_t *len)
{
	assert(len != NULL);

	if (unlikely(*data >= end))
		tnt_raise(IllegalParams, "invalid MsgPack binary");

	unsigned const char c = **data;
	*data += 1;
	switch (c) {
	case 0xc4:
		if (unlikely(*data + sizeof(uint8_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack binary");
		*len = *(uint8_t *) *data;
		*data += sizeof(uint8_t);
		break;
	case 0xc5:
		if (unlikely(*data + sizeof(uint16_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack binary");
		*len = *(uint16_t *) *data;
		*data += sizeof(uint16_t);
		break;
	case 0xc6:
		if (unlikely(*data + sizeof(uint32_t) > end))
			tnt_raise(IllegalParams, "invalid MsgPack binary");
		*len = *(uint32_t *) *data;
		*data += sizeof(uint32_t);
		break;
	default:
		tnt_raise(IllegalParams, "invalid MsgPack binary");
		return NULL;
	}

	if (unlikely(*data + *len > end))
		tnt_raise(IllegalParams, "invalid MsgPack binary");

	const char *str = *data;
	*data += *len;
	return str;
}


inline const char *
mp_bin_load(const char **data, uint32_t *len)
{
	assert(len != NULL);

	unsigned const char c = **data;
	*data += 1;
	const char *str;
	switch (c) {
	case 0xc4:
		*len = *(uint8_t *) *data;
		*data += sizeof(uint8_t);
		str = *data;
		*data += *len;
		return str;
	case 0xc5:
		*len = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		str = *data;
		*data += *len;
		return str;
	case 0xc6:
		*len = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		str = *data;
		*data += *len;
		return str;
	}

	mp_unreachable();
}

inline uint32_t
mp_nil_sizeof()
{
	return 1;
}

inline char *
mp_nil_pack(char *data)
{
	*data = 0xc0;
	return data + 1;
}

inline void
mp_nil_pick(const char **data, const char *end)
{
	if (unlikely(*data >= end))
		tnt_raise(IllegalParams, "invalid MsgPack nil");

	unsigned char c = *(const unsigned char *) *data;
	if (unlikely(c != 0xc0))
		tnt_raise(IllegalParams, "invalid MsgPack nil");
	*data += 1;
}

inline void
mp_nil_load(const char **data)
{
	unsigned char c = *(const unsigned char *) *data;
	assert(c == 0xc0);
	(void) c;
	*data += 1;
}

inline uint32_t
mp_bool_sizeof()
{
	return 1;
}

inline char *
mp_bool_pack(char *data, bool val)
{
	*data = 0xc2 | (val & 1);
	return data + 1;
}

inline bool
mp_bool_pick(const char **data, const char *end)
{
	if (unlikely(*data >= end))
		tnt_raise(IllegalParams, "invalid MsgPack bool");

	unsigned char c = *(const unsigned char *) *data;
	*data += 1;
	switch (c) {
	case 0xc3:
		return true;
	case 0xc2:
		return false;
	default:
		tnt_raise(IllegalParams, "invalid MsgPack bool");
	}
}

inline bool
mp_bool_load(const char **data)
{
	unsigned char c = *(const unsigned char *) *data;
	*data += 1;
	switch (c) {
	case 0xc3:
		return true;
	case 0xc2:
		return false;
	}

	mp_unreachable();
}

inline enum mp_type
mp_load(const char **data)
{
	uint32_t size;
	unsigned char c = *(unsigned char *) *data;
	*data += 1;

	switch (c) {
	/* {{{ MP_UINT */
	case 0x00 ... 0x7f:
		return MP_UINT;
	case 0xcc:
		*data += sizeof(uint8_t);
		return MP_UINT;
	case 0xcd:
		*data += sizeof(uint16_t);
		return MP_UINT;
	case 0xce:
		*data += sizeof(uint32_t);
		return MP_UINT;
	case 0xcf:
		*data += sizeof(uint64_t);
		return MP_UINT;
	/* }}} */

	/* {{{ MP_INT */
#if defined(TEST)
	case 0xd0 ... 0dx3:
		*data += 1 << (c & 0x3);
		*data += sizeof(uint8_t);
		return MP_INT;
#endif
	case 0xe0 ... 0xff:
		return MP_INT;
	case 0xd1:
		*data += sizeof(uint16_t);
		return MP_INT;
	case 0xd2:
		*data += sizeof(uint32_t);
		return MP_INT;
	case 0xd3:
		*data += sizeof(int64_t);
		return MP_INT;
	/* }}} */

	/* {{{ MP_MAP */
	case 0x80 ... 0x8f:
		size = (c & 0xf);
		for (uint32_t i = 0; i < size; i++) {
			mp_load(data); 	/* Key */
			mp_load(data);	/* Value */
		}
		return MP_MAP;
	case 0xde:
		size = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		for (uint32_t i = 0; i < size; i++) {
			mp_load(data); 	/* Key */
			mp_load(data);	/* Value */
		}
		return MP_MAP;
	case 0xdf:
		size = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		for (uint32_t i = 0; i < size; i++) {
			mp_load(data); 	/* Key */
			mp_load(data);	/* Value */
		}
		return MP_MAP;
	/* }}} */

	/* {{{ MP_ARRAY */
	case 0x90 ... 0x9f:
		size = c & 0xf;
		for (uint32_t i = 0; i < size; i++) {
			mp_load(data);
		}
		return MP_ARRAY;
	case 0xdc:
		size = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		for (uint32_t i = 0; i < size; i++) {
			mp_load(data);
		}
		return MP_ARRAY;
	case 0xdd:
		size = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		for (uint32_t i = 0; i < size; i++) {
			mp_load(data);
		}
		return MP_ARRAY;
	/* }}} */

	/* {{{ MP_STR */
	case 0xa0 ... 0xbf:
		size = (c & 0x1f);
		*data += size;
		return MP_STR;
	case 0xd9:
		size = *(uint8_t *) *data;
		*data += sizeof(uint8_t);
		*data += size;
		return MP_STR;
	case 0xda:
		size = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		*data += size;
		return MP_STR;
	case 0xdb:
		size = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		*data += size;
		return MP_STR;
	/* }}} */

	/* {{{ MP_NIL */
	case 0xc0:
		return MP_NIL;
	/* }}} */

	/* {{{ MP_BOOL */
	case 0xc2 ... 0xc3:
		return MP_BOOL;
	/* }}} */

	/* {{{ MP_FLOAT */
	case 0xca:
		*data += sizeof(float);
		return MP_FLOAT;
	/* }}} */

	/* {{{ MP_DOUBLE */
	case 0xcb:
		*data += sizeof(double);
		return MP_DOUBLE;
	/* }}} */

	/* {{{ MP_BIN */
	case 0xc4:
		size = *(uint8_t *) *data;
		*data += sizeof(uint8_t);
		*data += size;
		return MP_BIN;
	case 0xc5:
		size = bswap_u16(*(uint16_t *) *data);
		*data += sizeof(uint16_t);
		*data += size;
		return MP_BIN;
	case 0xc6:
		size = bswap_u32(*(uint32_t *) *data);
		*data += sizeof(uint32_t);
		*data += size;
		return MP_BIN;
	/* }}} */
#if 0
	case 0xc1:          /* reserved */
	case 0xc7 ... 0xc9: /* extensions */
	case 0xd4 ... 0xd8: /* extensions */
		assert(false);
		return MP_EXT;
#endif
	}

	mp_unreachable();
}

inline enum mp_type
mp_pick(const char **data, const char *end)
{
	if (unlikely(*data >= end))
		tnt_raise(IllegalParams, "invalid MsgPack");

	uint32_t size;

	switch (*(unsigned char *) *data) {
	case 0x00 ... 0x7f:
	case 0xcc ... 0xcf:
		(void) mp_uint_pick(data, end);
		return MP_UINT;
	case 0xd0 ... 0xd3:
	case 0xe0 ... 0xff:
		(void) mp_int_pick(data, end);
		return MP_INT;
	case 0x80 ... 0x8f:
	case 0xde ...  0xdf:
		size = mp_map_pick(data, end);
		for (uint32_t i = 0; i < size; i++) {
			mp_pick(data, end); 	/* Key */
			mp_pick(data, end);	/* Value */
		}
		return MP_MAP;
	case 0x90 ... 0x9f:
	case 0xdc ... 0xdd:
		size = mp_array_pick(data, end);
		for (uint32_t i = 0; i < size; i++) {
			mp_pick(data, end); /* Element */
		}
		return MP_ARRAY;
	case 0xa0 ... 0xbf:
	case 0xd9 ... 0xdb:
		(void) mp_str_pick(data, end, &size);
		return MP_STR;
	case 0xc0:
		(void) mp_nil_pick(data, end);
		return MP_NIL;
	case 0xc2 ... 0xc3:
		(void) mp_bool_pick(data, end);
		return MP_BOOL;
	case 0xca:
		(void) mp_float_pick(data, end);
		return MP_FLOAT;
	case 0xcb:
		(void) mp_double_pick(data, end);
		return MP_DOUBLE;
	case 0xc4 ... 0xc6:
		(void) mp_bin_pick(data, end, &size);
		return MP_BIN;
#if 0
	case 0xc1:
	case 0xc7 ... 0xc9:
	case 0xd4 ... 	0xd8:
		return MP_EXT;
#endif
	}

	tnt_raise(IllegalParams, "unsupported MsgPack");
	mp_unreachable();
}

#undef mp_unreachable

#if defined(__cplusplus)
} /* extern "C" */
#endif /* defined(__cplusplus) */

#endif /* TARANTOOL_PICKLE_H_INCLUDED */
