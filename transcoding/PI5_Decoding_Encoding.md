# Video Decoding and Encoding On PI5:
---

Ref: https://www.raspberrypi.com/news/introducing-raspberry-pi-5/
---

There are many questions on the internet over the decoding and encoding capabilities of Raspberry Pi 5.

The Maintainer responds with the below statements:

Q. Did just read somewhere that there is no hardware video encoding, is it true ? 
   That sounds strange as it would means poor performances for real-time applications.

Ans Pi>
""" 
    Ok, this is a big one… 
    The problem is that video encoding is not a standard. 
    
    You can put as much or as little effort into encoding as you like,
    on Pi 1, 2, 3, & 4 the encoding quality (for the bitrate) was relatively poor. 
 
    The nice thing about using the processors to do this is you get to choose exactly
    what balance between quality and bitrate you want. 
 
    Obviously, the bad thing is the power consumption, but actually it only takes
    around 1 processor to encode 1080p60 with our default settings 
    (which is still better quality than the PI 4 hardware encoder). 
 
    We think it might be possible with the right settings to be able to hit 4K 
    encode at around 24fps, but we’ve not been optimising in that direction yet.
 
    In future we’ll have to do something, but for Pi 5 we feel the hardware encode 
    is a mm^2 too far.
 
    Adding a hardware encoder to the Raspberry Pi 5 would require too much additional 
    space on the chip (in terms of area), which is not feasible or worthwhile.
 """
    
- There is no single, universally accepted way to encode video. 

- Video encoding is a complex process that involves compressing and formatting video data so that it can be
  stored, transmitted, and played back efficiently.

- There are many different factors that can affect the quality and efficiency of video encoding, such as:
    * Codec: The type of compression algorithm used, such as H.264, H.265, or VP9.
	* Bitrate: The amount of data used to represent each second of video.
	* Resolution: The number of pixels in the video image.
	* Frame rate: The number of frames per second.
	* Color depth: The number of bits used to represent each pixel's color.

- As a result, there are many different ways to encode video, and different devices, platforms, and
  applications may have different requirements or preferences for video encoding. 

  For example:
  - A video streaming service like Netflix may use a specific codec and bitrate to ensure efficient 
    streaming over the internet.
 
  - A video editing software like Adobe Premiere may use a different codec and bitrate to ensure
    high-quality video for editing and color grading.

- A device like a Raspberry Pi may use a specific codec and bitrate to ensure efficient playback on its HW.

- This lack of standardization means that video encoding can be a complex and nuanced process, and different
  implementations may have different trade-offs between quality, efficiency, and compatibility.

- WRT Raspberry Pi, the hardware encoder on previous models (Pi 1-4) had limitations and compromises that
  affected the quality of the encoded video. 

- By using software encoding on the processor, they can have more control over the encoding process and
  optimize it for their specific use case, but this comes at the cost of increased power consumption.

- On Pi5 it actually takes around 1 processor to encode 1080p60 with  default settings (which is still
  better quality than the PI 4 hardware encoder)

Additional Notes on Real-time requirements that seem to be effected by SW encoding:

- For any frame based encoding process, you will always have at least "_two_" frames worth of delay in any
  encoder – decode pipeline. 

- You have to collect the incoming frame data (one frame), encode, decode into another frame buffer, wait
  until the next frame is required, then display the resulting buffer. 

- Even if you had infinitely fast encoders/decoders you cant do better than that. 
  So some applications that talk of glass to glass latency of 50ms should sounds OK.

# Video Decoding:

- It's the process of taking compressed video data and converting it back into its original, uncompressed
  form so that it can be displayed on a screen.

- **Is video decoding a standard?**
  Video decoding is more standardized than video encoding, in the sense that there are widely accepted 
  standards for decoding specific video codecs, such as:
   
    * H.264 (AVC)
    * H.265 (HEVC)
    * VP9
    * AV1
    ...
  These standards define the format and structure of the compressed video data, as well as the algorithms 
  and processes required to decode it. As a result, most devices and platforms can decode video using these 
  standard codecs, and video content can be shared and played back across different devices and platforms.

- Challenges with hardware decoding:

- While video decoding is more standardized than encoding, there are still challenges associated with
  implementing HW decoding, particularly on devices like the Raspberry Pi. 
  Some of these challenges include:

  1. **Codec support**: 
  While there are standard codecs, new codecs are being developed, and older ones may become obsolete. 
  Hardware decoders may not support the latest codecs, or may not be able to decode them efficiently.
  2. **Bitstream complexity**: The bitstream is the compressed video data that needs to be decoded. 
  Different codecs & encoding settings can result in complex bitstreams that are difficult to decode in HW.
  3. **Error handling**: Decoding errors can occur due to bitstream errors, decoding errors, or other 
  issues. Hardware decoders need to be able to handle these errors and recover from them.
  4. **Power consumption**: Hardware decoding can consume significant power, particularly for 
  high-resolution or high-frame-rate video.
  5. **Silicon area**: As mentioned earlier, adding hardware decoding capabilities to a device like the 
  Raspberry Pi requires dedicated silicon area, which can increase the cost and complexity of the device.
  6. **Firmware updates**: Hardware decoders may require firmware updates to support new codecs, fix bugs, 
  or improve performance. This can be a challenge, particularly for devices that are not designed to receive
  frequent firmware updates.
  7. **Interoperability**: Hardware decoders may need to interact with other components, such as the OS, 
  graphics processing unit (GPU), or display controller. Ensuring interoperability between these components 
  can be a challenge.

- **Software decoding**
  1. Software decoding, on the other hand, can provide more flexibility and adaptability, particularly for 
  devices like the Raspberry Pi. 
  2. Software decoders can be updated more easily, and can support a wider range of codecs and bitstreams. 
  3. However, software decoding can also consume more CPU resources, which can impact system performance and 
  power consumption.
  
In the context of the Raspberry Pi, the decision to use software decoding or hardware decoding depends on 
the specific use case and requirements. 
For example, if the device is primarily used for video playback, hardware decoding may be preferred to 
reduce power consumption and improve performance. 
However, if the device is used for more general-purpose computing, software decoding may be preferred to 
provide more flexibility and adaptability.

- On Raspberry Pi 5: 
 
    1. H264 HW decoding is dropped, 
    2. Supports H265 4kp60 (HEVC) decode is available
       ( it only uses 50% of the processors to do 1080p60 on YouTube

