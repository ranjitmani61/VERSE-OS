cmake_minimum_required(VERSION 3.16.0)
project(codexfs_demo C)

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/LogRing)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/CodexFS)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/WriteClient)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/ReadClient)

DeclareCAmkESRootserver(codexfs_demo.camkes)
