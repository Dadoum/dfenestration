module dfenestration.widgets.text;

import std.logger;
import std.range;

import hairetsu;
import hairetsu.shaper.basic;
import hairetsu.render;
import hairetsu.render.builtin;

import dfenestration.style;
import dfenestration.renderers.image;
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

    Image _renderedText;

    bool shapingRequired = true;
    float scaling = 1.75;

    override bool onHoverStart(Point location) {
        window.cursor();
        return super.onHoverStart(location);
    }

    void onScalingChange(float scaling) {
        this.scaling = scaling;
        if (_face) {
            _face.dpi = 96 * scaling;
        }
    }

    override void reloadStyle() {
        super.reloadStyle();
        _face = style.regularFont().createFace();
        _face.pt = 13;
        _face.dpi = 96 * scaling;

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
        HaBasicShaper shaper = new HaBasicShaper();
        shaper.shape(_face, _textBuffer);

        HaRenderer renderer = new HaBuiltinRenderer();

        vec2 textSize = renderer.measureGlyphRun(_face, _textBuffer);
        auto metrics = _face.faceMetrics();

        _baselineHeight = cast(uint) (metrics.ascender.x);
        _boundingBox = Size(cast(uint) textSize.x, cast(uint) (metrics.ascender.x - metrics.descender.x));

        scope HaCanvas canvas = new HaCanvas(_boundingBox.width, _boundingBox.height, HaColorFormat.CBPP8);
        renderer.render(_face, _textBuffer, vec2(0, textSize.y), canvas);
        auto image = Image(_boundingBox.width, _boundingBox.height, Image.Format.c8);

        foreach (idx, line; image.lines().enumerate()) {
            ubyte[] source = cast(ubyte[]) canvas.scanline(cast(int) idx);
            foreach (pixel, w; line.lockstep(source)) {
                pixel[] = w;
            }

            // foreach (pixel, w; line.lockstep(source)) {
            //     pixel[] = [255, 0, 255, w];

            //     if (idx == _baselineHeight) {
            //         pixel[] = [0, 255, 255, 255];
            //     }
            // }
        }

        _renderedText = image * style.textColor();
        trace("Layout OK.");

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

        minimumWidth = cast(uint) (_boundingBox.width / scaling);
        naturalWidth = cast(uint) (_boundingBox.width / scaling);
        minimumHeight = cast(uint) (_boundingBox.height / scaling);
        naturalHeight = cast(uint) (_boundingBox.height / scaling);
    }

    override uint baselineHeight() {
        if (shapingRequired) {
            shape();
        }

        return cast(uint) (_baselineHeight / scaling);
    }

    override void draw(Context c, Rectangle rectangle) {
        if (shapingRequired) {
            shape();
        }
        import std.stdio;
        import std.algorithm;

        c.save();

        {
            c.scale(1 / scaling, 1 / scaling);
            c.sourceImage(_renderedText, 0, 0);
            c.rectangle(0, 0, _boundingBox.tupleof);
            c.fill();
        }

        c.restore();

        // c.rectangle(0, 0, allocation.size.tupleof);
        // c.sourceRgba(0, 1, 0, 1);
        // c.stroke();
    }
}
