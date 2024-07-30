module dfenestration.widgets.windowhandle;

import dfenestration.widgets.bin;
import dfenestration.widgets.control;
import dfenestration.widgets.widget;

/++
 + A zone where a click allow the user to move the window.
 +/
class WindowHandle: Bin {
    mixin State;
    bool pressed = false;

    this() {

    }

    override bool onHoverStart(Point location) { return true; }
    override bool onHover(Point location) {
        if (pressed) {
            window.moveDrag();
            return super.onHoverEnd(location);
        }
        return super.onHover(location);
    }
    override bool onHoverEnd(Point location) {
        pressed = false;
        return super.onHoverEnd(location);
    }

    override bool onClickStart(Point location, MouseButton button) {
        auto ret = super.onClickStart(location, button);
        if (button == MouseButton.left) {
            pressed = true;
            return true;
        } else if (button == MouseButton.right) {
            window.backendWindow.showWindowControlMenu(location);
        }
        return ret;
    }
    override bool onClickEnd(Point location, MouseButton button) {
        if (button == MouseButton.left) {
            pressed = false;
        }
        return super.onClickEnd(location, button);
    }
}
