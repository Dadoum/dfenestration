module dfenestration.widgets.button;

import dfenestration.widgets.widget;
import dfenestration.widgets.buttonbase;

final class Button: ButtonBase {
    private struct _ {
        void delegate(Button) pressed;
    }

    mixin State!_;

    override void onPress(Point location, MouseButton button) {
        focus();
        pressed()(this);
    }
}