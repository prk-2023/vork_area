# Logic Analyzers


A **logic analyzer** is an electronic instrument used to **capture, display, and analyze digital signals** 
in a circuit. 
Unlike an oscilloscope, which visualizes voltage over time (analog or digital), a logic analyzer focuses 
specifically on digital logic states — typically **high (1)** or **low (0)**.

---

### 🔍 What a Logic Analyzer Does:

* **Captures digital signals** from multiple channels (e.g., data lines, clock lines).
* **Time-aligns** these signals to show how they change relative to each other.
* Allows **triggering** (e.g., start capture when a specific pattern occurs).
* **Decodes protocols** (e.g., I2C, SPI, UART) to display meaningful data like addresses or messages.
* Provides **timing analysis** for debugging and performance testing.

---

### 🧠 Why Logic Analyzers Are Used:

1. **Debugging digital systems**: Catch logic errors, race conditions, and protocol violations.
2. **Timing verification**: Ensure correct sequencing of events (e.g., setup and hold times).
3. **Protocol analysis**: Decode communication protocols like I2C, SPI, CAN, USB, etc.
4. **Reverse engineering**: Understand undocumented or proprietary communication.
5. **Embedded system development**: Debug communication between microcontrollers and peripherals.

---

### 📍 Where They Are Used:

* **Embedded systems development labs**: To test firmware-hardware interactions.
* **Digital circuit design**: For FPGAs, ASICs, or complex PCB-based systems.
* **Automotive electronics**: Diagnosing CAN bus or LIN protocols.
* **Telecom and networking**: Debugging digital communication buses.
* **Consumer electronics**: Development and QA of gadgets and smart devices.

---

### 🛠️ Types of Logic Analyzers:

| Type                                | Description                                                          | Example Use                            |
| ----------------------------------- | -------------------------------------------------------------------- | -------------------------------------- |
| **Standalone**                      | Dedicated hardware unit with screen and controls.                    | High-end engineering labs              |
| **PC-based**                        | USB device connected to a computer, uses PC for display and control. | Hobbyist and low-cost professional use |
| **Mixed Signal Oscilloscope (MSO)** | Combines oscilloscope and logic analyzer in one.                     | General-purpose lab testing            |

---

### 🧪 Example:

Suppose you're working on an I2C sensor interfacing with a microcontroller, and the sensor isn’t responding. 
A logic analyzer can:

* Capture the I2C transaction.
* Decode it to show START, address, ACK/NACK, and data bytes.
* Reveal timing errors, wrong addresses, or missing signals.

---

# Logic Analyzer Reference table:

Here’s a clear **reference table** showing recommended **sampling rates** for various digital signal tasks, 
along with the **minimum logic analyzer sampling rate** you should aim for.

> 💡 Rule of thumb: A logic analyzer should sample at **4–10 times** the highest clock frequency of the 
signal to reliably capture transitions and timing.

---

### 📊 Sampling Rate Requirements for Common Digital Tasks

| **Use Case / Protocol**     | **Typical Signal Speed** | **Recommended Sampling Rate (Analyzer)** | **Notes**                                    |
| --------------------------- | ------------------------ | ---------------------------------------- | -------------------------------------------- |
| **UART (9600–115200 baud)** | \~10 kHz – 115 kHz       | 1–2 MS/s                                 | For debugging characters, 8-bit frames       |
| **I2C (Standard Mode)**     | 100 kHz                  | 1–2 MS/s                                 | 10x clock rate for good resolution           |
| **I2C (Fast Mode)**         | 400 kHz                  | 4–10 MS/s                                | More precise timing needed                   |
| **SPI (Low-speed)**         | 500 kHz – 1 MHz          | 10–20 MS/s                               | Clock + data on separate lines               |
| **SPI (Typical)**           | 5–10 MHz                 | 50–100 MS/s                              | Needs detailed capture                       |
| **SPI (High-speed)**        | 20–50 MHz                | 200–500 MS/s                             | High-performance analyzer required           |
| **1-Wire Protocol**         | 15.4 kbps (standard)     | 0.5–1 MS/s                               | Long pulses, but still needs resolution      |
| **CAN Bus (Standard)**      | 125 kbps – 1 Mbps        | 5–20 MS/s                                | For decoding frame boundaries                |
| **I2S (Audio interface)**   | 1–10 MHz (BCLK)          | 50–100 MS/s                              | Clock/data alignment critical                |
| **Parallel Bus (8/16-bit)** | 1–10 MHz (per line)      | 100–200 MS/s                             | More if data changes every clock             |
| **DDR/Memory Bus**          | 100–400 MHz              | 500 MS/s – 2 GS/s                        | Requires professional-grade logic analyzers  |
| **USB Low-Speed**           | 1.5 Mbps                 | 10–20 MS/s                               | Not trivial to decode without specific tools |
| **USB Full-Speed**          | 12 Mbps                  | 100–200 MS/s                             | Requires dedicated USB analyzers             |

---

### 🧪 Visual Summary Chart (for quick estimation)

| **Signal Frequency Range** | **Use Case Example**          | **Min Sampling Rate Needed** |
| -------------------------- | ----------------------------- | ---------------------------- |
| < 100 kHz                  | UART, I2C (standard)          | 1–2 MS/s                     |
| 100 kHz – 1 MHz            | I2C (fast), SPI (slow)        | 10–20 MS/s                   |
| 1–10 MHz                   | SPI, CAN, I2S                 | 50–100 MS/s                  |
| 10–50 MHz                  | SPI (high-speed), audio buses | 200–500 MS/s                 |
| 50–500 MHz                 | DDR, USB, fast memory buses   | 1–2 GS/s                     |

---

### 🧠 Final Tips:

* **Over-sampling** is always better: more detail, better edge detection.
* Consider **internal clock edges** vs **data setup/hold** — faster signals require tighter analysis.
* **Memory buffer** becomes a limitation at high sampling rates — ensure enough RAM or streaming capability.

---

# Recommendations:

Things that are essential to help tailor a recommendation for either **buying** or **building** a logic 
analyzer for your exact needs.

---
1. **What protocols or interfaces will you be analyzing?**

   * (e.g., SPI, I2C, UART, CAN, parallel bus, etc.)

2. **What’s the maximum speed (or clock rate) of the signals involved?**

   * (e.g., I2C at 400 kHz, SPI at 10 MHz)

3. **How many channels do you need?**

   * (e.g., 4 for I2C/SPI/UART, 16+ for buses)

4. **What’s your budget?**

   * (e.g., under \$20, \$50–100, \$200+, etc.)

5. **Do you prefer buying a device or building one yourself?**

   * DIY may require some electronics experience and time.

6. **What operating system do you use?**

   * (e.g., Linux, Windows, macOS — for software compatibility)

---

# Logic Analyzer SW for linux:

## 🧰 **1. Sigrok (with PulseView GUI)**

### 🔹 Overview:

* **Open-source**, cross-platform.
* Supports **many USB-based logic analyzers** (e.g., Saleae, FX2LA clones).
* Protocol decoding for dozens of protocols (I2C, SPI, UART, CAN, etc.).

### 🔹 Components:

* **Sigrok-cli**: Command-line interface for scripting and automation.
* **PulseView**: GUI for waveform viewing, signal decoding, and triggering.

### 🔹 Supported Hardware:

* Saleae Logic (older models)
* DreamSourceLab DSLogic
* FX2-based cheap analyzers (8-channel, 24MHz clones)
* LogicPort, OpenBench Logic Sniffer

### 🔹 Website:

* [https://sigrok.org](https://sigrok.org)

---

## 🧰 **2. Saleae Logic Software**

### 🔹 Overview:

* **Proprietary**, but Linux-compatible.
* Powerful, user-friendly UI with mixed signal support.
* Supports **protocol decoding**, measurements, and scripting (via Logic 2 SDK and extensions).

### 🔹 Requirements:

* Only works with **Saleae Logic analyzers** (Logic 8, Logic Pro 16, etc.)

### 🔹 Website:

* \[[https://www.saleae.com\](](https://www.saleae.com]%28)[https://www.saleae.com/download](https://www.saleae.com/download)]\([https://www.saleae.com/download](https://www.saleae.com/download))

---

## 🧰 **3. Scopy (by Analog Devices)**

### 🔹 Overview:

* Designed for **Analog Devices’ ADALM2000** (an educational lab tool).
* Runs on Linux.
* Provides logic analyzer, oscilloscope, and waveform generator functionality.

### 🔹 Website:

* [https://www.analog.com/en/design-center/evaluation-hardware-and-software/eval-adalm2000.html](https://www.analog.com/en/design-center/evaluation-hardware-and-software/eval-adalm2000.html)

---

## 🧰 **4. LogicSniffer (OBLS-specific)**

### 🔹 Overview:

* Java-based GUI for the **Open Bench Logic Sniffer**.
* Older software but still usable for those devices.

### 🔹 Limitations:

* Not actively maintained.
* Basic UI and limited protocol support.

---

## ✅ Summary Table

| Software           | License     | GUI | Hardware Support                        | Linux Support |
| ------------------ | ----------- | --- | --------------------------------------- | ------------- |
| Sigrok + PulseView | Open-source | ✅   | Many brands (incl. cheap USB analyzers) | ✅             |
| Saleae Logic       | Proprietary | ✅   | Only Saleae hardware                    | ✅             |
| Scopy              | Free (ADI)  | ✅   | ADALM2000                               | ✅             |
| LogicSniffer       | Open-source | ✅   | OpenBench Logic Sniffer                 | ✅             |

---

