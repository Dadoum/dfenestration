module dfenestration.widgets.text;

import std.logger;

import hairetsu;

import dfenestration.renderers.text.font;
import dfenestration.renderers.text.textlayouter;
import dfenestration.style;
import dfenestration.widgets.widget;

/++
 + A widget displaying some incompressible text.
 +/
class Text: Widget {
    struct _ {
        @Trigger!(onTextSet) string text;
        bool selectable = true;
    }
    mixin State!_;

    TextLayouter textLayouter;
    HRTextLayouter textLayouter2;

    override bool onHoverStart(Point location) {
        window.cursor();
        return super.onHoverStart(location);
    }

    override void reloadStyle() {
        super.reloadStyle();
        face = style.regularFont().createFace();
        reshape();
        // textLayouter.face = style.defaultFace;
        this.scheduleWindowSizeAllocation();
        this.invalidate();
    }

    this() {
        textLayouter = TextLayouter();
    }

    this(string text) {
        this();
        this.text = text;
    }

    void onTextSet() {
         textLayouter.text = text;
         this.scheduleWindowSizeAllocation();
    }

    override void preferredSize(
        out uint minimumWidth,
        out uint naturalWidth,
        out uint minimumHeight,
        out uint naturalHeight
    ) {
        auto boundingBox = textLayouter.boundingBox();
        minimumWidth = boundingBox.width;
        naturalWidth = boundingBox.width;
        minimumHeight = boundingBox.height;
        naturalHeight = boundingBox.height;
    }

    override uint baselineHeight() {
        return textLayouter.baseline();
    }

    override void draw(Context c, Rectangle rectangle) {
        /// TODO: text shaping
        c.sourceRgb(1, 0, 1);
        // c.rectangle(0, 0, allocation.size.tupleof);
        // c.fill();
        // c.selectFontPath = "/usr/share/fonts/liberation-mono/LiberationMono-Bold.ttf";

        c.moveTo(20, 0);
        foreach (glyph; textLayouter.renderedGlyphs()) {
            if (Rectangle.intersect(Rectangle(glyph.position, glyph.size), rectangle) != Rectangle.zero) {
                c.showGlyph(glyph);
                c.rectangle(glyph.position.tupleof, glyph.size.tupleof);
                // info(glyph);
                c.fill();
            }
        }
        // c.showText(text);
    }
}
