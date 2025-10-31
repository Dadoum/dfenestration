module dfenestration.widgets.text;

import std.logger;

import hairetsu;
import hairetsu.shaper.basic;
import hairetsu.render;
import hairetsu.render.builtin;

import dfenestration.style;
import dfenestration.widgets.widget;

alias Text = HorizontalText;

/++
 + A widget displaying some incompressible text.
 +/
class HorizontalText: Widget {
    struct _ {
        @Trigger!(onTextSet) string text;
        bool selectable = true;
    }
    mixin State!_;

    FontFace _face;
    HaBuffer _textBuffer;

    Size _boundingBox;
    uint _baselineHeight;

    bool shapingRequired = true;

    override bool onHoverStart(Point location) {
        window.cursor();
        return super.onHoverStart(location);
    }

    override void reloadStyle() {
        super.reloadStyle();
        _face = style.regularFont().createFace();
        shapingRequired = true;
        this.scheduleWindowSizeAllocation();
        this.invalidate();
    }

    this() {}

    this(string text) {
        this();
        this.text = text;
    }

    void onTextSet() {
        _textBuffer = new HaBuffer();
        _textBuffer.addUTF8(text);
        shapingRequired = true;
         this.scheduleWindowSizeAllocation();
    }

    void shape() {
        import numem;

        HaBasicShaper shaper = new HaBasicShaper();
        shaper.shape(_face, _textBuffer);

        HaRenderer renderer = new HaBuiltinRenderer();

        vec2 textSize = renderer.measureGlyphRun(_face, _textBuffer);
        auto metrics = _face.faceMetrics();

        _baselineHeight = cast(uint) metrics.ascender.x;
        _boundingBox = Size(cast(uint) textSize.x, cast(uint) (metrics.ascender.x + metrics.descender.x));

        HaCanvas canvas = new HaCanvas(_boundingBox.width, _boundingBox.height, HaColorFormat.CBPP8);
        renderer.render(_face, _textBuffer, vec2(0, metrics.ascender.x), canvas);

        shapingRequired = false;
    }

    override void preferredSize(
        out uint minimumWidth,
        out uint naturalWidth,
        out uint minimumHeight,
        out uint naturalHeight
    ) {
        if (!_face) {
            return;
        }

        if (shapingRequired) {
            shape();
        }

        minimumWidth = _boundingBox.width;
        naturalWidth = _boundingBox.width;
        minimumHeight = _boundingBox.height;
        naturalHeight = _boundingBox.height;
    }

    override uint baselineHeight() {
        if (shapingRequired) {
            shape();
        }

        return _baselineHeight;
    }

    override void draw(Context c, Rectangle rectangle) {
        if (shapingRequired) {
            shape();
        }

        /// TODO: text shaping
        c.sourceRgb(1, 0, 1);
        // c.rectangle(0, 0, allocation.size.tupleof);
        // c.fill();
        // c.selectFontPath = "/usr/share/fonts/liberation-mono/LiberationMono-Bold.ttf";

        // c.moveTo(20, 0);
        // foreach (glyph; textLayouter.renderedGlyphs()) {
        //     if (Rectangle.intersect(Rectangle(glyph.position, glyph.size), rectangle) != Rectangle.zero) {
        //         c.showGlyph(glyph);
        //         c.rectangle(glyph.position.tupleof, glyph.size.tupleof);
        //         // info(glyph);
        //         c.fill();
        //     }
        // }
        // c.showText(text);
    }
}
