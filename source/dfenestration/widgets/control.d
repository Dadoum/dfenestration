module dfenestration.widgets.control;

import dfenestration.widgets.widget;

mixin template Control() {
    private struct _ {
        WidgetState widgetState;
    }

    mixin State!_;

    override bool onHover(Point location) {
        super.onHover(__traits(parameters));
        return true;
    }

    override bool onHoverStart(Point location) {
        widgetState = widgetState | WidgetState.hovered;
        return true;
    }

    override bool onHoverEnd(Point location) {
        widgetState = widgetState & ~(WidgetState.hovered | WidgetState.pressed);
        return true;
    }
    override bool onClickStart(Point location, MouseButton button) {
        widgetState = widgetState | WidgetState.pressed;
        return true;
    }
    override bool onClickEnd(Point location, MouseButton button) {
        if (widgetState & WidgetState.pressed) {
            widgetState = widgetState & ~WidgetState.pressed;
            onPress(location, button);
        }
        return true;
    }
}

enum WidgetState {
    none = 0,
    hovered = 1 << 0,
    focused = 1 << 1,
    pressed = 1 << 2,
}
