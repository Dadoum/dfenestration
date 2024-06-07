module dfenestration.widgets.bin;

import dfenestration.widgets.container;
import dfenestration.widgets.widget;

/++
 + Container with a unique widget.
 +/
class Bin: Container!Widget {
    mixin State;

    override bool onSizeAllocate() {
        if (!super.onSizeAllocate()) {
            return false;
        }
        sizeAllocate(Rectangle(Point(0, 0), allocation().size), _content);
        return true;
    }

    override void preferredSize(
        out uint minimumWidth,
        out uint naturalWidth,
        out uint minimumHeight,
        out uint naturalHeight
    ) {
        _content.preferredSize(minimumWidth, naturalWidth, minimumHeight, naturalHeight);
    }
}
