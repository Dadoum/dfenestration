module dfenestration.widgets.buttonbase;

import dfenestration.widgets.container;
import dfenestration.widgets.control;
import dfenestration.widgets.widget;

public import dfenestration.primitives;
public import dfenestration.types;

abstract class ButtonBase: Container!Widget {
    mixin Control;

    private struct _ {
        @TriggerWindowSizeAllocation uint spacing = 4;
    }

    mixin State!_;

    this() {
        cursor = CursorType.pointer;
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

    override void draw(Context context, Rectangle rectangle) {
        auto allocation = allocation();
        auto widgetState = widgetState();

        context.rectangle(0, 0, allocation.size.tupleof);
        if (widgetState & WidgetState.pressed) {
            context.sourceRgb(0.1, 0.1, 0.1);
        } else if (widgetState & WidgetState.hovered) {
            context.sourceRgb(0.4, 0.4, 0.4);
        } else {
            context.sourceRgb(0.7, 0.7, 0.7);
        }
        context.fill();
        if (widgetState & WidgetState.focused) {
            context.sourceRgb(0, 0, 0);
            context.rectangle(2, 2, allocation.width - 4, allocation.height - 4);
            context.lineWidth = 2;
            context.stroke();
        }

        super.draw(context, rectangle);
    }

    override uint baselineHeight() {
        return spacing + content.baselineHeight();
    }
}
