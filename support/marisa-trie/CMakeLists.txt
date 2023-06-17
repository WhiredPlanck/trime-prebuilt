cmake_minimum_required(VERSION 3.5)
set (PACKAGE_NAME marisa-trie)
project (${PACKAGE_NAME} CXX)

include(GNUInstallDirs)

set(
  LIBMARISA_SOURCES
  lib/marisa/trie.cc
  lib/marisa/agent.cc
  lib/marisa/grimoire/io/reader.cc
  lib/marisa/grimoire/io/writer.cc
  lib/marisa/grimoire/io/mapper.cc
  lib/marisa/grimoire/trie/louds-trie.cc
  lib/marisa/grimoire/trie/tail.cc
  lib/marisa/grimoire/vector/bit-vector.cc
  lib/marisa/keyset.cc
)

add_library(marisa STATIC ${LIBMARISA_SOURCES})
target_include_directories(marisa
  PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  PRIVATE
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/lib>)
set_target_properties(marisa PROPERTIES POSITION_INDEPENDENT_CODE ON)
source_group(marisa FILES ${LIBMARISA_SOURCES})
install(TARGETS marisa
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  FILES_MATCHING PATTERN "*.h"
)
