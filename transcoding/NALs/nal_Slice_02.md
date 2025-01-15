# Slice NAL Unit:

### **Slice NAL Unit Type**

A **Slice NAL Unit** in both **H.264 (AVC)** and **H.265 (HEVC)** refers to a segment or part of a frame in 
the video stream. 

A "slice" is essentially a portion of a picture (frame), and encoding video in slices allows the codec to 
handle different regions of a frame independently. 

Slices are important because they help with parallel processing, error resilience, and efficient encoding 
of the video stream. 

Slices can be of different types depending on whether the frame is part of an **IDR (Instantaneous Decoder 
Refresh)** picture or a **non-IDR** picture.

### **In H.264 (AVC)**

In **H264**, a slice is part of a **NAL Unit** that contains a subset of the coded data for a pic (frame).

It can represent one or more macroblocks (the smallest unit in H.264). 

There are different types of slices based on the picture's reference frame (such as P,I,B-frames):

#### **Slice NAL Unit Types in H.264:**

- **NAL Unit Type 1**: **Slice of a non-IDR picture**

  - This NAL unit contains data for a slice in a non-IDR frame. 
    Non-IDR frames are frames that can reference previous frames (e.g., P-frames and B-frames).
    
- **NAL Unit Type 2**: **Slice of an IDR picture**

  - This NAL unit contains a slice of an **IDR (Instantaneous Decoder Refresh)** frame. 
  IDR frames are important because they do not rely on any previous frames and are used to refresh the 
  decoder state. 
  IDR frames often serve as the start of a new sequence of pictures (GOP, or Group of Pictures).

- **NAL Unit Type 3**: **Slice of a picture with an IDR frame**

  - Similar to NAL unit type 2, but this might represent a slice of an IDR frame in a more specific context.

### **In H.265 (HEVC)**

In **H.265**, the concept of slices is similar to H.264, but with a more advanced & flexible approach. 
The slice structure in H.265 is more versatile, allowing for better scalability and performance (ex:support
for large video resolutions and parallel processing). 
In H.265, slices can be independently decoded and processed.

#### **Slice NAL Unit Types in H.265:**

- **NAL Unit Type 1**: **Coded Slice of a non-IDR picture**

  - This NAL unit contains a slice of a non-IDR picture (like P-frames and B-frames). 
    Non-IDR frames can reference other frames for decoding.

- **NAL Unit Type 2**: **Coded Slice of an IDR picture**

  - This NAL unit contains a slice of an **IDR frame**. 
    Like in H.264, IDR frames are independent and do not reference other frames.

- **NAL Unit Type 3**: **Coded Slice of an Instantaneous Decoder Refresh (IDR) picture**

  - A more specific type of IDR slice. 
  IDR frames reset the decoder, making them useful for error recovery and stream synchronization.

### **Identifying a Slice NAL Unit in the Bitstream**

To identify a **Slice NAL unit** in the bitstream, you need to analyze the NAL unit header and the structure
of the bitstream. 

Both in H.264 and H.265, each NAL unit starts with a header that includes a **NAL unit type** 
(which is typically a 5-bit field). 
The NAL unit type is important because it tells the decoder what kind of data is contained in the NAL unit.

#### **H.264 Bitstream:**

- The NAL unit is preceded by a 1-byte start code (`0x00 0x00 0x01`) in the bitstream.

- Each NAL unit starts with a 1-byte **NAL header**, where the **NAL type** (bits 0-4) specifies the type 
  of NAL unit. For slices, the NAL type will be **1** (non-IDR slice) or **2** (IDR slice).
  
Example NAL header:
    ```
        [ 0  0  1 ] [ NAL Header ] [ Data ]
    ```

- The NAL header includes a **NAL unit type** that tells you if it's a slice or something else. 
  In H.264, slice NAL units have types 1 or 2.

- After the NAL header, you will find the **slice data** that contains the encoded video information for 
  that slice.

#### **H.265 Bitstream:**

- Like H.264, the NAL unit is also preceded by a start code (`0x00 0x00 0x01`).
- The NAL header in H.265 contains the **NAL unit type** (5 bits).
- In H.265, slice NAL units can have types 
    **1** (Coded slice of non-IDR picture) or 
    **2** (Coded slice of IDR picture).
- The slice data follows the NAL header, encoding information for the slice.

Example H.265 NAL unit:
    ```
        [ 0  0  1 ] [ NAL Header ] [ Slice Data ]
    ```

### **Steps to Identify a Slice NAL Unit:**

1. **Look for NAL Start Code**: The NAL unit begins with the start code (`0x00 0x00 0x01`).
2. **Check NAL Header**: The next byte(s) is the NAL header, where the **NAL unit type** (5 bits) is stored.
3. **Determine the Slice Type**:
   - If the NAL type is `1`, the unit is a **slice of a non-IDR picture**.
   - If the NAL type is `2`, the unit is a **slice of an IDR picture**.
4. **Parse Slice Data**: After identifying the slice type, the slice data follows the header and contains 
   the encoded information for that slice.

### **Conclusion**
- In **H.264** and **H.265**, slice NAL units represent a portion of a picture, and the **NAL unit type** 
  indicates whether the slice is from an IDR picture or a non-IDR picture.

- The **NAL unit type** is embedded in the NAL header, which can be found after the 
  start code (`0x00 0x00 0x01`).

- In **H.264**, slice NAL units are types `1` (non-IDR) and `2` (IDR). 
  In **H.265**, slice NAL units are also types `1` (non-IDR) and `2` (IDR).


# Meta data associated with Slice NAL Unit:

The **Slice NAL Unit Type** in **H.264 (AVC)** and **H.265 (HEVC)** video encoding standards refers to the 
specific type of NAL unit that contains a "slice" of a video frame (picture). 

A slice is a portion of a frame, and encoding video in slices allows for independent decoding of parts of 
the frame. 
This structure is essential for error resilience, parallel processing, and efficient video encoding.

In the context of slices, **metadata** refers to the extra information included in the **Slice NAL unit** 
that helps the decoder interpret the encoded video data correctly. 

This metadata is crucial for decoding slices properly and efficiently. 
The metadata for the **Slice NAL Unit Type** includes various pieces of information that describe the 
properties of the slice and the way it is to be decoded.

Here’s a detailed explanation of the metadata that can be associated with the **Slice NAL Unit Type**:

### **Key Metadata in Slice NAL Unit (H.264 and H.265)**

#### 1. **Slice Type**

- The **slice type** specifies the type of slice contained in the NAL unit. 
  The slice type determines whether the slice is from an 
  **I-frame (Intra-coded frame)**, 
  **P-frame (Predicted frame)**, or 
  **B-frame (Bi-directionally predicted frame)**. 
  Each type of slice has different encoding and prediction methods.
  
  - **H.264 Slice Types**:
    - **I-slice**: The slice contains only intra-predicted data, i.e., no reference to other frames.
    - **P-slice**: The slice is predicted from previous frames.
    - **B-slice**: The slice is predicted from both previous and future frames.
  
  - **H.265 Slice Types**:
    - **I-slice**: The slice is intra-coded (no reference frames).
    - **P-slice**: The slice is predicted from previous reference frames.
    - **B-slice**: The slice is predicted from both previous and future reference frames.

#### 2. **Slice Address**

- The **slice address** (also referred to as the **slice index**) is the position of the slice within a 
frame. This is essential for multi-slice frames where the frame is divided into multiple slices for parallel
processing.

  - The **slice address** is used to identify the relative position of a slice in the entire frame and to 
  indicate how the decoder should process different slices, especially when slices can be processed 
  independently in parallel.

#### 3. **Slice Start and End**

- **Slice start** and **slice end** refer to the position in the encoded bitstream where the slice data 
begins and ends. 
These markers help the decoder identify where the slice data starts and stops within the bitstream, which 
is particularly useful when processing video streams with multiple slices.
  
  - **Slice start**: The position in the bitstream where the encoded data for the slice begins.
  - **Slice end**: The position in the bitstream where the encoded data for the slice ends.

#### 4. **Slice Header Information**

The **slice header** is a part of the NAL unit that contains essential metadata for decoding the slice. 
This metadata may include various fields such as:

- **Slice size**: The number of bytes required to encode the slice.
- **Slice QP (Quantization Parameter)**: Defines the quantization level used for encoding the slice. 
  The QP value impacts the compression efficiency and video quality.
- **Reference frame indices**: The slice may reference multiple previous or future frames 
  (in the case of P or B slices), and the indices specify which frames are being referenced.

#### 5. **Slice Data Partitioning (In Advanced Encoding)**

In more advanced encoding techniques (like in H.264 and H.265), slices can be **partitioned** 
into multiple **data partitions**. 
This means the slice data can be split across multiple NAL units for enhanced error resilience and 
coding efficiency.
  
  - **Slice data partitioning** can occur at various levels, like macroblock-level partitioning (H.264) or 
  larger partition sizes in H.265.

#### 6. **Slice Group Information**

- In certain encoding scenarios, video frames are divided into multiple **slice groups**. 
Each slice group can have different structures, and the slices within each group are decoded in a specific 
way. Slice groups are used for better error resilience or when certain parts of the frame are processed 
differently (e.g., for region-of-interest coding).
  
  - Slice group metadata specifies how each slice should be grouped and processed during decoding.

#### 7. **Entropy Coding Information**

- The **entropy coding** method used in a slice, such as CABAC (Context-Adaptive Binary Arithmetic Coding) 
  or CAVLC (Context-Adaptive Variable-Length Coding), is important metadata for interpreting the encoded 
  slice data.
  
  - **CABAC** is more complex and achieves higher compression, but it requires more processing power to 
    decode.
  - **CAVLC** is simpler but less efficient in terms of compression.

#### 8. **Motion Vector Information (for P and B slices)**

- **Motion vectors** are used in P and B slices to represent the difference between blocks in the current 
  slice and the reference blocks from the previous or future frames. 
  These motion vectors are part of the metadata in a P or B slice.

  - Motion vectors are essential for predictive encoding in P and B slices and help to reduce the amount of
  data that needs to be encoded by referencing previously encoded frames.

#### 9. **Rounding Control (H.264 Specific)**

- In **H.264**, rounding control is a technique used to modify the precision of the encoded coefficients, 
  which can impact the bitrate and video quality. This is part of the metadata in the slice.

### **How to Identify Slice NALU and Extract Metadata in the Bitstream**

To identify a **Slice NAL Unit** and extract its metadata, you need to parse the **NAL header** and 
slice data in the bitstream. Here are the steps:

1. **Look for the NAL Unit Start Code**: 
   The NAL unit begins with the start code (`0x00 0x00 0x01`), which marks the beginning of a NAL unit.
  
2. **Check the NAL Header**: The NAL header is the byte(s) following the start code. 
   The **NAL unit type** is encoded in the header, and for slice NAL units in H.264 and H.265, the type 
   will be **1** (non-IDR slice) or **2** (IDR slice) in H.264, and **1** or **2** in H.265.
  
3. **Extract the Slice Header**: Once the NAL unit type is identified as a slice, the slice header will 
   contain various metadata:
   - Slice type (I, P, or B).
   - Slice QP.
   - Reference frame indices.
   - Slice size.
  
4. **Parse Slice Data**: 
   The slice data itself follows the slice header and contains the encoded information, such as motion 
   vectors (for P/B slices), quantized coefficients, and entropy-coded data (CABAC/CAVLC).

### **Conclusion**
The **metadata** in the **Slice NAL Unit** provides essential information for decoding the slice, including 
the slice type, slice size, reference frames, motion vectors, entropy coding method, and other settings 
like the Quantization Parameter (QP). This metadata is critical for the decoder to correctly reconstruct 
the video from its encoded form. 

In a bitstream, you can identify the **Slice NAL Unit** by checking the NAL unit type in the header, and 
the metadata is contained within the slice header and slice data itself, which provides all necessary 
parameters for decoding that specific slice of the frame.
