module dfenestration.backends.x11;

version (X11):

import std.datetime;
import std.exception;
import std.format;
import std.logger;
import std.string;
import std.traits: ReturnType, Parameters, isIntegral;

import libasync;

import x = X11.X;
alias VisualID = x.VisualID;
import X11.Xlib;

import dfenestration.backends.backend;
import dfenestration.primitives;
import dfenestration.renderers.nanovega.glrenderer;
import dfenestration.renderers.vkvg.renderer;
import dfenestration.renderers.context;
import dfenestration.renderers.renderer;
import dfenestration.widgets.window;

class X11Backend: Backend {
    Display* display;
    int screen;
    Visual* visual;

    Renderer renderer;
    X11Window[x.Window] x11Windows;

    this() {
        display = XOpenDisplay(null);
        if (display == null) {
            throw new XcbException("Can't connect to X server! Hopefully it printed something before in the console to help.");
        }

        screen = DefaultScreen(display);
        visual = DefaultVisual(display, screen);

        // renderer = this.buildRenderer();

        AsyncEvent event = new AsyncEvent(eventLoop, ConnectionNumber(display));
        event.run((code) => roundtrip());
    }

    final void roundtrip() {
        XEvent event;

        foreach (pendingEventCount; 0..XPending(display)) {
            XNextEvent(display, &event);
            /+
            if (!event.response_type) {
                error("X11 error: ", (cast(xcb_generic_error_t*) event).error_code.x11ErrorDescription());
                return;
            }

            switch (event.response_type) {
                case XCB_EXPOSE:
                    auto event_cm = cast(xcb_expose_event_t*) event;
                    renderer.draw(xcbWindows[event_cm.window]);
                    break;
                case XCB_CLIENT_MESSAGE | 1 << 7:
                    auto event_cm = cast(xcb_client_message_event_t*) event;
                    // X11Window* window = event_cm.window in nativeWindowToDObject;
                    if (event_cm.data.data32[0] == atom!"WM_DELETE_WINDOW") {
                        info("Delete window");
                        // if (window !is null) {
                        //     window.visible = false;
                        //     window.foreignVisibleChange(false);
                        // }
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
            +/
        }
    }

    ~this() {
        XCloseDisplay(display);
    }

    override X11Window createBackendWindow(Window window) {
        auto x11Window = new X11Window(this, window);
        x11Windows[x11Window.window] = x11Window;
        return x11Window;
    }

    version (VkVG) {
        public import erupted;

        /++
         + VkExtensions required for backend.
         +/
        string[] requiredExtensions() {
            return ["VK_KHR_x11_surface"];
        }

        void loadInstanceFuncs(VkInstance instance) {
            return loadInstanceLevelFunctionsExt(instance);
        }

        bool isDeviceSuitable(VkPhysicalDevice device, uint queueFamilyIndex) {
            return cast(bool) vkGetPhysicalDeviceXlibPresentationSupportKHR(device, queueFamilyIndex, display, visual.visualid);
        }
    }
}

version (VkVG) {
    import erupted.platform_extensions;

    mixin Platform_Extensions!USE_PLATFORM_XLIB_KHR vulkanX11;
}

class X11Window: BackendWindow {
    x.Window window;
    Window dWindow;
    X11Backend backend;

    this(X11Backend backend, Window dWindow) {
        this.backend = backend;
        this.dWindow = dWindow;

        auto d = backend.display;
        auto s = DefaultScreen(d);

        window = XCreateSimpleWindow(d, RootWindow(d, s), 10, 10, 100, 100, 1,
        BlackPixel(d, s), WhitePixel(d, s));
    }

    void paint(Context context) {
        dWindow.paint(context);
    }

    void invalidate() {

    }

    void role(Role role) {

    }

    string title() {
        return string.init; // xcbProperty!("_NET_WM_NAME", string);
    }
    void title(string value) {

    }

    Point position() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void position(Point value) {

    }

    Size size() {
        return typeof(return).init;
    }
    void size(Size value) {

    }

    Size minimumSize() {
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

    void parent(BackendWindow window) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void show() {
        XMapWindow(backend.display, window);
    }
    void hide() {
        XUnmapWindow(backend.display, window);
    }
    void minimize() {
        // XIconifyWindow(backend.display, window, screen);
    }

    void present() {
        // uint value = XCB_STACK_MODE_ABOVE;
        // backend.connection.xcb_configure_window(window, XCB_CONFIG_WINDOW_STACK_MODE, &value);
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
        return typeof(return).init;
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
        // sendClientMessage(backend.atom!"_NET_WM_MOVERESIZE", event);
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }
    void resizeDrag(ResizeEdge edge) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void showWindowControlMenu(Point location) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }
}

class X11BackendBuilder: BackendBuilder {
    X11Backend __instance;

    ushort evaluate() {
        // FIXME: add a better check for X11 server
        return 1;
    }

    X11Backend instance() {
        if (!__instance) {
            __instance = new X11Backend();
        }
        return __instance;
    }
}

static this() {
    registerBackend("x11", new X11BackendBuilder());
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
    else static if (isIntegral!T)
        enum atomNameForType = "CARDINAL";
    else
        static assert(false, "Please specify atom type manually (type for " ~ T.stringof ~ " is unknown).");
}
