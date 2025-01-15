# SEI Nal Unit:
---
The **SEI (Supplemental Enhancement Information)** NAL unit is a type of **NAL unit** used in video 
compression standards like **H.264 (AVC)** and **H.265 (HEVC)**. It carries additional information about 
the video that is not essential for decoding the video itself, but may provide enhancement or auxiliary 
information for specific applications or optimizations during decoding or playback.

The **SEI** NAL unit is used for transmitting supplementary data that can enhance or complement the core 
video stream. 

This data can include things like timing information, metadata related to the video content (ex:color space,
display resolution), or specific instructions for the decoder or display device.

### **Purpose of the SEI NAL Unit**

The **SEI NAL unit** is designed to carry non-essential information that can help improve the playback or 
presentation of the video. This can include:

- **Timing information**: Such as frame rate, picture timing, or synchronization with other media.
- **Colorimetry metadata**: For specifying the color format or primaries used in the video.
- **Dynamic Range or High Dynamic Range (HDR)**: Information regarding color depth, brightness, and other 
  display-related parameters.
- **Scene Information**: Metadata about the video content, such as scene changes or video content 
  classification.
- **Video parameter enhancements**: Information about the video's layout, resolution, or viewport for more 
  efficient display on different devices.

These pieces of information can be used by decoders, renderers, or media players to provide better playback, 
dynamic color adjustments, or syncing with other media sources.

### **How to Identify the SEI NALU in the Bitstream**
To identify an **SEI NAL unit** in the bitstream, you can follow these steps:

#### 1. **NAL Unit Start Code**
- As with all NAL units, the **SEI** NAL unit begins with a **start code** (`0x00 0x00 0x01`). 
  This marks the beginning of the NAL unit and is followed by the NAL header and the SEI payload.

#### 2. **NAL Unit Type**
- The NAL header contains a **NAL unit type** field that indicates the kind of NAL unit. 
  For the **SEI NAL unit**, the NAL unit type is:
  - **H.264**: `6` (decimal) or `0x06` (hexadecimal).
  - **H.265**: `39` (decimal) or `0x27` (hexadecimal).
  
  The **NAL unit type** field is typically the 5th byte in the NAL header.

#### 3. **NAL Header**
- The **NAL header** includes more than just the NAL unit type. It also contains information about the 
  NAL unit's reference status and whether it is a "forbidden zero" or a "non-reference" frame. 
  However, the **NAL unit type** is the key field for identifying the **SEI** unit.

#### 4. **SEI Payload**
- After the NAL header, the **SEI NAL unit** contains the **payload**, which carries the actual 
  **Supplemental Enhancement Information**. The payload can vary depending on the type of SEI message, 
  but it typically includes a sequence of data that decodes into a specific piece of information 
  (ex frame timing, color information, HDR parameters).
  
### **Types of SEI Messages**
The **SEI NAL unit** can carry various types of **SEI messages**. Some common types of SEI messages include:

1. **Frame Packing Arrangement**: Information related to 3D video (e.g., how the frames are packed for 
   stereoscopic 3D displays).
2. **Mastering Display Color Volume**: Information for color management and HDR (e.g., color primaries, max
   luminance).
3. **Tone Mapping**: Instructions for how to adjust the dynamic range of a video for HDR or different 
   display devices.
4. **Buffering Period**: Information related to video buffer size and timing, useful for video streaming or
   live broadcast.
5. **User Data**: General-purpose data that can be used for various applications, such as watermarking, 
   annotations, or custom data.
6. **Pic Timing**: Timing information related to picture display (e.g., frame rate, timestamps for 
    synchronization).

Each SEI message has a specific structure, and each message type is identified by a 
**message type identifier** within the SEI payload.

### **Example of SEI NAL Unit in the Bitstream**

Here’s a simplified example of what an **SEI NAL unit** might look like in the bitstream:

#### **H.264 Example**:
```
00 00 01 06 [SEI Header Byte(s)] [SEI Payload Data]
```
Where:
- `00 00 01` is the **start code**.
- `06` is the **NAL header** byte, indicating that this is an **SEI NAL unit** (NAL unit type `6`).
- The rest of the bytes represent the **SEI payload**, which contains the supplemental enhancement data 
  (e.g., timing info, HDR metadata, etc.).

#### **H.265 Example**:
```
00 00 01 27 [SEI Header Byte(s)] [SEI Payload Data]
```
Where:
- `00 00 01` is the **start code**.
- `27` is the **NAL header** byte, indicating that this is an **SEI NAL unit** (NAL unit type `39` in decimal).
- The rest of the bytes represent the **SEI payload**, containing specific **SEI messages**.

### **Structure of the SEI NAL Unit Payload**

The **SEI NAL unit** has a flexible structure, as the payload can contain different types of SEI messages. 
Each SEI message is typically composed of the following parts:

1. **Message Type (Identifier)**:
   - A field that identifies the type of SEI message being carried in the payload. 
     This helps the decoder know how to interpret the rest of the data.
   
2. **Message Data**:
   - The data that corresponds to the specific type of message. 
     For example, if the SEI message type is **Mastering Display Color Volume**, the data might include 
     values like color primaries, maximum luminance, and minimum luminance.
   
3. **Message Size**:
   - The size of the SEI message or the number of bytes needed to decode the SEI data.

4. **Payload Syntax**:
   - The syntax and structure of the payload vary depending on the message type. For example:
     - **Frame Packing Arrangement** SEI might include information on how stereoscopic 3D frames are packed.
     - **Mastering Display Color Volume** SEI might include parameters for high dynamic range (HDR) video 
       display settings.

### **Conclusion**
The **SEI (Supplemental Enhancement Information)** NAL unit is used to transmit additional metadata or 
auxiliary information that enhances the video stream, such as timing details, colorimetry, HDR metadata, or 
other non-essential information for better display or optimization during playback. 

To identify an **SEI NAL unit** in the bitstream:
1. Look for the **start code** (`0x00 0x00 0x01`).
2. Check the **NAL unit type** in the **NAL header** (`0x06` for **H.264** or `0x27` for **H.265`).
3. Parse the **SEI payload**, which contains the actual supplemental information. 
   The payload includes one or more **SEI messages** identified by a message type field.

The **SEI NAL unit** provides valuable additional information for applications such as video streaming, 
playback optimizations, HDR video, and more, although it is not necessary for the core decoding process.


# SEI Meta-data:
---
The **SEI (Supplemental Enhancement Information)** NAL unit carries non-essential, additional metadata in 
video compression standards like **H.264 (AVC)** and **H.265 (HEVC)**. 
This metadata is supplemental to the video bitstream and is not strictly required for decoding the video, 
but it enhances the playback, display, or processing of the video stream. 
It can include information about the video's presentation, color properties, timing, dynamic range, and 
other parameters.

The **SEI NAL unit** can carry different types of **SEI messages** (also referred to as "SEI payloads"), 
each designed to convey specific types of information that might be useful for decoders, display devices, 
or media players.

### **Purpose of SEI NAL Unit Metadata**

The purpose of the **SEI NAL unit** is to provide additional data that may help optimize or enhance the 
decoding and playback experience. 
While the **SPS (Sequence Parameter Set)** and **PPS (Picture Parameter Set)** NAL units provide core 
information necessary for decoding, the **SEI** NAL unit contains information like:

- **Timing Information**: Frame timing, display timestamps, or synchronization information.
- **Display Parameters**: Color space, dynamic range, or HDR (High Dynamic Range) metadata.
- **Scene Description**: Metadata that helps with scene transitions, object detection, or video analysis.
- **3D Video Information**: Frame packing arrangement and other 3D video-related metadata.
- **Buffering and Rate Control**: Buffering information for streaming or rate control.

Each type of **SEI message** carries its own specific set of metadata.

### **Key Metadata in SEI NAL Unit**

The metadata in an **SEI NAL unit** varies depending on the type of **SEI message** it carries. 
Some common types of **SEI messages** and their corresponding metadata include:
---

### 1. **Frame Packing Arrangement**
   - This message provides metadata about how 3D video frames are packed. 
     It helps a display or decoder to correctly interpret and present stereoscopic 3D video.
   - **Metadata**:
     - **Frame packing arrangement type**: Specifies how the frames are arranged in a 3D sequence.
     - **Frame packing arrangement parameters**: Defines how the left and right frames for stereoscopic 
       3D content are packaged.
     - **Content interpretation**: Information on whether the video is to be displayed in 3D and how it 
       should be viewed.

---

### 2. **Mastering Display Color Volume (HDR)**

   - This message conveys metadata for HDR (High Dynamic Range) video, specifically about the mastering 
     display used to encode the video. This helps display devices or media players adjust the content to 
     the correct brightness and color range.

   - **Metadata**:
     - **Color primaries**: Specifies the color space used (e.g., BT.709, BT.2020).
     - **Max luminance**: Maximum brightness level supported by the display.
     - **Min luminance**: Minimum brightness level supported by the display.
     - **Display color gamut**: Defines the color range of the mastering display.

---

### 3. **Tone Mapping Information**
   - This SEI message provides instructions on how to map the video content from a high dynamic range (HDR) 
     to a lower dynamic range (SDR), or how to adjust the brightness levels for different display devices.
   - **Metadata**:
     - **Tone mapping parameters**: These specify the characteristics of the mapping algorithm used to adapt 
       HDR content to SDR or other display devices.
     - **Max luminance for tone mapping**: Defines the maximum luminance expected for SDR displays.
     - **Tone mapping function**: Specifies the function used to convert HDR to SDR, such as a transfer 
       function or a look-up table.

---

### 4. **Buffering Period**

   - This message provides buffering information related to the video sequence, which is useful for video 
     streaming or adaptive bitrate streaming. It helps manage the playback buffer and ensures smooth 
     delivery of video data.

   - **Metadata**:
     - **Buffer size**: The size of the buffer used for video playback.
     - **Timing of the start of the next frame**: Information related to how the decoder should manage its 
       timing and when to expect the next video frame.
     - **Rate control information**: Specifies how the video stream should be regulated to avoid playback 
       issues or to adjust to different network conditions.

---

### 5. **Pic Timing (Picture Timing)**
   - This message provides timing-related information about the pictures (frames) in the sequence, 
     including timestamps and display timings. It can be used for synchronization with other media 
     (e.g., audio or other video streams).
   - **Metadata**:
     - **Display timestamp**: A timestamp that specifies when the picture should be displayed.
     - **Decode timestamp**: A timestamp indicating when the picture should be decoded.
     - **Frame rate**: The rate at which the frames should be displayed.

---

### 6. **User Data**
   - This is a more general-purpose message that allows custom user data to be inserted into the video 
     bitstream. It can include anything from watermarking information to annotations.

   - **Metadata**:
     - **User-defined data**: This could include arbitrary data inserted by the content producer or 
       application, such as text information, markers, or identifiers.
     - **Watermarking**: A message containing data used for digital rights management (DRM) or tracking purposes.

---

### 7. **Scene Change Information**
   - This SEI message provides metadata indicating scene changes, which can be used by decoders or players 
   to adjust playback behavior, such as transitions or fade effects.
   - **Metadata**:
     - **Scene change indicators**: Flags or markers indicating when a scene transition happens.
     - **Keyframe information**: Indicates the location of keyframes that represent scene boundaries.

---

### **SEI NAL Unit Structure**
An **SEI NAL unit** typically has the following structure:

1. **NAL Header**:
   - The **NAL unit type** is defined in the NAL header. For **H.264**, this is `0x06` (decimal 6). 
   For **H.265**, it is `0x27` (decimal 39).
   - Other header fields include information like the **forbidden zero bit**, **nal_ref_idc**, and **NRI
   (NAL reference indicator)**.

2. **Payload Type**:
   - The **SEI NAL unit** contains a **payload type** that identifies the specific type of SEI message.
   Each type of SEI message (like mastering display color volume, buffering period, etc.) is assigned a unique identifier.
   - The payload type allows the decoder to interpret the data that follows correctly.

3. **Payload Size**:
   - This field indicates the size of the SEI message payload in bytes.

4. **SEI Message Data**:
   - The payload of the **SEI NAL unit** contains the **SEI message** data. This is the actual metadata 
   content and will vary depending on the message type.
   - The structure of the message data is determined by the specific type of SEI message.
   Each message type has its own set of parameters and encoding rules.

### **Example of SEI NAL Unit in H.264**:
A simplified **SEI NAL unit** in an H.264 bitstream might look like this:
```
00 00 01 06 [SEI Header] [SEI Payload Data]
```
- `00 00 01` is the **start code**.
- `06` is the **NAL unit type**, indicating this is an **SEI NAL unit** (type `6` in **H.264**).
- The **SEI header** contains the length and type of the message, followed by the actual **SEI payload**
with specific metadata (e.g., color volume, tone mapping, etc.).

### **Example of SEI NAL Unit in H.265**:
For **H.265**, the bitstream might look like this:
```
00 00 01 27 [SEI Header] [SEI Payload Data]
```
- `00 00 01` is the **start code**.
- `27` is the **NAL unit type**, indicating this is an **SEI NAL unit** (type `39` in **H.265**).
- The **SEI payload** would contain the metadata information, such as frame timing or HDR color volume.

### **Conclusion**
The **SEI NAL unit** carries important supplemental metadata that is not required for basic video decoding
but enhances the video stream in many ways. The metadata can be related to timing, color spaces, HDR, 
scene changes, 3D video arrangements, and more. Each type of **SEI message** has its own set of parameters,
and the structure of the **SEI NAL unit** reflects these different message types.

To identify and decode the **SEI NAL unit**:
1. Look for the **NAL start code** (`0x00 0x00 0x01`).
2. Check the **NAL unit type** (e.g., `0x06` for **H.264** or `0x27` for **H.265`).
3. Parse the **SEI payload** based on the payload type to extract the relevant metadata.
