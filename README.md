# MIPS CPU plugin for Hopper Disassembler

This is an experimental, highly unsophisticated plugin prototype using the [capstone](https://github.com/aquynh/capstone) (http://www.capstone-engine.org/) engine for the MIPS architecture (currently 32 bit EL only) whose main purpose is to be a play and learning ground for the Hopper plugin system and the MIPS architecture and some assembly language in general.

## Requirements

* Hopper Disassembler v4+ (https://www.hopperapp.com/)
* capstone (git `next` branch)

## Status

* Disassembly should roughly work
* Branch typing is incomplete (still need to figure out the different `DISASM_BRANCH_*` types)
* NOPping should work

## TODO

* Extend instruction analysis for Hopper to do its magic
* Disassemble into pseudo instructions (ideally as a second syntax option)
* String references (?)
* Add support for assembling instruction (using keystone)
* Support for EB (big endian), 64 bit
* Find ways to utilize some of `performBranchesAnalysis:`, `performInstructionSpecificAnalysis:`, `performProcedureAnalysis:`, `hasProcedurePrologAt:` etc.
* Use compact capstone engine for smaller footprint
