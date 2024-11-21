# pixel format:


- What is a Pixel Format?
    A pixel format is a way to represent the color information of a pixel in a digital image or video. 
    defines the organization and interpretation of the bits that make up a pixel, including the color model, 
    bit depth, and chroma subsampling.


- What does a Pixel Format Represent?

A pixel format represents the following aspects of a pixel:

1.  **Color Model**: 
    The color model defines how the color information is represented. 
    Common color models include
        - RGB (Red, Green, Blue), 
        - YUV (Luminance and Chrominance), and 
        - CMYK (Cyan, Magenta, Yellow, Black).

2.  **Bit Depth**: 
    The bit depth defines the number of bits used to represent each color component. 
    Common bit depths include 8-bit, 10-bit, 12-bit, and 16-bit.
    
3.  **Chroma Subsampling**: 
    Chroma subsampling defines how the color information is subsampled. 
    Common chroma subsampling schemes include 
        - 4:4:4 (no subsampling), 
        - 4:2:2 (horizontal subsampling), and 
        - 4:2:0 (horizontal and vertical subsampling).
    
4.  **Pixel Layout**: 
    The pixel layout defines the order in which the color components are stored in memory.
    Common pixel layouts include 
        - planar (separate planes for each color component) and 
        - packed (interleaved color components).

5. **Common Pixel Formats**
    Some common pixel formats include:

    1. RGB: planar format with 8-bit or 16-bit bit depth (used in graphics and gaming applications )
    2. YUV: planar format with 8-bit or 10-bit bit depth, (used in video compression and processing apps)
    3. YCbCr: planar format with 8-bit or 10-bit bit depth, (used in video compression & processing apps)
    4. NV12: planar format with 8-bit bit depth (used in video compression and processing applications)
    5. NV21: planar format with 8-bit bit depth ( commonly used in video compression and processing apps)


- **Pixel Format Conversion**

Converting between different pixel formats is a common operation in image and video processing. 
This can involve changing the color model, bit depth, chroma subsampling, or pixel layout. 

Pixel format conversion can be performed using various algorithms and techniques, 
including color space conversion, bit depth conversion, and chroma subsampling.

example of a pixel format conversion in C:

```c
void rgb_to_yuv(uint8_t* rgb_buffer, uint8_t* yuv_buffer, int width, int height) {
    // Convert RGB to YUV
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            uint8_t r = rgb_buffer[y * width * 3 + x * 3];
            uint8_t g = rgb_buffer[y * width * 3 + x * 3 + 1];
            uint8_t b = rgb_buffer[y * width * 3 + x * 3 + 2];

            // Convert RGB to YUV using the ITU-R BT.601 conversion formula
            uint8_t y = (0.299 * r + 0.587 * g + 0.114 * b);
            uint8_t u = (-0.14713 * r - 0.28886 * g + 0.436 * b);
            uint8_t v = (0.615 * r - 0.51499 * g - 0.10001 * b);

            // Store the YUV values in the output buffer
            yuv_buffer[y * width + x] = y;
            yuv_buffer[y * width + x + width * height] = u;
            yuv_buffer[y * width + x + width * height * 2] = v;
        }
    }
}
```
This code converts an RGB image to a YUV image using the ITU-R BT.601 conversion formula.



