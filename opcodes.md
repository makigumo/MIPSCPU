# Description of the opcode definition format

Instruction opcodes and their operands are defined in `opcodes.plist`. This file contains an array of instruction dictionaries containing the following fields.

* Mnemonic: String with the instruction mnemonic. Doesn't have to be unique.
* Comment: String with an optional comment.
* Release: An array of ISA releases this instruction definition belongs to. Mustn't be empty.
* Branchtype: Optional string specifying a branch type.
    * `ALWAYS` unconditional jump
    * `EQUAL_ZERO`
    * `GREATER_EQUAL`
    * `GREATER_EQUAL_ZERO`
    * `GREATER_ZERO`
    * `LESS_EQUAL_ZERO`
    * `LESS`
    * `LESS_ZERO`
    * `EQUAL`
    * `NOT_EQUAL`
    * `NOT_EQUAL_ZERO`
    * `OVERFLOW`
    * `NO_OVERFLOW`
    * `CALL`
    * `RET`
    * `TRUE`
    * `FALSE`
* Format: A string describing the instruction format. Consisting of bit range definitions describing the instruction parts.
    * Instruction parts are separated by one space.
    * Each instruction part must have at least a bit range defined.
    * Bit range(s) have the form of `n..m` with n > m >=0 denoting the leftmost (n) und rightmost (m) bit.
        * a single bit has to be denoted as `n..n`
        * non-continuous bit ranges can be expressed as a comma-separated list, e.g. `31..29,26..23`
    * Values: values follow a bit range and can be in decimal `=1` or hex notation `=0x1`
        * e.g. `31..26=0x14`
    * If operand is branch destination: `B`
    * Operand position: `#n` with n > 0
        * If operand is read and/or written: `#1w`, `#2r`, `#3rw`
        * Operands without a position are not considered for output.
    * Operand type
        * `rt` General Purpose Register (GPR)
        * `rs` GPR
        * `rd` GPR
        * `coprt` Coprocessor Register (CPR)
        * `coprs` CPR
        * `coprd` CPR
        * `hwrd` Hardware Register (HWR)
        * `ft` Floating Point Register (FPR)
        * `fs` FPR
        * `fd` FPR
        * `uimm` unsigned immediate of size determined by bit range length.
        * `imm16` 16-bit signed immediate
        * `imm16sl16` 16-bit signed immediate shifted left by 16 bits
        * `imm19sl2` 19-bit signed immediate shifted left by 2 bits
        * `fcc` FPU control
        * `ffmt` FPU format
        * `fcond` FPU condition
        * `fcondn` FPU condition (MIPS32R6)
        * `base` base register for memory
        * `copbase` cop base register for memory
        * `index` index register for memory
        * `off9` 9-bit offset
        * `off11` 11-bit offset
        * `off16` 16-bit offset
        * `off18` 18-bit offset
        * `off21` 21-bit offset
        * `off23` 23-bit offset
        * `off28` 28-bit offset
        * `size`
        * `code10`
        * `code20`
        * `possize`
        * `jmpadr`
        * `ignored`
        * `bp`
        * `sa`
        * `sa+1`
        * `op`
        * `msb`
        * `msbd`
        * `msbminus32`
        * `msbdminus32`
        * `lsb`
        * `lsbminus32`
        * `ignored` ignored value
* Idiom: Optional boolean for an idiom of another instruction.
* Conditions: Optional conditions that must be satisfied, e.g. for MIPS32R6.
    * compare operand and operand, or
        * `#1==#2`
    * compare operand and value
        * `#1!=0`
    * operands are designated by their position from the left inside the format string `0..n-1`
    * compare operations are:
        * `==`
        * `!=`
        * `>`
