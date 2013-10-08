#ifdef ENABLE_DTRACE
#include "coro_dtrace.h"
#else
#define	CORO_END()
#define	CORO_END_ENABLED() (0)
#define	CORO_INIT()
#define	CORO_INIT_ENABLED() (0)
#define	CORO_START()
#define	CORO_START_ENABLED() (0)
#endif
