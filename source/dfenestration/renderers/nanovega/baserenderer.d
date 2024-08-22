module dfenestration.renderers.nanovega.baserenderer;

import dfenestration.backends.backend;
import dfenestration.primitives;
import dfenestration.renderers.renderer;

version (NanoVega) {
    import arsd.nanovega;

    import nanovegacontext;

    abstract class NanoVegaBaseRenderer: Renderer {
        override void draw(BackendWindow backendWindow) {
            auto window = cast(NanoVegaBaseWindow) backendWindow;
            assert(window !is null);

            scope nvgContext = window.nvgContext;
            {
                nvgContext.beginFrame(window.canvasSize.tupleof);
                scope(exit) nvgContext.endFrame();

                window.paint(new NanoVegaContext(nvgContext));
            }
        }
    }

    interface NanoVegaBaseWindow: BackendWindow {
        /// Somewhere to store an NVGContext.
        ref NVGContext nvgContext();
        /// Size of the canvas (the drawing surface).
        Size canvasSize();
    }
}
