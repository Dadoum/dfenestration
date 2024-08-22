module dfenestration.backends.backend;

import core.thread;

import std.algorithm;
import std.conv;
import std.exception;
import std.format;
import std.string;
import std.logger;
import std.process;
import std.traits;

import bindbc.hb;
import bindbc.freetype;

import libasync;

import dfenestration.primitives;
import dfenestration.renderers.context;
import dfenestration.renderers.renderer;
import dfenestration.renderers.text.font;
import dfenestration.renderers.text.textlayouter;
import dfenestration.widgets.window;

enum backendEnvironmentVariable = "DFBACKEND";
enum rendererEnvironmentVariable = "DFRENDERER";

abstract class Backend {
    EventLoop _eventLoop;
    FT_Library _freetypeLibrary;

    int exitCode = 0;

    EventLoop eventLoop() => _eventLoop;

    Face createDefaultFace() => loadFaceFromFile("/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf");
    Face createMonospaceFace() => loadFaceFromFile("/usr/share/fonts/liberation-mono/LiberationMono-Regular.ttf");

    this() {
        _eventLoop = new EventLoop();

        FTSupport ftStatus = loadFreeType();
        HBSupport hbStatus = loadHarfBuzz();

        if (ftStatus <= FTSupport.badLibrary || hbStatus <= HBSupport.badLibrary) {
            throw new MissingLibraryException(
                "Cannot load FreeType or HarfBuzz (identified FreeType: %s, identified HarfBuzz: %s)".format(ftStatus, hbStatus)
            );
        }

        FT_Init_FreeType(&_freetypeLibrary);
    }

    ~this() {
        if (_freetypeLibrary) {
            FT_Done_FreeType(_freetypeLibrary);
        }
    }

    final int run() {
        while (eventLoop.loop()) {}

        return exitCode;
    }

    final void exit(int code = 0) {
        exitCode = code;
        _eventLoop.exit();
    }

    Renderer buildRenderer(this R)() {
        if (auto rendererOverride = environment.get(rendererEnvironmentVariable, null)) {
            Renderer delegate() buildRenderer = null;

            static foreach_reverse (Type; InterfacesTuple!R) {{
                static if (is(Type: BackendCompatibleWith!RendererT, RendererT)) {
                    if (RendererT.compatible(cast(R) this)) {
                        enum RendererIdentifier[] attributes = [getUDAs!(RendererT, RendererIdentifier)];
                        if (attributes.length > 0 && attributes.any!((id) => id.identifier == rendererOverride)) {
                            return new RendererT(this);
                        }
                        buildRenderer = () => new RendererT(this);
                    }
                }
            }}

            warning(rendererOverride, " is not available, or is not compatible with the ", R.stringof, " backend.");

            if (buildRenderer !is null) {
                return buildRenderer();
            }
        } else {
            static foreach_reverse (Type; InterfacesTuple!R) {{
                static if (is(Type: BackendCompatibleWith!RendererT, RendererT)) {
                    if (RendererT.compatible(cast(R) this)) {
                        return new RendererT(this);
                    }
                }
            }}
        }

        throw new NoRendererException(format!"No renderer is available for %s."(R.stringof));
    }

    abstract BackendWindow createBackendWindow(Window window);

    final Face loadFaceFromFile(string path) {
        FT_Open_Args openArgs;
        openArgs.flags = FT_OPEN_PATHNAME;
        openArgs.pathname = cast(char*) path.toStringz();
        openArgs.stream   = null;
        return Face(_freetypeLibrary, openArgs);
    }

    final Face loadFaceFromMemory(ubyte[] data) {
        FT_Open_Args openArgs;
        openArgs.flags = FT_OPEN_MEMORY;
        openArgs.memory_base = data.ptr;
        openArgs.memory_size = data.length;
        openArgs.stream = null;
        return Face(_freetypeLibrary, openArgs, data);
    }

    final void runInMainThread(void delegate() func) {
        AsyncNotifier notifier = new AsyncNotifier(_eventLoop);
        notifier.run({
            func();
            notifier.kill();
        });
        notifier.trigger();
    }
}

interface BackendWindow {
    void paint(Context context);
    void invalidate();

    void role(Role role);

    string title();
    void title(string value);

    void cursor(CursorType type);

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

    void showWindowControlMenu(Point location);
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

class MissingLibraryException: Exception {
    this(string msg, string file = __FILE__, int line = __LINE__) {
        super(msg, file, line);
    }
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
