cmake_minimum_required(VERSION 3.16.0)
project(cortexmm_demo C)

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/LogRing)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/CortexMM)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/MemClient)

DeclareCAmkESRootserver(cortexmm_demo.camkes)
