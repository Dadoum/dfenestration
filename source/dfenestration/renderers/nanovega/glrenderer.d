module dfenestration.renderers.nanovega.glrenderer;

import std.exception;
import std.logger;
import std.meta;

import dfenestration.backends.backend;
import dfenestration.primitives;
import dfenestration.renderers.context;
import dfenestration.renderers.renderer;

import dfenestration.widgets.window;

version (NanoVega) {
    import bindbc.opengl;

    import arsd.nanovega;

    import dfenestration.renderers.nanovega.baserenderer;

    @RendererIdentifier("nanovegagl")
    class NanoVegaGLRenderer: NanoVegaBaseRenderer {
        this(Backend backend) {
            scope nanoVegaBackend = cast(NanoVegaGLRendererCompatible) backend;
            assert(nanoVegaBackend !is null);

            nanoVegaBackend.loadGL();
        }

        static bool compatible() {
            // the library can be loaded.
            return loadOpenGL() >= GLSupport.noContext;
        }

        override void draw(BackendWindow backendWindow) {
            scope window = cast(NanoVegaGLWindow) backendWindow;
            assert(window !is null);

            if (!window.setAsCurrentContextGL()) {
                return;
            }

            glViewport(0, 0, window.canvasSize().tupleof);

            glClearColor(0, 0, 0, 0);
            glClear(glNVGClearFlags);

            super.draw(backendWindow);
            window.swapBuffersGL();
        }

        override void initializeWindow(BackendWindow backendWindow) {
            scope window = cast(NanoVegaGLWindow) backendWindow;
            assert(window !is null);

            window.createWindowGL(200, 200);

            synchronized {
                window.setAsCurrentContextGL();
                NVGContext nvgContext = nvgCreateContext();
                enforce(nvgContext !is null, "Cannot build NVGContext");
                window.nvgContext = nvgContext;
            }
            window.swapBuffersGL();
        }

        override void cleanup(BackendWindow backendWindow) {
            scope window = cast(NanoVegaGLWindow) backendWindow;
            assert(window !is null);

            window.cleanupGL();
        }

        override void resize(BackendWindow backendWindow, uint width, uint height) {
            scope window = cast(NanoVegaGLWindow) backendWindow;
            assert(window !is null);

            window.resizeGL(width, height);
        }
    }

    interface NanoVegaGLRendererCompatible: BackendCompatibleWith!NanoVegaGLRenderer {
        void loadGL();
        NanoVegaGLWindow createBackendWindow(Window w);
    }

    interface NanoVegaGLWindow: NanoVegaBaseWindow {
        void createWindowGL(uint width, uint height);
        void resizeGL(uint width, uint height);
        void swapBuffersGL();
        bool setAsCurrentContextGL();
        void cleanupGL();
    }
} else {
    alias NanoVegaGLRenderer = AliasSeq!();
    alias NanoVegaGLRendererCompatible = AliasSeq!();
    alias NanoVegaGLWindow = AliasSeq!();
}
