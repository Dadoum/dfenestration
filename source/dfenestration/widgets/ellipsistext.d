module dfenestration.widgets.ellipsistext;

import std.algorithm.iteration : fold;
import std.algorithm.comparison : max;
import std.string;

import dfenestration.primitives;
import dfenestration.renderers.text.textlayouter;
import dfenestration.widgets.text;

// TODO
class EllipsisText: Text {
    uint ellipsisSize;

    this(string text) {
        super(text);
    }

    override void reloadStyle() {
        super.reloadStyle();
        RenderedGlyph[] glyphs;
        textLayouter.computeGlyphsForText("…", glyphs);
        ellipsisSize =
            glyphs
                .fold!((acc, glyph) => max(acc, glyph.size.width))(0);
    }

    // override EllipsisText allocation(Rectangle rect) {
    //     foreach (index, c; text.renderedGlyphs()) {
    //         auto totalSize =
    //     }
    //     return this;
    // }
}

private static uint abs(int r) {
    if (r < 0) {
        return -r;
    }
    return r;
}
