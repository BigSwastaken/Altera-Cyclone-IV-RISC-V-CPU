# Altera Cyclone IV RV32I Multi-Cycle Processor

A hardware-verified, multi-cycle RISC-V soft-core processor written in Verilog and synthesized for the Altera Cyclone IV FPGA.

## Board Preview
![20260307_034447](https://github.com/user-attachments/assets/72c66eec-63bb-4ed3-86f3-28ded5996755)  
(Currently displaying Reg x2)

## About The Project

This project is a complete, from-scratch implementation of the RISC-V RV32I base integer instruction set. It is designed around a multi-cycle state machine architecture, allowing it to execute complex instructions systematically across discrete clock cycles, maximizing resource efficiency on the FPGA.

This processor has been fully synthesized, routed, and hardware-verified on an Altera Cyclone IV EP4CE6F17C8 FPGA. The link to my specific development board can be found here: 
* [CSSBuy Link](https://www.cssbuy.com/item-894990981970.html)
* [Taobao Link](https://item.taobao.com/item.htm?id=894990981970)

### Architecture Overview
* **Datapath:** Multi-cycle architecture (Fetch, Decode, Execute, Memory, Writeback) controlled by a central FSM.
* **Memory System:** Utilizes native Altera block RAM primitives (`altsyncram`) configured for 32-bit word widths with precise byte-enable masking for Store/Load instructions.
* **Hardware Debugging:** Features an independent, asynchronous debugging path. On-board switches allow the user to step through the internal register file, multiplexing live 32-bit register data out to a physical 7-segment display array. It can also be set to be used as a manual clock. 

### Built With

* Intel Quartus Prime Lite
* Questa Starter Edition
* Verilog-2001 

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

You will need the Intel Quartus Prime design suite installed to compile the hardware and program the board.
* Intel Quartus Prime (Lite Edition is sufficient)  
  [Download Here](https://www.intel.com/content/www/us/en/software-kit/868561/intel-quartus-prime-lite-edition-design-software-version-25-1-for-windows.html)   
  [How to get free Questa Starter Edition License](https://www.youtube.com/watch?v=yOSu6zMbNHI)
* A development board featuring an Altera Cyclone FPGA
* If you are using a different development board, (`pins.tcl`) would need to be edited to fit your pin map.
* Optional: [Get Icarus Verilog](https://bleyer.org/icarus/) for simulations instead of using Questa. The UI is more intuitive and beginner friendly, but you can't use `altsyncram` anymore. I recommend sticking to Questa. You will need to write your own testbench for either simulations.

### Installation

1. Clone the repository
   ```sh
   git clone https://github.com/BigSwastaken/Altera-Cyclone-IV-RISC-V-CPU.git
   ```
2. Open the project in Quartus
   * Launch Intel Quartus Prime.
   * Go to `File` -> `Open Project` and select the `computer_project.qpf` file.
3. Apply Pin Assignments
   * If you are using the exact development board linked above, navigate to `Tools` -> `Tcl Scripts...`
   * If NOT using the exact development board, make sure your `pins.tcl` is updated to match the board you are using
   * Select `pins.tcl` and click **Run** to map the physical FPGA pins to the top-level Verilog entity.
4. Compile the Design
   * Click `Processing` -> `Start Compilation` to synthesize the design and generate the SRAM Object File (`.sof`).


## Compilation and Usage

### Programming the CPU
The processor's instruction memory is initialized using a standard Altera Memory Initialization File (`program.mif`). This file uses a highly readable, human-editable format without the need for checksum calculations.

To run a custom RISC-V program:
1. Compile your RV32I assembly code into raw 32-bit hexadecimal machine code.
2. Open `program.mif` in a text editor. You can also use the Quartus built in `.mif` editor, specify word size = 32 if needed. 
3. Paste your 32-bit hex instructions sequentially, starting at address `00`.
4. Recompile the Quartus project to pack the new program into the M9K blocks.
5. Program the board via USB Blaster.  

<details>
<summary><b>Click to view default test program & expected register states</b></summary>

  ```
# Address : Hex Code : Assembly Instruction
0x00      : 00500093 : addi  x1, x0, 5        #Load 5 into x1
0x04      : FFD00113 : addi  x2, x0, -3       #Load -3 into x2
0x08      : 002081B3 : add   x3, x1, x2       #x3 = 5 + (-3) = 2
0x0C      : 40208233 : sub   x4, x1, x2       #x4 = 5 - (-3) = 8
0x10      : 003092B3 : sll   x5, x1, x3       #x5 = 5 << 2 = 20
0x14      : 00112333 : slt   x6, x2, x1       #x6 = (-3 < 5)
0x18      : 001133B3 : sltu  x7, x2, x1       #x7 = (-3 < 5 unsigned)
0x1C      : 0030C433 : xor   x8, x1, x3       #x8 = 5 ^ 2
0x20      : 0032D4B3 : srl   x9, x5, x3       #x9 = 20 >> 2 
0x24      : 40315533 : sra   x10, x2, x3      #x10 = -3 >>> 2 
0x28      : 0030E5B3 : or    x11, x1, x3      #x11 = 5 | 2
0x2C      : 0030F633 : and   x12, x1, x3      #x12 = 5 & 2
0x30      : 00F0C693 : xori  x13, x1, 15      #x13 = 5 ^ 15
0x34      : 0106E713 : ori   x14, x13, 16     #x14 = x13 | 16
0x38      : 00A77793 : andi  x15, x14, 10     #x15 = x14 & 10
0x3C      : 00A12D13 : slti  x26, x2, 10      #x26 = (-3 < 10) 
0x40      : 00A13D93 : sltiu x27, x2, 10      #x27 = (-3 < 10 unsigned)

#Memory Load/Store Tests
0x44      : 12345837 : lui   x16, 0x12345     #Load Upper Immediate into x16
0x48      : 00001897 : auipc x17, 1           #Add Upper Immediate to PC
0x4C      : 0C800913 : addi  x18, x0, 200     #x18 = 200 (Base address for memory)
0x50      : 01092023 : sw    x16, 0(x18)      #Store Word (32-bit)
0x54      : 00F91223 : sh    x15, 4(x18)      #Store Halfword (16-bit)
0x58      : 00E90323 : sb    x14, 6(x18)      #Store Byte (8-bit)
0x5C      : 00092983 : lw    x19, 0(x18)      #Load Word
0x60      : 00491A03 : lh    x20, 4(x18)      #Load Halfword (sign-extended)
0x64      : 00495A83 : lhu   x21, 4(x18)      #Load Halfword (zero-extended)
0x68      : 00690B03 : lb    x22, 6(x18)      #Load Byte (sign-extended)
0x6C      : 00694B83 : lbu   x23, 6(x18)      #Load Byte (zero-extended)

#Branch & Jump Tests
0x70      : 00108463 : beq   x1, x1, 8        #Branch Equal (Always taken)
0x74      : 00000013 : nop                    #(Skipped by branch)
0x78      : 00209463 : bne   x1, x2, 8        #Branch Not Equal (Taken)
0x7C      : 00000013 : nop                    #(Skipped by branch)
0x80      : 00114463 : blt   x2, x1, 8        #Branch Less Than (Taken)
0x84      : 00000013 : nop                    #(Skipped by branch)
0x88      : 0020D463 : bge   x1, x2, 8        #Branch Greater/Equal (Taken)
0x8C      : 00000013 : nop                    #(Skipped by branch)
0x90      : 0020E463 : bltu  x1, x2, 8        #Branch Less Than Unsigned (Taken)
0x94      : 00000013 : nop                    #(Skipped by branch)
0x98      : 00117463 : bgeu  x2, x1, 8        #Branch Greater/Equal Unsigned (Taken)
0x9C      : 00000013 : nop                    #(Skipped by branch)
0xA0      : 00800C6F : jal   x24, 8           #Jump and Link (PC = PC+8)
0xA4      : 00000013 : nop                    #(Skipped by jump)
0xA8      : 008C0C67 : jalr  x24, x24, 8      #Jump and Link Register
0xAC      : 0000006F : j     0                #Infinite Loop (Halt)
```
| Reg | Hex Value | Reg | Hex Value | Reg | Hex Value | Reg | Hex Value |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **x0** | `0x00000000` | **x8** | `0x00000007` | **x16** | `0x12345000` | **x24** | `0x000000AC` |
| **x1** | `0x00000005` | **x9** | `0x00000005` | **x17** | `0x00001048` | **x25** | `0x00000000` |
| **x2** | `0xFFFFFFFD` | **x10** | `0xFFFFFFFF` | **x18** | `0x000000C8` | **x26** | `0x00000001` |
| **x3** | `0x00000002` | **x11** | `0x00000007` | **x19** | `0x12345000` | **x27** | `0x00000000` |
| **x4** | `0x00000008` | **x12** | `0x00000000` | **x20** | `0x0000000A` | **x28** | `0x00000000` |
| **x5** | `0x00000014` | **x13** | `0x0000000A` | **x21** | `0x0000000A` | **x29** | `0x00000000` |
| **x6** | `0x00000001` | **x14** | `0x0000001A` | **x22** | `0x0000001A` | **x30** | `0x00000000` |
| **x7** | `0x00000000` | **x15** | `0x0000000A` | **x23** | `0x0000001A` | **x31** | `0x00000000` |

</details>

### On-Board Debugging
Once the processor is running, use the defined hardware keys to interact with the CPU:
* **Clock Control:** If the clock mode switch is set to manual, use the dedicated clock button to advance the CPU state cycle-by-cycle. (key 0)
* **Register Inspection:** Use the target register switches/buttons to select a register address (x0 - x31). The physical 7-segment display array will output the live, real-time hexadecimal value of the currently selected register.(key 2 to go up a register, key 1 to go down)


## Roadmap

* UART Communication
* Pipelining
* External SDRAM and an RTOS
* Speed and Area optimizations

<p align="right">(<a href="#readme-top">back to top</a>)</p>
