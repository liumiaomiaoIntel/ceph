function(build_qatzip)
  if(NOT TARGET qatlib_ext)
    include(BuildQatlib)
    build_qatlib()
  endif()
  include(FindMake)
  find_make("MAKE_EXECUTABLE" "make_cmd")

  set(source_dir_args
    SOURCE_DIR ${CMAKE_BINARY_DIR}/src/qatzip
    GIT_REPOSITORY https://github.com/intel/QATzip.git
    GIT_TAG "v1.1.2"
    GIT_SHALLOW TRUE
    GIT_CONFIG advice.detachedHead=false)

  set(install_cmd ${make_cmd} install)
  set(configure_cmd0 "./autogen.sh")
  if(WITH_QATLIB OR WITH_QATLIB_inContainer)
    set(configure_cmd1 ./configure)
  elseif(WITH_QAT)
    set(configure_cmd1 ./configure --with-ICP_ROOT=$ENV{ICP_ROOT})
  endif()

  include(ExternalProject)
  ExternalProject_Add(qatzip_ext
      ${source_dir_args}
      DEPENDS qatlib_ext
      CONFIGURE_COMMAND  ${configure_cmd0} COMMAND ${configure_cmd1}
      BUILD_COMMAND ${make_cmd} "CFLAGS=${CMAKE_C_FLAGS} -fPIC" CC=${CMAKE_C_COMPILER}
      BUILD_IN_SOURCE 1
      BUILD_BYPRODUCTS "<SOURCE_DIR>/src/.libs/libqatzip.so"
      INSTALL_COMMAND ${install_cmd})
  unset(make_cmd)

  ExternalProject_Get_Property(qatzip_ext source_dir)
  set(qatzip_INCLUDE_DIR ${source_dir}/include)
  set(qatzip_LIBRARIES ${source_dir}/src/.libs)

  add_library(qatzip::qatzip SHARED IMPORTED)
  add_dependencies(qatzip::qatzip qatzip_ext)
  file(MAKE_DIRECTORY ${qatzip_INCLUDE_DIR})
  set_target_properties(qatzip::qatzip PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${qatzip_INCLUDE_DIR}"
    IMPORTED_LINK_INTERFACE_LANGUAGES "C"
    IMPORTED_LOCATION "${qatzip_LIBRARIES}/libqatzip.so")
    
  unset(source_dir)
endfunction()
