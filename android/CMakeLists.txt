cmake_minimum_required(VERSION 3.4.1)

set (CMAKE_VERBOSE_MAKEFILE ON)
set (CMAKE_CXX_STANDARD 11)

include_directories(
  ../cpp
  ../module
  ../node_modules/react-native/React
  ../node_modules/react-native/React/Base
  ../node_modules/react-native/ReactCommon/jsi
)

add_library(example
  SHARED
  cpp-adapter.cpp
  ../cpp/example.cpp
  ../cpp/example.h
  ../module/wasm-lib.c
  ../module/wasm-lib.h
  ../module/wasm-rt-impl.c
  ../module/wasm-rt-impl.h
  ../module/wasm-rt.h
  ../node_modules/react-native/ReactCommon/jsi/jsi/jsi.cpp
)

target_link_libraries(example)
