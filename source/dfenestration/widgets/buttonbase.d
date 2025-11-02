module dfenestration.widgets.buttonbase;

import dfenestration.animation;

import dfenestration.widgets.container;
import dfenestration.widgets.control;
import dfenestration.widgets.widget;

public import dfenestration.primitives;
public import dfenestration.types;

abstract class ButtonBase: Container!Widget {
    mixin Control;

    private struct _ {
        @TriggerWindowSizeAllocation uint spacing = 4;
        @TriggerRedraw float backgroundColor = 1.;
    }

    mixin State!_;

    this() {
        cursor = CursorType.pointer;
    }

    AnimationCancellationToken animCancel;
    WidgetState _state;

    @StateGetter
    WidgetState widgetState() {
        return _state;
    }

    @StateSetter
    ButtonBase widgetState(WidgetState state) {
        auto changes = state ^ _state;
        if (changes & (WidgetState.pressed | WidgetState.hovered)) {
            if (animCancel.valid) {
                animCancel.cancel(window);
            }

            auto currentColor = backgroundColor;
            auto targetColor =
                state & WidgetState.pressed ? pressedColor :
                state & WidgetState.hovered ? hoveredColor :
                normalColor;

            animCancel = window.registerAnimation(new Animation(dur!"msecs"(100), (progress) {
                backgroundColor = lerp(currentColor, targetColor, progress);
            }, true));
        }
        _state = state;
        invalidate(allocation());
        return this;
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

    enum pressedColor = 0.9;
    enum hoveredColor = 0.95;
    enum normalColor = 1.;

    override void draw(Context context, Rectangle rectangle) {
        auto allocation = allocation();
        auto widgetState = widgetState();

        context.roundedRectangle(0, 0, allocation.size.tupleof, 10);
        context.sourceRgb(backgroundColor, backgroundColor, backgroundColor);
        context.fillPreserve();
        context.sourceRgb(0.9, 0.9, 0.9);
        context.lineWidth = 2;
        context.stroke();

        if (widgetState & WidgetState.focused) {
            context.sourceRgba(0, 0, 0, 0.05);
            context.rectangle(2, 2, allocation.width - 4, allocation.height - 4);
            context.lineWidth = 1;
            context.stroke();
        }

        super.draw(context, rectangle);
    }

    override uint baselineHeight() {
        return spacing + content.baselineHeight();
    }
}
