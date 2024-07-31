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
        if (button == MouseButton.left) {
            widgetState = widgetState | WidgetState.pressed;
        }
        return true;
    }
    override bool onClickEnd(Point location, MouseButton button) {
        if (button == MouseButton.left && (widgetState & WidgetState.pressed)) {
            widgetState = widgetState & ~WidgetState.pressed;
            onPress(location, button);
        }
        return true;
    }

    override bool onTouchStart(Point location) { return onClickStart(location, MouseButton.left); }
    override bool onTouchMove(Point location) { return onHover(location); }
    override bool onTouchEnd(Point location) { return onClickEnd(location, MouseButton.left); }
}

enum WidgetState {
    none = 0,
    hovered = 1 << 0,
    focused = 1 << 1,
    pressed = 1 << 2,
}
