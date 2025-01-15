# VPS Nal Unit:
---

### **VPS (Video Parameter Set) NALU**

A **VPS (Video Parameter Set)** is a specific type of NAL unit in the **H.265 (HEVC)** video encoding 
standard. It contains parameters necessary to describe the configuration of a video stream, specifically 
those that apply to the video sequence as a whole. 
These parameters are used by the decoder to decode the video properly and are essential for setting up the 
decoding context. 
The VPS holds important information, including details about the sequence and coding structure, and helps 
the decoder understand the entire video stream's configuration.

### **Purpose of VPS:**

The **VPS** in H.265 serves as a container for high-level information related to the video stream. 
This is similar to the **SPS (Sequence Parameter Set)** in H.264, but the VPS has more advanced capabilities 
due to the improvements in H.265/HEVC. 
The **VPS** is typically used in scenarios where multiple coding layers or hierarchical video streams are 
involved, such as in multi-layer video coding or multi-resolution video.

### **Key Information Stored in the VPS:**

The VPS includes critical information that helps the decoder to:
- Understand the video resolution, frame rates, color spaces, and other essential attributes.
- Configure the decoder for multi-layer (scalable) video coding setups.
- Handle advanced features, such as color primaries and chroma subsampling, which are important for video 
  formats like HDR (High Dynamic Range).
- Establish video decoding parameters for advanced use cases (e.g., 3D video, 4K, 8K, or multi-view video).

### **VPS NALU in H.265 (HEVC)**

The **VPS NALU** specifically stores the Video Parameter Set, and it is essential for configuring the 
decoder to understand the video sequence.

#### **VPS NALU Type in H.265**:

In the H.265 (HEVC) bitstream, each NAL unit is preceded by a **1-byte start code** (typically `00 00 01`), 
followed by the **NAL header**, which contains information about the NAL unit's type. 
The **VPS NAL unit** has a specific type identifier:

- **NALU Type for VPS**: **32** (decimal) or **0x20** (hexadecimal).

This means that the **VPS NALU** can be identified by checking if the NAL unit's type is **32**.

### **How to Identify a VPS NALU in the Bitstream**
To identify a **VPS NALU** in the bitstream, follow these steps:

1. **Look for the Start Code**:
   - Every NAL unit in the H.265 bitstream begins with a start code of **`0x00 0x00 0x01`**.
   - This is used to signal the beginning of each NAL unit.

2. **Check the NAL Unit Type**:
   - After the start code, the next byte(s) contain the **NAL header**, which includes the **NAL unit type**.
   - The NAL unit type is typically stored in the **first byte** of the header, where the first 5 bits 
     specify the NAL unit type.
   
   In H.265, the NAL unit type for **VPS** is `32` (decimal), which is represented by `0x20` (hexadecimal).

   Example of the NAL header in binary format:
   ```
   NAL Header Byte:
   [ 0 | 0 | 0 | 0 | 0 | 0 | 0 | NAL Unit Type (5 bits) ]
   ```

   For **VPS**, the NAL unit type will be `32`, which translates to:
   ```
   NAL Unit Type (32) = 100000 (binary)
   ```

3. **Extract and Parse the VPS Data**:
   - After the NAL header, the data that follows contains the **VPS payload**.
   - The VPS payload will include all the parameters necessary to configure the decoder for the video sequence.

### **Example of Identifying VPS in the Bitstream**

Given the following bitstream:
```
00 00 01 40 [VPS data]
```

- `00 00 01` is the **start code** indicating the beginning of a NAL unit.

- `40` is the **NAL header byte**, and the first 5 bits of `40` (`100000`) indicate the **NAL unit type** 
  of `32`, which corresponds to the **VPS** NAL unit.

- The subsequent bytes represent the **VPS payload**, which contains the actual Video Parameter Set info.

### **Summary**
The **VPS NAL unit** in **H.265 (HEVC)** holds high-level configuration information about the video stream.
To identify a VPS NAL unit in the bitstream:

1. Look for the **start code** (`0x00 0x00 0x01`).
2. Check the **NAL header** for a NAL unit type of `32` (decimal) or `0x20` (hexadecimal).
3. The **VPS payload** follows the NAL header and contains the Video Parameter Set data, which provides 
   critical information for decoding the video stream.

Understanding the VPS is important for applications involving complex video setups, such as multi-layered 
or scalable video coding.


# VPS meta-data:

The **VPS (Video Parameter Set)** NAL unit in **H.265 (HEVC)** video encoding contains critical 
configuration parameters that are needed to decode and process a video stream. 
The VPS is an important part of the video stream as it defines high-level parameters about the entire video 
sequence. 
This NAL unit allows the decoder to understand the configuration of the video, including information about 
the encoding settings, resolution, frame rates, and other aspects of the video stream that are needed for 
proper decoding.

The **VPS NAL unit** contains **metadata** that describes how the entire video stream should be decoded. 
This metadata is typically applied to all frames in the video sequence, making it one of the first pieces of 
information transmitted in the bitstream.

### **Purpose of the VPS NAL Unit**

The **VPS** serves to:
- Define key parameters for video decoding.
- Set up the **SPS (Sequence Parameter Set)** and **PPS (Picture Parameter Set)**.
- Handle advanced features like multi-layer video coding, higher resolution, and chroma formats.
- Convey information required for things like **high dynamic range (HDR)**, **multi-view**, or **3D video**.

### **VPS Metadata (Fields)**

The **VPS** NAL unit contains multiple fields in its payload that define essential parameters. 
The metadata within the **VPS NAL unit** in H.265 includes the following key fields:

1. **VPS ID**:

   - **VPS ID** a unique identifier for the **VPS**. 
   Each VPS NAL unit has a distinct ID, allowing the decoder to identify which parameter set is being used.

   - This is crucial in scenarios where multiple **VPSs** are used in a video stream, such as in multi-layer 
   video coding or multi-resolution setups.

2. **Max Sub Layers**:

   - This field specifies the number of sub-layers in the video stream. A **sub-layer** refers to different
     levels of video quality or resolution. For ex, in scalable video coding, a stream might contain 
     multiple layers with different resolutions, and this field defines how many layers exist.

   - **Sub-layer** information is especially important for **scalable video coding** (SVC) where multiple 
     video layers are encoded, and decoding requires knowing how many layers to process.

3. **Chroma Format**:
   - This field specifies the **chroma format** used for the video. 
     The chroma format defines how the color components (chroma) are represented relative to the luma 
     (brightness) component in the video. For example:

     - **4:4:4**: Full color resolution (no chroma subsampling).
     - **4:2:2**: Half chroma resolution in horizontal direction.
     - **4:2:0**: Common format used for most video (half chroma resolution both horizontally & vertically)

   - The **chroma format** helps the decoder understand how to handle the color information for correct rendering.

4. **Bit Depth**:
   - This field specifies the **bit depth** used in the video stream. Bit depth defines the number of bits
     used to represent each pixel's color channels (luma and chroma). 
     A higher bit depth allows for more color precision and is crucial for high-quality video, especially 
     in high dynamic range (HDR) content.

   - Common bit depths include:
     - **8 bits** per channel (standard for most video).
     - **10 bits** per channel (used for HDR or higher-quality video).

5. **Video Full Range Flag**:

   - This flag indicates whether the video uses **full-range color** or **limited-range color**.
     - **Full range**: The color values span the entire range (0 to 255 for 8-bit, or 0 to 1023 for 10-bit).
     - **Limited range**: The color values are restricted (ex: 16 to 235 for 8bit video in broadcast formats).
   - This metadata is important for correctly interpreting the brightness and color in the decoded video.

6. **Timing Information**:

   - This part of the metadata provides **timing-related information** such as frame rate or temporal 
   synchronization. This ensures that the video is decoded and displayed at the correct time relative to 
   other frames, particularly for synchronization with audio or in live streaming applications.

   - It may also include information related to **frame rate** (e.g., 24 fps, 30 fps, 60 fps) or 
   **frame timing** adjustments for smooth playback.

7. **Max Picture Width and Height**:

   - These fields specify the **maximum width** and **maximum height** of the video frames in the sequence. 
     This is crucial for the decoder to allocate the appropriate memory and resources for video processing.
   - The maximum width and height represent the dimensions of the largest picture that could appear in the 
     video stream, which is important for setting up the video buffer.

8. **Sequence Scaling Information**:
   - This field can provide **scaling information** that may be used to adjust the picture size based on the 
     viewing conditions or decoder capabilities. 
     This can be useful for applications like streaming where video resolution might change dynamically to 
     accommodate different network conditions or display sizes.

9. **Layered Coding and Multiview Information**:
   - If the video stream includes **layered coding** (e.g., multi-resolution or multi-view), the VPS 
     includes information about the layers.
   - **Multiview** refers to multiple video perspectives (such as in 3D or panoramic video), and the VPS 
   metadata can include how to decode each view layer.

10. **Color Primaries and Color Matrix**:
    - This specifies the **color primaries** and **color matrix** used in the video. 
      These parameters define how colors are represented in terms of red, green, and blue primary colors 
      and the mathematical transformation between color spaces.
    - This is important for **HDR** content or videos with wide color gamuts, ensuring that the color 
      representation matches the display device's capabilities.

11. **General Decoder Configuration Information**:
    - The VPS also contains **general configuration data** that might be necessary for specific video 
      decoders to handle features like **HDR**, **3D**, or **high frame rate** video. 
      This can include details such as metadata for optimal decoding parameters based on specific display 
      technologies.

### **VPS Metadata Example**
Here is an example of how some of the key metadata fields in a VPS might appear:

- **VPS ID**: 0
- **Max Sub Layers**: 3 (indicating 3 video layers or sub-layers)
- **Chroma Format**: 4:2:0 (standard chroma format)
- **Bit Depth**: 10 (higher bit depth for improved color precision)
- **Full Range Flag**: True (indicating full-range color)
- **Timing Information**: Frame rate of 30 fps
- **Max Picture Width**: 1920 pixels
- **Max Picture Height**: 1080 pixels
- **Layered Coding**: Not used (single-layer video)
- **Color Primaries**: BT.709 (standard for HD video)
- **Color Matrix**: BT.709 (standard color matrix for HD)

### **How to Identify the VPS NAL Unit in the Bitstream**
To identify the **VPS NAL unit** in the bitstream:

1. **Start Code**: Like all NAL units in H.265, the VPS starts with a **start code** (`0x00 0x00 0x01`).
2. **NAL Header**: The NAL header byte(s) immediately after the start code contains the **NAL unit type**, 
   which for **VPS** is `32` (decimal) or `0x20` (hexadecimal).
3. **VPS Payload**: After the NAL header, the **VPS payload** follows, containing all the metadata 
   information mentioned above (like `VPS ID`, `max sub-layers`, `chroma format`, etc.).

### **Summary**
The **VPS NAL unit** in **H.265 (HEVC)** video contains metadata that defines essential parameters for 
decoding the entire video sequence. The metadata in the VPS includes information like:

- **Chroma format**, **bit depth**, and **color primaries**.
- **Timing and scaling information** for the video stream.
- Information for **multi-layer video coding** and **multiview** (e.g., 3D).
- **Maximum resolution** and **decoder configuration** details.

By providing this crucial information, the VPS ensures that the decoder can correctly interpret and display 
the video according to its configuration and the intended playback conditions.

