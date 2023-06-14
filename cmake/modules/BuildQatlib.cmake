function(build_qatlib)
  include(FindMake)
  find_make("MAKE_EXECUTABLE" "make_cmd")

  set(source_dir_args
    SOURCE_DIR ${CMAKE_BINARY_DIR}/src/qatlib
    GIT_REPOSITORY https://github.com/intel/qatlib.git
    GIT_TAG "23.02.0"
    GIT_SHALLOW TRUE
    GIT_CONFIG advice.detachedHead=false)

  set(qatlib_cflags "-fPIC")
  set(install_cmd ${make_cmd} install)
  set(configure_cmd0 "./autogen.sh")
  if(WITH_QATLIB_inContainer)
    set(configure_cmd1 ./configure --enable-systemd=no)
  else()
    set(configure_cmd1 ./configure --enable-service)
  endif()

  include(ExternalProject)
  ExternalProject_Add(qatlib_ext
      ${source_dir_args}
      CONFIGURE_COMMAND  ${configure_cmd0} COMMAND ${configure_cmd1}
      BUILD_COMMAND ${make_cmd} CC=${CMAKE_C_COMPILER} EXTRA_CFLAGS=${qatlib_cflags}
      BUILD_IN_SOURCE 1
      BUILD_BYPRODUCTS "<SOURCE_DIR>/.libs/libqat.so" "<SOURCE_DIR>/.libs/libusdm.so"
      INSTALL_COMMAND ${install_cmd})
  unset(make_cmd)

  ExternalProject_Get_Property(qatlib_ext source_dir)
  set(Qatlib_INCLUDE_DIRS
      ${source_dir}/quickassist/include
      ${source_dir}/quickassist/include/dc
      ${source_dir}/quickassist/lookaside/access_layer/include
      ${source_dir}/quickassist/include/lac
      ${source_dir}/quickassist/utilities/libusdm_drv
      ${source_dir}/quickassist/utilities/libusdm_drv/include)
  set(Qatlib_LIB ${source_dir}/.libs)

  add_library(Qatlib::qat SHARED IMPORTED GLOBAL)
  add_dependencies(Qatlib::qat qatlib_ext)
  file(MAKE_DIRECTORY ${Qatlib_INCLUDE_DIRS})
  set_target_properties(Qatlib::qat PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${Qatlib_INCLUDE_DIRS}"
    IMPORTED_LINK_INTERFACE_LANGUAGES "C"
    IMPORTED_LOCATION "${Qatlib_LIB}/libqat.a")

  add_library(Qatlib::usdm SHARED IMPORTED GLOBAL)
  add_dependencies(Qatlib::usdm qatlib_ext)
  set_target_properties(Qatlib::usdm PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${Qatlib_INCLUDE_DIRS}"
    IMPORTED_LINK_INTERFACE_LANGUAGES "C"
    IMPORTED_LOCATION "${Qatlib_LIB}/libusdm.so")

  unset(source_dir)
endfunction()
