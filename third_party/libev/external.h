#ifdef ENABLE_DTRACE
#include "ev_dtrace.h"
#else
#define EV_TICK_START(flags)
#define EV_TICK_STOP(flags)
#endif
