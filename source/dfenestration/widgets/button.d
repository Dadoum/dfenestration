module dfenestration.widgets.button;

import dfenestration.widgets.container;
import dfenestration.widgets.widget;

class Button: Container!Widget {
    private struct _ {
        uint spacing;
        WidgetState widgetState;
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
        content.preferredSize(minimumWidth, naturalWidth, minimumHeight, naturalHeight);
        const uint spacing = 2 * this.spacing();
        minimumWidth += spacing;
        naturalWidth += spacing;
        minimumHeight += spacing;
        naturalHeight += spacing;
    }

    override bool onSizeAllocate() {
        if (!super.onSizeAllocate()) {
            return false;
        }
        const uint offset = this.spacing();
        const uint spacing = 2 * offset;
        const size = this.allocation().size;
        sizeAllocate(Rectangle(offset, offset, size.width - spacing, size.height - spacing), _content);
        return true;
    }

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

    override void onPress(Point location, MouseButton button) {

    }

    override void draw(Context context, Rectangle rectangle) {
        auto allocation = allocation();

        context.rectangle(0, 0, allocation.size.tupleof);
        if (widgetState & WidgetState.pressed) {
            context.sourceRgb(0.1, 0.1, 0.1);
        } else if (widgetState & WidgetState.hovered) {
            context.sourceRgb(0.4, 0.4, 0.4);
        } else {
            context.sourceRgb(0.7, 0.7, 0.7);
        }
        context.fill();

        super.draw(context, rectangle);
    }
}

enum WidgetState {
    none = 0,
    hovered = 1 << 0,
    focused = 1 << 1,
    pressed = 1 << 2,
}
