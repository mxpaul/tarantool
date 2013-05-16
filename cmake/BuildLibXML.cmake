option(ENABLE_LIBXML "Integrate tarantool with LibXML" OFF)

if (ENABLE_LIBXML)

	find_package(PkgConfig)
	pkg_check_modules(PC_LIBXML QUIET libxml-2.0)
	set(LIBXML2_DEFINITIONS ${PC_LIBXML_CFLAGS_OTHER})
	find_path(LIBXML2_INCLUDE_DIR libxml/xpath.h
		HINTS ${PC_LIBXML_INCLUDEDIR} ${PC_LIBXML_INCLUDE_DIRS}
		PATH_SUFFIXES libxml2 )
	find_library(LIBXML2_LIBRARY NAMES xml2 libxml2
		HINTS ${PC_LIBXML_LIBDIR} ${PC_LIBXML_LIBRARY_DIRS} )

	set(LIBXML2_LIBRARIES ${LIBXML2_LIBRARY} )
	set(LIBXML2_INCLUDE_DIRS ${LIBXML2_INCLUDE_DIR} )

	message(STATUS "LibXML includes: ${LIBXML2_INCLUDE_DIRS}")
	message(STATUS "LibXML library: ${LIBXML2_LIBRARIES}")


	add_compile_flags("C;CXX" "-I${LIBXML2_INCLUDE_DIRS}" "-DENABLE_LIBXML")
	set (common_libraries ${common_libraries} xml2)

endif()
