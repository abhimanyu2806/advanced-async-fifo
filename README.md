# Advanced Asynchronous FIFO Design using Verilog

## Overview

This project implements an **Asynchronous First-In First-Out (FIFO)** using Verilog HDL.

An asynchronous FIFO is a memory buffer used to transfer data between two independent clock domains. Since the write and read operations are controlled by separate clocks, proper clock-domain crossing (CDC) techniques are required to ensure reliable data transfer.

The design uses binary and Gray code pointers, two-stage synchronisation, and status flag generation to manage asynchronous read and write operations.

## Design Specifications

| Parameter | Specification |
|---|---|
| Data Width | 8 bits |
| FIFO Depth | 16 locations |
| Address Width | 4 bits |
| Pointer Width | 5 bits |
| Write Clock | Independent clock |
| Read Clock | Independent clock |
| Reset | Active-low asynchronous reset |
| Pointer Synchronisation | Two-stage synchroniser |
| Pointer Encoding | Binary and Gray code |

## Features

- Independent write and read clock domains.
- Binary pointer and Gray code pointer implementation.
- Two-stage synchronisation of Gray code pointers.
- FIFO full and empty detection.
- Almost-full and almost-empty status flags.
- Overflow and underflow detection.
- Modular RTL design using separate controller, memory and synchroniser modules.

## Design Architecture

The design is divided into three main RTL modules:

### 1. `async_fifo.v`
- Main FIFO controller.
- Manages read and write pointers.
- Performs binary-to-Gray and Gray-to-binary conversions.
- Generates full, empty, almost-full and almost-empty flags.
- Handles overflow and underflow detection.
- Integrates the memory and synchroniser modules.

### 2. `fifo_memory.v`
- Implements the FIFO storage array.
- Supports write operations using the write clock.
- Supports read operations using the read clock.

### 3. `synchronizer.v`
- Implements a two-stage synchroniser.
- Transfers Gray code pointers safely between independent clock domains.
- Helps reduce the risk of metastability propagation.

## Project Structure

```text
advanced_async_fifo/
│
├── rtl/
│   ├── async_fifo.v
│   ├── fifo_memory.v
│   └── synchronizer.v
│
├── testbenches/
│   ├── tb_basic.v
│   ├── tb_full_empty.v
│   ├── tb_clock_domains.v
│   └── tb_random.v
│
├── docs/
│   ├── rtl_schematic.png
│   ├── basic_fifo_waveform.png
│   ├── full_empty_waveform.png
│   └── clock_domains_waveform.png
│
├── README.md
└── .gitignore
```

## Verification and Testing

The RTL design was functionally simulated and verified using **Xilinx Vivado Simulator**.

Four testbenches were developed to validate different operating conditions.

| Testbench | Purpose |
|---|---|
| `tb_basic.v` | Verifies basic FIFO write and read operations |
| `tb_full_empty.v` | Tests full and empty conditions, overflow and underflow |
| `tb_clock_domains.v` | Verifies data transfer between independent clock domains |
| `tb_random.v` | Tests randomised data inputs and operation delays across multiple rounds |

The testbenches were used to verify:
- Correct FIFO data storage and retrieval.
- Full and empty flag behaviour.
- Overflow and underflow handling.
- Operation with independent write and read clocks.
- Data integrity across multiple test rounds.

## Design Documentation

The `docs/` directory contains selected design and simulation screenshots:

- **RTL Schematic:** Overall elaborated RTL architecture.
- **Basic FIFO Waveform:** Write and read operation.
- **Full/Empty Waveform:** FIFO status and boundary-condition behaviour.
- **Clock-Domain Waveform:** Independent write and read clock operation.

## Tools and Technologies

- **HDL:** Verilog
- **Simulation:** Xilinx Vivado Simulator
- **Development Environment:** Visual Studio Code
- **Design Analysis:** Vivado RTL Schematic

## Project Status

**RTL implementation and functional simulation verification completed.**

The design has been simulated using the developed testbenches in Vivado. FPGA hardware implementation and physical board testing are not included in this project.

## Author

Abhimanyu Singh Bhati

