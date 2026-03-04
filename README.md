<a name="readme-top"></a>

<br />
<div align="center">
  <h3 align="center">Altera Cyclone IV RV32I Multi-Cycle Processor</h3>

  <p align="center">
    A hardware-verified, multi-cycle RISC-V soft-core processor written in Verilog and synthesized for the Altera Cyclone IV FPGA.
    <br />
    <a href="https://github.com/BigSwastaken/Altera-Cyclone-IV-RISC-V-CPU/issues">Report Bug</a>
  </p>
</div>

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#architecture-overview">Architecture Overview</a></li>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

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

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

You will need the Intel Quartus Prime design suite installed to compile the hardware and program the board.
* Intel Quartus Prime (Lite Edition is sufficient)
* A development board featuring an Altera Cyclone FPGA
*   Note: if you are using a different development board, (`pins.tcl`) would need to be edited to fit your pin map

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
   * Select `pins.tcl` and click **Run** to map the physical FPGA pins to the top-level Verilog entity.
4. Compile the Design
   * Click `Processing` -> `Start Compilation` to synthesize the design and generate the SRAM Object File (`.sof`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>


## Usage

### Programming the CPU
The processor's instruction memory is initialized using a standard Altera Memory Initialization File (`program.mif`). This file uses a highly readable, human-editable format without the need for checksum calculations.

To run a custom RISC-V program:
1. Compile your RV32I assembly code into raw 32-bit hexadecimal machine code.
2. Open `program.mif` in a text editor (like VS Code).
3. Paste your 32-bit hex instructions sequentially, starting at address `00`.
4. Recompile the Quartus project to pack the new program into the M9K blocks.
5. Program the board via JTAG (`Tools` -> `Programmer`) using your compiled `.sof` file.

### On-Board Debugging
Once the processor is running, use the defined hardware keys to interact with the CPU:
* **Clock Control:** If the clock mode switch is set to manual, use the dedicated clock button to advance the CPU state cycle-by-cycle.
* **Register Inspection:** Use the target register switches/buttons to select a register address (x0 - x31). The physical 7-segment display array will output the live, real-time hexadecimal value of the currently selected register.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


## Roadmap

- [x] RV32I Core Datapath Implementation
- [x] Multi-cycle FSM Control Unit
- [x] Native M9K Block RAM Integration (`altsyncram`)
- [x] Hardware-level 7-Segment Debugging & Manual Clocking

<p align="right">(<a href="#readme-top">back to top</a>)</p>


## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


## Contact

Simon (Zixuan) Yin - [GitHub Profile](https://github.com/BigSwastaken)

Project Link: [https://github.com/BigSwastaken/Altera-Cyclone-IV-RISC-V-CPU](https://github.com/BigSwastaken/Altera-Cyclone-IV-RISC-V-CPU)

<p align="right">(<a href="#readme-top">back to top</a>)</p>
