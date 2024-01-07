## Overview

This repository contains tested builds of [OpenWrt firmware for the GL.iNet GL-MT6000](https://openwrt.org/toh/gl.inet/gl-mt6000).

It builds the images using the [OpenWrt ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder). One advantage of this over from-source custom builds is that the kernel is the same as the official builds, so all kmods from the standard repos are installable.

After installing, the device will be similar to the official OpenWrt image. You can upgrade using the official sysupgrade firmwares matching the patched firmware. If you are reverting to stock later, make sure to use the exact same stock firmware version as you originally upgraded from. 


## Changes compared to the official OpenWrt firmware

* Applied [patches](./patches/)
  * hnyman's LED patch from [PR-14355](https://github.com/openwrt/openwrt/pull/14355)
* LuCI, [Attended Sysupgrade](https://openwrt.org/docs/guide-user/installation/attended.sysupgrade)
* my favourite red prompt
* @obsy's [sysinfo](https://github.com/obsy/packages/blob/master/sysinfo/files/sbin/sysinfo.sh)


## Download firmware

See the [releases page](https://github.com/xabolcs/openwrt_glinet_gl-mt6000_patched_dts/releases/) for links to the firmware images.

These are built using [this Github workflow](./.github/workflows/build_release_images.yml). You can see the build logs [here](https://github.com/xabolcs/openwrt_glinet_gl-mt6000_patched_dts/actions?query=workflow%3ABuild-Release-Images).


## Building & Customizing

If you want to build the firmwares yourself, checkout this repo and:

```bash
make

# or to add other packages
make PACKAGES=nano
```

The firmware will be located at `build/openwrt-imagebuilder-*-mediatek-filogic.Linux-x86_64/bin/targets/mediatek/filogic`. To customize the firmware further (packages etc), see the [ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) wiki.


## Thanks

### Thanks to @jwmullally.

Thanks to @jwmullally for creating this nice addition to ImageBuilder!
* [Custom DTS / DTB building with ImageBuilder](http://lists.openwrt.org/pipermail/openwrt-devel/2021-March/034239.html)
* [jwmullally/openwrt_wpa8630p_v2_fullmem](https://github.com/jwmullally/openwrt_wpa8630p_v2_fullmem)
* [jwmullally/openwrt_wpa8630pv2_patched_firmware](https://github.com/jwmullally/openwrt_wpa8630pv2_patched_firmware)

### Thanks to @hnyman.

For fixing the LED functionality [on the first day](https://forum.openwrt.org/t/gl-mt6000-discussions/173524/311) after flashing OpenWrt to GL-MT6000! 🙏
