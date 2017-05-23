cmake_minimum_required(VERSION 3.0)

if(UNIX)
    set(CMAKE_C_COMPILER "clang")
    set(CMAKE_CXX_COMPILER "clang++")
endif(UNIX)

set(PRODUCT_NAME MIPSCPU)
project(${PRODUCT_NAME})

set(HOPPER_SDK_PATH ${CMAKE_SOURCE_DIR}/HopperSDK/include)
if(APPLE)
    set(HOPPER_PLUGINS_PATH "~/Library/Application Support/Hopper/Plugins/V4")
else(UNIX)
    set(HOPPER_PLUGINS_PATH "~/GNUstep/Library/ApplicationSupport/Hopper/PlugIns/v4")
endif(APPLE)
set(HOPPER_PLUGIN_CPU_DIRNAME CPUs)
set(HOPPER_PLUGIN_CPU_EXTENSION hopperCPU)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)
set(CMAKE_INSTALL_PREFIX ${HOPPER_PLUGINS_PATH} CACHE PATH "Plugins install prefix" FORCE)

add_definitions(
    -std=c11
)

include_directories("${HOPPER_SDK_PATH}" "${CMAKE_SOURCE_DIR}" capstone/include)

if(NOT APPLE)
    if (NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
       message(FATAL_ERROR "Clang required!")
    endif(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    find_program(GNUSTEP gnustep-config)
    if(NOT GNUSTEP)
        message(FATAL_ERROR "gnustep-config not found!")
    endif(NOT GNUSTEP)

    execute_process(COMMAND ${GNUSTEP} --objc-flags
        OUTPUT_VARIABLE GNUSTEP_FLAGS
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    separate_arguments(GNUSTEP_FLAGS UNIX_COMMAND ${GNUSTEP_FLAGS})

    execute_process(COMMAND ${GNUSTEP} --base-libs
        OUTPUT_VARIABLE GNUSTEP_LIBS
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(GNUSTEP_LIBS "${GNUSTEP_LIBS}")
endif(NOT APPLE)

add_library(
    capstone
    capstone/cs.c
    capstone/MCInst.c
    capstone/MCInstrDesc.c
    capstone/MCRegisterInfo.c
    capstone/SStream.c
    capstone/utils.c
    capstone/arch/Mips/MipsModule.c
    capstone/arch/Mips/MipsDisassembler.c
    capstone/arch/Mips/MipsMapping.c
    capstone/arch/Mips/MipsInstPrinter.c
)

add_definitions(-DCAPSTONE_USE_SYS_DYN_MEM)
add_definitions(-DCAPSTONE_HAS_MIPS)

SET_TARGET_PROPERTIES(
    capstone PROPERTIES
    COMPILE_FLAGS "-fPIC")

add_library(
    ${PRODUCT_NAME} MODULE
    MIPSCPU/MIPSCPU.m
    MIPSCPU/MIPSCtx.m
    MIPSCPU/MIPSCSCtx.m
)

target_compile_options(
    ${PRODUCT_NAME} PUBLIC
    -fno-exceptions
    -pedantic
    -Wall
    -Wextra
    -fPIC
    -fobjc-arc
    -fobjc-nonfragile-abi
    -fblocks
    ${GNUSTEP_FLAGS}
)

if(APPLE)
    set_target_properties(
        ${PRODUCT_NAME} PROPERTIES
        BUNDLE TRUE
        BUNDLE_EXTENSION ${HOPPER_PLUGIN_CPU_EXTENSION}
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in)

    target_link_libraries(${PRODUCT_NAME} "-framework Foundation" capstone)

    install(
        TARGETS ${PRODUCT_NAME}
        LIBRARY DESTINATION ${HOPPER_PLUGIN_CPU_DIRNAME}
    )

else(UNIX)
    set_target_properties(
        ${PRODUCT_NAME} PROPERTIES
        PREFIX ""
        SUFFIX "")

    target_link_libraries(${PRODUCT_NAME} ${GNUSTEP_LIBS} capstone)

    install(
        TARGETS ${PRODUCT_NAME}
        LIBRARY DESTINATION "${HOPPER_PLUGIN_CPU_DIRNAME}/${PRODUCT_NAME}.${HOPPER_PLUGIN_CPU_EXTENSION}"
    )
    install(
        DIRECTORY Resources
        DESTINATION "${HOPPER_PLUGIN_CPU_DIRNAME}/${PRODUCT_NAME}.${HOPPER_PLUGIN_CPU_EXTENSION}"
    )

endif(APPLE)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)

