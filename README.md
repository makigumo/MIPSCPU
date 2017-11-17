[![Build Status](https://travis-ci.org/makigumo/MIPSCPU.svg?branch=master)](https://travis-ci.org/makigumo/MIPSCPU)

# MIPS CPU plugin for Hopper Disassembler

This is an experimental, unsophisticated plugin prototype using a custom disassembler and the [capstone](https://github.com/aquynh/capstone) (http://www.capstone-engine.org/) engine for the MIPS architecture whose main purpose is to provide a play and learning ground for the Hopper plugin system and the MIPS architecture and some assembly language in general.

There are currently two disassembler engines:
* capstone based engine for MIPS32
* custom engine for MIPS I, II, III, IV and MIPS32/MIPS64

## Requirements

* Hopper Disassembler v4+ (https://www.hopperapp.com/)
* capstone (git `next` branch)

## Building

* build with Xcode
* or, via `xcodebuild`
* or, using *cmake*
    ```
    mkdir build
    cd build
    cmake ..
    make
    make install
    ```
### Linux

The Linux build requires the compilation of the Hopper SDK.
Please also refer the official [SDK Documentation](https://github.com/makigumo/HopperSDK-v4/blob/master/SDK%20Documentation.pdf). 

#### Compile SDK

* download and extract the Hopper SDK from https://hopperapp.com
    ```
    mkdir HopperSDK
    cd HopperSDK
    unzip HopperSDK-*.zip # your downloaded SDK file
    ```
* build the SDK
    ```
    cd Linux
    ./install.sh
    ```
* add the newly created bin-path to your `PATH`
    ```
    export PATH="$PATH":gnustep-Linux-x86_64/bin/
    ```

#### Build plugin

* follow the instructions for building with *cmake*
* or, run
    ```
    ./build.sh
    ```

### Linux (Docker)

A docker image with a precompiled Hopper SDK for Linux is also available, just run

```
./docker/linux-build.sh
```

## Status

- [x] Little and big endianess
- [x] MIPS I
- [x] MIPS II
- [x] MIPS III
- [x] MIPS IV
- [x] MIPS32 (release 1)
- [x] MIPS32 release 2
- [x] MIPS32 release 5
- [x] MIPS32 release 6
- [x] MIPS64 (release 1)
- [x] MIPS64 release 2
- [x] MIPS64 release 3
- [x] MIPS64 release 5
- [x] MIPS64 release 6
* Branch typing is incomplete (still need to figure out the different `DISASM_BRANCH_*` types)
* NOPping should work

## TODO

* [ ] Extend instruction analysis for Hopper to do its magic
* [ ] Handle branch delay slots
* [ ] Disassemble into pseudo instructions (ideally as a second syntax option)
    * Find a way to make syntax variant work
* [ ] Add support for assembling instructions (using keystone)
* [ ] Find ways to utilize some of `performBranchesAnalysis:`, `performInstructionSpecificAnalysis:`, `performProcedureAnalysis:`, `hasProcedurePrologAt:` etc.

## Resources

* https://www.mips.com/downloads/
