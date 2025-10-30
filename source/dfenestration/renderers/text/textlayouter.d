module dfenestration.renderers.text.textlayouter;

import std.algorithm.comparison;
import std.algorithm.iteration;
import std.format;
import std.logger;
import std.string;
import std.typecons;
import std.utf;

import bindbc.freetype;

import dfenestration.renderers.text.font;

import dfenestration.primitives;
import dfenestration.renderers.context;

/++
 + Layouts and stores text to be shown.
 +/
struct TextLayouter {
    string _text;
    Nullable!FontFaceRef _face;

    RenderedGlyph[] _glyphs;
    Size _boundingBox;
    uint _baseline;

    string text() {
        return _text;
    }

    void text(string value) {
        _text = value;
        _glyphs = null;
    }

    Nullable!FontFaceRef face() {
        return _face;
    }

    void face(FontFaceRef value) {
        _face = value;
        _glyphs = null;
    }

    void computeGlyphsForText(string text, out RenderedGlyph[] glyphs) {
        synchronized {
            if (face.isNull) {
                return;
            }

            auto face = _face.get();

            FT_Error error;
            error = FT_Set_Pixel_Sizes(face, 0, 20);
            if (error) {
                warning("Freetype error: ", FT_Error_String(error).fromStringz());
                return;
            }

            int x, y;
            glyphs = new RenderedGlyph[](text.length);

            FT_GlyphSlot slot = face.glyph;
            _baseline = 0;

            size_t index;
            foreach (character; text.byCodeUnit()) {
                scope(exit) index += 1;

                error = FT_Load_Char(face, character, FT_LOAD_RENDER);
                if (error) {
                    warning("Freetype error: ", FT_Error_String(error).fromStringz());
                    continue;
                }

                uint baseline = slot.bitmap_top;
                glyphs[index] = RenderedGlyph(
                    Point(x, y),
                    Size(cast(uint) slot.metrics.width >> 6, cast(uint) slot.metrics.height >> 6),
                    baseline
                );
                if (baseline > _baseline) {
                    _baseline = baseline;
                }

                x += slot.advance.x >> 6;
                // y += slot.advance.y >> 6;
            }

            foreach (ref glyph; glyphs) {
                glyph.position.y += _baseline - glyph.baseline;
            }

            _boundingBox.width = x;
            _boundingBox.height = cast(uint) (face.size.metrics.height >> 6);
        }
    }

    void _computeGlyphs() {
        computeGlyphsForText(_text, _glyphs);
    }

    Size boundingBox() {
        if (!_glyphs) {
            _computeGlyphs();
        }
        return _boundingBox;
    }

    uint baseline() {
        if (!_glyphs) {
            _computeGlyphs();
        }
        return _baseline;
    }

    RenderedGlyph[] renderedGlyphs() {
        if (!_glyphs) {
            _computeGlyphs();
        }
        return _glyphs;
    }
}

struct RenderedGlyph {
    Point position;
    Size size;
    uint baseline;
    // Image buffer;
}
