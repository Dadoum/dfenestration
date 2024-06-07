module vkvg.surface;

version(VkVG):

import erupted;
import vkvg;

class Surface {
    vkvg_surface_t* handle;
    bool owned = false;

    this(Device vkvgDevice, uint width, uint height) {
        handle = vkvg_surface_create(vkvgDevice.handle, width, height);
        owned = true;
    }

    ~this() {
        if (owned) {
            vkvg_surface_destroy(handle);
        }
    }

    void clear() {
        vkvg_surface_clear(handle);
    }

    VkImage vkImage() {
        return vkvg_surface_get_vk_image(handle);
    }
}
