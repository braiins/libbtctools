cmake_minimum_required (VERSION 3.4)

project (libbtctools)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

###################################### Options ######################################
message("") # empty line
message("------------------------------- Options -------------------------------")

#
# Build Type: -DCMAKE_BUILD_TYPE=Debug|Release
# Default: Release
#
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()
message("-- Build Type: ${CMAKE_BUILD_TYPE} (-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE})")

#
# Library Type: -DBTCTOOLS__LIB_TYPE=STATIC|SHARED
# Default: STATIC
#
if(BTCTOOLS__LIB_TYPE MATCHES SHARED)
  set(BTCTOOLS__LIB_TYPE SHARED)
else()
  set(BTCTOOLS__LIB_TYPE STATIC)
endif()
message("-- Library Type: ${BTCTOOLS__LIB_TYPE} (-DBTCTOOLS__LIB_TYPE=STATIC|SHARED)")

#
# Lua Engine Type: luajit-2.0 or normal lua-5.1
# Default: use luajit-2.0
#
if(BTCTOOLS__LUA_TYPE MATCHES NORMAL)
  set(BTCTOOLS__LUA_TYPE NORMAL)
else()
  set(BTCTOOLS__LUA_TYPE JIT)
endif()
message("-- Lua Engine Type: ${BTCTOOLS__LUA_TYPE} (-DBTCTOOLS__LUA_TYPE=JIT|NORMAL)")


# set build options (msvc not required)
if(NOT WIN32)
  IF(CMAKE_BUILD_TYPE MATCHES Debug)
    set(CMAKE_CXX_FLAGS "-g -O0")
  ELSEIF(CMAKE_BUILD_TYPE MATCHES Release)
    set(CMAKE_CXX_FLAGS "-O2")
  ENDIF()
endif()

# enable C++11 (msvc not required)
if(NOT WIN32)
  set(CMAKE_CXX_COMPILER_ARG1 "-std=c++0x")
endif()

###################### Windows Only Options ######################
if(WIN32)

  ###
  # static linking VC++ runtime library
  ###
  option(BTCTOOLS__STATIC_LINKING_VC_LIB
    "Static linking VC++ runtime library (/MT)" OFF)

  macro(set_linking_vclib CompilerFlag LinkFlag)
    string(REPLACE "/MDd" "" ${CompilerFlag} "${${CompilerFlag}}")
    string(REPLACE "/MD" "" ${CompilerFlag} "${${CompilerFlag}}")
    string(REPLACE "/MTd" "" ${CompilerFlag} "${${CompilerFlag}}")
    string(REPLACE "/MT" "" ${CompilerFlag} "${${CompilerFlag}}")
    set(${CompilerFlag} "${${CompilerFlag}} ${LinkFlag}")
    message("${CompilerFlag}=${${CompilerFlag}}")
  endmacro()

  if(BTCTOOLS__STATIC_LINKING_VC_LIB)
    message("-- Static linking VC++ runtime library (/MT): -DBTCTOOLS__STATIC_LINKING_VC_LIB=ON")

    set_linking_vclib(CMAKE_CXX_FLAGS_DEBUG          "/MTd")
    set_linking_vclib(CMAKE_C_FLAGS_DEBUG            "/MTd")
    set_linking_vclib(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MTd")
    set_linking_vclib(CMAKE_C_FLAGS_RELWITHDEBINFO   "/MTd")
    set_linking_vclib(CMAKE_CXX_FLAGS_RELEASE        "/MT")
    set_linking_vclib(CMAKE_C_FLAGS_RELEASE          "/MT")
    set_linking_vclib(CMAKE_CXX_FLAGS_MINSIZEREL     "/MT")
    set_linking_vclib(CMAKE_C_FLAGS_MINSIZEREL       "/MT")

  else()
    message("-- Dynamic linking VC++ runtime library (/MD): -DBTCTOOLS__STATIC_LINKING_VC_LIB=OFF")

    set_linking_vclib(CMAKE_CXX_FLAGS_DEBUG          "/MDd")
    set_linking_vclib(CMAKE_C_FLAGS_DEBUG            "/MDd")
    set_linking_vclib(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MDd")
    set_linking_vclib(CMAKE_C_FLAGS_RELWITHDEBINFO   "/MDd")
    set_linking_vclib(CMAKE_CXX_FLAGS_RELEASE        "/MD")
    set_linking_vclib(CMAKE_C_FLAGS_RELEASE          "/MD")
    set_linking_vclib(CMAKE_CXX_FLAGS_MINSIZEREL     "/MD")
    set_linking_vclib(CMAKE_C_FLAGS_MINSIZEREL       "/MD")
  endif()

  ###
  # define NT version
  ###
  message("-- define NT version: -D_WIN32_WINNT=0x0501")
  add_definitions(-D_WIN32_WINNT=0x0501)

  ###
  # disable IOCP
  ###
  #add_definitions(-DBOOST_ASIO_DISABLE_IOCP)

  ###
  # disable SAFESEH
  ###
  message("-- disable SAFESEH")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SAFESEH:NO")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /SAFESEH:NO")
  message("CMAKE_EXE_LINKER_FLAGS=${CMAKE_EXE_LINKER_FLAGS}")
  message("CMAKE_SHARED_LINKER_FLAGS=${CMAKE_SHARED_LINKER_FLAGS}")

  # avoid errors when include Windows.h
  add_definitions(-DWIN32_LEAN_AND_MEAN)

  # export all symbols when genrate a DLL.
  if(BTCTOOLS__LIB_TYPE MATCHES SHARED)
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
  endif()

endif()
###################### End of Windows Only Options ######################


###################################### Libs ######################################
message("") # empty line
message("------------------------------- Libs -------------------------------")

find_package(Boost 1.59 COMPONENTS regex system context)
if(NOT Boost_FOUND)
  message(FATAL_ERROR "Boost 1.59 or later not found!")
else()
  message("-- Boost_INCLUDE_DIRS: ${Boost_INCLUDE_DIRS}")
  message("-- Boost_LIBRARIES: ${Boost_LIBRARIES}")
endif()

find_package(OpenSSL)
if(NOT OPENSSL_FOUND)
  message(FATAL_ERROR "OpenSSL not found!")
else()
  message("-- OPENSSL_INCLUDE_DIR: ${OPENSSL_INCLUDE_DIR}")
  message("-- OPENSSL_CRYPTO_LIBRARY: ${OPENSSL_CRYPTO_LIBRARY}")
  message("-- OPENSSL_SSL_LIBRARY: ${OPENSSL_SSL_LIBRARY}")
endif()

if(BTCTOOLS__LUA_TYPE MATCHES JIT)
  find_package(LuaJIT)
  if(NOT LUAJIT_FOUND)
    message(FATAL_ERROR "LuaJIT not found!")
  else()
    message("-- LUA_INCLUDE_DIR: ${LUA_INCLUDE_DIR}")
    message("-- LUA_LIBRARIES: ${LUA_LIBRARIES}")
  endif()
else()
  find_package(Lua51)
  if(NOT LUA51_FOUND)
    message(FATAL_ERROR "Lua-5.1 not found!")
  else()
    message("-- LUA_INCLUDE_DIR: ${LUA_INCLUDE_DIR}")
    message("-- LUA_LIBRARIES: ${LUA_LIBRARIES}")
  endif()
endif()

find_package(CryptoPP)
if(NOT CRYPTOPP_FOUND)
  message(FATAL_ERROR "Crypto++ not found!")
else()
  message("-- CRYPTOPP_INCLUDE_DIRS: ${CRYPTOPP_INCLUDE_DIRS}")
  message("-- CRYPTOPP_LIBRARIES: ${CRYPTOPP_LIBRARIES}")
endif()

if (WIN32)
  set(PTHREAD_INCLUDE_DIR "")
  set(PTHREAD_LIBRARIES ws2_32)
else()
  find_package(LibPthread)
  if(NOT PTHREAD_FOUND)
    message(FATAL_ERROR "libpthread not found!")
  else()
    message("-- PTHREAD_INCLUDE_DIR: ${PTHREAD_INCLUDE_DIR}")
    message("-- PTHREAD_LIBRARIES: ${PTHREAD_LIBRARIES}")
  endif()
endif()

# include dir for targets
include_directories(src ${Boost_INCLUDE_DIRS} ${OPENSSL_INCLUDE_DIR}
                        ${LUA_INCLUDE_DIR} ${CRYPTOPP_INCLUDE_DIRS} ${PTHREAD_INCLUDE_DIR})

set(THIRD_LIBRARIES ${Boost_LIBRARIES} ${OPENSSL_CRYPTO_LIBRARY} ${OPENSSL_SSL_LIBRARY}
                      ${LUA_LIBRARIES} ${CRYPTOPP_LIBRARIES} ${PTHREAD_LIBRARIES})
if(WIN32)
  set(THIRD_LIBRARIES ${THIRD_LIBRARIES} crypt32)
endif()


###################################### Targets ######################################

###
# build: libbtctools
###
file(GLOB_RECURSE LIB_SOURCES src/*.h src/*.hpp src/*.cpp src/*.lua)
source_group(TREE ${CMAKE_SOURCE_DIR} FILES ${LIB_SOURCES})

if(BTCTOOLS__LIB_TYPE MATCHES SHARED)
  add_library(btctools SHARED ${LIB_SOURCES})
  target_link_libraries(btctools ${THIRD_LIBRARIES})
else()
  add_library(btctools STATIC ${LIB_SOURCES})
endif()

###
# librarys for targets
###
set(TARGET_LIBRARIES btctools ${THIRD_LIBRARIES})


###################### demos ######################

# scanMinerDemo
add_executable(scanMinerDemo demo/scanMinerDemo.cpp)
target_link_libraries(scanMinerDemo ${TARGET_LIBRARIES})

# configMinerDemo
add_executable(configMinerDemo demo/configMinerDemo.cpp)
target_link_libraries(configMinerDemo ${TARGET_LIBRARIES})

# rebootMinerDemo
add_executable(rebootMinerDemo demo/rebootMinerDemo.cpp)
target_link_libraries(rebootMinerDemo ${TARGET_LIBRARIES})

# upgradeMinerDemo
add_executable(upgradeMinerDemo demo/upgradeMinerDemo.cpp)
target_link_libraries(upgradeMinerDemo ${TARGET_LIBRARIES})

# tcpClientHttpDemo
add_executable(tcpClientHttpDemo demo/tcpClientHttpDemo.cpp)
target_link_libraries(tcpClientHttpDemo ${TARGET_LIBRARIES})

# tcpClientScanDemo
add_executable(tcpClientScanDemo demo/tcpClientScanDemo.cpp)
target_link_libraries(tcpClientScanDemo ${TARGET_LIBRARIES})

# ipGeneratorDemo
add_executable(ipGeneratorDemo demo/ipGeneratorDemo.cpp)
target_link_libraries(ipGeneratorDemo ${TARGET_LIBRARIES})

# cryptoRSADemo
add_executable(cryptoRSADemo demo/cryptoRSADemo.cpp)
target_link_libraries(cryptoRSADemo ${TARGET_LIBRARIES})

###################### toolkits ######################

# make-rsa-keys
add_executable(make-rsa-keys toolkits/make-rsa-keys.cpp)
target_link_libraries(make-rsa-keys ${TARGET_LIBRARIES})

# rsatools
add_executable(rsatools toolkits/rsatools.cpp)
target_link_libraries(rsatools ${TARGET_LIBRARIES})


###################################### Installtion ######################################

install(DIRECTORY src/ DESTINATION include/btctools FILES_MATCHING PATTERN "*.h")
install(DIRECTORY src/ DESTINATION include/btctools FILES_MATCHING PATTERN "*.hpp")
install(DIRECTORY src/lua/scripts DESTINATION share/btctools/lua)

install(TARGETS btctools DESTINATION lib)

install(TARGETS
          scanMinerDemo
          configMinerDemo
          rebootMinerDemo
          upgradeMinerDemo
          tcpClientHttpDemo
          tcpClientScanDemo
          ipGeneratorDemo
          cryptoRSADemo
          make-rsa-keys
          rsatools
        DESTINATION
          bin/btctools)

# demo need these scripts to run
install(DIRECTORY src/lua/scripts DESTINATION bin/btctools/lua)
