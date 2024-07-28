module vkvg.device;

version(VkVG):

import erupted;
import vkvg;

class Device/+(bool hardwareAccelerated)+/ {
    vkvg_device_t* handle;
    private bool owned = false;

    this(VkInstance inst, VkPhysicalDevice phy, VkDevice vkdev, uint qFamIdx, uint qIndex) {
        handle = vkvg_device_create_from_vk(inst, phy, vkdev, qFamIdx, qIndex);
        owned = true;
    }

    this(VkInstance inst, VkPhysicalDevice phy, VkDevice vkdev, uint qFamIdx, uint qIndex, VkSampleCountFlags samples, bool deferredResolve) {
        handle = vkvg_device_create_from_vk_multisample(inst, phy, vkdev, qFamIdx, qIndex, samples, deferredResolve);
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
