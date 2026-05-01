cmake_minimum_required(VERSION 3.16.0)
project(dharmanet_severity C)

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/LogRing)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/WorkerA)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/WorkerB)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/DharmaNet)

DeclareCAmkESRootserver(dharmanet_severity.camkes)
