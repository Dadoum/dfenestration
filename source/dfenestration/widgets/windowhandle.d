module dfenestration.widgets.windowhandle;

import dfenestration.widgets.bin;
import dfenestration.widgets.widget;

/++
 + A zone where a click allow the user to move the window.
 +/
class WindowHandle: Bin {
    mixin State;

    this() {

    }

    override bool onClickStart(Point location, MouseButton button) {
        if (super.onClickStart(location, button)) {
            return true;
        }

        window.moveDrag();
        return true;
    }
}
