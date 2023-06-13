function(build_qatlib)
  include(FindMake)
  find_make("MAKE_EXECUTABLE" "make_cmd")

  set(source_dir_args
    SOURCE_DIR ${CMAKE_BINARY_DIR}/src/qatlib
    GIT_REPOSITORY https://github.com/intel/qatlib.git
    GIT_TAG "23.02.0"
    GIT_SHALLOW TRUE
    GIT_CONFIG advice.detachedHead=false)

  set(qatlib_cflags "-Wno-error -fno-lto")
  set(install_cmd $(MAKE) install)
  if(WITH_QATLIB_inContainer)
    set(configure_cmd "./autogen.sh && ./configure --enable-systemd=no")
  else()
    set(configure_cmd "./autogen.sh && ./configure --enable-service")
  endif()

  include(ExternalProject)
  ExternalProject_Add(qatlib_ext
      ${source_dir_args}
      CONFIGURE_COMMAND  ${configure_cmd}
      BUILD_COMMAND ${make_cmd}
      BUILD_IN_SOURCE 1
      BUILD_BYPRODUCTS "<SOURCE_DIR>/.lib/libqat.a" "<SOURCE_DIR>/.lib/libusdm.a"
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
  set(Qatlib_LIB ${source_dir}/.lib)

  add_library(Qatlib::qat STATIC IMPORTED GLOBAL)
  add_dependencies(Qatlib::qat qatlib_ext)
  #file(MAKE_DIRECTORY ${Qatlib_INCLUDE_DIRS})
  set_target_properties(Qatlib::qat PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${Qatlib_INCLUDE_DIRS}"
    IMPORTED_LINK_INTERFACE_LANGUAGES "C"
    IMPORTED_LOCATION "${Qatlib_LIB}/libqat.a")

  add_library(Qatlib::usdm STATIC IMPORTED GLOBAL)
  add_dependencies(Qatlib::usdm qatlib_ext)
  set_target_properties(Qatlib::usdm PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${Qatlib_INCLUDE_DIRS}"
    IMPORTED_LINK_INTERFACE_LANGUAGES "C"
    IMPORTED_LOCATION "${Qatlib_LIB}/libusdm.a")

  unset(source_dir)
endfunction()
