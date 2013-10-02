macro(libusdt_build)
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

    #set_target_properties(usdt_objs PROPERTIES COMPILE_FLAGS "-g -O0 -Wall -Werror -arch i386 -arch x86_64")
    set_target_properties(usdt_objs PROPERTIES COMPILE_FLAGS "-arch i386 -arch x86_64")

    set(LIBUSDT_LIBRARIES usdt)

    set(usdt_objs_dir ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/usdt_objs.dir/third_party/libusdt)

    message(STATUS "Use bundled libusdt includes: ${LIBUSDT_INCLUDE_DIR}/usdt.h")
    message(STATUS "Use bundled libusdt library: ${LIBUSDT_LIBRARIES}")

    add_custom_command(OUTPUT ${usdt_objs_dir}/usdt_tracepoints.o
        COMMAND as -arch i386 -o ${usdt_objs_dir}/usdt_tracepoints_i386.o
            ${usdt_src_dir}/usdt_tracepoints_i386.s
        COMMAND as -arch x86_64 -o ${usdt_objs_dir}/usdt_tracepoints_x86_64.o
            ${usdt_src_dir}/usdt_tracepoints_x86_64.s
        COMMAND lipo -create -output ${usdt_objs_dir}/usdt_tracepoints.o
            ${usdt_objs_dir}/usdt_tracepoints_i386.o
            ${usdt_objs_dir}/usdt_tracepoints_x86_64.o
        DEPENDS ${usdt_objs_dir}/usdt.c.o
    )


    set(usdt_obj
        $<TARGET_OBJECTS:usdt_objs>
        $<TARGET_OBJECTS:lua_usdt_objs>
        ${usdt_objs_dir}/usdt_tracepoints.o
    )

    add_library(usdt STATIC ${usdt_obj})

    unset(usdt_objs_dir)
    unset(usdt_objs)
    unset(lua_usdt_objs)
    unset(usdt_obj)
    unset(usdt_src)
    unset(usdt_src_lua)
    unset(usdt_src_dir)
endmacro(libusdt_build)

