# [Stark] VE3 RPC Implement

SW-4930:
VE3 RPC channel
    - kernel added ve3 rpc ring buffer
    -  IPC lib adds ve3 rpc ring buffer interface
    -  ipc share memory needs to add two variables to be used in sync with VE3
        --> Bootcode needs to be updated and init

1. The original ringbuffer and header locations of ACPU and VCPU are
    
    0x40ff000 ~ 0x4100b00
    ```
    rpc_poll_device 0 addr: 4100000 /*afw poll write*/
    The 0th poll dev:
    RPC ringStart: 40ff000
    RPC ringEnd:   40ff200
    RPC ringIn:      40ff000
    RPC ringOut:   40ff000

    rpc_poll_device 1 addr: 4100040 /*afw poll read*/
    The 1th poll dev:
    RPC ringStart: 40ff400
    RPC ringEnd:   40ff600
    RPC ringIn:      40ff400
    RPC ringOut:   40ff400
     
    rpc_poll_device 2 addr: 4100080 /*vfw poll write*/
    The 2th poll dev:
    RPC ringStart: 40ff800
    RPC ringEnd:   40ffa00
    RPC ringIn:      40ff800
    RPC ringOut:   40ff800

    rpc_poll_device 3 addr: 41000c0 /*vfw poll read*/
    The 3th poll dev:
    RPC ringStart: 40ffc00
    RPC ringEnd:   40ffe00
    RPC ringIn:      40ffc00
    RPC ringOut:   40ffc00
     
    rpc_intr_device 0 addr: 4100100 /*afw intr write*/
    The 0th intr dev:
    RPC ringStart: 40ff200
    RPC ringEnd:   40ff400
    RPC ringIn:    40ff200
    RPC ringOut:   40ff200
     
    rpc_intr_device 1 addr: 4100140 /*afw intr read*/
    The 1th intr dev:
    RPC ringStart: 40ff600
    RPC ringEnd:   40ff800
    RPC ringIn:    40ff600
    RPC ringOut:   40ff600
     
    rpc_intr_device 2 addr: 4100180 /*vfw intr write*/
    The 2th intr dev:
    RPC ringStart: 40ffa00
    RPC ringEnd:   40ffc00
    RPC ringIn:    40ffa00
    RPC ringOut:   40ffa00
     
    rpc_intr_device 3 addr: 41001c0 /*vfw intr read*/
    The 3th intr dev:
    RPC ringStart: 40ffe00
    RPC ringEnd:   4100000
    RPC ringIn:    40ffe00
    RPC ringOut:   40ffe00

    rpc_kern_device 0 addr: 4100a00 /*afw kern write*/
    The 0th kern dev:
    RPC ringStart: 4100200
    RPC ringEnd:   4100400
    RPC ringIn:      4100200
    RPC ringOut:   4100200

    rpc_kern_device 1 addr: 4100a40 /*afw kern read*/
    The 1th kern dev:
    RPC ringStart: 4100400
    RPC ringEnd:   4100600
    RPC ringIn:      4100400
    RPC ringOut:   4100400

    rpc_kern_device 2 addr: 4100a80 /*vfw kern write*/
    The 2th kern dev:
    RPC ringStart: 4100600
    RPC ringEnd:   4100800
    RPC ringIn:      4100600
    RPC ringOut:   4100600


    rpc_kern_device 3 addr: 4100ac0 /*vfw kern read*/
    The 3th kern dev:
    RPC ringStart: 4100800
    RPC ringEnd:   4100a00
    RPC ringIn:      4100800
    RPC ringOut:   4100800
    ```


2. 

VE3 is added from the above address downwards. 
Since poll rpc is no longer in use, only the intr and kern parts are added.

Header address
---
    ```
    intr: write rpc header 0x4101800
    intr: read rpc header 0x410840
    kern: write rpc header 0x4101880
    kern: read rpc header 0x41018c0

    rpc_intr_device 4 addr: 4101800 /*VE3 intr write*/
    The 4th intr dev:
    RPC ringStart: 4101000
    RPC ringEnd:   4101200
    RPC ringIn:    4101000
    RPC ringOut:   4101000

    rpc_intr_device 5 addr: 4101840 /*VE3 intr read*/
    The 5th intr dev:
    RPC ringStart: 4101200
    RPC ringEnd:   4101400
    RPC ringIn:    4101200
    RPC ringOut:   4101200

    rpc_kern_device 4 addr: 4101880 /*VE3 kern write*/
    The 4th kern dev:
    RPC ringStart: 4101400
    RPC ringEnd:   4101600
    RPC ringIn:      4101400
    RPC ringOut:   4101400

    rpc_kern_device 5 addr: 41018C0 /*VE3 kern read*/
    The 5th kern dev:
    RPC ringStart: 4101600
    RPC ringEnd:   4101800
    RPC ringIn:      4101600
    RPC ringOut:   4101600
    ```

3. 
IPC share memory added ve3_rpc_flag and ve3_int_sync to synchronize with VE3
The physical address is:
ve3_rpc_flag: 0x4080180
ve3_int_sync: 0x4080184

    ```
    struct rtk_ipc_shm { 

       volatile uint32_t sys_assign_serial;
       volatile uint32_t pov_boot_vd_std_ptr;
       volatile uint32_t pov_boot_av_info;
       volatile uint32_t audio_rpc_flag;
       volatile uint32_t suspend_mask;
       volatile uint32_t suspend_flag;
       volatile uint32_t vo_vsync_flag;
       volatile uint32_t audio_fw_entry_pt;
       volatile uint32_t power_saving_ptr; 
       volatile unsigned char printk_buffer[24]; 
       volatile uint32_t ir_extended_tbl_pt;
       volatile uint32_t vo_int_sync;
       volatile uint32_t bt_wakeup_flag;
       volatile uint32_t ir_scancode_mask;
       volatile uint32_t ir_wakeup_scancode;
       volatile uint32_t suspend_wakeup_flag; 
       volatile uint32_t acpu_resume_state;
       volatile uint32_t gpio_wakeup_enable;
       volatile uint32_t gpio_wakeup_activity;
       volatile uint32_t gpio_output_change_enable;
       volatile uint32_t gpio_output_change_activity;
       volatile uint32_t audio_reciprocal_timer_sec;
       volatile uint32_t u_boot_version_magic;
       volatile uint32_t u_boot_version_info;
       volatile uint32_t suspend_watchdog;
       volatile uint32_t xen_domu_boot_st;
       volatile uint32_t gpio_wakeup_enable2;
       volatile uint32_t gpio_wakeup_activity2;
       volatile uint32_t gpio_output_change_enable2;
       volatile uint32_t gpio_output_change_activity2;
       volatile uint32_t gpio_wakeup_enable3;
       volatile uint32_t gpio_wakeup_activity3;
       volatile uint32_t video_rpc_flag;
       volatile uint32_t video_int_sync;
       volatile unsigned char video_printk_buffer[24];
       volatile uint32_t video_suspend_mask;
       volatile uint32_t video_suspend_flag;
       volatile uint32_t ve3_rpc_flag;
       volatile uint32_t ve3_int_sync;
     };
    ```
4. IPC share memory corresponding bit (ve3_rpc_flag)

    ```
    #define RPC_VE3_SET_NOTIFY (__cpu_to_be32(1U << 2)) /* SCPU write */
    #define RPC_VE3_FEEDBACK_NOTIFY (__cpu_to_be32(1U << 3))
    #define VE3_RPC_SET_NOTIFY (__cpu_to_be32(1U << 0)) /* VE3 write */ 
    #define VE3_RPC_FEEDBACK_NOTIFY (__cpu_to_be32(1U << 1))
    ```
5. 
kernel ve3 rpc patch
    20210610_rpc_ve3_kernel.patch



    IPC lib patch (android/device/realtek/proprietary/libs/rtk_libs/common)
    20210607_rtk_libs_common_rpc.patch 20210607_rtk_libs_common_rpc_ve3_only.patch



    VE3 rpc lib Android.mk patch (android/device/realtek/proprietary/libs/rtk_libs)
    --> Include VE3 RPC API
    20210607_rtk_libs_ve3_android_mk.patch

6. 
It should be noted that

The upper layer uses the rpc lib part. Currently, the ve3 proxy is independent. 
If you need to use VE3, you need to call initRPCProxy2()

7. 
kernel ve3 & ve3 uart patch

20210714_ve3_uart.patch

8. [DEV] SW4800: add VE3 RPC LIB
- IPC Library commit (Branch realtek/firmware/android-common | master)
https://cm2sd6.rtkbf.com/gerrit/c/realtek/firmware/android-common/+/181613/
IPC/include/rpcapi.h
IPC/include/RPCProxy.h
IPC/include/RPCstruct.h
IPC/include/rpcstubapi.h
IPC/src/Makefile
IPC/src/rpcapi.c
IPC/src/RPCProxy.c 
IPC/src/rpcstubapi.c 

- kernel commit ( [DEV_FIX][STARK][RPC] add VE3 RPC )
https://cm2sd6.rtkbf.com/gerrit/c/kernel/common/+/181902/
arch/arm64/boot/dts/realtek/rtd16xxb.dtsi
drivers/soc/realtek/common/rpc/rtk_rpc.h
drivers/soc/realtek/common/rpc/rtk_rpc.c
drivers/soc/realtek/common/rpc/rtk_rpc_intr.c
drivers/soc/realtek/common/rpc/rtk_rpc_kern.c
drivers/soc/realtek/common/rpc/rtk_rpc_poll.c
include/soc/realtek/rtk_ipc_shm.h

[DEV_FIX][STARK][RPC] fix the way to clear ve3 interrupt status
https://cm2sd6.rtkbf.com/gerrit/#/c/kernel/common/+/183080/
check the old kernel for owrt: drivers/soc/realtek/common/rpc/rtk_rpc.c
