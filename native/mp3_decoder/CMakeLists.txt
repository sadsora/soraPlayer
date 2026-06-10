cmake_minimum_required(VERSION 3.10)
project(mp3_decoder C)
add_library(mp3_decoder SHARED mp3_decoder.c)
if(WIN32)
  add_custom_command(TARGET mp3_decoder POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "$<TARGET_FILE:mp3_decoder>"
      "$<TARGET_FILE_DIR:soraplayer02>"
    COMMENT "Copying mp3_decoder.dll to executable directory"
  )
endif()