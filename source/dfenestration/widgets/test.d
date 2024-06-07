module dfenestration.widgets.test;

import std.logger;

import dfenestration.widgets.widget;

/++
 + A test widget, black background, white cross and white border.
 + You can set its size.
 +/
class Test: Widget {
    struct _ {
        Size size;
        Size naturalSize;
    }

    mixin State!_;

    this() {

    }

    override void preferredSize(
        out uint minimumWidth,
        out uint naturalWidth,
        out uint minimumHeight,
        out uint naturalHeight
    ) {
        minimumWidth = size.width;
        naturalWidth = naturalSize.width;
        minimumHeight = size.height;
        naturalHeight = naturalSize.height;
    }

    Size sizeToRequest;
    @StateSetter Test size(Size sz) {
        sizeToRequest = sz;
        naturalSize = sz;
        return this;
    }
    @StateGetter Size size() {
        return sizeToRequest;
    }

    override void draw(Context context) {
        auto allocation = allocation();
        context.sourceRgb(0, 0, 0);
        context.rectangle(0, 0, allocation.width, allocation.height);
        context.fillPreserve();
        context.sourceRgb(1, 1, 1);
        context.lineWidth(2);
        context.stroke();
        context.moveTo(0, 0);
        context.lineTo(allocation.width, allocation.height);
        context.moveTo(0, allocation.height);
        context.lineTo(allocation.width, 0);
        context.stroke();
        // +/
    }
}
