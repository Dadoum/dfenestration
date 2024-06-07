module dfenestration.widgets.null_;

import dfenestration.widgets.container;
import dfenestration.widgets.widget;
import dfenestration.widgets.window;

// Edgiest edge case.
/// A widget really doing nothing, to use if you don't want to make null checks in your container.
class Null: Widget {
    mixin State;

    override Window window() { return null; }
    override void invalidate() {}
    override void onStateChange() {}
    override Null parent(ContainerBase) { return this; }
    override ContainerBase parent() { return null; }
    override Null parentData(ContainerData) { return this; }
    override ContainerData parentData() { return null; }
    override Null allocation(Rectangle) { return this; }
    override Rectangle allocation() { return Rectangle.zero; }
}

static Null nullWidget;

static this() {
    nullWidget = new Null();
}
