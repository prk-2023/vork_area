# AUD Nal Unit:
---
The **AUD (Access Unit Delimiter)** NAL unit is a special type of NAL unit used in video compression 
standards like **H.264 (AVC)** and **H.265 (HEVC)**. It serves as a marker or delimiter to indicate the 
boundaries of an **access unit** (AU). 
An **access unit** is typically a group of NAL units that together form a video frame or a sequence of 
frames, and the **AUD** is used to demarcate the start of this unit.

### **Purpose of the AUD NAL Unit**
The **AUD** NAL unit is designed to assist in identifying the beginning of an access unit within a video 
bitstream. 
An **access unit** is typically a picture or group of pictures (such as I-frames or IDR frames) that the 
decoder needs to decode in order to render the video content. 

The **AUD** provides a clear indication of where an access unit starts, which is useful for:
- **Stream synchronization**: It helps in identifying the correct place in the bitstream where the 
  video decoder should begin decoding to present a valid access unit.
- **Error recovery**: If there are errors in the bitstream, the **AUD** can be used to detect access unit 
  boundaries, enabling better error handling or recovery.
- **Seamless playback**: In streaming or real-time applications, the **AUD** ensures that the decoder knows
  exactly where a new access unit starts, improving smooth playback.

### **How to Identify the AUD NALU in the Bitstream**

To identify an **AUD NAL unit** in the bitstream, you need to look for the following characteristics:

#### 1. **NAL Unit Start Code**
   - As with all NAL units, an **AUD NAL unit** begins with a **start code** (usually `0x00 0x00 0x01` in 
     the bitstream).
   
#### 2. **NAL Unit Type**
   - The **NAL unit type** field in the **NAL header** indicates the type of NAL unit. 
   For an **AUD** NAL unit, the NAL unit type is:
     - **H.264 (AVC)**: `0x09` (decimal 9).
     - **H.265 (HEVC)**: `0x09` (decimal 9).
   
   This means that the **NAL unit type** for **AUD** is `9` in both **H.264** and **H.265**.

#### 3. **NAL Header**
   - The **NAL header** contains several bits, including the **NAL unit type** (which is `0x09` for **AUD**)
   and other flags that determine the reference status and priority of the frame.
   - For example, the **NAL header** in **H.264** and **H.265** will contain the **NAL unit type** field at
   a specific position (usually the 5th byte) of the byte stream.

#### 4. **AUD NALU Structure**
   After the **NAL header**, the **AUD** NAL unit typically contains a **single byte** of payload, which
   has a specific format. The structure for the **AUD NAL unit** in both **H.264** and **H.265** is very
   simple and usually consists of the following:
   - A **start code** (`0x00 0x00 0x01`).
   - The **NAL unit type** (which is `0x09` for **AUD**).
   - The **AUD payload** (which consists of a few bytes indicating the structure of the access unit).
   
---

### **Example of AUD NAL Unit in H.264**

In the **H.264** bitstream, an **AUD NAL unit** would typically look like this:

```
00 00 01 09 [AUD Payload Data]
```

Where:
- `00 00 01` is the **start code**.
- `09` indicates this is an **AUD NAL unit** (NAL unit type `9` in **H.264**).
- The **AUD payload** might consist of one or more bytes depending on the specific implementation and whether
any additional data is required.

The **AUD** in **H.264** is a very simple marker, and in many cases, the **AUD** NAL unit might not have 
additional data in the payload apart from the NAL header.

---

### **Example of AUD NAL Unit in H.265**

In **H.265**, the **AUD NAL unit** is structured in much the same way:

```
00 00 01 09 [AUD Payload Data]
```

Where:
- `00 00 01` is the **start code**.
- `09` indicates the **NAL unit type** for **AUD** (NAL unit type `9` in **H.265**).
- The **AUD payload** typically consists of a few bytes or no additional data, as the **AUD** serves as a 
delimiter rather than carrying substantive video data.

---

### **Payload of the AUD NAL Unit**

The **AUD** NAL unit generally carries very little information in the payload. The main purpose of the
**AUD** is to signal the start of an access unit. In some cases, the **AUD** may carry a
**presentation order number (PON)** or a **field of view (FOV)** information, but most of the time, the
**AUD** is used as a simple marker.

For example:
- In **H.264**, the **AUD payload** might consist of a single byte, and that byte typically doesn't carry
important video data—just a signal indicating the start of an access unit.
- In **H.265**, the structure is similar, though the specific implementation might involve additional 
details in the payload for synchronization or error recovery.

---

### **Practical Use of the AUD NAL Unit**
- **Error Handling and Recovery**: The **AUD** NAL unit is used in video bitstreams to detect access unit 
boundaries, which helps in error handling. When errors occur in streaming or transmission, the **AUD** can
be used to identify where an access unit begins, allowing for the decoder to attempt to recover from the
error and start decoding from a known boundary.
- **Video Playback**: During playback, the **AUD** ensures that the decoder knows where to begin decoding 
the next access unit, which is important for maintaining smooth playback, especially in streaming or 
low-latency scenarios.

---

### **Conclusion**
The **AUD (Access Unit Delimiter)** NAL unit is a special marker used in **H.264 (AVC)** and 
**H.265 (HEVC)** video bitstreams to signify the start of an **access unit**. 
The **AUD** does not carry video data itself but acts as a boundary marker to help decoders and media 
players identify the start of an access unit, which typically corresponds to a frame or group of frames. 

To identify an **AUD NAL unit** in the bitstream:
1. Look for the **NAL start code** (`0x00 0x00 0x01`).
2. Check the **NAL unit type** field in the **NAL header** (type `0x09` in both **H.264** and **H.265**).
3. Parse the simple **AUD payload** (usually consisting of minimal data).

The **AUD** is essential for ensuring proper access unit demarcation and stream synchronization, 
particularly in streaming and error recovery scenarios.

# AUD meta-data
---

The **AUD (Access Unit Delimiter)** NAL unit is a special NAL unit used to indicate the boundaries of
an **access unit** (AU) in video compression formats such as **H.264 (AVC)** and **H.265 (HEVC)**.
Unlike other NAL units (such as SPS, PPS, or SEI), the **AUD** NAL unit itself carries minimal or no 
significant video-related data. Its primary function is to mark the boundaries of an **access unit**,
which is a group of frames or a video frame that the decoder needs to process for proper video playback.

While the **AUD NAL unit** itself does not carry substantial metadata like color information, 
picture parameters, or display settings, it does provide essential metadata related to the boundary of 
access units in the bitstream.

### **Purpose of the AUD NAL Unit**
The **AUD** NAL unit is used primarily for:
- **Access Unit Delimiting**: It marks the boundary where an **access unit** (which typically consists of 
one or more pictures, like I-frames or IDR frames) begins in the bitstream.
- **Synchronization**: It helps synchronize the decoder by signaling the beginning of an access unit,
making it easier to determine where to start decoding.
- **Error Recovery**: In the event of a stream error, **AUD NAL units** help identify the beginning of 
an access unit so the decoder can try to recover from errors by restarting decoding from the boundary.

### **Meta-Data in the AUD NAL Unit**
While the **AUD** NAL unit is designed to be lightweight and minimal in terms of its actual data, it does
have a few pieces of **metadata** that provide the information necessary for access unit delimiting. 
This metadata is very simple compared to other NAL units that carry richer video or stream-related data.

#### **Key Metadata in the AUD NAL Unit**
1. **NAL Unit Type (NALU Type)**:
   - The **NAL unit type** in the **NAL header** defines the type of NAL unit. For the **AUD NAL unit**, 
   this field is set to `0x09` (decimal 9) in both **H.264 (AVC)** and **H.265 (HEVC)** standards. 
   This is the primary way to identify an **AUD NAL unit** in the bitstream.
   
   - In the **NAL header** of both H.264 and H.265, the **NAL unit type** is the key metadata that 
   distinguishes **AUD** from other types of NAL units. The **NAL unit type** is located in the 
   **first byte** (or the first few bits, depending on the format) of the NAL header.

2. **Access Unit Delimiter Payload**:
   - The **AUD NAL unit** generally does **not carry any substantial data** in its payload, unlike other 
   NAL units like SPS or PPS. The payload in an **AUD NAL unit** may contain minimal or no data at all in
   many cases.
   
   - **AUD payload** (if present) often serves as a simple indicator, marking the start of an access unit. 
   It may sometimes include flags or sequence numbers to help with stream synchronization in certain 
   implementations, but it is typically just a boundary marker with little data content.

   - For **H.264 (AVC)**, the **AUD** payload may include:
     - A **presentation order number (PON)** that helps to maintain the correct display order of access units.
   
   - For **H.265 (HEVC)**, the **AUD** may include:
     - A **frame number** or **field of view** information, depending on the specific configuration of the
     encoder or application.

3. **NAL Header**:
   - The **NAL header** in the **AUD NAL unit** contains information on how the unit should be processed by 
   the decoder, although it is very minimal. The fields in the **NAL header** include:
     - **Forbidden zero bit**: This is a reserved bit in the NAL header, which must be zero for valid NAL units.
     - **NAL Reference IDC (nal_ref_idc)**: This indicates the importance of the NAL unit and whether it is
     a reference for prediction purposes.
     - **NAL Unit Type**: As previously mentioned, the type `0x09` indicates an **AUD NAL unit**.
     - **RBSP (Raw Byte Sequence Payload)**: For **AUD**, this is typically very minimal or empty.

---

### **Structure of the AUD NAL Unit**

In terms of structure, the **AUD NAL unit** in the bitstream will typically appear as follows:

1. **Start Code**:
   - **0x00 0x00 0x01**: This marks the beginning of a NAL unit in the bitstream.

2. **NAL Header**:
   - The **NAL header** contains the **NAL unit type** field (`0x09` for **AUD**) along with other bits 
   that indicate the reference status, forbidden bit, and more. The **NAL unit type** is crucial for 
   identifying this as an **AUD** NAL unit.

3. **Payload (Optional)**:
   - In many cases, the **AUD NAL unit** does not contain any payload data or the payload may consist of 
   just a few bytes. If there is payload data, it typically involves:
     - **Presentation Order Number (PON)**: To track display order in H.264.
     - **Frame number or field of view**: In some implementations, to assist with synchronization or 3D video.

4. **End of NAL Unit**:
   - After the **AUD NAL unit** header and (optional) payload, the unit ends, and the next NAL unit begins
   with its own start code and header.

---

### **Example of AUD NAL Unit in the Bitstream**

- **H.264 Example**:
    ```
    00 00 01 09 [AUD Payload Data]  [Start of Next NAL Unit]
    ```

    Here:
    - `00 00 01` is the **start code**.
    - `09` indicates the **NAL unit type** for **AUD** (type `9` in **H.264**).
    - The **AUD payload** is minimal or could contain **Presentation Order Number (PON)** or 
      other information related to synchronization.
    - The **next NAL unit** begins after this.

- **H.265 Example**:
    ```
    00 00 01 09 [AUD Payload Data]  [Start of Next NAL Unit]
    ```

    Similarly:
    - `00 00 01` is the **start code**.
    - `09` indicates the **NAL unit type** for **AUD** (type `9` in **H.265**).
    - The **AUD payload** could include additional metadata like **frame number** or **field of view**.
    - The **next NAL unit** follows after the **AUD NAL unit**.

---

### **Conclusion**

The **AUD (Access Unit Delimiter)** NAL unit is a simple and lightweight marker used to indicate the 
boundaries of an **access unit** (AU) in a video bitstream. Its primary function is to help the decoder
identify where an access unit begins, enabling proper synchronization, stream handling, and error recovery.

The **metadata** in an **AUD NAL unit** is minimal and includes:
- **NAL unit type** (`0x09`), which helps identify the **AUD** NAL unit.
- A very small **payload**, which may include the **Presentation Order Number (PON)** or other optional
synchronization data, depending on the specific implementation and video standard (H.264 or H.265).
  
Since the **AUD** is not intended to carry substantial video data, it is primarily used for stream
management and access unit delimiting in video compression bitstreams.
