module dfenestration.renderers.text.textlayouter;

import std.algorithm.comparison;
import std.algorithm.iteration;
import std.format;
import std.logger;
import std.string;
import std.typecons;
import std.utf;

import hairetsu;
import hairetsu.shaper.basic;

import dfenestration.renderers.text.font;

import dfenestration.primitives;
import dfenestration.renderers.context;

/++
 + Layouts and stores text to be shown.
 +/
struct TextLayouter {
    string _text;
    FontFace _face;
    HaBuffer _haBuffer = new HaBuffer();

    RenderedGlyph[] _glyphs;
    Size _boundingBox;
    uint _baseline;

    string text() {
        return _text;
    }

    void text(string value) {
        _text = value;
        _glyphs = null;

        _haBuffer.clear();
        _haBuffer.addUTF8(value);
    }

    FontFace face() {
        return _face;
    }

    void face(FontFace value) {
        _face = value;
        _glyphs = null;
    }

    void _shapeBuffer() {
        HaBasicShaper shaper = new HaBasicShaper();
        shaper.shape(face, _haBuffer);
        shaper.release();
    }

    Size boundingBox() {
        if (!_haBuffer.isShaped) {
            _shapeBuffer();
        }
        return _boundingBox;
    }

    uint baseline() {
        if (!_haBuffer.isShaped) {
            _shapeBuffer();
        }
        return _baseline;
    }

    RenderedGlyph[] renderedGlyphs() {
        if (!_haBuffer.isShaped) {
            _shapeBuffer();
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
