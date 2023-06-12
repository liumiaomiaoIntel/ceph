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
      #BUILD_BYPRODUCTS "<SOURCE_DIR>/src/build/libqat.a" "<SOURCE_DIR>/src/build/lib.a"
      INSTALL_COMMAND ${install_cmd})
  unset(make_cmd)

  find_path(Qatlib_INCLUDE_DIR NAMES qat/cpa.h)

  set(Qatlib_Library_Components qat usdm)
  foreach(component ${Qatlib_Library_Components})
    find_library(Qatlib_${component}_LIBRARIES
                NAMES ${component}
                HINTS /usr/local/lib/)
    mark_as_advanced(Qatlib_INCLUDE_DIR
      Qatlib_${component}_LIBRARIES)
    list(APPEND Qatlib_LIBRARIES "${Qatlib_${component}_LIBRARIES}")  
  endforeach()

  set(failure_message  "Failed to install qatlib. Please check your System Prerequisites according to the link https://github.com/intel/qatlib.git ")

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Qatlib
    REQUIRED_VARS Qatlib_LIBRARIES Qatlib_INCLUDE_DIR
    FAIL_MESSAGE ${failure_message})

  foreach(component ${Qatlib_Library_Components})
    if(NOT TARGET Qatlib::${component})
      add_library(Qatlib::${component} STATIC IMPORTED GLOBAL)
      set_target_properties(Qatlib::${component} PROPERTIES
                            INTERFACE_INCLUDE_DIRECTORIES "${Qatlib_INCLUDE_DIR}"
                            IMPORTED_LINK_INTERFACE_LANGUAGES "C"
                            IMPORTED_LOCATION "${Qatlib_${component}_LIBRARIES}")
    endif()
  endforeach()
endfunction()
