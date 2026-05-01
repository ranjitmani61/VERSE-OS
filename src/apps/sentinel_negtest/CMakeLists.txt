cmake_minimum_required(VERSION 3.16.0)
project(sentinel_negtest C)

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/Sentinel)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/Hello)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/PublicClient)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/SecretClient)

DeclareCAmkESRootserver(sentinel_negtest.camkes)
