[![Build Status](https://travis-ci.org/makigumo/MIPSCPU.svg?branch=master)](https://travis-ci.org/makigumo/MIPSCPU)

# MIPS CPU plugin for Hopper Disassembler

This is an experimental, unsophisticated plugin prototype using a custom disassembler and the [capstone](https://github.com/aquynh/capstone) (http://www.capstone-engine.org/) engine for the MIPS architecture (currently 32 bit EL only) whose main purpose is to provide a play and learning ground for the Hopper plugin system and the MIPS architecture and some assembly language in general.

There are currently two disassembler engines:
* capstone based engine for MIPS32
* custom engine for MIPS I, II, III, IV and MIPS32

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

Run `install.sh` from the Hopper-SDK.
Then adjust your `PATH` to include the created `gnustep-Linux-x86_64/bin/` path.
Follow above instructions for building with *cmake*.

## Status

* Little and big endianess
    * support for MIPS I
    * support for MIPS II
    * support for MIPS III
    * support for MIPS IV
    * support for MIPS32 (release 1)
    * support for MIPS32 release 2
    * support for MIPS32 release 5
    * support for MIPS32 release 6
    * support for MIPS64 (release 1)
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

* https://imgtec.com/documentation/
