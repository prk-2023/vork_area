# Writing DRM Applications:

- DRM is a way to draw things to your computer monitor without the need of windowing system on a linux
  system.

- DRM stands for Direct Rendering Manager.

- Linux graphics stack has evolved and updates quite often, this leaves a gap for documentation to keep up
  to these changes and DRM is one such new system. And many links have older APIs or cover information
  related for people writing kernel drivers.

- DRM can be interacted from user space using IOCTLs found in /usr/include/libdrm/{xf86drm.h,xf86drmMode.h}
- Dealing with the raw IOCTLs is a pain.
- MESA provides another library(libdrm) that wraps over these IOCTls.

- Opening GPU: /dev/dri/cardN where N is a number, counting up from 0. 

    int drm_fd = open("/dev/dri/card0", O_RDRW|O_NONBLOCK);

    O_NONBLOCK : this is not mandatory but helpful.
    
    This file descriptor is not reading and writing, but use ful over DRM API.

## Part-2 DRM Resources:
-------------

- There are many types of kernel-side objects that are useful to know and configure to get everything
  working. These are each referred to by uint32_t handle.

- To find the the objects associated with GPU: we need to call:
    
    drmModeRes *resources = drmModeGetResources(drm_fd);

where drmModeRes :
    
        typedef struct _drmModeRes {
            int         count_fbs;
            uint32_t    *fbs;

            int         count_crtcs;
            uint32_t    *crtcs;

            int         count_connectors;
            uint32_t    *connectors;

            int         count_encoders;
            uint32_t    *encoders;

            uint32_t    min_width, max_width;
            uint32_t    min height, max_height;
        } drmModeRes, *drmModeResPtr;

Thie contains several arrays of handles to DRM objects.

## Connectors:
----------

- Connector is the most simple to understand DRM object. It represents the actual physical connectors on
  your GPUs. So if we have DVI or HDMI-A connector on your GPU, they should each have their own DRM
  connector object.

- Below are the key points about DRM connectors:

    - Dynamic Nature of connectors:

        - Number of DRM connectors can change between different calls to "drmModeGetResources".
        - This may seem surprising as it implies that the number of connectors on a GPU is not fixed. 

    - Multi-Stream Transport (MST) Feature:

        - DisplayPort 1.2 introduces a feature called Multi Stream Transport (MST)
        - MST allows multiple monitors to be connected to a single physical connector.
        - This can be achived through daisy-chaining or using a hub.

    - Implications for Code:

        - When a new monitor is plugged into a MST setup, it will appear as a seperate DRM connector.
        - The number of connectors in the code should not contain fixed number of connectors.

        One way is to loop through all the connectors and printing some information about them:

        for ( int i=0; i < resources->count_connectors; i++ ) {
            drmModeConnector *conn = drmModeGetConnector( drm_fd, resources->connectors[i]);
            if (!conn) 
                continue;

            drmModeFreeConnector(conn);
        }

        typedef struct _drmModeConnector {

            uint32_t connector_id;
            uint32_t encoder_id; /**< Encoder currently connected to */
            uint32_t connector_type;
            uint32_t connector_type_id;
            drmModeConnection connection;
            uint32_t mmWidth, mmHeight; /**< HxW in millimeters */
            drmModeSubPixel subpixel;

            int count_modes;
            drmModeModeInfoPtr modes;

            int count_props;
            uint32_t *props; /**< List of property ids */
            uint64_t *prop_values; /**< List of property values */

            int count_encoders;
            uint32_t *encoders; /**< List of encoder ids */

        } drmModeConnector, *drmModeConnectorPtr;

    - 'connector_type' tells us whether our connector is HDMI-A, DVI, DisplayPort, etc....
    - 'connector_type_id' distinguished between connectors of the same type, so if there are 2 HDMI-A
      connectors, one will be 1 and other will be 2. We can use this info to give our connectors a
      meaningful name, such as "HDMI-A-0"
    - 'connection' tells us if there is a monitor plugged in.

    'connector_type' is only an integer, so we'll write a concenience function to get the corresponding
    string.

## Modes:
------

    typedef struct _drmModeModeInfo {

        uint32_t clock;
        uint16_t hdisplay, hsync_start, hsync_end, htotal, hskew;
        uint16_t vdisplay, vsync_start, vsync_end, vtotal, vscan;

        uint32_t vrefresh;

        uint32_t flags;
        uint32_t type;
        char name[DRM_DISPLAY_MODE_LEN];

    } drmModeModeInfo, *drmModeModeInfoPtr;

    A mode is a description of the resolution and refresh rate that a monitor should run at.
    The modes in 'drmModeConnector' are the modes that a monitor reports that it can run natively.

    They're ordered from best to worst:

    - 'hdisplay': is the horizontal resolution.
    - 'vdisplay': is the vertical resolution.
    - 'vrefresh': is the refresh rate in Hz, but it's quite inaccurate. We'll write another function to
      compute a more accurate refresh rate from the rest of the mode.
    - 'flags': thells various extra things about the mode. such as if it used interlacing.

- The above information should be fetched to work with DRM API's.

- Next step would be know more about DRM objects, and configure the display pipeline ... to do operations we
  wish to perform.


## Part 2: Modesetting:

       
