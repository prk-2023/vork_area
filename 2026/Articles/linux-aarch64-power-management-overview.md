# ARM Linux Power Monitoring


## Introduction:
On ARM systems, power management is often implemented using external components such as **PMICs** and system 
controllers, whereas on Intel/AMD systems much of the power measurement and control logic is integrated 
within the CPU package itself (e.g., via RAPL). 

As a result, power monitoring and control tooling on ARM tends to be more platform-specific and may need 
adaptation across different SoCs and vendors.

### ARM commonly uses external power management 

Many ARM SoCs rely on:
    - External PMICs.
    - System Control Processors (SCP/MCP)
    - Firmware managed power domains.

These components:
    - Control voltage rails 
    - Sequence power states
    - Measure current/power at the board or rail level 

This is mainly applicable for :
    - Mobile SoCs 
    - Embedded systems 
    - Many ARM servers.

### Intel/AMD integrate power logic into the CPU package

`x86_64` platforms typically integrate:
    - Energy counters
    - Power control loops
    - Thermal management logic

These are Exposed via:
    - MSRs (RAPL)
    - Unified kernel interfaces (powercap, turbostat)

So tooling is:
    - Portable across generations
    - Largely architecture-stable

### ARM tooling varies across ARM platforms:

Different ARM SoCs expose power via:
    - hwmon
    - SCMI
    - BMC / IPMI
    - DebugFS

Names, domains, and granularity vary
Tooling often needs:
    - Platform detection
    - Sensor discovery
    - Per-vendor mappings

NOTE:
---
1. 
    - Not all ARM systems use external PMICs.
        Some ARM server SoCs integrate:
        * Voltage regulators
        * Power sensors 
    But the interface is not standardized line RAPL.

2. Not all x86 power is *inside the CPU*
    - DRAM power
    - Board-level rails
    - NIC / accelerator power

   These still rely on:
    - External sensors
    - BMC / IPMI
    - RAPL is CPU-package-centric, not system-wide.

---

=> ARM platforms have greater variation in how power data is exposed and therefore requires more adaptable 
   tooling across ARM targets.


## What's RAPL

**RAPL (Running Average Power Limit)** is an **Intel-defined hardware + SW power management interface** 
introduced with Sandy Bridge.

From a Linux point of view, RAPL provides:

1. **Hardware energy counters**

   * Exposed via **Model Specific Registers (MSRs)**
   * Measure **energy consumption**, not instantaneous power
   * Units are well defined (joules via a fixed energy unit)

2. **Power domains**

   * `package` (entire socket)
   * `core` / `pp0`
   * `uncore`
   * `dram` (on supported systems)

3. **Power control**

   * Enforce average power limits over time windows
   * Used for thermal control, power capping, and data-center energy budgeting

4. **Linux exposure**

   * `perf stat -e power/energy-pkg/`
   * `/sys/class/powercap/intel-rapl/`
   * Tools like `turbostat`, `powertop`

In short:

> **RAPL is a standardized, architectural energy accounting and power-limiting mechanism tightly integrated 
into Intel x86 CPUs.**

---

### Why ARM never standardized RAPL

ARM *could* have created a RAPL-like interface : 
But there are **fundamental architectural, business, and ecosystem reasons** why it didn’t.

---

#### 1. ARM is an *IP ecosystem*, not a platform vendor

Intel:

* Designs the CPU
* Designs the uncore
* Designs the memory controller
* Controls the MSRs
* Controls the firmware + reference platforms

ARM:

* Licenses **CPU cores only** (Cortex, Neoverse)
* SoC integrators decide:

  * Power rails
  * PMIC
  * Sensors
  * Memory controllers
  * DVFS topology

There is **no single “package” definition** across ARM systems.

A RAPL-style abstraction would have been *wrong* or *meaningless* for many SoCs.

---

#### 2. No architectural equivalent of MSRs

RAPL depends on:

* Privileged, fast, per-core **MSRs**
* Uniform across all Intel CPUs

ARM:

* Avoids vendor-specific architectural registers
* Strong separation between:

  * CPU
  * Power controller
  * System firmware

ARM instead uses:

* Memory-mapped I/O
* Firmware mediation
* Management controllers

➡️ Standardizing energy MSRs would break ARM’s clean architectural model.

---

#### 3. Power is *system-level* on ARM, not CPU-centric

Intel systems:

```
CPU package ≈ power domain
```

ARM systems:

```
CPU cluster + GPU + NPU + ISP + DRAM + PMIC
```

Power is:

* Distributed
* Hierarchical
* Managed externally (PMIC, SCP, firmware)

➡️ Measuring *only* the CPU is often not useful on ARM. 
This implies that the numbers on power consumption for CPU should include other components to get a complete
picture unlike x86_64 CPU's

---

#### 4. ARM optimized for mobile first

RAPL was designed for:

* Servers
* Sustained workloads
* Thermal envelopes measured in seconds

ARM’s early priorities:

* Smartphones
* Energy per task
* Millisecond-scale DVFS
* Aggressive power gating

Mobile SoCs rely on:

* Firmware-driven power management
* Closed-loop control outside the OS

➡️ OS-visible energy counters were not a priority.

---

#### 5. Standardization came later — via **SCMI**, not RAPL

ARM eventually addressed the problem, but differently.

**SCMI (System Control and Management Interface)**:

* Firmware-based standard
* Vendor-agnostic protocol
* Supports:

  * Power
  * Energy
  * Performance
  * DVFS
  * Thermal

Linux exposes SCMI via:

```
/sys/class/hwmon/
```

Key difference:

| RAPL              | SCMI                          |
| ----------------- | ----------------------------- |
| CPU-centric       | System-centric                |
| MSRs              | Firmware protocol             |
| Intel-only        | Multi-vendor                  |
| Fast, low-latency | Higher latency, broader scope |

ARM chose **correct abstraction over convenience**.

---

#### 6. Data center ARM came *after* RAPL

By the time ARM servers (Neoverse) emerged:

* RAPL was deeply entrenched in Intel tooling
* ARM focused on:

  * BMC / IPMI
  * Redfish
  * Board-level sensors

Energy accounting moved **out of the CPU** and **into the platform**.

---

### Bottom line

> **RAPL exists because Intel controls the entire platform.
> ARM never standardized RAPL because ARM does not.**

ARM systems require:

* Platform-aware power measurement
* Firmware participation
* Board-specific sensors

Trying to retrofit RAPL would have:

* Broken abstraction
* Excluded many vendors
* Delivered misleading data

---

## Linux centric approach for AArch64. 

Below is a **practical, Linux-centric walkthrough** showing:

1. How to **aggregate `hwmon` power/energy with `perf`**
2. How to **time-align and correlate them**
3. Where **eBPF fits** (and where it does *not*)

Everything is ARM/AArch64-friendly and avoids x86/RAPL assumptions.

---

### 1. Discover available power sensors (`hwmon`)

First, identify which `hwmon` devices expose power or energy.

```bash
for h in /sys/class/hwmon/hwmon*; do
  echo "== $h =="
  grep -H . $h/name
  ls $h | grep -E 'power|energy|curr|in'
done
```

Typical files:

* `power*_input` → microwatts (µW)
* `energy*_input` → microjoules (µJ)

Example:

```text
/sys/class/hwmon/hwmon2/power1_input
/sys/class/hwmon/hwmon2/energy1_input
```

---

### 2. Simple shell aggregation: `hwmon` + `perf stat`

#### 2.1 Sampling power while running a workload

```bash
POWER=/sys/class/hwmon/hwmon2/power1_input

while true; do
  ts=$(date +%s.%N)
  p=$(cat $POWER)
  echo "$ts $p"
  sleep 1
done > power.log &
PWR_PID=$!

perf stat -a \
  -e cycles,instructions,cache-misses \
  -- sleep 10

kill $PWR_PID
```

Now you have:

* `power.log` → real power
* `perf stat` → performance counters

You can post-process:

```bash
awk '{sum+=$2} END {print sum/NR}' power.log
```

---

### 3. Energy-based accounting (preferred if available)

If your platform exposes **energy counters**:

```bash
ENERGY=/sys/class/hwmon/hwmon2/energy1_input

e_start=$(cat $ENERGY)
perf stat -a -e cycles,instructions -- sleep 5
e_end=$(cat $ENERGY)

echo "Energy used (uJ): $((e_end - e_start))"
```

This is the **closest ARM equivalent to RAPL energy-pkg**.

---

### 4. Python example: time-aligned correlation

This gives you **time-series correlation**, not just totals.

```python
import time
import subprocess

POWER = "/sys/class/hwmon/hwmon2/power1_input"

samples = []

start = time.time()

while time.time() - start < 5:
    ts = time.time()
    with open(POWER) as f:
        p = int(f.read().strip())
    samples.append((ts, p))
    time.sleep(0.1)

# Run perf separately or in parallel
subprocess.run([
    "perf", "stat",
    "-e", "cycles,instructions",
    "--", "sleep", "5"
])

for t, p in samples:
    print(f"{t},{p}")
```

You can now:

* Plot power vs time
* Overlay perf results
* Build energy-per-instruction models

---

### 5. Using `perf record` for finer correlation

Instead of `perf stat`, capture **time-stamped samples**:

```bash
perf record -a -F 99 -e cycles,instructions -- sleep 5
perf script > perf.log
```

Now:

* `perf.log` → timestamped CPU events
* `power.log` → timestamped power

Correlation is done in user space.

---

### 6. Where eBPF fits (and where it doesn’t)

### What eBPF **cannot** do

❌ Read power sensors directly
❌ Replace `hwmon` or SCMI
❌ Measure energy

### What eBPF **is excellent at**

✔ Explaining *why* power changed
✔ Adding kernel context
✔ Ultra-low overhead tracing

---

### 7. eBPF examples for power correlation

#### 7.1 CPU frequency transitions (DVFS)

```bash
bpftrace -e '
tracepoint:power:cpu_frequency {
  printf("%d %d\n", args->cpu_id, args->state);
}'
```

Correlate:

* Frequency ↑ → power ↑
* Frequency ↓ → idle or thermal throttling

---

#### 7.2 Scheduler activity (workload intensity)

```bash
bpftrace -e '
tracepoint:sched:sched_switch {
  @[args->next_comm] = count();
}'
```

Useful for:

* Identifying noisy neighbors
* Understanding bursty power usage

---

#### 7.3 Idle state residency

```bash
bpftrace -e '
tracepoint:power:cpu_idle {
  printf("cpu %d state %d\n", args->cpu_id, args->state);
}'
```

Power drops often correlate with:

* Deeper idle states
* Longer residency

---

### 8. Combined workflow (recommended)

```
hwmon / SCMI     → ground truth power
perf             → workload intensity
eBPF             → kernel behavior context
user-space model → energy attribution
```

This gives you:

* **What** power was consumed (hwmon)
* **How much work** was done (perf)
* **Why** power changed (eBPF)

---

### 9. Mental model vs RAPL

| Intel RAPL  | ARM approach            |
| ----------- | ----------------------- |
| Single API  | Multiple interfaces     |
| CPU-centric | Platform-centric        |
| MSRs        | sysfs + firmware        |
| Easy        | Accurate but fragmented |

ARM trades **convenience for correctness**.

---

TODO: Cover the below topics 

* Build a **RAPL-like wrapper script for ARM**
* Show **Prometheus / Grafana integration**
* Compare **SCMI vs hwmon vs BMC accuracy**
* Discuss **energy-aware scheduling (EAS) internals**
