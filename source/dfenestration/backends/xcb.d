module dfenestration.backends.xcb;

version (Xcb):

import std.datetime;
import std.exception;
import std.format;
import std.logger;
import std.string;
import std.traits: ReturnType, Parameters, isIntegral;
import std.typecons;

import core.stdc.stdlib;

import libasync;

import xcb.xcb;
import xcb.icccm;

import dfenestration.backends.backend;
import dfenestration.primitives;
import dfenestration.renderers.nanovega.glrenderer;
import dfenestration.renderers.vkvg.renderer;
import dfenestration.renderers.context;
import dfenestration.renderers.image;
import dfenestration.renderers.renderer;
import dfenestration.widgets.window;

final class XcbBackend: Backend, VkVGRendererCompatible, NanoVegaGLRendererCompatible {
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

        static ubyte i = 0;
        ++i;
        while (auto event = xcb_poll_for_event(connection)) {
            scope(exit) free(event);
            if (!event.response_type) {
                error("X11 error: ", (cast(xcb_generic_error_t*) event).error_code.x11ErrorDescription());
                continue;
            }

            switch (event.response_type) {
                case XCB_EXPOSE:
                    info(i, " EXPOSE");
                    auto event_expose = cast(xcb_expose_event_t*) event;
                    xcbWindows[event_expose.window].dWindow.invalidate();
                    break;
                case XCB_CONFIGURE_NOTIFY:
                    info(i, " configure");
                    xcb_configure_notify_event_t* event_configure = cast(xcb_configure_notify_event_t*) event;
                    auto window = xcbWindows[event_configure.window];

                    auto newSize = Size(event_configure.width, event_configure.height);

                    if (newSize != window.size()) {
                        window.onResize(newSize);
                    }
                    break;
                case XCB_BUTTON_PRESS:
                    auto evt = cast(xcb_button_press_event_t*) event;
                    auto window = xcbWindows[evt.event];
                    auto location = Point(evt.event_x, evt.event_y);
                    auto detail = evt.detail;
                    if (detail == 4 || detail == 5 || detail == 6 || detail == 7) {
                        warning("scroll not handled.");
                        break;
                    }
                    auto button = detail.x11ToMouseButton();
                    window.dWindow.onClickStart(location, button);
                    break;
                case XCB_BUTTON_RELEASE:
                    auto evt = cast(xcb_button_release_event_t*) event;
                    auto window = xcbWindows[evt.event];
                    auto location = Point(evt.event_x, evt.event_y);
                    auto detail = evt.detail;
                    if (detail == 4 || detail == 5 || detail == 6 || detail == 7) {
                        warning("scroll not handled.");
                        break;
                    }
                    auto button = detail.x11ToMouseButton();
                    window.dWindow.onClickEnd(location, button);
                    break;
                case XCB_FOCUS_IN:
                    auto event_focus_in = cast(xcb_focus_in_event_t*) event;
                    auto window = xcbWindows[event_focus_in.event];
                    if (!window._focused) {
                        window._focused = true;
                        window.dWindow.onFocusedChange(true);
                    }
                    break;
                case XCB_FOCUS_OUT:
                    auto event_focus_out = cast(xcb_focus_out_event_t*) event;
                    auto window = xcbWindows[event_focus_out.event];
                    if (window._focused) {
                        window._focused = false;
                        window.dWindow.onFocusedChange(false);
                    }
                    break;
                case XCB_ENTER_NOTIFY:
                    auto event_enter_notify = cast(xcb_enter_notify_event_t*) event;
                    auto window = xcbWindows[event_enter_notify.event];
                    Point hoverLocation = Point(event_enter_notify.event_x, event_enter_notify.event_y);
                    window.dWindow.onHoverStart(hoverLocation);
                    break;
                case XCB_MOTION_NOTIFY:
                    auto event_motion_notify = cast(xcb_motion_notify_event_t*) event;
                    auto window = xcbWindows[event_motion_notify.event];
                    Point hoverLocation = Point(event_motion_notify.event_x, event_motion_notify.event_y);
                    window.dWindow.onHover(hoverLocation);
                    break;
                case XCB_LEAVE_NOTIFY:
                    auto event_leave_notify = cast(xcb_leave_notify_event_t*) event;
                    auto window = xcbWindows[event_leave_notify.event];
                    Point hoverLocation = Point(event_leave_notify.event_x, event_leave_notify.event_y);
                    window.dWindow.onHoverEnd(hoverLocation);
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

final class XcbWindow: BackendWindow, VkVGWindow, NanoVegaGLWindow {
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

    ~this() {
        auto connection = backend.connection;
        xcb_destroy_window_checked(connection, window).xcbEnforce(connection);
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
        ubyte format = U.sizeof * 8;

        xcb_change_property_checked(
            backend.connection,
            XCB_PROP_MODE_REPLACE,
            window,
            backend.atom!propertyName,
            type,
            format,
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
            format > 32 ? 32 : format,
            format > 32 ? T.sizeof * 8 / 32 : 1,
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
        scheduleRedraw();
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

    Size _size;
    Size size() {
        return _size;
    }
    void size(Size value) {
        const(uint)[2] array = [value.tupleof];
        xcb_configure_window_checked(backend.connection, window, XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT, array.ptr)
        .xcbEnforce(backend.connection);
        onResize(value);
    }
    void onResize(Size newSize) {
        _size = newSize;
        dWindow.onResize(newSize);
    }

    Size _minSize;
    Size minimumSize() {
        return _minSize;
    }
    void minimumSize(Size value) {
        _minSize = value;
        WMSizeHints hints;
        hints.flags = WMSizeHintsFlag.P_MIN_SIZE;
        hints.min_width = value.width;
        hints.min_height = value.height;
        xcbProperty!"WM_NORMAL_HINTS" = hints;
    }

    Size _maxSize = Size(uint.max, uint.max);
    Size maximumSize() {
        return _maxSize;
    }
    void maximumSize(Size value) {
        if (value == Size.zero) {
            value.width = int.max;
            value.height = int.max;
        }
        _maxSize = value;
        WMSizeHints hints;
        hints.flags = WMSizeHintsFlag.P_MAX_SIZE;
        hints.max_width = value.width;
        hints.max_height = value.height;
        xcbProperty!"WM_NORMAL_HINTS" = hints;
    }

    Size canvasSize() {
        return size();
    }

    bool _resizable = true;
    bool resizable() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return _resizable;
    }
    void resizable(bool value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        if (_resizable && !value) {
            WMSizeHints hints;
            hints.flags = WMSizeHintsFlag.P_MIN_SIZE | WMSizeHintsFlag.P_MAX_SIZE;
            hints.min_width = _size.width;
            hints.min_height = _size.height;
            hints.max_width = _size.width;
            hints.max_height = _size.height;
            xcbProperty!"WM_NORMAL_HINTS" = hints;
            _resizable = false;
        } else if (!_resizable && value) {
            WMSizeHints hints;
            hints.flags = WMSizeHintsFlag.P_MIN_SIZE | WMSizeHintsFlag.P_MAX_SIZE;
            hints.min_width = _minSize.width;
            hints.min_height = _minSize.height;
            hints.max_width = _maxSize.width;
            hints.max_height = _maxSize.height;
            xcbProperty!"WM_NORMAL_HINTS" = hints;
            _resizable = true;
        }
    }

    bool _decorated = true;
    bool decorated() {
        return _decorated;
    }
    void decorated(bool value) {
        uint[] hints = [
            /+ flags +/ 2, // I think 2 stands for (1 << 1), the request only changes the decoration mode.
            /+ functions +/ 0,
            /+ decorations +/ value ? 1 : 0,
            /+ input_mode +/ 0,
            /+ status +/ 0,
        ];
        xcbProperty!"_MOTIF_WM_HINTS"(hints, backend.atom!"_MOTIF_WM_HINTS");
        _decorated = value;
    }

    Nullable!Image icon() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return Nullable!Image.init;
    }
    void icon(Nullable!Image value) {
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
        maximized = _maximized;
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
    bool _focused = false;
    bool focused() {
        return _focused;
    }

    bool _maximized = false;
    bool maximized() {
        return _maximized;
    }
    void maximized(bool value) {
        uint[5] event = [
            value,
            backend.atom!"_NET_WM_STATE_MAXIMIZED_VERT",
            backend.atom!"_NET_WM_STATE_MAXIMIZED_HORZ",
            1,
            0
        ];
        sendMessageToRootWindow(backend.atom!"_NET_WM_STATE", event);
        _maximized = value;
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

    void moveResize(uint flag) {
        xcb_query_pointer_reply_t* pointer = queryPointer();
        scope(exit) free(pointer);

        uint[5] event = [
            pointer.root_x,
            pointer.root_y,
            flag,
            XCB_BUTTON_INDEX_ANY,
            0
        ];
        sendMessageToRootWindow(backend.atom!"_NET_WM_MOVERESIZE", event);
    }

    void moveDrag() {
        moveResize(8);
    }
    void resizeDrag(ResizeEdge edge) {
        uint flag;
        final switch (edge) {
            case ResizeEdge.left:
                flag = 7;
                break;
            case ResizeEdge.right:
                flag = 3;
                break;
            case ResizeEdge.top:
                flag = 1;
                break;
            case ResizeEdge.bottom:
                flag = 5;
                break;
            case ResizeEdge.topLeft:
                flag = 0;
                break;
            case ResizeEdge.topRight:
                flag = 2;
                break;
            case ResizeEdge.bottomLeft:
                flag = 6;
                break;
            case ResizeEdge.bottomRight:
                flag = 4;
                break;
        }
        moveResize(flag);
    }

    xcb_query_pointer_reply_t* queryPointer()
        => xcbEnforce!xcb_query_pointer_reply(
            backend.connection,
            xcb_query_pointer(backend.connection, backend.screen.root)
        );

    void showWindowControlMenu(Point location) {
        xcb_query_pointer_reply_t* pointer = queryPointer();
        scope(exit) free(pointer);

        int[5] data = [
            1,
            pointer.root_x,
            pointer.root_y,
            0,
            0,
        ];
        sendClientMessage(backend.screen.root, backend.atom!"_GTK_SHOW_WINDOW_MENU", data);
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
    else static if (is(T == WMSizeHints))
        enum atomNameForType = "WM_SIZE_HINTS";
    else static if (is(T == U[], U: int))
        enum atomNameForType = "XCB_ATOM_INTEGER";
    else static if (isIntegral!T)
        enum atomNameForType = "CARDINAL";
    else
        static assert(false, "Please specify atom type manually (type for " ~ T.stringof ~ " is unknown).");
}

struct WMSizeHints
{
    uint flags;
    int  x, y;
    int  width, height;
    int  min_width, min_height;
    int  max_width, max_height;
    int  width_inc, height_inc;
    int  min_aspect_num, min_aspect_den;
    int  max_aspect_num, max_aspect_den;
    int  base_width, base_height;
    uint win_gravity;
}

enum WMSizeHintsFlag
{
    US_POSITION   = 1U << 0,
    US_SIZE       = 1U << 1,
    P_POSITION    = 1U << 2,
    P_SIZE        = 1U << 3,
    P_MIN_SIZE    = 1U << 4,
    P_MAX_SIZE    = 1U << 5,
    P_RESIZE_INC  = 1U << 6,
    P_ASPECT      = 1U << 7,
    BASE_SIZE     = 1U << 8,
    P_WIN_GRAVITY = 1U << 9
}

MouseButton x11ToMouseButton(ubyte button) {
    MouseButton mouseButton = void;
    switch (button) {
        case XCB_BUTTON_INDEX_1:
            mouseButton = MouseButton.left;
            break;
        case XCB_BUTTON_INDEX_2:
            mouseButton = MouseButton.middle; // the doc is wrong
            break;
        case XCB_BUTTON_INDEX_3:
            mouseButton = MouseButton.right; // the doc is wrong
            break;
        case 8:
            mouseButton = MouseButton.back;
            break;
        case 9:
            mouseButton = MouseButton.forward;
            break;
        default:
            mouseButton = MouseButton.unknown;
            break;
    }
    return mouseButton;
}
