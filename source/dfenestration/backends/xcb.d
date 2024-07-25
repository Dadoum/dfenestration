module dfenestration.backends.xcb;

version (Xcb):

import std.datetime;
import std.exception;
import std.format;
import std.logger;
import std.string;
import std.traits: ReturnType, Parameters, isIntegral;

import xcb.xcb;
import xcb.icccm;

import dfenestration.backends.backend;
import dfenestration.primitives;
import dfenestration.renderers.context;
import dfenestration.widgets.window;

class XcbBackend: Backend {
    xcb_connection_t* connection;

    this() {
        connection = xcb_connect(null, null);
        if (connection == null) {
            throw new XcbException("Can't connect to X server!");
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

    override void paintWindow(BackendWindow window) {

    }

    override void presentWindow(BackendWindow window) {

    }

    override void handleEvents(Duration defaultTimeout) {
        xcb_flush(connection);
        while (auto event = xcb_poll_for_event(connection)) {
            if (!event.response_type) {
                error("X11 error: ", (cast(xcb_generic_error_t*) event).error_code.x11ErrorDescription());
                return;
            }

            switch (event.response_type) {
                case XCB_EXPOSE:
                    auto event_cm = cast(xcb_expose_event_t*) event;
                    // X11Window* window = event_cm.window in nativeWindowToDObject;
                    // renderer().onResize(*window);
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
            event = xcb_poll_for_event(connection);
        }
    }

    override BackendWindow createBackendWindow(Window window) {
        return new XcbWindow(this, window);
    }
}

class XcbWindow: BackendWindow {
    Window dWindow;
    XcbBackend backend;

    xcb_window_t window;
    xcb_screen_t* screen;

    this(XcbBackend backend, Window dWindow) {
        this.backend = backend;
        this.dWindow = dWindow;

        auto setup = xcb_get_setup(backend.connection);
        screen = setup.xcb_setup_roots_iterator().data;
        // screen = *setup.xcb_setup_visual_iterator().data;

        xcb_visualid_t visual = screen.root_visual;

        xcb_depth_iterator_t depth_iter = xcb_screen_allowed_depths_iterator (screen);
        for (; depth_iter.rem; xcb_depth_next (&depth_iter)) {
            xcb_visualtype_iterator_t visual_iter;

            visual_iter = xcb_depth_visuals_iterator (depth_iter.data);
            for (; visual_iter.rem; xcb_visualtype_next (&visual_iter)) {
                info(depth_iter.data.depth);
                if (depth_iter.data.depth == 32) {
                    // visual = visual_iter.data.visual_id;
                    break;
                }
            }
        }

        uint[2] values = [
            XCB_PIXMAP_NONE,
            XCB_EVENT_MASK_KEY_PRESS | XCB_EVENT_MASK_KEY_RELEASE |
            XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE |
            XCB_EVENT_MASK_ENTER_WINDOW | XCB_EVENT_MASK_LEAVE_WINDOW |
            XCB_EVENT_MASK_POINTER_MOTION | XCB_EVENT_MASK_BUTTON_MOTION |
            XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_VISIBILITY_CHANGE |
            XCB_EVENT_MASK_FOCUS_CHANGE | XCB_EVENT_MASK_KEYMAP_STATE |
            XCB_EVENT_MASK_STRUCTURE_NOTIFY | XCB_EVENT_MASK_PROPERTY_CHANGE
        ];

        window = xcb_generate_id(backend.connection);
        xcb_create_window(
            backend.connection,
            XCB_COPY_FROM_PARENT, window, screen.root,
            10, 10, 20, 20, 0,
            XCB_WINDOW_CLASS_INPUT_OUTPUT,
            visual,
            XCB_CW_BACK_PIXMAP | XCB_CW_EVENT_MASK,
            values.ptr
        );

        xcbProperty!"WM_PROTOCOLS" = [backend.atom!"WM_DELETE_WINDOW"];
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

        return *cast(T*) xcb_get_property_value(reply);
    }

    void xcbProperty(string propertyName, T: U[], U)(T data, xcb_atom_t type = 0) {
        if (type == 0) {
            type = backend.atom!(atomNameForType!T);
        }

        xcb_change_property(
            backend.connection,
            XCB_PROP_MODE_REPLACE,
            window,
            backend.atom!propertyName,
            type,
            U.sizeof * 8,
            cast(uint) data.length,
            data.ptr
        );
        xcb_flush(backend.connection);
    }

    void xcbProperty(string propertyName, T)(T data, xcb_atom_t type = 0, ubyte format = T.sizeof) {
        if (type == 0) {
            type = backend.atom!(atomNameForType!T);
        }

        xcb_change_property(
            backend.connection,
            XCB_PROP_MODE_REPLACE,
            window,
            backend.atom!propertyName,
            type,
            format,
            1,
            &data
        );
        xcb_flush(backend.connection);
    }

    void sendClientMessage(T: U[n], U, size_t n)(xcb_atom_t type, T data, ubyte format = U.sizeof * 8) if (T.sizeof == 20) {
        xcb_client_message_event_t event = {
            response_type   : XCB_CLIENT_MESSAGE,
            format          : format,
            sequence        : 0,
            window          : window,
            type            : type,
        };
        event.data.data32 = cast(uint[5]) data;
        // event.data.data8 = cast(uint[20]) data; TODO
        backend.connection.xcb_send_event(
            false,
            screen.root,
            XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY | XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT,
            cast(const(char*)) &event
        );
    }

    void paint(Context context) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void invalidate() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void role(Role role) {

    }

    string title() {
        return xcbProperty!("_NET_WM_NAME", string);
    }
    void title(string value) {
        xcbProperty!"_NET_WM_NAME" = value;
    }

    Point position() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void position(Point value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    Size size() {
        auto reply = xcbEnforce!xcb_get_geometry_reply(backend.connection, xcb_get_geometry(backend.connection, window));
        return Size(cast(uint) reply.width, cast(uint) reply.height);
    }
    void size(Size value) {
        const(uint)[2] array = [value.tupleof];
        xcb_configure_window(backend.connection, window, XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT, array.ptr);
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
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
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
        xcb_map_window(backend.connection, window);
    }
    void hide() {
        xcb_unmap_window(backend.connection, window);
    }
    void minimize() {
        uint[5] event = [
            XCB_ICCCM_WM_STATE_ICONIC,
            0,
            0,
            0,
            0
        ];
        sendClientMessage(backend.atom!"WM_CHANGE_STATE", event);
    }

    void present() {
        uint value = XCB_STACK_MODE_ABOVE;
        backend.connection.xcb_configure_window(window, XCB_CONFIG_WINDOW_STACK_MODE, &value);
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
