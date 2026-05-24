# apb-present-crypto-accelerator
Lightweight PRESENT cipher hardware accelerator with AMBA 3 APB slave interface and fully pipelined crypto-core.
[![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Project Overview

This project implements a custom **64‑bit block cipher** with an **80‑bit secret key** and a standard **APB (Advanced Peripheral Bus) slave interface**. The design is intended for resource‑constrained SoC environments that require a compact, low‑gate‑count encryption engine accessible from a host processor.

Data flow: the processor writes the plaintext and key over APB; the interface automatically triggers the cryptographic core, which performs 32 rounds of a substitution‑permutation network (SPN) transformation. The resulting ciphertext can then be read back from dedicated APB registers.

## System Architecture

* **Top Module** (`top`): Instantiates the APB slave interface and the crypto core, wiring them together.
* **APB Slave Interface** (`apb_slave_interface`): Memory‑mapped peripheral that handles register access, sequencing of configuration writes, and initiation / completion of encryption.
* **Crypto Core** (`crypto_core`): Combinational‑next‑state SPN block cipher with a 6‑bit internal counter (0–31 rounds), operating on a 64‑bit data block and an 80‑bit key.

The design does **not** include a S‑box definition; users must provide a function `sbox_table` that accepts a 4‑bit input and returns a 4‑bit output.

## Register Map

The APB slave exposes the following 32‑bit registers (accessed at byte‑aligned addresses):

| Address | Name             | Access | Description                                   |
|:-------:|:-----------------|:------:|:----------------------------------------------|
| `0x00`  | `DATA_LO`        |  W/R   | Plaintext / ciphertext, lower 32 bits         |
| `0x01`  | `DATA_HI`        |  W/R   | Plaintext / ciphertext, upper 32 bits         |
| `0x02`  | `KEY_LO`         |  W/R   | Secret key, bits [31:0]                       |
| `0x03`  | `KEY_MI`         |  W/R   | Secret key, bits [63:32]                      |
| `0x04`  | `KEY_HI`         |  W/R   | Secret key, bits [79:64] (upper 16 bits used) |
| `0x05`  | `CRYPTO_DATA_LO` |   R    | Encrypted result, lower 32 bits               |
| `0x06`  | `CRYPTO_DATA_HI` |   R    | Encrypted result, upper 32 bits               |

All registers except the result registers can be read back for verification.

## Operation Sequence

1. **Reset** – The peripheral enters idle state, all internal counters are cleared.
2. **Configuration** – The processor writes the plaintext and key in any order:
   - Write `DATA_LO` and `DATA_HI` (exactly two writes total).
   - Write `KEY_LO`, `KEY_MI`, and `KEY_HI` (exactly three writes).
3. **Auto‑start** – Once both data and key have been fully written, the interface asserts `cr_start` and moves to the `DATA_CR_OUT` state.
4. **Encryption** – The crypto core runs 32 rounds (see Algorithm) and asserts `ready_out`.
5. **Result latching** – The APB slave captures the 64‑bit ciphertext and sets its `ready` flag.
6. **Readout** – The processor reads `CRYPTO_DATA_LO` and `CRYPTO_DATA_HI` to obtain the encrypted block.

While the core is busy, the APB interface does not accept new writes.

## Encryption Algorithm (Crypto Core)

The core operates on a 64‑bit state `S` and an 80‑bit key `K`. One round consists of:
for i = 0..62: out[(16*i) mod 63] = S[i]
out[63] = S[63]
4. **Key Schedule** – The key is rotated left by 19 bits, its top nibble is substituted, and bits `[19:15]` are XORed with the current round counter.

After exactly 32 rounds, an extra key injection (`S = S XOR K[79:16]`) is applied to produce the final ciphertext.

*Note: the S‑box function must be supplied externally. Without it the design will not synthesise.*

## Implementation Details

- **Technology**: RTL SystemVerilog, fully synthesizable.
- **State Machines**:
- APB slave: `START` (wait for configuration) → `DATA_CR_OUT` (wait for crypto completion).
- Crypto core: `IDLE` → `WORK` (32 cycles) → `DONE` (output + key XOR).
- **Timing**: Single‑clock domain; all logic is registered on `posedge clk` with synchronous reset (`negedge rst`).
- **Resource Usage**: Minimal – only a 64‑bit data register, 80‑bit key register, a 6‑bit counter, and small combinational clouds.

## How to Simulate

1. Add all source files (`crypto_core.sv`, `apb_slave_interface.sv`, `top.sv`) and a testbench to your simulator (ModelSim, QuestaSim, Vivado XSim, Verilator, etc.).
2. Provide an implementation of the `sbox_table` function, e.g. as a separate package or in the top module.
3. Write a testbench that:
- Resets the system.
- Writes a known plaintext and key via the APB bus.
- Waits for the `ready` signal.
- Reads back `CRYPTO_DATA_LO`/`HI` and compares against expected ciphertext.
4. Run the simulation and verify the output.

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

---

**Author:** Sergey Azov  
*Candidate for Intern RTL Design at YADRO*
1. **Key Injection** – `S = S XOR K[79:16]`
2. **Substitution** – Each 4‑bit nibble of `S` is passed through a 4×4 S‑box (user‑defined `sbox_table`).
3. **Permutation** – The 64 bits are rearranged according to:
