# PPS Nal Unit:
---
The **PPS (Picture Parameter Set)** NAL unit is an essential part of video compression standards like 
**H.264 (AVC)** and **H.265 (HEVC)**. 
Contains a set of parameters that define how a specific picture or group of pictures in a video stream is e
ncoded and decoded. 
The **PPS** NAL unit provides metadata related to slice-level encoding, filtering, quantization, and other 
encoding settings, which help the decoder interpret the encoded video correctly.

### **Purpose of the PPS NALU**

The **PPS** serves as a parameter set for individual pictures in the video stream. 
These parameters are applied to **pictures** or **frames**, determining how the video data is organized and
decoded. 
The **PPS** NAL unit works in conjunction with the **SPS (Sequence Parameter Set)** NAL unit, which 
contains settings for the entire video sequence (i.e., the entire sequence of frames), while the **PPS** 
contains settings for specific pictures.

In both **H.264** and **H.265**, the **PPS** typically includes:

- Information about **slice sizes** and **slice grouping**.
- Settings for **entropy coding** (whether **CABAC** or **CAVLC** is used).
- Parameters for **deblocking filters** to smooth out blockiness in decoded frames.
- Quantization settings and slice-specific details.
- Additional information that allows for efficient decoding of the picture.

### **How to Identify the PPS NALU in the Bitstream**

To identify a **PPS NAL unit** in a video bitstream, you can follow these steps:

#### 1. **NAL Unit Start Code**
- All NAL units in **H.264** & **H.265**, the **PPS** NAL unit begins with a **start code** (`0x00 0x00 0x01`).
  This marks the beginning of a NAL unit in the bitstream.

#### 2. **NAL Unit Type**
- After the start code, the **NAL unit type** is indicated by a **single byte** (the NAL header). 
  The NAL unit type specifies the kind of NAL unit.
  - In **H.264**, the **PPS** NAL unit type is `8` (decimal) or `0x08` (hexadecimal).
  - In **H.265**, the **PPS** NAL unit type is `4` (decimal) or `0x04` (hexadecimal).

#### 3. **NAL Header**
- The **NAL header** contains information about the NAL unit, such as the **NAL unit type** and other flags.
  The most important field here for identifying the **PPS** NAL unit is the **NAL unit type** field. 
  In the case of the **PPS**, it will be either `0x08` in H.264 or `0x04` in H.265.

#### 4. **PPS Payload**
- After the NAL header, the rest of the NAL unit is the **PPS payload**, which contains the actual metadata 
  (parameters) needed to decode the picture. The payload will include various parameters, such as:
  - **PPS ID**: Unique identifier for the PPS.
  - **Entropy coding method** (CABAC or CAVLC).
  - **Deblocking filter information** (whether deblocking is applied and its strength).
  - **Slice type** and quantization parameters.
  - Additional flags related to specific settings for decoding.

#### **Bitstream Example: Identifying PPS NALU**
Let's consider a simplified example of how a **PPS NAL unit** might appear in the bitstream.

    ```
    00 00 01 68 [PPS Header Byte(s)] [PPS Payload Data]
    ```
Here:
- `00 00 01` is the **start code** indicating the start of a NAL unit.

- `68` is the **NAL header** byte for the **PPS** NAL unit in **H.264** (since the NAL unit type for 
  **PPS** is `0x08`, which corresponds to `0x68` when combined with other header flags).

- The **PPS Payload** is the rest of the data following the header and contains the parameters specific to 
  the **PPS**, such as the **PPS ID**, quantization parameters, deblocking filter settings, and slice 
  configurations.

### **Structure of the PPS NALU**

The structure of the **PPS NAL unit** varies slightly between **H.264** and **H.265**, but generally, it 
includes the following key fields:

#### **H.264 PPS Structure**:
In **H.264**, the **PPS** structure typically includes:
- **PPS ID**: A unique identifier for the PPS.
- **SPS ID**: The **SPS ID** that links this PPS to a specific sequence parameter set (SPS).
- **Entropy Coding Mode**: Specifies whether **CABAC** or **CAVLC** is used for entropy coding.
- **Deblocking Filter Parameters**: Whether the deblocking filter is enabled and any relevant parameters.
- **Pic Size Parameters**: Parameters related to the dimensions of the picture (e.g., slice dimensions).
- **Weighted Prediction**: Information about weighted prediction used for P-slices and B-slices.
  
#### **H.265 PPS Structure**:
In **H.265**, the **PPS** has similar parameters but may include additional fields specific to the more 
complex features of HEVC, such as:

- **PPS ID**: A unique identifier for the PPS.
- **SPS ID**: The **SPS ID** that links this PPS to an SPS.
- **Slice-level settings**: Information on how slices are encoded.
- **Deblocking Filter Flags**: Flags for enabling or disabling the deblocking filter and settings like 
  strength.
- **Scaling List Parameters**: Defines how scaling is applied to the coefficients for the residual data.
- **Weighting Prediction**: Information about how motion vectors are weighted.

### **Example in H.264** (Simplified):
Here’s an example showing a **PPS NAL unit** in a bitstream:
```
00 00 01 68 45 00 00 1f 00 00 00 01 00 00 00 00 03 00
00 00 00 02 00 00 00 01 01 00 00 00 00
```
- `00 00 01` is the **start code**.
- `68` is the **NAL header** with the **PPS** NAL unit type (`0x08`).
- The subsequent bytes represent the **PPS payload**, containing parameters like the **PPS ID**, **SPS ID**, 
  **entropy coding method**, **deblocking filter**, and other configuration data.

### **Conclusion**
The **PPS (Picture Parameter Set)** NAL unit is a critical part of the **H.264** and **H.265** video 
compression standards, providing metadata for how individual pictures or frames are encoded and decoded. 
To identify a **PPS NAL unit** in a bitstream:

1. Look for the **start code** (`0x00 0x00 0x01`).
2. Check the **NAL unit type** in the **NAL header** (`0x08` for **H.264** or `0x04` for **H.265**).
3. Parse the **PPS payload** to extract important parameters, such as **PPS ID**, **slice settings**, 
  **entropy coding**, **deblocking filter**, and other decoding configurations.

The **PPS** NAL unit is essential for the correct decoding of video, ensuring that picture-level 
configurations are applied properly throughout the video stream.

# PPS Nal Meta-data:
The **PPS (Picture Parameter Set)** NAL unit in **H.264 (AVC)** and **H.265 (HEVC)** video encoding holds 
essential metadata related to a group of pictures (GOP) or a picture within a sequence, helping the decoder 
interpret and decode the picture accurately. 
The **PPS** works alongside the **SPS (Sequence Parameter Set)** and the **VPS (Video Parameter Set)** 
(in the case of H.265) to configure the decoding process, providing parameters that apply to the pictures 
within the stream.

### **Purpose of the PPS NAL Unit**

The **PPS** contains parameters that apply to a group of pictures or a single picture in the video stream. 
It provides metadata needed by the decoder for decoding individual pictures based on the settings provided
by the **SPS** (in H.264) or **VPS** (in H.265). 
The parameters defined in the **PPS** allow the decoder to understand how to handle specific picture-level 
encoding features, such as slice size, prediction types, and quantization.

### **Metadata in the PPS NAL Unit**
In both **H.264 (AVC)** and **H.265 (HEVC)**, the **PPS NAL unit** contains various fields or parameters 
that define how the picture (or group of pictures) is encoded. Here is a breakdown of the key metadata 
fields in the **PPS**:

#### **1. PPS ID (PPS Identifier)**

- **PPS ID** is a unique identifier for the **PPS**. Each **PPS** in the stream must have a different ID, 
  which helps the decoder identify which parameter set applies to the current picture or group of pictures.

- In both **H.264** and **H.265**, the **PPS ID** is used to link a **PPS** to a specific sequence of 
  pictures and to indicate which settings should be applied when decoding the associated picture.

#### **2. Picture Size and Slice Parameters**

- This metadata defines settings related to how slices are encoded within the picture.
  - **Slice group settings**: In both **H.264** and **H.265**, pictures may be divided into multiple slices 
    or slice groups. A slice group helps with parallel processing or error resilience.

  - **Max slice size**: Defines the maximum size of each slice for encoding, affecting the efficiency of 
    compression and the ability to decode slices independently. 

#### **3. Entropy Coding Mode**

- **Entropy coding** is the process of encoding symbols based on their statistical properties, typically 
  using techniques like **CABAC (Context-Adaptive Binary Arithmetic Coding)** or **CAVLC 
  (Context-Adaptive Variable-Length Coding)**.

  - **CABAC** is more computationally complex but provides better compression efficiency.
  - **CAVLC** is simpler and faster but provides lower compression efficiency.

- The **PPS** specifies which entropy coding method is used for the current picture.

#### **4. Weighted Prediction Parameters**

- The **PPS** contains metadata that specifies whether **weighted prediction** is used for inter-prediction 
  in **P-slices** and **B-slices**. Weighted prediction allows for more accurate motion compensation by 
  adjusting the predicted values based on weights for the reference frames.

- Parameters related to **weighted prediction** may include the weights for the **motion vectors** and how 
  the weighted prediction is applied across slices or frames.

#### **5. Transform Skip Flag**

- The **transform skip flag** indicates whether the **transform skip** mode is used for encoding. 
  When enabled, transform skip reduces the computational complexity during encoding by skipping the 
  transform step (which is normally applied to residual data). 
  This is useful for encoding high-quality video or when computational efficiency is more critical than 
  compression efficiency.

#### **6. Deblocking Filter Parameters**

- The **deblocking filter** helps smooth out block boundaries in video frames by filtering the edges of 
  macroblocks or coding units, which reduces visible blockiness or artifacts.
- The **PPS** specifies whether the **deblocking filter** should be applied to the picture, as well as any 
  related parameters such as the **filter strength** or **filtering on/off** for specific regions of the pic.
  - In **H.264**, the **PPS** contains information about the deblocking filter settings.
  - In **H.265**, the filter settings are applied at a more granular level, and the **PPS** provides the 
  relevant filtering flags.

#### **7. Constrained Intra Prediction Flag (H.264)**

- In **H.264**, the **PPS** includes the **constrained intra prediction flag**, which indicates whether 
  **intra prediction** should be restricted to certain neighboring blocks. 
  This flag is used to control whether the decoder can predict a block based solely on the current frame 
  or should rely on neighboring blocks that are decoded from previous frames.

#### **8. Slice QP (Quantization Parameter)**
- **Quantization** is a process that reduces the precision of the residual data to achieve compression. 
  The **PPS** may include metadata related to the **slice QP** values, which control the quantization level 
  applied to the residual data in a slice.

- The **PPS** allows for different QP values to be applied to various slices within a picture, enabling 
  finer control over the compression versus quality trade-off.

#### **9. GOP Structure Information (In H.264)**

- The **PPS** in **H.264** can also include metadata related to the **GOP (Group of Pictures)** structure. 
  The GOP structure defines the sequence of I-frames, P-frames, and B-frames that make up the video.

  - The **PPS** may contain information on how many **B-frames** can be between **I-frames** & **P-frames** 
    in the GOP structure, influencing video encoding and decoding.

#### **10. SPS Link (H.265)**

- In **H.265**, the **PPS** is linked to the **SPS (Sequence Parameter Set)**, which defines settings for 
  the entire sequence of pictures. The **PPS** can reference the **SPS ID**, indicating which **SPS** 
  parameters apply to the current picture.
- The **SPS** contains global settings, while the **PPS** provides specific parameters for each picture.

#### **11. Miscellaneous Flags**
- **Pic order count type**: The PPS specifies how the picture order count (POC) is handled, which affects 
  how pictures are ordered and presented for decoding.
- **Scaling lists**: The **PPS** may include **scaling list parameters** that control how the transformation 
  coefficients are scaled, allowing for finer control over the quality versus compression of the video.

### **How to Identify the PPS NAL Unit in the Bitstream**
To identify a **PPS NAL unit** in the bitstream:

1. **Look for the Start Code**: As with all NAL units, the **PPS NAL unit** begins with the standard start 
   code (`0x00 0x00 0x01`), which indicates the beginning of a NAL unit.

2. **Check the NAL Unit Type**: The **NAL header** (following the start code) contains the **NAL unit type**, 
   which for the **PPS** is typically:
   - **H.264**: `8` (PPS NAL unit).
   - **H.265**: `4` (PPS NAL unit).

3. **Parse the PPS Payload**: After the NAL header, the **PPS payload** contains the metadata parameters, 
   including the **PPS ID**, slice parameters, entropy coding mode, and other encoding-related settings.

### **Example of PPS Metadata in the Bitstream**

A simplified example of the **PPS NAL unit** bitstream might look like this (after the start code):
```
00 00 01 68 [PPS Header Byte(s)] [PPS Metadata Payload]
```
- `00 00 01` is the **start code**.
- `68` is the **NAL header byte**, which indicates a **PPS** NAL unit.
- The **PPS metadata payload** will contain all the parameters such as the **PPS ID**, **slice size**, 
  **entropy coding mode**, and other encoding settings.

### **Conclusion**
The **PPS (Picture Parameter Set)** NAL unit in **H.264** and **H.265** video contains important metadata 
that defines how to decode a picture or group of pictures within a sequence. 
The metadata in the **PPS** includes slice parameters, entropy coding mode, deblocking filter settings, 
quantization parameters, and other encoding-related information. This metadata is crucial for the decoder 
to process the video correctly, and the **PPS** works together with the **SPS (Sequence Parameter Set)** 
and **VPS (Video Parameter Set)** (in H.265) to provide complete configuration for the video stream.
