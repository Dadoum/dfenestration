module dfenestration.widgets.widget;

public import dfenestration.types;
public import dfenestration.primitives;
public import dfenestration.renderers.context;

import dfenestration.primitives;
import dfenestration.style;
import dfenestration.widgets.containerbase;
import dfenestration.widgets.window;

/++
 + Base widget class. All widgets are inheriting that class.
 +/
abstract class Widget {
    private struct _ {
        /// Real parent in the internal widget tree
        @Trigger!(Widget.cacheWindowAndStyle) ContainerBase parent;
        /// Parent data for the apparent widget parent
        ContainerData parentData;
        /// Space given to the widget inside the parent container allocation.
        @TriggerRedraw Rectangle allocation;
        /// Cursor shown when hovering the widget
        CursorType cursor = CursorType.default_;
        /// Widget style
        Style* style;
    }
    mixin State!_;

    size_t containerIndex = -1;

    void reloadStyle() {}
    void draw(Context context, Rectangle rectangle) {}

    /++
     + Called when the widget gets hovered, with the relative hover location.
     + Returns true if the hover has been captured.
     +/
    bool onHover(Point location) { return false; }
    bool onHoverStart(Point location) { return false; }
    bool onHoverEnd(Point location) { return false; }

    /++
     + Called when the widget gets clicked, with the relative click location.
     + Returns true if the click has been captured.
     +/
    bool onClickStart(Point location, MouseButton button) { return false; }
    bool onClickEnd(Point location, MouseButton button) { return false; }

    bool onTouchStart(Point location) { return false; }
    bool onTouchMove(Point location) { return false; }
    bool onTouchEnd(Point location) { return false; }

    /++
     + Pinch touchpad gesture (or touch screen)
     +/
    bool onPinch(Point location, int scale) {
        return false;
    }

    /++
     + Swipe touchpad gesture (or touch screen)
     +/
    bool onSwipe(Point location, int dx, int dy) {
        return false; // TODO: default handling swipe/scrolling, implement velocity
    }

    /++
     + Called when any velocity should be cancelled.
     +/
    bool onHold(Point location) {
        return false;
    }

    bool onScroll(Point location) {
        return false;
    }

    /++
     + Called when the scaling of the window changed.
     +/
    void onScalingChange(float scaling) {}

    /++
     + Called when the focus is moved forward, and that the widget could be focused (or is).
     + If it takes focus, the next nextFocus/previousFocus call will also be forwarded to it until it releases the focus.
     + Call unfocus if needed.
     + Returns: Whether the widget takes/retains focus.
     + [Default behaviour: call onFocus and see if the focus is desired there]
     +/
    bool nextFocus() {
        return onFocusRequest();
    }

    /++
     + Called when the focus is moved backward, and that the widget could be focused (or is).
     + If it takes focus, the next nextFocus/previousFocus call will also be forwarded to it until it releases the focus.
     + Don't call unfocus, it will be done by the container.
     + Returns: Whether the widget takes/retains focus.
     + [Default behaviour: call onFocus and see if the focus is desired there]
     +/
    bool previousFocus() {
        return onFocusRequest();
    }

    /++
     + Called when it's your turn to get focused, and decide whether you should get focused or not.
     + It should not call focus or unfocus, which are forcing that decision.
     + Returns: Whether the widget takes/retains focus.
     + [Default behaviour: call onFocus and see if the focus is desired there]
     +/
    bool onFocusRequest() {
        return false;
    }

    /++
     + Steal focus
     +/
    void focus() {
        auto focusedWidget = window.focusedWidget;
        if (focusedWidget == this || focusedWidget is null) {
            return;
        }
        focusedWidget.unfocus();
        window.focusedWidget = this;
    }

    /++
     + Release focus
     +/
    void unfocus() {
        parent.unfocus();
    }

    /++
     + Request the widget to be redrawn.
     +/
    void invalidate() {
        if (parent) {
            parent.invalidate(allocation);
        }
    }

    /++
     + Widget's preferred size. Can be called called by containers for layout.
     +/
    void preferredSize(
        out uint minimumWidth,
        out uint naturalWidth,
        out uint minimumHeight,
        out uint naturalHeight
    ) {
        minimumWidth = 0;
        naturalWidth = 0;
        minimumHeight = 0;
        naturalHeight = 0;
    }

    /++
     + Widget's preferred size given a certain width. Can be called called by containers for layout.
     +/
    void preferredHeightForWidth(
        uint width,
        out uint minimumHeight,
        out uint naturalHeight
    ) {
        uint _, __;
        preferredSize(
            _, __, minimumHeight, naturalHeight
        );
    }

    /++
     + Widget's preferred size given a certain height. Can be called called by containers for layout.
     +/
    void preferredWidthForHeight(
        uint height,
        out uint minimumWidth,
        out uint naturalWidth,
    ) {
        uint _, __;
        preferredSize(
            minimumWidth, naturalWidth, _, __
        );
    }

    uint baselineHeight() {
        return allocation.height;
    }

    /++
     + Configure specific fields for a given container type.
     +/
    pragma(inline, true)
    R layoutProperties(T: ContainerBase, this R)(DataFor!T containerData) {
        parentData = containerData;
        return cast(R) this;
    }

    /++
     + Configure specific fields for a given container type.
     +/
    pragma(inline, true)
    R layoutProperties(T: ContainerBase, this R)(typeof(DataFor!T.tupleof)) { // TODO: give the right name to params
        auto data = new DataFor!T();
        static foreach (idx, field; __traits(parameters)) {
            __traits(child, data, DataFor!T.tupleof[idx]) = field;
        }
        return layoutProperties!(T, R)(data);
    }

    final void scheduleWindowSizeAllocation() {
        if (auto window = window()) {
            window.scheduleSizeAllocation();
        }
    }

    Window _window;
    final void cacheWindowAndStyle() {
        _window = parent !is null ? parent._window : null;
        if (ContainerBase container = cast(ContainerBase) this) {
            container.forall((widget) { widget.cacheWindowAndStyle(); });
        }

        if (_window && style != window.style) {
            style = _window.style;
            reloadStyle();
        }
    }

    final Window window() {
        return _window;
    }

    debug {
        override string toString() {
            import std.format;
            return format!"%s(%x)"(super.toString(), cast(void*) this);
        }
    }
}

struct StateGetter {}
struct StateSetter {}

mixin template State() {
    import std.traits;
    static if (!is(__stateDone)) {
        private enum __stateDone;

        static if (is(typeof(this) BaseClass == super)) {
            static foreach (member; __traits(allMembers, BaseClass[0])) {
                static foreach (overload; __traits(getOverloads, BaseClass[0], member)) {
                    static if (hasUDA!(overload, StateSetter)) {
                        mixin(`
                        @StateSetter override typeof(this) ` ~ __traits(identifier, overload) ~ `(Parameters!overload params) {
                            __traits(child, super, overload)(params);
                            return this;
                        }
                        `);
                    } else static if (hasUDA!(overload, StateGetter)) {
                        mixin(`
                        @StateGetter override ReturnType!(typeof(overload)) ` ~ __traits(identifier, overload) ~ `() {
                            return __traits(child, super, overload)();
                        }
                        `);
                    }
                }
            }
        }
    }
}

struct Trigger(alias U) {}
alias TriggerRedraw = Trigger!(Widget.invalidate);
alias TriggerWindowSizeAllocation = Trigger!(Widget.scheduleWindowSizeAllocation);

mixin template State(StateStructure) {
    mixin State;

    import std.traits;
    import std.format;

    static foreach (property; StateStructure.tupleof) {
        static if (!__traits(hasMember, typeof(this), __traits(identifier, property))) {
            mixin(format!"
                typeof(property) _%2$s = __traits(child, StateStructure(), property);

                @StateSetter %1$s typeof(this) %2$s(typeof(property) value) {
                    _%2$s = value;
                    static foreach (attribute; __traits(getAttributes, property)) {
                        static if (is(attribute == Trigger!U, alias U)) {
                            U();
                        }
                    }
                    return this;
                }

                @StateGetter %1$s typeof(property) %2$s() {
                    return _%2$s;
                }
            "(__traits(getVisibility, property), __traits(identifier, property)));
        } else {
            static foreach (overload; __traits(getOverloads, typeof(this), __traits(identifier, property))) {
                static if (
                    is(typeof(&overload) == typeof(property) function())
                ) {
                    static assert(
                        hasUDA!(overload, StateGetter),
                        format!"\n%s(%d,%d): [Dfenestration error] Custom state property getter `"(__traits(getLocation, overload)) ~
                        __traits(fullyQualifiedName, overload) ~ "` does not have the `StateGetter` UDA."
                    );
                } else static if (
                    is(typeof(&overload) == typeof(this) function(typeof(property)))
                ) {
                    static assert(
                        hasUDA!(overload, StateSetter),
                        format!"\n%s(%d,%d): [Dfenestration error] Custom state property setter `"(__traits(getLocation, overload)) ~
                        __traits(fullyQualifiedName, overload) ~ "` does not have the `StateSetter` UDA."
                    );
                }
            }
        }
    }
}
