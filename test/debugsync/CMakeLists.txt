set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu99")
add_library(debugsync STATIC debugsync.m fiber_ds.m)
