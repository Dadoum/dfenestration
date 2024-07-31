module dfenestration.widgets.window;

public import dfenestration.types;
public import dfenestration.primitives;

import std.algorithm.comparison;
import std.logger;

import dfenestration.backends.backend;

import dfenestration.renderers.context;

import dfenestration.widgets.bin;
import dfenestration.widgets.column;
import dfenestration.widgets.container;
import dfenestration.widgets.text;
import dfenestration.widgets.widget;
import dfenestration.widgets.windowhandle;
import dfenestration.widgets.windowframe;

/++
 + Surface rendered on a desktop, providing some features to manage that surface.
 +/
class Window: Container!Widget {
    Backend backend;
    BackendWindow backendWindow;

    Rectangle invalidatedZone;

    private struct _ {
        string title;

        Point position;

        Size size;
        bool resizable;

        Size minimumSize;
        Size maximumSize;

        bool maximized;
        double scaling;

        bool decorated;
        bool useNativeDecorations;

        double opacity;
    }
    mixin State!_;

    bool running = false;
    WindowFrame frame;

    /++
     + Create a new Window with the best backend available.
     +/
    this() {
        this(bestBackend());
    }

    /++
     + Create a new Window with a specific backend.
     +/
    this(Backend backend) {
        frame = new WindowFrame();
        this.backend = backend;
        backendWindow = backend.createBackendWindow(this);

        // default fields
        role = Role.toplevel;
        size = Size(600, 400);
        minimumSize = Size(1, 1);
        maximumSize = Size(0, 0);
        title = "";
        decorated = true;
        resizable = true;
    }

    override bool onSizeAllocate() {
        if (!super.onSizeAllocate()) {
            return false;
        }

        auto widget = _content;
        if (decorated && !backendWindow.decorated) {
            // Backend does not support server-side decorations. Probably Wayland now that you say it.
            frame.content = _content;
            widget = frame;
        }

        uint minimumWidth, minimumHeight, _, __;
        widget.preferredSize(
            minimumWidth, _,
            minimumHeight, __
        );
        layoutSize = Size(minimumWidth, minimumHeight);
        backendWindow.minimumSize(minimumSize);
        if (size.width < minimumWidth || size.height < minimumHeight) {
            size = Size(
                size.width < minimumWidth ? minimumWidth : size.width,
                size.height < minimumHeight ? minimumHeight : size.height,
            );
            return true;
        }

        auto rect = Rectangle(Point(0, 0), size());
        sizeAllocate(rect, widget);
        return true;
    }

    bool isPrimaryWindow;
    /++
     + Method called when the user asks to close the window.
     + If the window is a pop-up, the window should be closed at the end.
     +/
    void onCloseRequest() {
        if (isPrimaryWindow) {
            backend.exit();
        }
    }

    /++
     + Enter in the main app loop, and quit on window close.
     + primaryWindow: shows the window, and exits when it is hidden.
     +/
    int run(bool isPrimaryWindow = true) {
        if (isPrimaryWindow) {
            this.isPrimaryWindow = true;
            show();
        }
        return backend.run();
    }

    /++
     + Paint all widgets.
     +/
    void paint(Context context) {
        if (invalidatedZone != Rectangle.zero) {
            draw(context, invalidatedZone);
            invalidatedZone = Rectangle.zero;
        }
    }

    override void draw(Context context, Rectangle rectangle) {
        context.sourceRgb(1, 1, 1);
        context.rectangle(0, 0, allocation.size.tupleof);
        context.fill();
        super.draw(context, rectangle);
    }

    override Window window() {
        return this;
    }

    override void invalidate() {
        invalidate(allocation);
    }

    override void invalidate(Rectangle rect) {
        if (rect.x < invalidatedZone.x) {
            invalidatedZone.x = rect.x;
        }
        if (rect.y < invalidatedZone.y) {
            invalidatedZone.y = rect.y;
        }
        auto x2 = rect.x + rect.width;
        if (x2 > invalidatedZone.x + invalidatedZone.width()) {
            invalidatedZone.width = x2 - invalidatedZone.x;
        }
        auto y2 = rect.y + rect.height;
        if (y2 > invalidatedZone.y + invalidatedZone.height()) {
            invalidatedZone.width = y2 - invalidatedZone.y;
        }
        backendWindow.invalidate();
    }

    Window role(Role role) { backendWindow.role(role); return this; }

    /++
     + Window title.
     + Default: ""
     +/
    @StateGetter string title() { return backendWindow.title(); }
    @StateSetter Window title(string value) { backendWindow.title(value); return this; }
    void onTitleChange(string title) {
        frame.title = title;
    }

    /++
     + Position of the window relative to its parent.
     + Don't expect to work in all situations. The backend may ignore that request.
     + It may even straight out refuse to give the position (Wayland for example).
     + Default: [backend defined]
     +/
    @StateGetter Point position() { return backendWindow.position(); }
    @StateSetter Window position(Point value) { backendWindow.position(value); return this; }
    void onMove(Point location) {}

    /++
     + Size of window's content.
     + Default: Size(600, 400)
     +/
    @StateGetter Size size() { return backendWindow.size(); }
    @StateSetter Window size(Size value) { backendWindow.size(value); return this; }
    void onResize(Size size) {
        allocation = Rectangle(Point.zero, size);
        onSizeAllocate();
    }

    Size layoutSize;
    Size userDefinedMinimumSize;
    /++
     + Minimum size of window's content. May be bypassed if widgets can't fit.
     + Default: Size(1, 1)
     +/
    @StateGetter Size minimumSize() {
        auto userSize = userDefinedMinimumSize;
        return Size(max(layoutSize.width, userSize.width), max(layoutSize.height, userSize.height));
    }
    @StateSetter Window minimumSize(Size value) { userDefinedMinimumSize = value; backendWindow.minimumSize(minimumSize); return this; }

    /++
     + Maximum size of window's content. May be bypassed if widgets can't fit.
     + Default: Size(0, 0)
     +/
    @StateGetter Size maximumSize() { return backendWindow.maximumSize(); }
    @StateSetter Window maximumSize(Size value) { backendWindow.maximumSize(value); return this; }

    /++
     + Whether the window can be resized by the user.
     + Default: true
     +/
    @StateGetter bool resizable() { return backendWindow.resizable(); }
    @StateSetter Window resizable(bool value) { backendWindow.resizable(value); return this; }

    bool _decorated;
    /++
     + Whether the window has decorations.
     + Default: true
     +/
    @StateGetter bool decorated() { return _decorated; }
    @StateSetter Window decorated(bool value) { _decorated = value; backendWindow.decorated(value); return this; }

    /++
     + Show window.
     +/
    void show() { return backendWindow.show(); }
    /++
     + Hide window.
     +/
    void hide() { return backendWindow.hide(); }
    /++
     + Minimize/iconify window.
     +/
    void minimize() { backendWindow.minimize(); }

    /++
     + Request window focus.
     +/
    void present() { return backendWindow.present(); }
    /++
     + Indicates if the window is focused, but not if any device is actually focused on the window.
     + Some desktops may want the window to appear focused while the user is actually typing in a system menu for
     + example.
     +/
    bool focused() { return backendWindow.focused(); }
    void onFocusedChange(bool focused) {

    }

    /++
     + Maximize window.
     + Default: false
     +/
    @StateGetter bool maximized() { return backendWindow.maximized(); }
    @StateSetter Window maximized(bool value) { backendWindow.maximized(value); return this; }
    void onMaximizeChange() {}

    /++
     + Window opacity (if supported).
     + Don't rely on opacity for critical features. It might be unavailable on some systems.
     + Default: 1.0
     +/
    @StateGetter double opacity() { return backendWindow.opacity(); }
    @StateSetter Window opacity(double value) { backendWindow.opacity(value); return this; }

    /++
     + Window scaling if supported.
     + Default: [backend defined]
     +/
    @StateGetter double scaling() { return backendWindow.scaling(); }
    @StateSetter Window scaling(double value) { backendWindow.scaling(value); return this; }

    /++
     + Close the window.
     + It will call onCloseRequest.
     +/
    void close() { backendWindow.close(); }

    /++
     + Request window to be moved from the current pointer location. May be ignored.
     +/
    void moveDrag() { backendWindow.moveDrag(); }
    /++
     + Request window to be resized from a given edge. May be ignored.
     +/
    void resizeDrag(ResizeEdge edge) { backendWindow.resizeDrag(edge); }
}

enum ResizeEdge: byte {
    left = 1 << 0,
    right = 1 << 1,
    top = 1 << 2,
    bottom = 1 << 3,
    topLeft = top | left,
    topRight = top | right,
    bottomLeft = bottom | left,
    bottomRight = bottom | right
}

enum Role {
    toplevel,
    popup
}
