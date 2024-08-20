module dfenestration.widgets.containerbase;

import std.exception;
import std.logger;
import std.typecons;

import dfenestration.primitives;
import dfenestration.renderers.context;
import dfenestration.widgets.widget;
/++
 + Widget that can contain other widgets.
 + It contains some widgets (apparent widget tree), and allocates some potentially different widgets (internal widget
 + tree). It layouts and dispatches events to allocated widgets.
 +/
abstract class ContainerBase: Widget, UsesData!ContainerData {
    struct Allocation {
        Widget widget;
        Rectangle extent;
    }
    Allocation[] allocations;

    override ContainerBase allocation(Rectangle value) {
        super.allocation(value);
        onSizeAllocate();
        return this;
    }

    override Rectangle allocation() {
        return super.allocation();
    }

    /++
     + Called when the container has to allocate to widgets some space in the container.
     + Returns false if something prevents the allocation from occuring.
     +/
    abstract bool onSizeAllocate() {
        foreach (allocation; allocations) {
            auto widget = allocation.widget;
            if (widget.parent == this)
                widget.parent = null;
        }
        allocations.length = 0; // keep the array allocated as it will likely have the same size.
        invalidate(allocation);
        return true;
    }

    /++
     + Give some space to some widget in the container. Widget allocated later in the code will appear above.
     +/
    void sizeAllocate(Rectangle allocationExtent, Widget widget) {
        widget.allocation = allocationExtent;
        // enforce(widget.parent is null, "Widget " ~ widget.toString() ~ " already has another parent!!");
        if (widget.parent == this) {
            foreach (index, ref allocation; allocations) {
                if (allocation.widget == widget) {
                    allocation.extent = allocationExtent;
                    return;
                }
            }
        }

        widget.parent = this;
        allocations ~= Allocation(widget, allocationExtent);
    }

    override void draw(Context context, Rectangle invalidatedRect) {
        super.draw(context, invalidatedRect);
        foreach (allocation; allocations) {
            auto widget = allocation.widget;
            auto allocatedRect = allocation.extent;
            auto rectangle = invalidatedRect.intersect(allocatedRect);
            if (rectangle != Rectangle.zero) {
                context.save();
                scope(exit) context.restore();

                context.translate(allocatedRect.x, allocatedRect.y);
                context.rectangle(0, 0, allocatedRect.width, allocatedRect.height);
                context.clip();
                widget.draw(context, rectangle);
            }
        }
    }

    /++
     + Request part of the widget to be redrawn.
     +/
    void invalidate(Rectangle rect) {
        if (parent) {
            rect.x += allocation.x;
            rect.y += allocation.y;
            parent.invalidate(rect);
        }
    }

    Widget _hoveredWidget = null;
    pragma(inline, true)
    final Widget hoveredWidget() {
        return _hoveredWidget;
    }
    pragma(inline, true)
    final void hoveredWidget(Widget widget) {
        _hoveredWidget = widget;
        window.scheduleCursorUpdate();
    }

    override bool onHoverStart(Point location) {
        // bool val = super.onHoverStart(location);
        foreach_reverse (allocation; allocations) {
            auto widget = allocation.widget;
            auto rectangle = allocation.extent;
            if (rectangle.contains(location)) {
                location.x -= rectangle.x;
                location.y -= rectangle.y;

                if (widget.onHoverStart(location)) {
                    hoveredWidget = widget;
                    return true;
                }
            }
        }

        return false;
    }

    override CursorType cursor() {
        return hoveredWidget ? hoveredWidget.cursor() : super.cursor();
    }

    override Widget cursor(CursorType cursor) {
        return super.cursor(cursor);
    }

    override bool onHover(Point location) {
        foreach_reverse (allocation; allocations) {
            auto widget = allocation.widget;
            auto rectangle = allocation.extent;
            if (rectangle.contains(location)) {
                auto relativeLocation = Point(location.x - rectangle.x, location.y - rectangle.y);
                if (hoveredWidget != widget) {
                    // does the widget handles hovering
                    if (widget.onHoverStart(relativeLocation)) {
                        if (hoveredWidget) {
                            hoveredWidget.onHoverEnd(relativeLocation);
                        }

                        hoveredWidget = widget;
                    } else {
                        // if not, consider it transparent.
                        continue;
                    }
                }
                if (widget.onHover(relativeLocation)) {
                    return true;
                }
            }
        }
        if (hoveredWidget) {
            auto rectangle = hoveredWidget.allocation;
            auto relativeLocation = Point(location.x - rectangle.x, location.y - rectangle.y);
            hoveredWidget.onHoverEnd(relativeLocation);

            hoveredWidget = null;
        }

        return false;
    }

    override bool onHoverEnd(Point location) {
        if (hoveredWidget) {
            bool val = hoveredWidget.onHoverEnd(location);
            hoveredWidget = null;
            return val;
        }
        return false;
    }

    override bool onClickStart(Point location, MouseButton button) {
        foreach_reverse (allocation; allocations) {
            auto widget = allocation.widget;
            auto rectangle = allocation.extent;
            if (rectangle.contains(location)) {
                location.x -= rectangle.x;
                location.y -= rectangle.y;
                return widget.onClickStart(location, button);
            }
        }

        return false;
    }

    override bool onClickEnd(Point location, MouseButton button) {
        foreach_reverse (allocation; allocations) {
            auto widget = allocation.widget;
            auto rectangle = allocation.extent;
            if (rectangle.contains(location)) {
                location.x -= rectangle.x;
                location.y -= rectangle.y;
                return widget.onClickEnd(location, button);
            }
        }

        return false;
    }

    Widget touchedWidget;
    override bool onTouchStart(Point location) {
        foreach_reverse (allocation; allocations) {
            auto widget = allocation.widget;
            auto rectangle = allocation.extent;
            if (rectangle.contains(location)) {
                location.x -= rectangle.x;
                location.y -= rectangle.y;

                if (widget.onTouchStart(location)) {
                    touchedWidget = widget;
                    return true;
                }
            }
        }

        return false;
    }

    override bool onTouchMove(Point location) {
        foreach_reverse (allocation; allocations) {
            auto widget = allocation.widget;
            auto rectangle = allocation.extent;
            if (rectangle.contains(location)) {
                auto relativeLocation = Point(location.x - rectangle.x, location.y - rectangle.y);
                if (touchedWidget != widget && touchedWidget) {
                    // does the widget handles touch
                    if (widget.onTouchStart(relativeLocation)) {
                        touchedWidget.onTouchEnd(relativeLocation);
                        touchedWidget = widget;
                    } else {
                        // if not, consider it transparent.
                        continue;
                    }
                }
                if (widget.onTouchMove(relativeLocation)) {
                    return true;
                }
            }
        }

        if (touchedWidget) {
            auto rectangle = touchedWidget.allocation;
            auto relativeLocation = Point(location.x - rectangle.x, location.y - rectangle.y);
            touchedWidget.onTouchEnd(location);
            touchedWidget = null;
        }
        return false;
    }

    override bool onTouchEnd(Point location) {
        if (touchedWidget) {
            bool val = touchedWidget.onTouchEnd(location);
            touchedWidget = null;
            return val;
        }
        return false;
    }

    /++
     + Call some function with every contained widget (in the internal tree).
     +/
    void forall(void delegate(Widget) callback) {
        foreach (allocation; allocations) {
            callback(allocation.widget);
        }
    }

    /++
     + Call some function with every contained widget (in the apparent tree).
     +/
    void foreach_(void delegate(Widget) callback) {
        foreach (widget; children) {
            callback(widget);
        }
    }

    /++
     + Apparent children to the container.
     +/
    abstract Widget[] children();

    bool sizeAllocationScheduled = false;
    final void scheduleSizeAllocation() {
        if (!sizeAllocationScheduled) {
            if (auto window = window()) {
                sizeAllocationScheduled = true;
                window.runInMainThread({
                    onSizeAllocate();
                    sizeAllocationScheduled = false;
                });
            }
        }
    }
}

class ContainerData {

}

interface UsesData(T: ContainerData) {

}

// FIXME: recursive templates and std traits
private template allInherits(U, T...) {
    static if (is(T[0]: UsesData!I, I)) {
        static assert(allInherits!(U, T[1..$]), U.stringof ~ " should be a superclass of all the container data types in the chain");
        static if (is (U: I)) {
            enum allInherits = allInherits!(U, T[1..$]);
        } else {
            enum allInherits = false;
        }
    } else static if (T.length) {
        enum allInherits = allInherits!(U, T[1..$]);
    } else {
        enum allInherits = true;
    }
}

private template ContainerDataAmong(T...) {
    static if (is(T[$ - 1]: UsesData!U, U)) {
        debug {
            // Hopefully people will be clever enough to avoid testing stuff in release mode.
            static assert(allInherits!(U, T[0..$ - 1]), U.stringof ~ " should be a superclass of all the container data types in the chain");
        }
        alias ContainerDataAmong = U;
    } else static if (T.length) {
        alias ContainerDataAmong = ContainerDataAmong!(T[0..$ - 1]);
    } else {
        static assert(false, "Should never happen. Container doesn't have ContainerData at all as parent class while ContainerBase has.");
    }
}

template DataFor(ContainerT: ContainerBase) {
    import std.traits: InterfacesTuple;
    alias DataFor = ContainerDataAmong!(InterfacesTuple!ContainerT);
}

alias TriggerSizeAllocation = Trigger!(ContainerBase.onSizeAllocate);
