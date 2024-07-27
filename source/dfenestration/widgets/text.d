module dfenestration.widgets.text;

import dfenestration.widgets.widget;

/++
 + A widget displaying some incompressible text.
 +/
class Text: Widget {
    struct WState {
        string text;
    }
    mixin State!WState;

    this(string text) {
        this.text = text;
    }

    override void preferredSize(
        out uint minimumWidth,
        out uint naturalWidth,
        out uint minimumHeight,
        out uint naturalHeight
    ) {
        /// TODO: text shaping
        minimumWidth = 0;
        naturalWidth = 0;
        minimumHeight = 20;
        naturalHeight = 20;
    }

    override void draw(Context c) {
        /// TODO: text shaping
        c.sourceRgb(1, 0, 1);
        // c.rectangle(0, 0, allocation.size.tupleof);
        // c.fill();
        // c.selectFontPath = "/usr/share/fonts/liberation-mono/LiberationMono-Bold.ttf";

        c.moveTo(0, 0);
        // c.showText(text);
        c.fill();
    }
}
