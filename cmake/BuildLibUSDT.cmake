macro(libusdt_build)
    enable_language(ASM)

    if (TARGET_OS_FREEBSD)
        # Depends by FreeBSD src because dtrace.h not in /usr/include/sys
        include_directories(
            /usr/src/sys/cddl/compat/opensolaris
            /usr/src/sys/cddl/contrib/opensolaris/uts/common
        )
    endif()

    set(usdt_cflags "-fPIC")

    if (${CMAKE_SYSTEM_PROCESSOR} STREQUAL "amd64")
        set(usdt_trace_arch "x86_64")
    else()
        set(usdt_trace_arch ${CMAKE_SYSTEM_PROCESSOR})
    endif()

    set(usdt_src_dir ${PROJECT_SOURCE_DIR}/third_party/libusdt) 
    set(usdt_src
        ${usdt_src_dir}/usdt.c
        ${usdt_src_dir}/usdt_dof_file.c
        ${usdt_src_dir}/usdt_probe.c
        ${usdt_src_dir}/usdt_dof.c
        ${usdt_src_dir}/usdt_dof_sections.c
    )

    set(usdt_src_lua
        ${PROJECT_SOURCE_DIR}/third_party/lua-usdt/usdt.c
    )

    set(LIBUSDT_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/third_party/libusdt)
    include_directories(${LIBUSDT_INCLUDE_DIR})


    add_library(usdt_objs OBJECT ${usdt_src})
    add_library(lua_usdt_objs OBJECT ${usdt_src_lua})
    add_library(usdt_trace OBJECT ${usdt_src_dir}/usdt_tracepoints_${usdt_trace_arch}.s)

    set_target_properties(usdt_objs PROPERTIES COMPILE_FLAGS ${usdt_cflags})
    set_property(SOURCE ${usdt_src_dir}/usdt_tracepoints_${usdt_trace_arch}.s PROPERTY LANGUAGE ASM)
    set_target_properties(usdt_trace PROPERTIES COMPILE_FLAGS ${usdt_cflags})

    set(LIBUSDT_LIBRARIES usdt)

    set(usdt_objs_dir ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/usdt_objs.dir/third_party/libusdt)

    message(STATUS "Use bundled libusdt includes: ${LIBUSDT_INCLUDE_DIR}/usdt.h")
    message(STATUS "Use bundled libusdt library: ${LIBUSDT_LIBRARIES}")


    set(usdt_obj
        $<TARGET_OBJECTS:usdt_objs>
        $<TARGET_OBJECTS:lua_usdt_objs>
        $<TARGET_OBJECTS:usdt_trace>
    )

    add_library(usdt STATIC ${usdt_obj})

    unset(usdt_objs_dir)
    unset(usdt_objs)
    unset(lua_usdt_objs)
    unset(usdt_obj)
    unset(usdt_src)
    unset(usdt_cflags)
    unset(usdt_trace_arch)
    unset(usdt_src_lua)
    unset(usdt_src_dir)
endmacro(libusdt_build)

