---
feature: <name>
difficulty: simple | medium | hard
clock_mhz: <target>
traces_to: [SR-xxx]
---

# <Feature> specification

## Purpose
<!-- one paragraph -->

## Requirements
<!-- EARS, defined as "- [<FEATURE>-nnn] text {by: test|review|analysis}" -->
- [FEAT-001] ...

## Interface
| Port | Dir | Width | Clock | Description |
|---|---|---|---|---|

| Parameter | Default | Range | Description |
|---|---|---|---|

## Behaviour
<!-- timing/latency, throughput, reset values, ordering -->

## Errors and timeouts
<!-- every wait state: timeout, error output/counter -->

<!-- @if weight=standard,comprehensive -->
## Registers
<!-- field table, or reference to the register package -->

## Xilinx IP used
<!-- IP/XPM, configuration, checked document + section -->

<!-- @end -->
## Test plan
| Test | Requirements | Description |
|---|---|---|

Coverage target: line ≥ 95 %, branch ≥ 90 % (change only with a reason).
