module dfenestration.renderers.text.textlayouter;

import std.format;
import std.logger;
import std.string;

import dfenestration.renderers.text.font;

import dfenestration.primitives;
import dfenestration.renderers.context;

/++
 + Layouts and stores text to be shown.
 +/
struct TextLayouter {
    string _text;
    Face _face;

    string text() {
        return _text;
    }

    void text(string value) {
        _text = value;
    }

    Face face() {
        return _face;
    }

    void face(Face value) {
        _face = value;
    }

    TextLayout layout() {
        Size size;
        Point[] points;
        return TextLayout(size, points);
    }
}

struct TextLayout {
  private:
    Size size;
    Point[] points;

    @disable this();
    this(typeof(typeof(this).tupleof) elems) {
        this.tupleof = elems;
    }
}

void showLayout(Context context, TextLayout layout) {

}
