cmake_minimum_required(VERSION 3.10)
project(flac_decoder C)
add_library(flac_decoder SHARED flac_decoder.c)
if(WIN32)
  add_custom_command(TARGET flac_decoder POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "$<TARGET_FILE:flac_decoder>"
      "$<TARGET_FILE_DIR:soraplayer>"
    COMMENT "Copying flac_decoder.dll to executable directory"
  )
endif()
