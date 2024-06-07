module dfenestration.renderers.nanovega.softwarerenderer;

import std.meta;

import dfenestration.renderers.renderer;

/+
version (NanoVega) {
    import arsd.nanovega;
    class NanoVegaSWRenderer: Renderer {
        this(Backend backend) {

        }

        static bool compatible() {
            return false;
        }
    }

    interface NanoVegaSWRendererCompatible: BackendCompatibleWith!NanoVegaSWRenderer {

    }
} else {
    alias NanoVegaSWRenderer = AliasSeq!();
    alias NanoVegaSWRendererCompatible = AliasSeq!();
}
// +/
