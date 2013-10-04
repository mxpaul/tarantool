file(GLOB all_sources *.c *.m *.mm)
set_source_files_compile_flags("TESTS" ${all_sources})

include_directories("${PROJECT_SOURCE_DIR}/test/unit")
include_directories("${PROJECT_SOURCE_DIR}/connector/c")

#tarantool_client("protocol" protocol.c)
tarantool_client("tp" tp.c)
