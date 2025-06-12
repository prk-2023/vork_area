# Pixel formats:

## Introduction:

Digitial media on a embedded platform refers to handling images, videos and audio.

Images and Video is a just a bunch of **pixels** being stored, processed and displayed.

### Colors in a computer:

Normally computer stores color images in RGB format:

Each Pixel has a value for each of these three. 
Combining them in different ways, we get every color on the screen.

ex:
    R=255,G=0,B=0 ---> red pixel

Apart from RGB there is another way to represent color it uses:

Y = Luminance ( brightness )
U = Blue color difference 
V = Red color difference 

Y tells how bright the pixel is 
U,V tell what color it is.

This YUV format is very helpful especially in embedded devices.

### What YUV is used:
1. Efficiency: Human eyes care more about brightness then color details.
   YUV takes advantage of this to reduce how much data is stored or transmitted.

2. Less Power and Bandwidth: YUV uses less data, especially with something called **chroma sub-sampling** 

3. Compatibility: Many video cameras, TV systems, and codecs (H.264..) use YUV.

### Chroma sub-sampling:

Lets say we have 4 pixels.

In RGB you will need 3 color values per pixel:

    4 pixels x 3 values = 12 values 

In YUV 4:2:0 you get:

    4 Y values ( 1 for each pixel )
    1 U value & 1 V value ( shared by all 4 pixels )

    that is 4 + 1 + 1 6 values instead of 12. ==> 50% less data.

This is the reason video systems use YUV to save space while still look good to human eye.


## Common YUV Formats 

1. YUV 444 : Full detail for every pixel ( high quality processing )
2. YUV 422 : Half Horizontal color resolution ( TV, Camera interfaces )
3. YUV 420 : Quarter color resolution ( Most video codecs H.264..)
4. NV12    : YUV420 with special layout (Y+ interleaved UV)  ( HW video decoders, android )

### Python program to convert RGB to YUV 

- Install libs

    pip install numpy opencv-python

- 
```python 

import cv2
import numpy as np

# Load an RGB image using OpenCV (note: OpenCV loads in BGR by default)
bgr_image = cv2.imread("example.jpg")  # Replace with your image path
rgb_image = cv2.cvtColor(bgr_image, cv2.COLOR_BGR2RGB)

# Function to convert RGB to YUV (YUV444 format)
def rgb_to_yuv(rgb):
    # Convert image to float for calculation
    rgb = rgb.astype(np.float32) / 255.0
    
    # Transformation matrix for RGB to YUV
    transformation_matrix = np.array([
        [0.299, 0.587, 0.114],
        [-0.14713, -0.28886, 0.436],
        [0.615, -0.51499, -0.10001]
    ])

    # Reshape image to (H*W, 3)
    flat_rgb = rgb.reshape(-1, 3)

    # Apply matrix multiplication
    yuv = np.dot(flat_rgb, transformation_matrix.T)

    # Reshape back to original image shape
    yuv_image = yuv.reshape(rgb.shape)

    return yuv_image

# Convert the image
yuv_image = rgb_to_yuv(rgb_image)

# Optional: Scale YUV to displayable range (0-255) for visualization
yuv_display = np.clip(yuv_image * 255.0, 0, 255).astype(np.uint8)

# Save or display result
cv2.imwrite("converted_yuv.jpg", cv2.cvtColor(yuv_display, cv2.COLOR_RGB2BGR))  # Still in 3-channel RGB layout

print("RGB to YUV conversion complete!")
```
- This converts to YUV444 (no chroma subsampling).
- For embedded platforms or video compression we often convert to YUV420 which includes chroma sub-sampling.
- opencv can also do this conversion directly using:

    yuv_opencv = cv2.cvtColor(rgb_image, cv2.COLOR_RGB2YUV)


## Planes in YUV:

Planes in YUV format is key when working with images/video data.

A plane is a 2D array ( like grayscale image ) that holds one component of the color data.

In YUV you usually split the image into 3 separate planes:
1. Y-plane : Contains brightnedd (Luminance) for each pixel.
2. U-plane : contains blue color infomation (chrominance)
3. V-plane : contains red color information (chrominance)

Each plane is matrix of numbers and depending on the format ( like YUV444, YUV420 )the size of each plane
may vary. 


Ex: YUV444 ( no subsampling)
Let’s say we have a 4×4 image.

    Y plane: 4×4 = 16 values (one per pixel)
    U plane: 4×4 = 16 values
    V plane: 4×4 = 16 values

Each pixel has full color and brightness information.

Ex: YUV 420 subsampling:

Now take 4x4 image in YUV420:
Now take a 4×4 image in YUV420:

    Y plane: 4×4 = 16 values (every pixel still gets a Y)
    U plane: 2×2 = 4 values (shared by 2x2 blocks of pixels)
    V plane: 2×2 = 4 values

Here U and V are subsampled meaning color detail is reduced to save space, while brightness stays sharp.

### How Planes Are Stored in Memory

Here’s how YUV420 data might be stored in memory (or in a file):

```
[ Y0, Y1, Y2, Y3, ..., Y15 ]  → 16 bytes
[ U0, U1, U2, U3 ]            → 4 bytes
[ V0, V1, V2, V3 ]            → 4 bytes
```

Or sometimes **interleaved** (e.g., in NV12 format):

```
[ Y plane ]
[ U0, V0, U1, V1, ... ]  → interleaved chroma
```

---

### Visual Analogy

Think of an image in YUV as 3 transparent sheets stacked together:

* **Y plane** is like a black-and-white photo.
* **U and V planes** are blurry, low-res color overlays.
* When you combine them, you get the full color image.

---

### Why Planes Matter in Embedded Systems

* You often **pass each plane separately** to hardware codecs (encoders/decoders).
* Some systems **store or stream raw YUV data**, so you need to know how to extract the planes.
* Optimizing **memory usage** and **bandwidth** is easier when you deal with planes directly.

---

