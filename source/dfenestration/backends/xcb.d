module dfenestration.backends.xcb;

version (Xcb):

import std.datetime;
import std.exception;
import std.format;
import std.logger;
import std.string;
import std.traits: ReturnType, Parameters, isIntegral;

import core.stdc.stdlib;

import libasync;

import xcb.xcb;
import xcb.icccm;

import dfenestration.backends.backend;
import dfenestration.primitives;
import dfenestration.renderers.nanovega.glrenderer;
import dfenestration.renderers.vkvg.renderer;
import dfenestration.renderers.context;
import dfenestration.renderers.renderer;
import dfenestration.widgets.window;

class XcbBackend: Backend, VkVGRendererCompatible, NanoVegaGLRendererCompatible {
    xcb_connection_t* connection;
    int screenNumber;
    xcb_screen_t* screen;
    xcb_visualid_t visual;

    Renderer renderer;
    XcbWindow[xcb_window_t] xcbWindows;

    this() {
        connection = xcb_connect(null, &screenNumber);
        if (connection == null) {
            throw new XcbException("Can't connect to X server!");
        }

        auto setup = xcb_get_setup(connection);
        screen = setup.xcb_setup_roots_iterator().data;

        visual = screen.root_visual;

        renderer = this.buildRenderer();

        AsyncEvent event = new AsyncEvent(super._eventLoop, xcb_get_file_descriptor(connection));
        event.run((code) => roundtrip());
    }

    final void roundtrip() {
        xcb_flush(connection);
        while (auto event = xcb_poll_for_event(connection)) {
            scope(exit) free(event);
            if (!event.response_type) {
                error("X11 error: ", (cast(xcb_generic_error_t*) event).error_code.x11ErrorDescription());
                continue;
            }
            // info("event time!");

            switch (event.response_type) {
                case XCB_EXPOSE:
                    auto event_expose = cast(xcb_expose_event_t*) event;
                    xcbWindows[event_expose.window].scheduleRedraw();
                    break;
                case XCB_CLIENT_MESSAGE | 1 << 7:
                    auto event_cm = cast(xcb_client_message_event_t*) event;
                    if (event_cm.data.data32[0] == atom!"WM_DELETE_WINDOW") {
                        xcbWindows[event_cm.window].dWindow.onCloseRequest();
                    } // else if (event_cm.data.data32[0] == connection.atom!"_NET_WM_NAME"()) {
                    //     if (window !is null) {
                    //         window.foreignTitleChange(window.title());
                    //     }
                    // } else if (event_cm.data.data32[0] == connection.atom!"_NET_WM_NAME"()) {
                    //     if (window !is null) {
                    //         window.foreignTitleChange(window.title());
                    //     }
                    // }
                    break;

                default:
                    break;
            }
        }
    }

    ~this() {
        xcb_disconnect(connection);
    }

    template atom(string name) {
        xcb_atom_t a;

        xcb_atom_t atom() {
            if(!a) {
                const(xcb_intern_atom_reply_t*) reply = xcbEnforce!xcb_intern_atom_reply(
                    connection,
                    xcb_intern_atom(
                        connection,
                        0,
                        name.length,
                        name
                    )
                );

                enforce(reply.atom != 0, "X server replied no atom.");
                a = reply.atom;
            }

            assert(a != 0);
            return a;
        }
    }

    override XcbWindow createBackendWindow(Window window) {
        auto xcbWindow = new XcbWindow(this, window);
        xcbWindows[xcbWindow.window] = xcbWindow;
        return xcbWindow;
    }

    version (NanoVega) {
        import dfenestration.renderers.egl;

        EGLDisplay eglDisplay;

        EGLConfig eglConfig;
        EGLContext eglContext;

        void loadGL() {
            loadEGLLibrary();
            loadBasicEGLSymbols();
            eglDisplay = enforce(eglGetPlatformDisplay(
                EGL_PLATFORM_XCB_EXT,
                cast(void*) connection,
                [const(long)(EGL_PLATFORM_XCB_SCREEN_EXT), /+ screen +/ const(long)(screenNumber), const(long)(EGL_NONE)].ptr
            ));
            initializeEGLForDisplay(eglDisplay, /+ out +/ eglConfig, /+ out +/ eglContext);
        }

        bool loadGLLibrary() {
            return true;
        }
    }

    version (VkVG) {
        public import erupted;

        /++
         + VkExtensions required for backend.
         +/
        string[] requiredExtensions() {
            return ["VK_KHR_xcb_surface"];
        }

        void loadInstanceFuncs(VkInstance instance) {
            return loadInstanceLevelFunctionsExt(instance);
        }

        bool isDeviceSuitable(VkPhysicalDevice device, uint queueFamilyIndex) {
            return cast(bool) vkGetPhysicalDeviceXcbPresentationSupportKHR(device, queueFamilyIndex, connection, visual);
        }
    }
}

version (VkVG) {
    import erupted.platform_extensions;

    mixin Platform_Extensions!USE_PLATFORM_XCB_KHR vulkanXcb;
}

class XcbWindow: BackendWindow, VkVGWindow, NanoVegaGLWindow {
    Window dWindow;
    XcbBackend backend;

    xcb_window_t window;

    this(XcbBackend backend, Window dWindow) {
        this.backend = backend;
        this.dWindow = dWindow;
        // screen = *setup.xcb_setup_visual_iterator().data;
        auto connection = backend.connection;
        auto screen = backend.screen;

        xcb_depth_iterator_t depth_iter = xcb_screen_allowed_depths_iterator (screen);
        for (; depth_iter.rem; xcb_depth_next (&depth_iter)) {
            xcb_visualtype_iterator_t visual_iter;

            visual_iter = xcb_depth_visuals_iterator (depth_iter.data);
            for (; visual_iter.rem; xcb_visualtype_next (&visual_iter)) {
                if (depth_iter.data.depth == 32) {
                    // visual = visual_iter.data.visual_id;
                    break;
                }
            }
        }

        uint[2] values = [
            screen.black_pixel,
            XCB_EVENT_MASK_KEY_PRESS | XCB_EVENT_MASK_KEY_RELEASE |
            XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE |
            XCB_EVENT_MASK_ENTER_WINDOW | XCB_EVENT_MASK_LEAVE_WINDOW |
            XCB_EVENT_MASK_POINTER_MOTION | XCB_EVENT_MASK_BUTTON_MOTION |
            XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_VISIBILITY_CHANGE |
            XCB_EVENT_MASK_FOCUS_CHANGE | XCB_EVENT_MASK_KEYMAP_STATE |
            XCB_EVENT_MASK_STRUCTURE_NOTIFY | XCB_EVENT_MASK_PROPERTY_CHANGE,
        ];

        window = xcb_generate_id(connection);
        xcb_create_window_checked(
            connection,
            XCB_COPY_FROM_PARENT, window, screen.root,
            -1, -1, 200, 200, 0,
            XCB_WINDOW_CLASS_INPUT_OUTPUT,
            backend.visual,
            XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK,
            values.ptr
        ).xcbEnforce(connection);

        xcbProperty!"WM_PROTOCOLS" = [backend.atom!"WM_DELETE_WINDOW"];
        backend.renderer.initializeWindow(this);
    }

    T xcbProperty(string propertyName, T: U[], U)(xcb_atom_t type = 0) {
        if (type == 0) {
            type = backend.atom!(atomNameForType!T);
        }

        xcb_get_property_reply_t* reply = xcbEnforce!xcb_get_property_reply(
            backend.connection,
            xcb_get_property(
                backend.connection,
                cast(ubyte) false,
                window,
                backend.atom!propertyName,
                type,
                cast(uint) 0,
                cast(uint) 1024
            )
        );
        scope(exit) free(reply);

        return cast(T) xcb_get_property_value(reply)[0..xcb_get_property_value_length(reply)];
    }

    T xcbProperty(string propertyName, T)(xcb_atom_t type = 0) {
        if (type == 0) {
            type = backend.atom!(atomNameForType!T);
        }

        xcb_get_property_reply_t* reply = xcbEnforce!xcb_get_property_reply(
            backend.connection,
            xcb_get_property(
                backend.connection,
                cast(ubyte) false,
                window,
                backend.atom!propertyName,
                type,
                cast(uint) 0,
                cast(uint) 1024
            )
        );
        scope(exit) free(reply);

        return *cast(T*) xcb_get_property_value(reply);
    }

    void xcbProperty(string propertyName, T: U[], U)(T data, xcb_atom_t type = 0) {
        if (type == 0) {
            type = backend.atom!(atomNameForType!T);
        }

        xcb_change_property_checked(
            backend.connection,
            XCB_PROP_MODE_REPLACE,
            window,
            backend.atom!propertyName,
            type,
            U.sizeof * 8,
            cast(uint) data.length,
            data.ptr
        ).xcbEnforce(backend.connection);
        xcb_flush(backend.connection);
    }

    void xcbProperty(string propertyName, T)(T data, xcb_atom_t type = 0, ubyte format = T.sizeof) {
        if (type == 0) {
            type = backend.atom!(atomNameForType!T);
        }

        xcb_change_property_checked(
            backend.connection,
            XCB_PROP_MODE_REPLACE,
            window,
            backend.atom!propertyName,
            type,
            format,
            1,
            &data
        ).xcbEnforce(backend.connection);
        xcb_flush(backend.connection);
    }

    pragma(inline, true)
    final void sendClientMessage(T: U[n], U, size_t n)(xcb_window_t destination, xcb_atom_t type, T data, ubyte format = U.sizeof * 8) if (T.sizeof == 20) {
        xcb_client_message_event_t event = {
            response_type   : XCB_CLIENT_MESSAGE,
            format          : format,
            sequence        : 0,
            window          : window,
            type            : type,
        };
        event.data.data32 = cast(uint[5]) data;
        // event.data.data8 = cast(uint[20]) data; TODO
        xcb_send_event_checked(
            backend.connection,
            false,
            destination,
            XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY | XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT,
            cast(const(char*)) &event
        ).xcbEnforce(backend.connection);
    }

    pragma(inline, true)
    final void sendMessageToRootWindow(T: U[n], U, size_t n)(xcb_atom_t type, T data, ubyte format = U.sizeof * 8) if (T.sizeof == 20)
        => sendClientMessage!(T, U, n)(backend.screen.root, __traits(parameters));

    void paint(Context context) {
        dWindow.paint(context);
    }

    void invalidate() {
        xcb_expose_event_t invalidate_event;
        invalidate_event.window = window;
        invalidate_event.response_type = XCB_EXPOSE;
        invalidate_event.x = 0;
        invalidate_event.y = 0;
        Size size = size();
        assert(size.width <= ushort.max && size.height <= ushort.max, "Window too big for X11");
        invalidate_event.width = cast(ushort) size.width;
        invalidate_event.height = cast(ushort) size.height;
        xcb_send_event_checked(backend.connection, false, window, XCB_EVENT_MASK_EXPOSURE, cast(char*) &invalidate_event)
            .xcbEnforce(backend.connection);
        xcb_flush(backend.connection);
    }

    void role(Role role) {

    }

    string title() {
        return xcbProperty!("_NET_WM_NAME", string);
    }
    void title(string value) {
        xcbProperty!"_NET_WM_NAME" = value;
    }

    void cursor(CursorType value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    Point position() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void position(Point value) {
        if (_parent) {
            Point parentPosition = _parent.position;
            value.x -= parentPosition.x;
            value.y -= parentPosition.y;
        }

        const(uint)[2] array = [value.tupleof];
        xcb_configure_window_checked(backend.connection, window, XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y, array.ptr)
            .xcbEnforce(backend.connection);
    }

    Size size() {
        auto reply = xcbEnforce!xcb_get_geometry_reply(backend.connection, xcb_get_geometry(backend.connection, window));
        scope(exit) free(reply);
        return Size(cast(uint) reply.width, cast(uint) reply.height);
    }
    void size(Size value) {
        const(uint)[2] array = [value.tupleof];
        xcb_configure_window_checked(backend.connection, window, XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT, array.ptr)
            .xcbEnforce(backend.connection);
    }

    Size minimumSize() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void minimumSize(Size value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    Size maximumSize() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void maximumSize(Size value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    Size canvasSize() {
        return size();
    }

    bool resizable() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void resizable(bool value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    bool decorated() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void decorated(bool value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    XcbWindow _parent;
    void parent(BackendWindow window) {
        XcbWindow parentWindow = cast(XcbWindow) window;
        assert(_parent !is null);
        _parent = parentWindow;
        xcbProperty!"WM_TRANSIENT_FOR" = parentWindow.window;
    }

    void show() {
        xcb_map_window_checked(backend.connection, window)
            .xcbEnforce(backend.connection);
    }
    void hide() {
        xcb_unmap_window_checked(backend.connection, window)
            .xcbEnforce(backend.connection);
    }
    void minimize() {
        uint[5] event = [
            XCB_ICCCM_WM_STATE_ICONIC,
            0,
            0,
            0,
            0
        ];
        sendMessageToRootWindow(backend.atom!"WM_CHANGE_STATE", event);
    }

    void present() {
        uint value = XCB_STACK_MODE_ABOVE;
        xcb_configure_window_checked(backend.connection, window, XCB_CONFIG_WINDOW_STACK_MODE, &value)
            .xcbEnforce(backend.connection);
    }
    bool focused() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }

    bool maximized() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void maximized(bool value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    double opacity() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void opacity(double value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    double scaling() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return 1;
    }
    void scaling(double value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void close() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void moveDrag() {
        // uint[5] event = [
        //     XCB_ICCCM_WM_STATE_ICONIC,
        //     0,
        //     0,
        //     0,
        //     0
        // ];
        // sendMessageToRootWindow(backend.atom!"_NET_WM_MOVERESIZE", event);
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }
    void resizeDrag(ResizeEdge edge) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void showWindowControlMenu(Point location) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    bool redrawScheduled = false;
    final void scheduleRedraw() {
        if (!redrawScheduled) {
            redrawScheduled = true;
            backend.runInMainThread({
                backend.renderer.draw(this);
                redrawScheduled = false;
            });
        }
    }

    version (NanoVega) {
        import bindbc.gles.egl;
        import bindbc.opengl;

        import dfenestration.renderers.egl;
        import arsd.nanovega;

        EGLSurface eglSurface;

        NVGContext _nvgContext;

        ref NVGContext nvgContext() {
            return _nvgContext;
        }

        void createWindowGL(uint width, uint height) {
            EGLint[5] attributes = [
                EGL_GL_COLORSPACE, EGL_GL_COLORSPACE_LINEAR, // or use EGL_GL_COLORSPACE_SRGB for sRGB framebuffer
                EGL_RENDER_BUFFER, EGL_BACK_BUFFER,
                EGL_NONE,
            ];
            eglSurface = enforce(eglCreateWindowSurface(backend.eglDisplay, backend.eglConfig, cast(ANativeWindow*) window, attributes.ptr));

            synchronized {
                setAsCurrentContextGL();
                loadOpenGLInCurrentContext();
            }

            debug {
                import bindbc.opengl;
                if (glDebugMessageCallback) {
                    glDebugMessageCallback(&nvgDebugLog, null);
                    glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
                } else {
                    warning("Can't output debug messages.");
                }
            }

            eglSwapInterval(backend.eglDisplay, 1).enforce();
        }

        bool setAsCurrentContextGL() {
            if (!eglSurface) {
                return false;
            }
            return eglMakeCurrent(backend.eglDisplay, eglSurface, eglSurface, backend.eglContext) == EGL_TRUE;
        }

        void swapBuffersGL() {
            if (!eglSurface) {
                return;
            }
            eglSwapBuffers(backend.eglDisplay, eglSurface).enforce();
        }

        void resizeGL(uint width, uint height) {}
        void cleanupGL() {}
    }

    version (VkVG) {
        import erupted;

        VkVGRendererProperties _vkvgRendererProperties;
        VkVGRendererProperties* vkvgRendererProperties() {
            return &_vkvgRendererProperties;
        }

        VkResult createSurface(VkInstance instance, const VkAllocationCallbacks* allocator, out VkSurfaceKHR vkSurface) {
            VkXcbSurfaceCreateInfoKHR createInfo = {
                flags: 0,
                connection: backend.connection,
                window: window
            };
            return vkCreateXcbSurfaceKHR(instance, &createInfo, allocator, &vkSurface);
        }
    }
}

class XcbBackendBuilder: BackendBuilder {
    XcbBackend __instance;

    ushort evaluate() {
        // FIXME: add a better check for X11 server
        return 1;
    }

    XcbBackend instance() {
        if (!__instance) {
            __instance = new XcbBackend();
        }
        return __instance;
    }
}

static this() {
    registerBackend("xcb", new XcbBackendBuilder());
}

class XcbException : Exception
{
    this(string msg, string file = __FILE__, int line = __LINE__)
    @safe pure nothrow
    {
        super(msg, file, line);
    }
}

pragma(inline, true)
ReturnType!func xcbEnforce(alias func)(Parameters!func[0..$-1] params)
    if (is(Parameters!func[$-1] == xcb_generic_error_t**))
{
    xcb_generic_error_t* error;

    auto reply = func(params, &error);

    if (error) {
        auto code = error.error_code;
        throw new XcbException(format!"Function %s returned code %s (%d)."(__traits(identifier, func), code.x11ErrorDescription(), code));
    }

    return reply;
}

pragma(inline, true)
void xcbEnforce(xcb_void_cookie_t cookie, xcb_connection_t* connection, string file = __FILE__, int line = __LINE__)
{
    xcb_generic_error_t* error = xcb_request_check(connection, cookie);

    if (error) {
        scope(exit) free(error);
        auto code = error.error_code;
        throw new XcbException(format!"%s (%d)."(code.x11ErrorDescription(), code), file, line);
    }
}

string x11ErrorDescription(ubyte errorCode) {
    switch (errorCode) {
        case 1:
            return "BadRequest";
        case 2:
            return "BadValue";
        case 3:
            return "BadWindow";
        case 4:
            return "BadPixmap";
        case 5:
            return "BadAtom";
        case 6:
            return "BadCursor";
        case 7:
            return "BadFont";
        case 8:
            return "BadMatch";
        case 9:
            return "BadDrawable";
        case 10:
            return "BadAccess";
        case 11:
            return "BadAlloc";
        case 12:
            return "BadColor";
        case 13:
            return "BadGC";
        case 14:
            return "BadIDChoice";
        case 15:
            return "BadName";
        case 16:
            return "BadLength";
        case 17:
            return "BadImplementation";
        case 128:
            return "FirstExtensionError";
        case 255:
            return "LastExtensionError";
        default:
            return "Unknown";
    }
}

template atomNameForType(T) {
    static if (is(T == string))
        enum atomNameForType = "UTF8_STRING";
    else static if (is(T == xcb_atom_t[]))
        enum atomNameForType = "ATOM";
    else static if (is(T == xcb_window_t))
        enum atomNameForType = "WINDOW";
    else static if (isIntegral!T)
        enum atomNameForType = "CARDINAL";
    else
        static assert(false, "Please specify atom type manually (type for " ~ T.stringof ~ " is unknown).");
}
