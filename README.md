[![Build Status](https://travis-ci.org/makigumo/MIPSCPU.svg?branch=master)](https://travis-ci.org/makigumo/MIPSCPU)

# MIPS CPU plugin for Hopper Disassembler

This is an experimental, unsophisticated plugin prototype using a custom disassembler and the [capstone](https://github.com/aquynh/capstone) (http://www.capstone-engine.org/) engine for the MIPS architecture (currently 32 bit EL only) whose main purpose is to provide a play and learning ground for the Hopper plugin system and the MIPS architecture and some assembly language in general.

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

Install [GNUstep](https://github.com/gnustep/base), [libobjc2](https://github.com/gnustep/libobjc2) and [libdispatch](https://github.com/nickhutchinson/libdispatch), e.g. by using the script in https://github.com/ckuethe/HopperSDK-Linux.
Then adjust your `PATH` to include `~/GNUstep/Library/ApplicationSupport/Hopper/gnustep-x86_64/bin/`.

## Status

* Disassembly should mostly work (with mnemonic and operand formatting)
    * support for MIPS32 (releases 1 to 6)
* Branch typing is incomplete (still need to figure out the different `DISASM_BRANCH_*` types)
* NOPping should work

## TODO

* [ ] Big endian support
* [ ] Extend instruction analysis for Hopper to do its magic
* [ ] Handle branch delay slots
* [ ] Disassemble into pseudo instructions (ideally as a second syntax option)
    * Find a way to make syntax variant work
* [ ] Add support for assembling instructions (using keystone)
* [ ] Support for EB (big endian), 64 bit
* [ ] Find ways to utilize some of `performBranchesAnalysis:`, `performInstructionSpecificAnalysis:`, `performProcedureAnalysis:`, `hasProcedurePrologAt:` etc.
* [ ] Use compact capstone engine for smaller footprint

## Resources

* https://imgtec.com/documentation/
