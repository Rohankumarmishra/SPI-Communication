# SPI-Communication: Master-Slave Design in Verilog

A full-duplex SPI (Serial Peripheral Interface) master and slave implemented in
Verilog and tested on a **Boolean FPGA board**. Data moves in both directions at
once through 8-bit shift registers and a generated SPI clock, with edge-triggered
sampling.

## Features

- SPI master with a configurable clock divider (`CLK_DIV`)
- SPI slave driven by the master's `sclk` and chip-select
- Full-duplex 8-bit transfer (MOSI and MISO at the same time)
- Edge-triggered sampling and shifting (SPI Mode 0: CPOL = 0, CPHA = 0)
- Self-checking testbench that prints PASSED or FAILED
- Hardware demo: push-buttons for reset/start, LEDs to verify the transfer

## Repository Structure

```
SPI-Communication/
├── src/
│   ├── spim.v        # SPI master
│   └── spislave.v    # SPI slave
├── sim/
│   └── tb_spi.v      # Testbench
├── constraints/
│   └── boolean.xdc   # Pin constraints [add if you have it]
├── docs/
│   └── timing_diagram [link or image]
└── README.md
```

## How It Works

The master loads `data_in` into its transmit shift register when `start` is
asserted. It pulls `cs_n` low and generates `sclk` from the system clock.

- **Leading edge (sclk rising):** both sides sample the incoming bit
  (master samples MISO, slave samples MOSI).
- **Trailing edge (sclk falling):** both sides shift out the next bit.
- After 8 bits, the master raises `cs_n`, clears `busy`, and updates `data_out`.
  The slave updates `received_data`.

The SPI clock frequency is `f_sclk = f_clk / (2 × CLK_DIV)`. With the default
`CLK_DIV = 4`, `sclk` runs at f_clk / 8.

## Modules

### `spim` (Master)

| Port | Dir | Description |
|------|-----|-------------|
| `clk` | in | System clock |
| `rst` | in | Synchronous reset |
| `data_in[7:0]` | in | Byte to transmit |
| `start` | in | Starts a transfer when not busy |
| `data_out[7:0]` | out | Byte received from the slave |
| `busy` | out | High during a transfer |
| `cs_n` | out | Active-low chip select |
| `sclk` | out | SPI clock |
| `mosi` | out | Master out, slave in |
| `miso` | in | Master in, slave out |

Parameter: `CLK_DIV` (default 4) sets the SPI clock divider.

### `spislave` (Slave)

| Port | Dir | Description |
|------|-----|-------------|
| `sclk` | in | SPI clock from the master |
| `ss` | in | Slave select (active low) |
| `mosi` | in | Data from the master |
| `transmit_data[7:0]` | in | Byte to send to the master |
| `received_data[7:0]` | out | Byte received from the master |
| `miso` | out | Data to the master |

## Simulation

1. Add `spim.v`, `spislave.v` and `tb_spi.v` to your simulator
   (Vivado, ModelSim, Icarus Verilog, etc.).
2. Set `tb_spi` as the top module and run.

Example with Icarus Verilog:

```bash
iverilog -o spi_sim src/spim.v src/spislave.v sim/tb_spi.v
vvp spi_sim
```

Expected output:

```
--------------------------------------
MASTER SENT     : 10110010
SLAVE RECEIVED  : 10110010

SLAVE SENT      : 01110110
MASTER RECEIVED : 01110110
--------------------------------------
********** TEST PASSED **********
```

## FPGA Implementation (Boolean Board)

1. Create a Vivado
