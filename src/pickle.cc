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
#include "pickle.h"

extern inline enum mp_type
mp_typeof(const char c);

extern inline uint32_t
mp_array_sizeof(uint32_t size);

extern inline char *
mp_array_pack(char *data, uint32_t size);

extern inline uint32_t
mp_array_pick(const char **data, const char *end);

extern inline uint32_t
mp_array_load(const char **data);

extern inline uint32_t
mp_map_sizeof(uint32_t size);

extern inline char *
mp_map_pack(char *data, uint32_t size);

extern inline uint32_t
mp_map_pick(const char **data, const char *end);

extern inline uint32_t
mp_map_load(const char **data);

extern inline uint32_t
mp_uint_sizeof(uint64_t num);

extern inline uint32_t
mp_int_sizeof(int64_t num);

extern inline char *
mp_uint_pack(char *data, uint64_t num);

extern inline char *
mp_int_pack(char *data, int64_t num);

extern inline uint64_t
mp_uint_pick(const char **data, const char *end);

extern inline int64_t
mp_int_pick(const char **data, const char *end);

extern inline uint64_t
mp_uint_load(const char **data);

extern inline int64_t
mp_int_load(const char **data);

extern inline uint32_t
mp_float_sizeof(float num);

extern inline uint32_t
mp_double_sizeof(double num);

extern inline char *
mp_float_pack(char *data, float num);

extern inline char *
mp_double_pack(char *data, double num);

extern inline float
mp_float_pick(const char **data, const char *end);

extern inline double
mp_double_pick(const char **data, const char *end);

extern inline float
mp_float_load(const char **data);

extern inline double
mp_double_load(const char **data);

extern inline uint32_t
mp_str_sizeof(uint32_t len);

extern inline uint32_t
mp_bin_sizeof(uint32_t len);

extern inline char *
mp_str_pack_size(char *data, uint32_t len);

extern inline char *
mp_str_pack(char *data, const char *str, uint32_t len);

extern inline char *
mp_bin_pack(char *data, const char *str, uint32_t len);

extern inline const char *
mp_str_load(const char **data, uint32_t *len);

extern inline const char *
mp_str_pick(const char **data, const char *end, uint32_t *len);

extern inline const char *
mp_bin_pick(const char **data, const char *end, uint32_t *len);

extern inline const char *
mp_bin_load(const char **data, uint32_t *len);

extern inline uint32_t
mp_nil_sizeof();

extern inline char *
mp_nil_pack(char *data);

extern inline void
mp_nil_pick(const char **data, const char *end);

extern inline void
mp_nil_load(const char **data);

extern inline uint32_t
mp_bool_sizeof();

extern inline char *
mp_bool_pack(char *data, bool val);

extern inline bool
mp_bool_pick(const char **data, const char *end);

extern inline bool
mp_bool_load(const char **data);

extern inline enum mp_type
mp_load(const char **data);

extern inline enum mp_type
mp_pick(const char **data, const char *end);
