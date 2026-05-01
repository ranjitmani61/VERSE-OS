cmake_minimum_required(VERSION 3.16.0)
project(watchdog_tcb C)

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/Watchdog)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/TestWorker)

DeclareCAmkESRootserver(watchdog_tcb.camkes)
