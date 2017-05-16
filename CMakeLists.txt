cmake_minimum_required(VERSION 3.0)

set(PRODUCT_NAME MIPSCPU)
project(${PRODUCT_NAME})

set(HOPPER_SDK_PATH ${CMAKE_SOURCE_DIR}/HopperSDK/include)
set(HOPPER_PLUGINS_PATH "~/Library/Application Support/Hopper/Plugins/V4")
set(HOPPER_PLUGIN_CPU_DIRNAME CPUs)
set(HOPPER_PLUGIN_CPU_EXTENSION hopperCPU)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)
set(CMAKE_INSTALL_PREFIX ${HOPPER_PLUGINS_PATH} CACHE PATH "Plugins install prefix" FORCE)

add_definitions(
#    -std=c++11
#    -fno-rtti
)

include_directories("${HOPPER_SDK_PATH}" "${CMAKE_SOURCE_DIR}" capstone/include)

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
    -fobjc-arc
)

set_target_properties(
    ${PRODUCT_NAME} PROPERTIES
    BUNDLE TRUE
    BUNDLE_EXTENSION ${HOPPER_PLUGIN_CPU_EXTENSION}
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in
)

target_link_libraries(${PRODUCT_NAME} "-framework Foundation" capstone)

install(
    TARGETS ${PRODUCT_NAME}
    LIBRARY DESTINATION ${HOPPER_PLUGIN_CPU_DIRNAME}
)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)

