# Network Abstraction Layer Unit:
---

### Intro :

In both H.264 (AVC) and H.265 (HEVC) video coding standards, **NAL units(Network Abstraction Layer units)**
are the basic data packets used to represent the compressed video stream. 

The NAL units are classified into different types, each serving different purposes in the bitstream.

Start delimiter of a NAL Unit:

In bitstream  **( 00 00 00 01 )** is the start code prefix, ( or delimiter ), this is a 4-byte sequence 
that indicates the start of a new NAL unit.

Example:
    00 00 00 01 40 01 0c 01 ff ff 01 60 00 00 03 00

    `00 00 00 01` : Start code prefix start of NAL Unit.
    `40`  : This is the NAL unit type, which is a 1-byte value. 
        In this case, the value `40` indicates that this NAL unit is a Video Parameter Set (VPS).

    `01` : This is the NAL unit layer ID, which is a 1-byte value. 
         In this case, the value 01 indicates that this NAL unit belongs to layer 1.

    `0c` : This is the 6-bit VPS ID, which is a unique identifier for the VPS. 
           The value `0c` ( decimal 12) is the VPS ID.

    `01` : This is the 2-bit VPS base layer internal flag and VPS base layer available flag. 
        The value `01` indicates that:
        * The base layer is internal (i.e., not an external reference)
        * The base layer is available

    `ff` `ff` : These are the 16-bit VPS max sub-layers minus 1 and VPS max layer ID. 
            The value `ff` `ff` ( decimal 65535) indicates that:
            * The maximum number of sub-layers is 65535 (which is the maximum allowed value)
            * The maximum layer ID is 65535 (which is the maximum allowed value)

    `01` : This is the 1-bit VPS num layer sets minus 1. 
           The value `01` indicates that there is 1 layer set (since num layer sets minus 1 is 1, we add 
           1 to get the actual number of layer sets).

    `60` : This is the 8-bit VPS layer ID included flag and other flags. 
        The value `60` ( binary `01100000`) indicates that:
        * Layer 0 is included in the layer set (since the most significant bit is 0)
        * Other flags are set to 0

    `00 00 03 00` : These bytes are part of the VPS and contain additional information, such as the profile,
        tier, and level of the video. These require additional bitstream to explain what these bytes rep.

    Note: The above are just a brief explanation of the first 32 bits of the H.265 bitstream, and there may 
    be additional information and nuances that are not covered here.

### Types of NAL Units in H.264 (AVC):

In H.264, NAL units are classified by a **NAL unit type**, which is defined by a 5-bit value. 

There are **33 defined NAL unit types**, but some are reserved or for special use cases. 


The most common NAL unit types include:

1. **0**: **Slice of a non-IDR picture** –
    Contains a slice of a picture that is not an IDR (Instantaneous Decoder Refresh) frame.

2. **1**: **Slice of an IDR picture** – 
    Contains a slice of an IDR frame, which can be used to start a new GOP (Group of Pictures).

3. **2**: **SEI (Supplemental Enhancement Information)** – 
    Contains SEI messages, used for conveying additional information like timing, color space, etc.

4. **3**: **SPS (Sequence Parameter Set)** – 
    Defines sequence-level parameters for decoding the video stream.

5. **4**: **PPS (Picture Parameter Set)** – 
    Defines picture-level parameters for decoding.

6. **5**: **Access Unit Delimiter** – 
    Marks the boundary of an access unit (a group of NAL units representing a complete coded picture).

7. **6**: **End of Sequence** – 
    Indicates the end of a video sequence.

8. **7**: **Sequence Parameter Set (SPS)** – 
    Defines the configuration for the video stream.

9. **8**: **Picture Parameter Set (PPS)** – 
    Contains additional picture-level settings for decoding.

10. **9-13**: 
    Reserved for future use or specific extensions.

Some other types include:

- **14**: Reserved
- **15**: Reserved

- **16-18**: **B-frames** (Backward Prediction frames)
- **19-23**: Reserved for experimental use or future features.

### Types of NAL Units in H.265 (HEVC)

In **H.265 (HEVC)**, the NAL unit types are also 5-bit values, but the number and structure of NAL unit 
types are more flexible. 

HEVC has **32 NAL unit types**, and these are used to structure the video stream in various ways.

1. **0**: **Unspecified** – 
    Typically used for error handling or as a placeholder.

2. **1**: **Coded Slice of a Non-IDR Picture** – 
    A slice of a non-IDR picture.

3. **2**: **Coded Slice of an IDR Picture** – 
    A slice of an IDR frame.

4. **3**: **Coded Slice of an Instantaneous Decoder Refresh (IDR)** – 
    Contains an IDR slice.

5. **4**: **Coded Slice of a (non-IDR) Picture**.

6. **5**: **SEI (Supplemental Enhancement Information)** – 
    Contains additional metadata information like color space, timing, etc.

7. **6**: **SPS (Sequence Parameter Set)** – 
    Defines configuration for the video sequence.

8. **7**: **PPS (Picture Parameter Set)** – 
    Defines configuration for a single picture.

9. **8**: **Access Unit Delimiter** – 
    Marks boundaries between units of decoded video.

10. **9**: **End of Sequence (EOS)** – 
    Marks the end of a video stream.

11. **10**: **End of Stream (EOSTREAM)** – 
    Used to indicate the final packet of the stream.

12. **11-21**: 
    Reserved and for experimental or future use.

13. **22**: **Coded Slice of a Random Access Point** – 
    A slice in a random access point.

14. **23-31**: Other specialized or future NAL unit types.

### Common NAL Unit Types:
For both H.264 and H.265, there are **key NAL unit types** frequently used in practice:
- **Slices** (used for encoding video frames),
- **SEI** (used for carrying additional metadata),
- **SPS** and **PPS** (used for sequence and picture configuration),
- **Access Unit Delimiters** (to mark boundaries between video sequences or frames).

### Summary:
- **H.264 NAL Units**: 33 types, including slices, SPS, PPS, SEI, and others.
- **H.265 NAL Units**: 32 types, with more flexibility in metadata handling and additional support for advanced features like random access and error resilience.

Each NAL unit type plays a distinct role in how the video is encoded and transmitted.
