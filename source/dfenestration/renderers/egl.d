module dfenestration.renderers.egl;

version (Have_bindbc_gles):

public import bindbc.gles.egl;

// HACK: use of a string in the mixin
mixin template DefaultEGLBackend() {
    import bindbc.gles.egl;

    import dfenestration.renderers.egl;

    EGLDisplay eglDisplay;
    EGLConfig eglConfig;

    EGLContext eglContext;

    static assert(is(typeof(getPlatformDisplay)), "Implement `EGLDisplay getPlatformDisplay()`.");

    void loadGL() {
        loadEGL();
        eglDisplay = enforce(getPlatformDisplay());

        EGLint major, minor;
        enforce(eglInitialize(eglDisplay, &major, &minor) == EGL_TRUE);
        checkError();
        trace("EGL ", major, ".", minor, " has been loaded");

        enforce(eglBindAPI(EGL_OPENGL_API) == EGL_TRUE);
        checkError();

        int[] attributes = [
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_CONFORMANT,        EGL_OPENGL_BIT,
            EGL_RENDERABLE_TYPE,   EGL_OPENGL_BIT,
            EGL_COLOR_BUFFER_TYPE, EGL_RGB_BUFFER,

            EGL_RED_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_BLUE_SIZE, 8,
            EGL_ALPHA_SIZE, 8,
            EGL_BUFFER_SIZE, 32,
            EGL_NONE
        ];

        EGLint numConfig;
        enforce(eglChooseConfig(eglDisplay, attributes.ptr, &eglConfig, 1, &numConfig) == EGL_TRUE);
        checkError();

        int[9] ctxAttributes = [
            EGL_CONTEXT_MAJOR_VERSION_KHR, 3,
            EGL_CONTEXT_MINOR_VERSION_KHR, 0,
            EGL_NONE, EGL_NONE,
            EGL_NONE, EGL_NONE,
            EGL_NONE
        ];

        debug {
            ctxAttributes[4..8] = [
                EGL_CONTEXT_OPENGL_DEBUG, EGL_TRUE,
                EGL_CONTEXT_FLAGS_KHR, EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR,
            ];
        }

        eglContext = enforce(eglCreateContext (eglDisplay, eglConfig, EGL_NO_CONTEXT, ctxAttributes.ptr));
        checkError();
    }
}

enum EGL_PLATFORM_XCB_EXT = 0x31DC;
enum EGL_PLATFORM_XCB_SCREEN_EXT = 0x31DE;

enum EGL_PLATFORM_WAYLAND_EXT = 0x31D8;

/* Out-of-band handle values */
enum EGLNativeDisplayType EGL_DEFAULT_DISPLAY = cast(EGLNativeDisplayType)0;
enum EGLSurface EGL_NO_SURFACE = null;
enum EGLSync EGL_NO_SYNC       = null;

/* Out-of-band attribute value */
enum EGLint EGL_DONT_CARE = -1;

enum EGL_CONTEXT_MAJOR_VERSION_KHR = 0x3098;
enum EGL_CONTEXT_MINOR_VERSION_KHR = 0x30FB;
enum EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR = 0x00000001;
enum EGL_CONTEXT_FLAGS_KHR = 0x30FC;

enum : EGLint {
    /* Errors / GetError return values */
    EGL_SUCCESS                     = 0x3000,
    EGL_NOT_INITIALIZED             = 0x3001,
    EGL_BAD_ACCESS                  = 0x3002,
    EGL_BAD_ALLOC                   = 0x3003,
    EGL_BAD_ATTRIBUTE               = 0x3004,
    EGL_BAD_CONFIG                  = 0x3005,
    EGL_BAD_CONTEXT                 = 0x3006,
    EGL_BAD_CURRENT_SURFACE         = 0x3007,
    EGL_BAD_DISPLAY                 = 0x3008,
    EGL_BAD_MATCH                   = 0x3009,
    EGL_BAD_NATIVE_PIXMAP           = 0x300A,
    EGL_BAD_NATIVE_WINDOW           = 0x300B,
    EGL_BAD_PARAMETER               = 0x300C,
    EGL_BAD_SURFACE                 = 0x300D,
    EGL_CONTEXT_LOST                = 0x300E,  /* EGL 1.1 - IMG_power_management */
    /* Reserved 0x300F-0x301F for additional errors */

    /* Config attributes */
    EGL_BUFFER_SIZE                 = 0x3020,
    EGL_ALPHA_SIZE                  = 0x3021,
    EGL_BLUE_SIZE                   = 0x3022,
    EGL_GREEN_SIZE                  = 0x3023,
    EGL_RED_SIZE                    = 0x3024,
    EGL_DEPTH_SIZE                  = 0x3025,
    EGL_STENCIL_SIZE                = 0x3026,
    EGL_CONFIG_CAVEAT               = 0x3027,
    EGL_CONFIG_ID                   = 0x3028,
    EGL_LEVEL                       = 0x3029,
    EGL_MAX_PBUFFER_HEIGHT          = 0x302A,
    EGL_MAX_PBUFFER_PIXELS          = 0x302B,
    EGL_MAX_PBUFFER_WIDTH           = 0x302C,
    EGL_NATIVE_RENDERABLE           = 0x302D,
    EGL_NATIVE_VISUAL_ID            = 0x302E,
    EGL_NATIVE_VISUAL_TYPE          = 0x302F,
    EGL_SAMPLES                     = 0x3031,
    EGL_SAMPLE_BUFFERS              = 0x3032,
    EGL_SURFACE_TYPE                = 0x3033,
    EGL_TRANSPARENT_TYPE            = 0x3034,
    EGL_TRANSPARENT_BLUE_VALUE      = 0x3035,
    EGL_TRANSPARENT_GREEN_VALUE     = 0x3036,
    EGL_TRANSPARENT_RED_VALUE       = 0x3037,
    EGL_NONE                        = 0x3038,  /* Attrib list terminator */
    EGL_BIND_TO_TEXTURE_RGB         = 0x3039,
    EGL_BIND_TO_TEXTURE_RGBA        = 0x303A,
    EGL_MIN_SWAP_INTERVAL           = 0x303B,
    EGL_MAX_SWAP_INTERVAL           = 0x303C,
    EGL_LUMINANCE_SIZE              = 0x303D,
    EGL_ALPHA_MASK_SIZE             = 0x303E,
    EGL_COLOR_BUFFER_TYPE           = 0x303F,
    EGL_RENDERABLE_TYPE             = 0x3040,
    EGL_MATCH_NATIVE_PIXMAP         = 0x3041,  /* Pseudo-attribute (not queryable) */
    EGL_CONFORMANT                  = 0x3042,

    /* Reserved 0x3041-0x304F for additional config attributes */

    /* Config attribute values */
    EGL_SLOW_CONFIG                 = 0x3050,  /* EGL_CONFIG_CAVEAT value */
    EGL_NON_CONFORMANT_CONFIG       = 0x3051,  /* EGL_CONFIG_CAVEAT value */
    EGL_TRANSPARENT_RGB             = 0x3052,  /* EGL_TRANSPARENT_TYPE value */
    EGL_RGB_BUFFER                  = 0x308E,  /* EGL_COLOR_BUFFER_TYPE value */
    EGL_LUMINANCE_BUFFER            = 0x308F,  /* EGL_COLOR_BUFFER_TYPE value */

    /* More config attribute values, for EGL_TEXTURE_FORMAT */
    EGL_NO_TEXTURE                  = 0x305C,
    EGL_TEXTURE_RGB                 = 0x305D,
    EGL_TEXTURE_RGBA                = 0x305E,
    EGL_TEXTURE_2D                  = 0x305F,

    /* Config attribute mask bits */
    EGL_PBUFFER_BIT                 = 0x0001,  /* EGL_SURFACE_TYPE mask bits */
    EGL_PIXMAP_BIT                  = 0x0002,  /* EGL_SURFACE_TYPE mask bits */
    EGL_WINDOW_BIT                  = 0x0004,  /* EGL_SURFACE_TYPE mask bits */
    EGL_VG_COLORSPACE_LINEAR_BIT    = 0x0020,  /* EGL_SURFACE_TYPE mask bits */
    EGL_VG_ALPHA_FORMAT_PRE_BIT     = 0x0040,  /* EGL_SURFACE_TYPE mask bits */
    EGL_MULTISAMPLE_RESOLVE_BOX_BIT = 0x0200,  /* EGL_SURFACE_TYPE mask bits */
    EGL_SWAP_BEHAVIOR_PRESERVED_BIT = 0x0400,  /* EGL_SURFACE_TYPE mask bits */

    EGL_OPENGL_ES_BIT               = 0x0001,  /* EGL_RENDERABLE_TYPE mask bits */
    EGL_OPENVG_BIT                  = 0x0002,  /* EGL_RENDERABLE_TYPE mask bits */
    EGL_OPENGL_ES2_BIT              = 0x0004,  /* EGL_RENDERABLE_TYPE mask bits */
    EGL_OPENGL_BIT                  = 0x0008,  /* EGL_RENDERABLE_TYPE mask bits */

    /* QueryString targets */
    EGL_VENDOR                      = 0x3053,
    EGL_VERSION                     = 0x3054,
    EGL_EXTENSIONS                  = 0x3055,
    EGL_CLIENT_APIS                 = 0x308D,

    /* QuerySurface / SurfaceAttrib / CreatePbufferSurface targets */
    EGL_HEIGHT                      = 0x3056,
    EGL_WIDTH                       = 0x3057,
    EGL_LARGEST_PBUFFER             = 0x3058,
    EGL_TEXTURE_FORMAT              = 0x3080,
    EGL_TEXTURE_TARGET              = 0x3081,
    EGL_MIPMAP_TEXTURE              = 0x3082,
    EGL_MIPMAP_LEVEL                = 0x3083,
    EGL_RENDER_BUFFER               = 0x3086,
    EGL_VG_COLORSPACE               = 0x3087,
    EGL_VG_ALPHA_FORMAT             = 0x3088,
    EGL_HORIZONTAL_RESOLUTION       = 0x3090,
    EGL_VERTICAL_RESOLUTION         = 0x3091,
    EGL_PIXEL_ASPECT_RATIO          = 0x3092,
    EGL_SWAP_BEHAVIOR               = 0x3093,
    EGL_MULTISAMPLE_RESOLVE         = 0x3099,

    /* EGL_RENDER_BUFFER values / BindTexImage / ReleaseTexImage buffer targets */
    EGL_BACK_BUFFER                 = 0x3084,
    EGL_SINGLE_BUFFER               = 0x3085,

    /* OpenVG color spaces */
    EGL_VG_COLORSPACE_sRGB          = 0x3089,  /* EGL_VG_COLORSPACE value */
    EGL_VG_COLORSPACE_LINEAR        = 0x308A,  /* EGL_VG_COLORSPACE value */

    /* OpenVG alpha formats */
    EGL_VG_ALPHA_FORMAT_NONPRE      = 0x308B,  /* EGL_ALPHA_FORMAT value */
    EGL_VG_ALPHA_FORMAT_PRE         = 0x308C,  /* EGL_ALPHA_FORMAT value */

    /* Constant scale factor by which fractional display resolutions &
     * aspect ratio are scaled when queried as integer values.
     */
    EGL_DISPLAY_SCALING             = 10000,

    /* Unknown display resolution/aspect ratio */
    EGL_UNKNOWN                     = -1,

    /* Back buffer swap behaviors */
    EGL_BUFFER_PRESERVED            = 0x3094,  /* EGL_SWAP_BEHAVIOR value */
    EGL_BUFFER_DESTROYED            = 0x3095,  /* EGL_SWAP_BEHAVIOR value */

    /* CreatePbufferFromClientBuffer buffer types */
    EGL_OPENVG_IMAGE                = 0x3096,

    /* QueryContext targets */
    EGL_CONTEXT_CLIENT_TYPE         = 0x3097,

    /* CreateContext attributes */
    EGL_CONTEXT_CLIENT_VERSION      = 0x3098,

    /* Multisample resolution behaviors */
    EGL_MULTISAMPLE_RESOLVE_DEFAULT = 0x309A,  /* EGL_MULTISAMPLE_RESOLVE value */
    EGL_MULTISAMPLE_RESOLVE_BOX     = 0x309B,  /* EGL_MULTISAMPLE_RESOLVE value */

    /* BindAPI/QueryAPI targets */
    EGL_OPENGL_ES_API               = 0x30A0,
    EGL_OPENVG_API                  = 0x30A1,
    EGL_OPENGL_API                  = 0x30A2,

    /* GetCurrentSurface targets */
    EGL_DRAW                        = 0x3059,
    EGL_READ                        = 0x305A,

    /* WaitNative engines */
    EGL_CORE_NATIVE_ENGINE          = 0x305B,

    /* EGL 1.2 tokens renamed for consistency in EGL 1.3 */
    EGL_COLORSPACE                  = EGL_VG_COLORSPACE,
    EGL_ALPHA_FORMAT                = EGL_VG_ALPHA_FORMAT,
    EGL_COLORSPACE_sRGB             = EGL_VG_COLORSPACE_sRGB,
    EGL_COLORSPACE_LINEAR           = EGL_VG_COLORSPACE_LINEAR,
    EGL_ALPHA_FORMAT_NONPRE         = EGL_VG_ALPHA_FORMAT_NONPRE,
    EGL_ALPHA_FORMAT_PRE            = EGL_VG_ALPHA_FORMAT_PRE,

    /* EGL 1.5 */
    EGL_CONTEXT_MAJOR_VERSION       = 0x3098,
    EGL_CONTEXT_MINOR_VERSION       = 0x30FB,
    EGL_CONTEXT_OPENGL_PROFILE_MASK = 0x30FD,
    EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY = 0x31BD,
    EGL_NO_RESET_NOTIFICATION       = 0x31BE,
    EGL_LOSE_CONTEXT_ON_RESET       = 0x31BF,
    EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT = 0x00000001,
    EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT = 0x00000002,
    EGL_CONTEXT_OPENGL_DEBUG        = 0x31B0,
    EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE = 0x31B1,
    EGL_CONTEXT_OPENGL_ROBUST_ACCESS = 0x31B2,
    EGL_OPENGL_ES3_BIT              = 0x00000040,
    EGL_CL_EVENT_HANDLE             = 0x309C,
    EGL_SYNC_CL_EVENT               = 0x30FE,
    EGL_SYNC_CL_EVENT_COMPLETE      = 0x30FF,
    EGL_SYNC_PRIOR_COMMANDS_COMPLETE = 0x30F0,
    EGL_SYNC_TYPE                   = 0x30F7,
    EGL_SYNC_STATUS                 = 0x30F1,
    EGL_SYNC_CONDITION              = 0x30F8,
    EGL_SIGNALED                    = 0x30F2,
    EGL_UNSIGNALED                  = 0x30F3,
    EGL_SYNC_FLUSH_COMMANDS_BIT     = 0x0001,
    EGL_TIMEOUT_EXPIRED             = 0x30F5,
    EGL_CONDITION_SATISFIED         = 0x30F6,
    EGL_SYNC_FENCE                  = 0x30F9,
    EGL_GL_COLORSPACE               = 0x309D,
    EGL_GL_COLORSPACE_SRGB          = 0x3089,
    EGL_GL_COLORSPACE_LINEAR        = 0x308A,
    EGL_GL_RENDERBUFFER             = 0x30B9,
    EGL_GL_TEXTURE_2D               = 0x30B1,
    EGL_GL_TEXTURE_LEVEL            = 0x30BC,
    EGL_GL_TEXTURE_3D               = 0x30B2,
    EGL_GL_TEXTURE_ZOFFSET          = 0x30BD,
    EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_X = 0x30B3,
    EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_X = 0x30B4,
    EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Y = 0x30B5,
    EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x30B6,
    EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Z = 0x30B7,
    EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x30B8,
}

static const EGLTime EGL_FOREVER = 0xFFFFFFFFFFFFFFFFUL;

enum EGLError: uint {
    success = 0x3000,
    notInitialized = 0x3001,
    badAccess = 0x3002,
    badAlloc = 0x3003,
    badAttribute = 0x3004,
    badConfig = 0x3005,
    badContext = 0x3006,
    badCurrentSurface = 0x3007,
    badDisplay = 0x3008,
    badMatch = 0x3009,
    badNativePixmap = 0x300A,
    badNativeWindow = 0x300B,
    badParameter = 0x300C,
    badSurface = 0x300D,
    contextLost = 0x300E,
}

void checkError(string file = __FILE__, size_t line = __LINE__, string func = __FUNCTION__) {
    alias eglGetError_t = extern(C) EGLError function();
    auto errorCode = (cast(eglGetError_t) eglGetError)();
    if (errorCode != EGLError.success) {
        import std.logger;
        // TODO throw something if it's severe.
        error(file, ":", line, " ", func, ": Error code ", errorCode);
    }
}
