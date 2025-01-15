# SPS Nal Unit:
---
The **SPS (Sequence Parameter Set)** NAL unit is a crucial element in video encoding standards like 
**H.264 (AVC)** and **H.265 (HEVC)**. 
It provides metadata and parameters about the video sequence, such as resolution, frame rate, and color 
information, that are required for proper decoding of a video stream. 
The **SPS** helps the decoder understand how the video is structured and provides high-level information 
about the video, such as how frames are encoded, the frame sizes, chroma formats, and more.

### **Purpose of the SPS NALU**
The **SPS** defines the sequence-wide settings for a video stream and applies to all pictures (frames) 
within the sequence. This includes information that is common across the entire sequence, like:
- **Resolution**: The width and height of the video.
- **Frame rate**: The number of frames per second.
- **Chroma format**: The color space (e.g., YUV 4:2:0, 4:4:4).
- **Bit depth**: How many bits are used for representing color channels.
- **Picture order**: How frames are ordered during decoding and display.

The **SPS** is often used in conjunction with the **PPS (Picture Parameter Set)** NAL unit, which provides 
parameters for individual pictures or groups of pictures within the sequence.

### **How to Identify the SPS NALU in the Bitstream**

To identify an **SPS NAL unit** in the bitstream, you need to locate the **NAL start code**, then examine 
the **NAL unit type** within the **NAL header**. Here's the step-by-step process:

#### 1. **NAL Unit Start Code**

- Every NAL unit in the bitstream starts with a **start code**: `0x00 0x00 0x01`.
- This indicates the beginning of a NAL unit, followed by the NAL header and payload.

#### 2. **NAL Unit Type**

- After the start code, the **NAL header** contains information about the NAL unit type. 
  The NAL unit type is a field in the header that tells you the kind of NAL unit (e.g., SPS, PPS, slice, etc.).
- In **H.264**, the **SPS** NAL unit has a **type of `7`** (decimal), which means the NAL unit type is 
  `0x07` (hexadecimal).
- In **H.265**, the **SPS** NAL unit also has a **type of `33`** (decimal), meaning the NAL unit type is 
  `0x21` (hexadecimal).

#### 3. **NAL Header**

- The **NAL header** includes not only the **NAL unit type** but also flags (such as the 
  **forbidden zero bit** and the **NRI (NAL reference indicator)**). 
  The most important part for identifying the **SPS** NAL unit is the **NAL unit type**.
  - **H.264**: NAL unit type for **SPS** is `7` (decimal).
  - **H.265**: NAL unit type for **SPS** is `33` (decimal).

#### 4. **SPS Payload**

- After the NAL header, the rest of the NAL unit is the **SPS payload**, which contains the sequence parameters (e.g., resolution, chroma format, frame rate, etc.).
- The **SPS payload** is structured with various parameters that help the decoder configure the video decoding process.

### **Bitstream Example: Identifying SPS NALU**

A simplified example of how an **SPS NAL unit** might appear in the bitstream (H.264) is as follows:
```
00 00 01 67 [SPS Header Byte(s)] [SPS Payload Data]
```
Here:
- `00 00 01` is the **start code**.
- `67` is the **NAL header** byte for the **SPS** NAL unit in **H.264** (since the NAL unit type for 
  **SPS** is `0x07`, which corresponds to `0x67` when combined with other header flags).
- The **SPS Payload** is the rest of the data after the header, containing the parameters for the sequence 
  (such as resolution, bit depth, etc.).

### **Structure of the SPS NALU**

The structure of the **SPS** differs slightly between **H.264** and **H.265**, but they share similar 
high-level concepts. The **SPS** typically includes the following key parameters:

#### **H.264 SPS Structure**
In **H.264**, the **SPS** NAL unit includes:
1. **SPS ID**: A unique identifier for the SPS, linking it to specific **PPS** NAL units.
2. **Profile ID**: Defines the profile used for encoding (e.g., Baseline, Main, High).
3. **Level**: Defines the encoding complexity (e.g., Level 4.1, Level 5.1).
4. **Width and Height**: The width and height of the video resolution.
5. **Frame Rate**: The number of frames per second.
6. **Chroma Format**: Defines the chroma (color) format, like 4:2:0 or 4:4:4.
7. **Bit Depth**: Defines the bit depth used to represent color channels (e.g., 8 bits, 10 bits).
8. **Other sequence parameters**: Includes information like reference frames, aspect ratio, and video 
   coding settings.

#### **H.265 SPS Structure**
In **H.265**, the **SPS** NAL unit contains similar parameters but also includes additional fields to 
support more advanced features in HEVC:

1. **SPS ID**: A unique identifier for the SPS.
2. **Profile and Tier**: Information about the encoding profile and tier (e.g., Main, Main10).
3. **Level**: Defines the HEVC encoding level (e.g., Level 3.1, Level 5.2).
4. **Width and Height**: The resolution of the video in terms of width and height.
5. **Chroma Format**: Defines the chroma format, like 4:2:0 or 4:4:4.
6. **Bit Depth**: Defines the bit depth of the video stream.
7. **Frame Rate and Timing Info**: Information about how frames are timed and presented.
8. **Reference Picture List Size**: Specifies the number of reference pictures used in inter-picture prediction.
9. **Other sequence parameters**: Like scaling lists, weighted prediction, and more.

### **Example of SPS NALU in H.264**
For **H.264**, the bitstream may look like this:
```
00 00 01 67 42 00 1f d8 20 13 01 02 04 04 18 00 00
```
Here:
- `00 00 01` is the **start code**.
- `67` indicates that the NAL unit type is `7` (SPS).
- The rest (`42 00 1f d8 20 13 01 02 04 04 18 00 00`) represents the **SPS payload**, containing sequence 
  parameters such as resolution, chroma format, bit depth, etc.

### **Example of SPS NALU in H.265**
For **H.265**, the bitstream may look like this:
```
00 00 01 42 01 01 10 00 1f d8 00 00 00 04 00 00 00 03
```
Here:
- `00 00 01` is the **start code**.
- `42` indicates that the NAL unit type is `33` (SPS) in **H.265**.
- The rest (`01 01 10 00 1f d8 00 00 00 04 00 00 00 03`) represents the **SPS payload**, containing various 
  parameters for the video sequence.

### **Conclusion**
The **SPS (Sequence Parameter Set)** NAL unit is a vital part of video encoding in **H.264** and **H.265**. 
It provides important parameters about the video sequence, such as resolution, frame rate, chroma format, 
and bit depth, which are essential for the correct decoding and display of the video. 

To identify an **SPS NAL unit** in the bitstream:

1. Look for the **start code** (`0x00 0x00 0x01`).
2. Check the **NAL unit type** in the **NAL header** (`0x07` for **H.264** and `0x21` for **H.265**).
3. Parse the **SPS payload** to extract the sequence parameters.

The **SPS NAL unit** is typically the first NAL unit in the stream and is followed by other parameter sets like the **PPS (Picture Parameter Set)** and **slice** NAL units.

# SPS - Meta-data:
---
The **SPS (Sequence Parameter Set)** NAL unit in video compression standards such as **H.264 (AVC)** and 
**H.265 (HEVC)** contains important meta-data that defines the overall characteristics of the video stream. 
This metadata allows the decoder to correctly interpret and decode the video frames by providing essential 
information about the sequence-wide settings (such as resolution, frame rate, bit depth, and chroma format). 
These parameters are used for the entire sequence of video pictures (frames).

### **Purpose of the SPS NAL Unit**

The **SPS** provides a set of global parameters that apply to the entire sequence of encoded video frames, 
as opposed to parameters that apply to individual pictures (which are typically stored in the **PPS 
(Picture Parameter Set)**). The **SPS** helps the decoder interpret the video stream and sets the stage for 
the decoding of the individual frames (or pictures) within that sequence.

### **Key Metadata in the SPS NAL Unit**

The metadata in the **SPS** NAL unit includes a variety of fields that describe the video sequence. 
These fields help the decoder understand the sequence structure and how to process the bitstream effectively. 
Below is a breakdown of the key metadata in the **SPS** NAL unit for both **H.264** and **H.265**.

---

### **Metadata in H.264 SPS (Sequence Parameter Set)**

In **H.264**, the **SPS** NAL unit typically contains the following key fields:

1. **SPS ID (Sequence Parameter Set ID)**
   - A unique identifier for the **SPS**. 
   This ID links the **SPS** to the relevant **PPS** NAL units and slices in the bitstream.
   
2. **Profile ID**
   - Indicates the **H.264 profile** used for encoding. For example:
     - `Baseline` profile (Profile ID: 66).
     - `Main` profile (Profile ID: 77).
     - `High` profile (Profile ID: 100).
   - The profile specifies a set of features and constraints used during encoding 
     (e.g., supported compression methods, slice structures, etc.).

3. **Level**
   - Specifies the **level** of encoding complexity for the video stream. 
     This determines the maximum values for parameters such as frame size, bitrate, and decoding speed.
   - Examples: Level 3.1, Level 4.1, etc. Higher levels allow for more complex features 
     (such as higher resolutions or higher bitrates).

4. **Sequence Parameter Set Flags**
   - These flags indicate specific settings that affect how the sequence is encoded and decoded. 
     For example:
     - **Constraint Flags**: Indicate whether certain features (ex B-frm or CABAC) are enabled or disabled.
     - **Decoding Flags**: Indicate how pictures are presented and decoded in the sequence.

5. **Video Resolution (Width and Height)**
   - The width and height of the video in pixels. These values define the frame size (ex 1920x1080 for FullHD).
   
6. **Frame Rate**
   - The number of frames per second (FPS) at which the video is intended to be displayed. 
     This is essential for timing and presentation of frames.
   - The frame rate is usually conveyed as a rational number (e.g., 24/1 for 24 fps).

7. **Chroma Format**
   - Specifies the **chroma sampling** format, which indicates how color information is encoded relative to 
     luminance (brightness).
     - **4:2:0**: Most common format (used in consumer video).
     - **4:2:2**: Higher quality format, used in professional video.
     - **4:4:4**: Full chroma resolution (rare, used for high-quality video).

8. **Bit Depth**
   - Specifies the number of bits used to represent each color channel (luminance and chrominance). 
     Common bit depths are:
     - 8-bit: Standard for most video.
     - 10-bit: Often used in professional video or HDR content.

9. **Profile Compatibility**
   - A field that indicates which profiles are compatible with the current profile. 
   This can help with decoding in cases where the video stream can be decoded with multiple profiles.

10. **Reference Frames**
    - Specifies the number of reference frames available for inter-frame prediction. 
      This is important for how motion compensation is applied during decoding.
    - **Reference frame list size**: The max number of reference frames used for inter-picture prediction.

11. **Entropy Coding**
    - Indicates the type of **entropy coding** used in the stream.
      **CABAC (Context-Adaptive Binary Arithmetic Coding)** and 
      **CAVLC (Context-Adaptive Variable-Length Coding)** are the two main coding methods:

      - **CABAC** provides better compression but is computationally heavier.
      - **CAVLC** is simpler and more lightweight but provides less compression efficiency.

12. **Aspect Ratio**
    - Specifies the aspect ratio of the video (e.g., 16:9, 4:3). 
    This is important for scaling the video correctly when presented on different devices.

13. **VUI (Video Usability Information)**
    - **VUI** contains additional parameters that can provide further details about how the video should 
      be displayed, such as:
      - **Timing Information**: To ensure the proper presentation of frames.
      - **SAR (Sample Aspect Ratio)**: Defines how individual pixels are scaled.
      - **Color Primaries, Transfer Characteristics, and Matrix Coefficients**: These fields help specify 
        how the color information should be interpreted (important for color accuracy).

---

### **Metadata in H.265 SPS (Sequence Parameter Set)**

In **H.265**, the **SPS** is more advanced and includes additional fields to support more complex features 
of **HEVC**. Key metadata in **H.265 SPS** includes:

1. **SPS ID**
   - A unique identifier for the **SPS**, linking it to the relevant **PPS** NAL units and slices.

2. **Profile and Tier**
   - **Profile**: Specifies the encoding profile (e.g., Main, Main10, etc.).
   - **Tier**: Specifies whether the profile is a **Main Tier** (standard profile) or a **High Tier** 
     (for higher resolutions or bit depths).
   
3. **Level**
   - Defines the level of encoding complexity, similar to **H.264**. 
   In **H.265**, the levels are designed to allow higher resolutions (e.g., 4K, 8K) and better bit depth 
   (e.g., 10-bit or higher).

4. **Chroma Format**
   - The chroma format field defines how color is represented in the video stream (e.g., **4:2:0**, 
     **4:2:2**, or **4:4:4**).

5. **Bit Depth**
   - Specifies the number of bits used to represent each pixel, with **H.265** supporting higher bit depths, 
     such as **10-bit** and **12-bit**.

6. **Resolution**
   - Specifies the resolution of the video, including the width and height in pixels, just like in **H.264**.

7. **Frame Rate**
   - Specifies the frame rate for the sequence (frames per second). This field is used to ensure the correct
     timing of frames.

8. **Timing Info**
   - Provides more detailed timing information for decoding and displaying the frames, such as 
     **decode time** and **display time**.

9. **Reference Picture List Size**
   - Specifies the number of reference frames used for motion compensation in inter-prediction.

10. **Scaling Lists**
    - Defines how **scaling lists** are applied to residuals, which impacts compression efficiency and 
      quality.

11. **Deblocking Filter Parameters**
    - Indicates whether the deblocking filter should be applied and specifies the strength or behavior of 
      the filter.

12. **Video Usability Information (VUI)**
    - Similar to **H.264**, the **VUI** in **H.265** provides additional information about the video, such 
      as color primaries, transfer characteristics, and matrix coefficients.

13. **Intra Prediction**
    - Specifies whether **intra prediction** is used (for encoding I-frames), and other details related to 
      intra-frame prediction.

14. **Additional Flags**
    - Includes various flags indicating how the video stream should be decoded, such as whether 
      **CABAC** or **CAVLC** is used for entropy coding.

---

### **Example of SPS NAL Unit in H.264 (Simplified)**

A simplified example of an **SPS NAL unit** in an H.264 bitstream might look like this:

```
00 00 01 67 42 00 1f d8 20 13 01 02 04 04 18 00 00
```

- `00 00 01` is the **start code**.
- `67` indicates this is an **SPS NAL unit**.
- The remaining bytes represent the **SPS metadata**: profile, level, resolution, frame rate, etc.

---

### **Conclusion**
The *SPS (Sequence Parameter Set)** NAL unit is crucial for encoding and decoding video streams in both 
**H.264 (AVC)** and **H.265 (HEVC)**. 
It provides essential metadata that applies to the entire video sequence, including information on the 
profile, level, resolution, chroma format, bit depth, frame rate, and reference frames. 
This metadata allows the decoder to configure itself properly for decoding and displaying the video, 
ensuring that the stream is processed efficiently and accurately.
