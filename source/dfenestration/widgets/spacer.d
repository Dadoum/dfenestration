module dfenestration.widgets.spacer;

import dfenestration.widgets.widget;

/++
 + Does nothing. Use it to add a stub expand in a linear container.
 +/
class Spacer: Widget {
    mixin State;

    override void draw(Context c) {}
}
