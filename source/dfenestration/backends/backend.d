module dfenestration.backends.backend;

import core.thread;

import std.conv;
import std.datetime;
import std.exception;
import std.format;
import std.logger;
import std.process;
import std.traits;

import eventcore.core;

import dfenestration.linkedlist;

import dfenestration.primitives;
import dfenestration.renderers.context;
import dfenestration.renderers.renderer;
import dfenestration.widgets.window;

enum backendEnvironmentVariable = "DFBACKEND";
enum rendererEnvironmentVariable = "DFRENDERER";

abstract class Backend {
    Duration delayMsecs = dur!"msecs"(1000 / 60);

    BackendWindow[size_t] windowsToRedraw;

    /++
     + Target framerate if using the default waitNextFrame implementation.
     +/
    void targetFramerate(uint framerate) {
        delayMsecs = ((1. / framerate) * 1000).to!long.msecs;
    }

    struct TimerCallback {
        MonoTime time;
        void delegate() callback;
    }
    LinkedList!TimerCallback timers;
    MonoTime targetTime;
    void roundtrip() {
        targetTime = MonoTime.currTime() + delayMsecs;
        handleEvents(delayMsecs);
        foreach (_, window; windowsToRedraw) {
            paintWindow(window);
        }
        waitNextFrame();
        auto node = timers.head;
        while (node) {
            if (node.object.time > targetTime) {
                break;
            }
            node.object.callback();
            timers.removeFront();
            node = node.next;
        }
        foreach (_, window; windowsToRedraw) {
            presentWindow(window);
        }
        windowsToRedraw.clear();
    }

    void planCallback(MonoTime time, void delegate() callback) {
        timers.insertAfter((node) => node.time < time, TimerCallback(time, callback));
    }

    void waitNextFrame() {
        auto timeAhead = targetTime - MonoTime.currTime();
        if (timeAhead > 0.msecs) {
            Thread.sleep(timeAhead);
        } // if we're late present the frame anyway. TODO: maybe skip that frame? Renderer may do that anyway ¯\_(ツ)_/¯
    }

    Renderer buildRenderer(this R)() {
        // TODO add a renderer override

        static foreach_reverse (Type; InterfacesTuple!R) {{
            static if (is(Type: BackendCompatibleWith!RendererT, RendererT)) {
                if (RendererT.compatible()) {
                    return new RendererT(this);
                }
            }
        }}

        throw new NoRendererException(format!"No renderer is available for %s."(R.stringof));
    }

    void queueRedraw(Window window) {
        // TODO: Use a real set for this.
        auto hash = window.toHash();
        if (hash in windowsToRedraw) {
            return;
        }
        windowsToRedraw[hash] = window.backendWindow;
    }

    abstract void paintWindow(BackendWindow window);
    abstract void presentWindow(BackendWindow window);
    abstract void handleEvents(Duration defaultTimeout);
    abstract BackendWindow createBackendWindow(Window window);
}

interface BackendWindow {
    void paint(Context context);

    void role(Role role);

    string title();
    void title(string value);

    // Image icon();
    // void icon(Image value);

    Point position();
    void position(Point value);

    Size size();
    void size(Size value);

    Size minimumSize();
    void minimumSize(Size value);

    Size maximumSize();
    void maximumSize(Size value);

    Size canvasSize();

    bool resizable();
    void resizable(bool value);

    bool decorated();
    void decorated(bool value);

    void parent(BackendWindow window);

    void show();
    void hide();
    void minimize();

    void present();
    bool focused();

    bool maximized();
    void maximized(bool value);

    double opacity();
    void opacity(double value);

    double scaling();
    void scaling(double value);

    void close();

    void moveDrag();
    void resizeDrag(ResizeEdge edge);
}

interface BackendBuilder {
    ushort evaluate();
    Backend instance();
}

BackendBuilder[string] backendBuilders;
BackendBuilder computedBestBackendBuilder;

void registerBackend(string backendIdentifier, BackendBuilder backendBuilder) {
    backendBuilders[backendIdentifier] = backendBuilder;
    // computedBestBackendBuilder = null;
}

Backend bestBackend() {
    if (auto backendStr = environment.get(backendEnvironmentVariable, null)) {
        if (auto backendBuilder = backendStr in backendBuilders) {
            return backendBuilder.instance();
        }

        throw new NoBackendException(format!"No backend with the identifier \"%s\" is available."(backendStr));
    } else {
        if (computedBestBackendBuilder) {
            return computedBestBackendBuilder.instance();
        }

        ushort maxScore = 0;

        foreach (backendBuilder; backendBuilders) {
            ushort score = backendBuilder.evaluate();
            if (score > maxScore) {
                maxScore = score;
                computedBestBackendBuilder = backendBuilder;
            }
        }

        if (!computedBestBackendBuilder) {
            throw new NoBackendException("No backend available. ");
        }

        return computedBestBackendBuilder.instance();
    }
}

/++
 + Build the best backend for a certain renderer. Quite expensive, as it will initialize all backends to try.
 +/
Backend bestBackendForRenderer(RendererT: Renderer)(bool ignoreEnvironment = false) {
    if (auto backendStr = environment.get(backendEnvironmentVariable, null)) {
        if (!ignoreEnvironment) {
            if (auto backendBuilder = backendStr in backendBuilders) {
                auto backend = backendBuilder.instance();
                enforce(cast(BackendCompatibleWith!RendererT) backend != null, format!`Environment enforced the incompatible backend "%s"`(backendStr));
                return backend;
            }

            throw new NoBackendException(format!"No backend with the identifier \"%s\" is available."(backendStr));
        }
    }

    Backend bestBackend;
    ushort maxScore = 0;

    foreach (backendBuilder; backendBuilders) {
        ushort score = backendBuilder.evaluate();
        if (score > maxScore) {
            if (auto backend = cast(BackendCompatibleWith!RendererT) backendBuilder.instance()) {
                maxScore = score;
                bestBackend = backend;
            }
        }
    }

    if (!bestBackend) {
        throw new NoBackendException(format!"No backend available for the renderer %s."(RendererT.stringof));
    }

    return bestBackend;
}

class NoBackendException: Exception {
    this(string msg, string file = __FILE__, int line = __LINE__) {
        super(msg, file, line);
    }
}

class NoRendererException: Exception {
    this(string msg, string file = __FILE__, int line = __LINE__) {
        super(msg, file, line);
    }
}
