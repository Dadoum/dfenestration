module dfenestration.backends.simpledisplay;

version (SimpleDisplay):

import std.datetime;
import std.exception;
import std.format;
import std.logger;
import std.string;
import std.traits: ReturnType, Parameters, isIntegral;
import std.typecons;

import core.stdc.stdlib;

import libasync;

import sd = arsd.simpledisplay;

import dfenestration.backends.backend;
import dfenestration.primitives;
import dfenestration.renderers.nanovega.glrenderer;
import dfenestration.renderers.vkvg.renderer;
import dfenestration.renderers.context;
import dfenestration.renderers.image;
import dfenestration.renderers.renderer;
import dfenestration.widgets.window;

final class SimpleDisplayBackend: Backend, NanoVegaGLRendererCompatible {
    Renderer renderer;
    sd.EventLoop sdEventLoop;

    this() {
        sdEventLoop = sd.EventLoop.get;
        version (Windows) {
            AsyncEvent event = new AsyncEvent(super._eventLoop, sdEventLoop.impl.customEventH);
        }
        else version (Posix) {
            AsyncEvent event = new AsyncEvent(super._eventLoop, sdEventLoop.impl.displayFd);
        } else {
            assert(false, "Unsupported backend");
        }
        event.run((code) => roundtrip());
    }

    final void roundtrip() {
        sdEventLoop.run();

        info("loopin'");
    }

    ~this() {}

    override SimpleDisplayWindow createBackendWindow(Window window) {
        return new SimpleDisplayWindow(this, window);
    }

    version (NanoVega) {
        void loadGL() {
            //
        }

        bool loadGLLibrary() {
            return true;
        }
    }
}

final class SimpleDisplayWindow: BackendWindow, NanoVegaGLWindow {
    Window dWindow;
    SimpleDisplayBackend backend;

    sd.SimpleWindow window;

    this(SimpleDisplayBackend backend, Window dWindow) {
        this.backend = backend;
        this.dWindow = dWindow;

        window = new sd.SimpleWindow();

        // backend.renderer.initializeWindow(this);
    }

    ~this() {}

    void paint(Context context) {
        dWindow.paint(context);
    }

    void invalidate() {
        scheduleRedraw();
    }

    void role(Role role) {

    }

    string title() {
        return window.title();
    }
    void title(string value) {
        window.title = value;
    }

    void cursor(CursorType value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    Point position() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void position(Point value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    Size _size;
    Size size() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void size(Size value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }
    void onResize(Size newSize) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    Size _minSize;
    Size minimumSize() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return typeof(return).init;
    }
    void minimumSize(Size value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    Size _maxSize = Size(uint.max, uint.max);
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
        return false;
        // return window.resizable;
    }
    void resizable(bool value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        // window.resizable = value;
    }

    bool _decorated = true;
    bool decorated() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return _decorated;
    }
    void decorated(bool value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        _decorated = value;
    }

    Nullable!Pixbuf icon() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return Nullable!Pixbuf.init;
    }
    void icon(Nullable!Pixbuf value) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void parent(BackendWindow window) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void show() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }
    void hide() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }
    void minimize() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void present() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }
    bool _focused = false;
    bool focused() {
        return _focused;
    }

    bool _maximized = false;
    bool maximized() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        return _maximized;
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

    void moveResize(uint flag) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void moveDrag() {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }
    void resizeDrag(ResizeEdge edge) {
        warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
    }

    void showWindowControlMenu(Point location) {

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
        import bindbc.opengl;

        import dfenestration.renderers.egl;
        import arsd.nanovega;

        NVGContext _nvgContext;

        ref NVGContext nvgContext() {
            return _nvgContext;
        }

        void createWindowGL(uint width, uint height) {
            warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        }

        bool setAsCurrentContextGL() {
            warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
            return false;
        }

        void swapBuffersGL() {
            warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
        }

        void resizeGL(uint width, uint height) {}
        void cleanupGL() {}
    }
}

class SimpleDisplayBackendBuilder: BackendBuilder {
    SimpleDisplayBackend __instance;

    ushort evaluate() {
        version (Windows) {
            return 1;
        }
        else version (Posix) {
            return 1;
        }
        else {
            return 0;
        }
    }

    SimpleDisplayBackend instance() {
        if (!__instance) {
            __instance = new SimpleDisplayBackend();
        }
        return __instance;
    }
}

static this() {
    registerBackend("simpledisplay", new SimpleDisplayBackendBuilder());
}

class SimpleDisplayException : Exception
{
    this(string msg, string file = __FILE__, int line = __LINE__)
    @safe pure nothrow
    {
        super(msg, file, line);
    }
}
