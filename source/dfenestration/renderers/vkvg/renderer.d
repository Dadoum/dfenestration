module dfenestration.renderers.vkvg.renderer;

version (VkVG) {
    import std.algorithm;
    import std.array;
    import std.logger;
    import std.meta;
    import std.string;

    import erupted;
    import erupted.vulkan_lib_loader;

    import vkvg;

    import dfenestration.backends.backend;
    import dfenestration.primitives;
    import dfenestration.renderers.renderer;

    import dfenestration.widgets.window;

    public enum vulkanApiVersion = VK_MAKE_API_VERSION(0, 1, 2, 0);

    class VkVGRenderer: Renderer {
        VkInstance instance;
        VkDevice device;
        VkPhysicalDevice physicalDevice;
        VkQueue graphicsQueue;
        VkCommandPool commandPool;

        Device vkvgDevice;

        uint graphicsQueueIndex = -1;
        uint computeQueueIndex = -1;
        uint transferQueueIndex = -1;

        this(Backend backend) {
            VkVGRendererCompatible vkvgBackend = cast(VkVGRendererCompatible) backend;
            assert(vkvgBackend !is null);

            uint vkvgExtsLen;
            vkvg_get_required_instance_extensions(null, &vkvgExtsLen);

            const(char)*[] vkvgExts = new const(char)*[](vkvgExtsLen);

            vkvg_get_required_instance_extensions(vkvgExts.ptr, &vkvgExtsLen);

            const(char)*[] exts = [VK_KHR_SURFACE_EXTENSION_NAME]
            ~ vkvgBackend.requiredExtensions().map!((ext) => cast(const(char)*) ext.toStringz).array
            ~ vkvgExts[0..vkvgExtsLen];

            VkApplicationInfo appInfo = {
                pEngineName: "Dfenestration",
                apiVersion: vulkanApiVersion,
            };

            VkInstanceCreateInfo instInfo = {
                pApplicationInfo		: &appInfo,
                enabledExtensionCount	: cast(uint) exts.length,
                ppEnabledExtensionNames	: exts.ptr,
            };

            debug {
                enum layers = ["VK_LAYER_KHRONOS_validation"];

                uint layerCount;
                vkEnumerateInstanceLayerProperties(&layerCount, null);

                VkLayerProperties[] availableLayers = new VkLayerProperties[](layerCount);
                vkEnumerateInstanceLayerProperties(&layerCount, availableLayers.ptr);

                const(char*)[] enabledLayers;

                loop: foreach (availableLayer; availableLayers) {
                    import core.stdc.string;
                    static foreach (requiredLayer; layers) {
                        if (strncmp(availableLayer.layerName.ptr, requiredLayer, requiredLayer.length) == 0) {
                            enabledLayers ~= requiredLayer.ptr;
                            continue loop;
                        }
                    }
                }

                if (layers.length > enabledLayers.length) {
                    warning("Some validation layers are missing !");
                }

                instInfo.enabledLayerCount = cast(uint) enabledLayers.length;

                if (enabledLayers.length)
                    instInfo.ppEnabledLayerNames = enabledLayers.ptr;
            } else {
                instInfo.enabledLayerCount = 0;
            }

            vkCreateInstance(&instInfo, null, &instance).vkEnforce();

            loadInstanceLevelFunctions(instance);
            vkvgBackend.loadInstanceFuncs(instance);

            uint count;
            vkEnumeratePhysicalDevices(instance, &count, null).vkEnforce();

            auto devices = new VkPhysicalDevice[](count);
            vkEnumeratePhysicalDevices(instance, &count, devices.ptr).vkEnforce();

            /// Discriminate devices on their type (discrete, integrated, or other, usually emulated)
            VkPhysicalDevice[][3] categorize(VkPhysicalDevice[] devices) {
                VkPhysicalDevice[][3] ret;
                static foreach (element; 0..ret.length) {
                    ret[element] = new VkPhysicalDevice[](devices.length);
                    ret[element].length = 0;
                }

                foreach (device; devices) {
                    VkPhysicalDeviceProperties props;
                    vkGetPhysicalDeviceProperties(device, &props);
                    with (VkPhysicalDeviceType) switch (props.deviceType) {
                        case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU:
                            ret[0] ~= device;
                            break;
                        case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU:
                            ret[1] ~= device;
                            break;
                        default:
                            ret[2] ~= device;
                            break;
                    }
                }
                return ret;
            }

            // We will prefer a discrete GPU over an integrated one, and among them we take the one with the most memory.
            foreach (deviceGroup; categorize(devices)) {
                ulong length = deviceGroup.length;
                if (length) {
                    if (length == 1) {
                        // If there is only one device, don't do all the computations and directly take it.
                        if (vkvgBackend.isDeviceSuitable(deviceGroup[0], 0)) {
                            this.physicalDevice = deviceGroup[0];
                            break;
                        }
                    } else {
                        import std.algorithm.searching: maxIndex;
                        this.physicalDevice = deviceGroup[deviceGroup.map!((dev) {
                            if (vkvgBackend.isDeviceSuitable(physicalDevice, 0)) {
                                long size;
                                VkPhysicalDeviceMemoryProperties props;
                                vkGetPhysicalDeviceMemoryProperties(dev, &props);
                                foreach (memoryHeap; props.memoryHeaps[0..props.memoryHeapCount]) {
                                    if (memoryHeap.flags & VK_MEMORY_HEAP_DEVICE_LOCAL_BIT) {
                                        size += memoryHeap.size;
                                    }
                                }
                                return size;
                            } else {
                                return -1;
                            }
                        }).maxIndex()];

                        if (vkvgBackend.isDeviceSuitable(physicalDevice, 0)) {
                            break;
                        }
                    }
                }
            }
            if (!this.physicalDevice) {
                throw new VulkanException("No suitable graphic device has been found for Vulkan.");
            }
            import core.stdc.string: strlen;
            VkPhysicalDeviceProperties props;
            vkGetPhysicalDeviceProperties(physicalDevice, &props);

            // We will now try to get queues.
            uint queueCount = 0;
            vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueCount, null);
            auto queues = new VkQueueFamilyProperties[queueCount];
            vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueCount, queues.ptr);

            bool graphicsQueueSet = false;
            bool computeQueueSet = false;
            bool transferQueueSet = false;

            foreach (queueIndex, queue; queues) {
                if (!graphicsQueueSet && queue.queueFlags & VK_QUEUE_GRAPHICS_BIT) {
                    graphicsQueueSet = true;
                    graphicsQueueIndex = cast(uint) queueIndex;

                    // We can use the graphics queue as other queues, but we will gladly take another one
                    // if there is a better one.
                    if (computeQueueIndex == -1) {
                        computeQueueIndex = cast(uint) queueIndex;
                    }

                    if (transferQueueIndex == -1) {
                        transferQueueIndex = cast(uint) queueIndex;
                    }
                } else if (!computeQueueSet && queue.queueFlags & VK_QUEUE_COMPUTE_BIT) {
                    computeQueueSet = true;
                    computeQueueIndex = cast(uint) queueIndex;
                } else if (!transferQueueSet && queue.queueFlags & VK_QUEUE_TRANSFER_BIT) {
                    transferQueueSet = true;
                    transferQueueIndex = cast(uint) queueIndex;
                }
            }

            VkPhysicalDeviceFeatures enabledFeatures = {0};
            const void* pNext = vkvg_get_device_requirements(&enabledFeatures);

            VkDeviceQueueCreateInfo queueInfo = {
                sType               : VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                queueFamilyIndex    : 0,
                queueCount          : 1,
                flags               : 0,
                pQueuePriorities    : [ 1.0f ].ptr,
            };

            VkDeviceCreateInfo deviceInfo = {
                sType: VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
                queueCreateInfoCount    : 1,
                pQueueCreateInfos       : &queueInfo,
                enabledExtensionCount	: 1,
                ppEnabledExtensionNames	: [VK_KHR_SWAPCHAIN_EXTENSION_NAME].ptr,
                pEnabledFeatures        : &enabledFeatures,
                pNext                   : pNext
            };

            infof("Using %s for rendering. ", props.deviceName[0..strlen(props.deviceName.ptr)]);
            vkCreateDevice(physicalDevice, &deviceInfo, null, &device).vkEnforce();
            loadDeviceLevelFunctions(device);

            VkCommandPoolCreateInfo commandPoolCreateInfo = {
                flags               : 0,
                queueFamilyIndex    : graphicsQueueIndex
            };

            vkCreateCommandPool(device, &commandPoolCreateInfo, null, &commandPool).vkEnforce();

            vkGetDeviceQueue(device, graphicsQueueIndex, 0, &graphicsQueue);

            vkvgDevice = new Device(instance, physicalDevice, device, graphicsQueueIndex, 0, VK_SAMPLE_COUNT_8_BIT, false);
        }

        ~this() {
            if (commandPool) {
                vkDestroyCommandPool(device, commandPool, null);
            }
            destroy(vkvgDevice);
            if (device) {
                vkDestroyDevice(device, null);
            }
            if (instance) {
                vkDestroyInstance(instance, null);
            }
        }

        static bool compatible() {
            import dynamicloader;
            return loadGlobalLevelFunctions() && LibImport.tryLoad!libvkvg();
        }

        /// Called when a new window is created.
        override void initializeWindow(BackendWindow backendWindow) {
            VkVGWindow window = cast(VkVGWindow) backendWindow;
            assert(window !is null, "BackendWindow does not support VkVG? And it compiled?");

            trace("Initializing a window for Vulkan.");

            VkVGRendererProperties* rendererProperties = window.vkvgRendererProperties();
            rendererProperties.renderer = this;
            rendererProperties.swapchainSize = backendWindow.canvasSize();

            // rendererProperties.device
            //     = new Device(instance, physicalDevice, device, graphicsQueueIndex, 0, VK_SAMPLE_COUNT_8_BIT, false);
            VkSurfaceKHR surface;
            window.createSurface(instance, null, surface).vkEnforce();

            VkFormat preferredFormat() {
                uint formatCount = 0;
                vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, &formatCount, null).vkEnforce();
                if (formatCount <= 0) throw new VulkanException("No format is available for the surface.");

                VkSurfaceFormatKHR[] formats = new VkSurfaceFormatKHR[](formatCount);
                vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, &formatCount, formats.ptr).vkEnforce();

                VkFormat selectedFormat = formats[0].format;

                foreach (format; formats) {
                    if (format.colorSpace != VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
                        continue;
                    }

                    if (format.format == VK_FORMAT_B8G8R8A8_UNORM) {
                        return format.format;
                    }
                }

                error("Cannot pick a good color space. Expect color problems!");
                return selectedFormat;
            }

            VkFormat imageFormat = preferredFormat();
            rendererProperties.imageFormat = imageFormat;
            rendererProperties.surface = surface;

            VkSurfaceCapabilitiesKHR capabilities;
            vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physicalDevice, surface, &capabilities).vkEnforce();

            uint imageBufferCount = 2;
            if (capabilities.minImageCount > imageBufferCount) {
                imageBufferCount = capabilities.minImageCount;
            } else if (capabilities.maxImageCount > 0 && imageBufferCount > capabilities.maxImageCount) {
                imageBufferCount = capabilities.maxImageCount;
            }

            VkSemaphoreCreateInfo semaphoreCreateInfo;

            vkCreateSemaphore(device, &semaphoreCreateInfo, null, &rendererProperties.graphicsSemaphore).vkEnforce();
            vkCreateSemaphore(device, &semaphoreCreateInfo, null, &rendererProperties.presentationSemaphore).vkEnforce();

            VkSwapchainCreateInfoKHR swapchainCreateInfo = {
                surface                 : surface,
                minImageCount           : imageBufferCount,
                imageFormat             : imageFormat,
                imageColorSpace         : VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
                imageArrayLayers        : 1,
                imageUsage              : VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
                imageSharingMode        : VK_SHARING_MODE_EXCLUSIVE,
                queueFamilyIndexCount   : 1,
                // pQueueFamilyIndices     : (uint32_t[]) { 0 },
                preTransform            : VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR,
                compositeAlpha          : VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR,
                presentMode             : VK_PRESENT_MODE_FIFO_KHR, // It should always be supported.
            };
            rendererProperties.swapchainCreateInfo = swapchainCreateInfo;
        }

        bool createSwapchain(VkVGWindow window, uint width, uint height) {
            auto vkvgRendererProperties = window.vkvgRendererProperties();
            if (!vkvgRendererProperties.surface) {
                // the window has probably not been initialized, it could be hidden or something.
                trace("Draw has been asked while the window doesn't exist");
                return false;
            }

            vkvgRendererProperties.destroySwapchain();

            VkSwapchainCreateInfoKHR swapchainCreateInfo = vkvgRendererProperties.swapchainCreateInfo;
            swapchainCreateInfo.imageExtent = VkExtent2D(width, height);

            VkSwapchainKHR swapchain;
            vkCreateSwapchainKHR(
                device,
                &swapchainCreateInfo,
                null,
                &swapchain
            ).vkEnforce();

            vkvgRendererProperties.swapchain = swapchain;

            uint imageCount;
            vkGetSwapchainImagesKHR(
                device,
                swapchain,
                &imageCount,
                null
            ).vkEnforce();

            auto images = new VkImage[](imageCount);
            vkGetSwapchainImagesKHR(
                device,
                swapchain,
                &imageCount,
                images.ptr
            ).vkEnforce();

            vkvgRendererProperties.vkvgSurface = new Surface(vkvgDevice, width, height); // TODO fractional scaling.

            vkvgRendererProperties.commandBuffers.length = imageCount;
            VkCommandBufferAllocateInfo commandBufferAllocateInfo = {
                commandPool         : commandPool,
                level               : VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                commandBufferCount  : imageCount
            };

            vkAllocateCommandBuffers(
                device,
                &commandBufferAllocateInfo,
                vkvgRendererProperties.commandBuffers.ptr
            ).vkEnforce();

            auto sourceImage = vkvgRendererProperties.vkvgSurface.vkImage();

            vkvgRendererProperties.imageBuffers.length = imageCount;
            // Credit: https://github.com/jpbruyere/vkvg/blob/405ebe04413f8cd7cc82d990c497de58743b612e/doc/sample_1.cpp
            foreach (index, ref imageBuffer; vkvgRendererProperties.imageBuffers) {
                auto image = images[index];
                auto commandBuffer = vkvgRendererProperties.commandBuffers[index];

                imageBuffer.image = image;
                VkImageViewCreateInfo imageViewCreateInfo = {
                    flags               : 0,
                    image               : image,
                    viewType            : VK_IMAGE_VIEW_TYPE_2D,
                    format              : vkvgRendererProperties.imageFormat,
                    components          : {
                        r   : VK_COMPONENT_SWIZZLE_R,
                        g   : VK_COMPONENT_SWIZZLE_G,
                        b   : VK_COMPONENT_SWIZZLE_B,
                        a   : VK_COMPONENT_SWIZZLE_A,
                    },
                    subresourceRange    : {
                        aspectMask      : VK_IMAGE_ASPECT_COLOR_BIT,
                        baseMipLevel    : 0,
                        levelCount      : 1,
                        baseArrayLayer  : 0,
                        layerCount      : 1,
                    }
                };

                vkCreateImageView(
                    device,
                    &imageViewCreateInfo,
                    null,
                    &imageBuffer.view
                ).vkEnforce();

                void copyImage(
                    VkImage sourceImage,
                    int srcX,
                    int srcY,
                    VkImage destinationImage,
                    int destX,
                    int destY
                ) {
                    VkCommandBufferBeginInfo commandBufferBeginInfo = {
                        flags               : 0,
                        pInheritanceInfo    : null,
                    };

                    vkBeginCommandBuffer(commandBuffer, &commandBufferBeginInfo).vkEnforce();

                    void changeImageLayout(
                        VkImage image,
                        VkImageAspectFlags aspectMask,
                        VkImageLayout oldImageLayout,
                        VkImageLayout newImageLayout,
                        VkPipelineStageFlags srcStages,
                        VkPipelineStageFlags destStages) {
                        VkImageMemoryBarrier imageMemoryBarrier = {
                            srcAccessMask       : 0,
                            dstAccessMask       : 0,
                            oldLayout           : oldImageLayout,
                            newLayout           : newImageLayout,
                            srcQueueFamilyIndex : VK_QUEUE_FAMILY_IGNORED,
                            dstQueueFamilyIndex : VK_QUEUE_FAMILY_IGNORED,
                            image               : image,
                            subresourceRange    : {
                                aspectMask      : aspectMask,
                                baseMipLevel    : 0,
                                levelCount      : 1,
                                baseArrayLayer  : 0,
                                layerCount      : 1,
                            },
                        };

                        switch (oldImageLayout) {
                            case VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL:
                                imageMemoryBarrier.srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
                                break;

                            case VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL:
                                imageMemoryBarrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
                                break;

                            case VK_IMAGE_LAYOUT_PREINITIALIZED:
                                imageMemoryBarrier.srcAccessMask = VK_ACCESS_HOST_WRITE_BIT;
                                break;

                            default:
                                break;
                        }

                        switch (newImageLayout) {
                            case VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL:
                                imageMemoryBarrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
                                break;

                            case VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL:
                                imageMemoryBarrier.dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
                                break;

                            case VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL:
                                imageMemoryBarrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
                                break;

                            case VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL:
                                imageMemoryBarrier.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
                                break;

                            case VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL:
                                imageMemoryBarrier.dstAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
                                break;

                            default:
                                break;
                        }

                        vkCmdPipelineBarrier(
                            commandBuffer,
                            srcStages,
                            destStages,
                            0,
                            0,
                            null,
                            0,
                            null,
                            1,
                            &imageMemoryBarrier
                        );
                    }

                    changeImageLayout(
                        destinationImage,
                        VK_IMAGE_ASPECT_COLOR_BIT,
                        VK_IMAGE_LAYOUT_UNDEFINED,
                        VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                        VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
                        VK_PIPELINE_STAGE_TRANSFER_BIT
                    );

                    changeImageLayout(
                        sourceImage,
                        VK_IMAGE_ASPECT_COLOR_BIT,
                        VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                        VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                        VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
                        VK_PIPELINE_STAGE_TRANSFER_BIT
                    );

                    VkImageCopy imageCopyOperation = {
                        srcSubresource  : {
                            aspectMask      : VK_IMAGE_ASPECT_COLOR_BIT,
                            mipLevel        : 0,
                            baseArrayLayer  : 0,
                            layerCount      : 1
                        },
                        srcOffset       : {
                            x   : srcX,
                            y   : srcY,
                            z   : 0,
                        },
                        dstSubresource  : {
                            aspectMask      : VK_IMAGE_ASPECT_COLOR_BIT,
                            mipLevel        : 0,
                            baseArrayLayer  : 0,
                            layerCount      : 1
                        },
                        dstOffset       : {
                            x   : destX,
                            y   : destY,
                            z   : 0,
                        },
                        extent          : {
                            width   : width,
                            height  : height,
                            depth   : 1,
                        }
                    };

                    vkCmdCopyImage(
                        commandBuffer,
                        sourceImage,
                        VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                        destinationImage,
                        VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                        1,
                        &imageCopyOperation);

                    changeImageLayout(
                        destinationImage,
                        VK_IMAGE_ASPECT_COLOR_BIT,
                        VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                        VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
                        VK_PIPELINE_STAGE_TRANSFER_BIT,
                        VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT
                    );

                    changeImageLayout(
                        sourceImage,
                        VK_IMAGE_ASPECT_COLOR_BIT,
                        VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                        VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                        VK_PIPELINE_STAGE_TRANSFER_BIT,
                        VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT
                    );

                    vkEndCommandBuffer(commandBuffer).vkEnforce();
                }

                copyImage(sourceImage, 0, 0, image, 0, 0);
            }

            return true;
        }

        /// Called when a window is deleted.
        override void cleanup(BackendWindow backendWindow) {
            VkVGWindow window = cast(VkVGWindow) backendWindow;
            assert(window !is null);

            window.vkvgRendererProperties().dispose();
        }

        /// Called when a window is resized.
        override void resize(BackendWindow backendWindow, uint width, uint height) {
            VkVGWindow window = cast(VkVGWindow) backendWindow;
            assert(window !is null);

            auto props = window.vkvgRendererProperties();
            props.destroySwapchain();
            props.swapchainSize = Size(width, height);
        }

        /++
         + Called when a window needs to be drawn.
         + It should call window's paint function with the context, and doesn't have to make any operation on the surface
         + before calling it.
         + IT HAS TO SUPPORT SCALING, AND ADJUST THE CANVAS SIZE APPROPRIATELY (see NanoVega's BaseRenderer for reference).
         +/
        override void draw(BackendWindow backendWindow) {
            VkVGWindow window = cast(VkVGWindow) backendWindow;
            assert(window !is null);

            uint imageIndex;
            auto vulkanProps = window.vkvgRendererProperties();

            if (!vulkanProps.swapchain) {
                if (!createSwapchain(window, vulkanProps.swapchainSize.tupleof)) {
                    return;
                }
            }

            vkDeviceWaitIdle(device);

            VkResult result = vkAcquireNextImageKHR(
                device,
                vulkanProps.swapchain,
                ulong.max,
                vulkanProps.presentationSemaphore,
                VK_NULL_HANDLE,
                &(window.vkvgRendererProperties().currentImageIndex)
            );

            if (result == VK_ERROR_OUT_OF_DATE_KHR || result == VK_SUBOPTIMAL_KHR) {
                createSwapchain(window, backendWindow.canvasSize().tupleof);
                draw(window);
                return;
            }

            if (result != VK_SUCCESS) {
                throw new VulkanException("Cannot get the next frame!");
            }

            window.paint(new VkVGContext(vulkanProps.vkvgSurface));
        }


        /++
         + Called when a window that has been drawn has to be presented. It is timed to not exceed a certain number of
         + frames.
         +/
        override void present(BackendWindow backendWindow) {
            VkVGWindow window = cast(VkVGWindow) backendWindow;
            assert(window !is null);

            auto vulkanProps = window.vkvgRendererProperties();

            // TODO optimize that
            if (!vulkanProps.swapchain) {
                return;
            }

            VkSemaphore[] waitSemaphores = [ vulkanProps.presentationSemaphore ];
            VkSemaphore[] signalSemaphores = [ vulkanProps.graphicsSemaphore ];

            VkPipelineStageFlags waitStages = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
            uint imageIndex = vulkanProps.currentImageIndex;

            VkSubmitInfo submitInfo = {
                waitSemaphoreCount      : cast(uint) waitSemaphores.length,
                pWaitSemaphores         : waitSemaphores.ptr,
                pWaitDstStageMask       : &waitStages,
                commandBufferCount      : 1,
                pCommandBuffers         : &vulkanProps.commandBuffers[imageIndex],
                signalSemaphoreCount    : cast(uint) signalSemaphores.length,
                pSignalSemaphores       : signalSemaphores.ptr
            };

            vkQueueSubmit(graphicsQueue, 1, &submitInfo, null).vkEnforce();

            auto swapchains = [vulkanProps.swapchain];

            VkPresentInfoKHR presentInfo = {
                waitSemaphoreCount      : cast(uint) signalSemaphores.length,
                pWaitSemaphores         : signalSemaphores.ptr,
                swapchainCount          : cast(uint) swapchains.length,
                pSwapchains             : swapchains.ptr,
                pImageIndices           : &imageIndex
            };

            vkQueuePresentKHR(graphicsQueue, &presentInfo).vkEnforce();
        }
    }

    interface VkVGRendererCompatible: BackendCompatibleWith!VkVGRenderer {
        VkVGWindow createBackendWindow(Window w);
        /++
         + VkExtensions required for backend.
         +/
        string[] requiredExtensions();
        void loadInstanceFuncs(VkInstance instance);
        bool isDeviceSuitable(VkPhysicalDevice device, uint queueFamilyIndex);
    }

    struct VkVGRendererProperties {
      // private:
        // vkvg.Device device;
        VkVGRenderer renderer;
        VkSurfaceKHR surface;
        VkFormat imageFormat;

        struct ImageBuffer {
            VkImage image;
            VkImageView view;
        }

        VkCommandBuffer[] commandBuffers;

        VkSemaphore graphicsSemaphore;
        VkSemaphore presentationSemaphore;

        VkSwapchainCreateInfoKHR swapchainCreateInfo;

        Size swapchainSize;
        VkSwapchainKHR swapchain;
        ImageBuffer[] imageBuffers;
        vkvg.Surface vkvgSurface;
        uint currentImageIndex = -1;

        void destroySwapchain() {
            if (!swapchain) {
                return;
            }

            destroy(vkvgSurface);
            vkDeviceWaitIdle(renderer.device).vkEnforce();
            vkDestroySwapchainKHR(renderer.device, swapchain, null);
            swapchain = null;

            foreach (imageBuffer; imageBuffers) {
                vkDestroyImageView(renderer.device, imageBuffer.view, null);
                // FIXME why it doesn't work??
                // vkDestroyImage(renderer.device, imageBuffer.image, null);
            }
            imageBuffers.length = 0;
        }

        void dispose() {
            destroySwapchain();

            vkDestroySemaphore(renderer.device, presentationSemaphore, null);
            vkDestroySemaphore(renderer.device, graphicsSemaphore, null);

            vkDestroySurfaceKHR(renderer.instance, surface, null);
        }
    }

    interface VkVGWindow: BackendWindow {
        VkVGRendererProperties* vkvgRendererProperties();
        VkResult createSurface(VkInstance instance, const VkAllocationCallbacks* allocator, out VkSurfaceKHR surface);
    }

    void vkEnforce(VkResult result, string file = __FILE__, int line = __LINE__) @trusted {
        if (result != VK_SUCCESS) {
            throw new VulkanException(result, file, line);
        }
    }

    class VulkanException: Exception {
        this(VkResult result = cast(VkResult) null, string file = __FILE__, size_t line = __LINE__) @trusted {
            import std.format;
            super(format!"Vulkan error at %s:%d: %s"(file, line, result) ~ (result == cast(VkResult) null ? "" : format!" (code %d)"(result)), file, line);
        }

        this(string message, string file = __FILE__, size_t line = __LINE__) @trusted {
            super(message, file, line);
        }
    }
} else {
    alias VkVGRenderer = AliasSeq!();
    alias VkVGRendererCompatible = AliasSeq!();
}