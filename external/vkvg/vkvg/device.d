module vkvg.device;

version(VkVG):

import erupted;
import vkvg;

class Device/+(bool hardwareAccelerated)+/ {
    VkvgDevice handle;
    private bool owned = false;

    this(vkvg_device_create_info_t* info) {
        handle = vkvg_device_create(info);
        owned = true;
    }

    void getDpy(out int hdpy, out int vdpy) {
        vkvg_device_get_dpy(handle, &hdpy, &vdpy);
    }

    void setDpy(int hdpy, int vdpy) {
        vkvg_device_set_dpy(handle, hdpy, vdpy);
    }

    ~this() {
        if (owned) {
            vkvg_device_destroy(handle);
        }
    }
}
