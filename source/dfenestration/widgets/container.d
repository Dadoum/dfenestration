module dfenestration.widgets.container;

public import dfenestration.widgets.containerbase;
public import dfenestration.widgets.null_;

import std.exception;
import std.traits;

import dfenestration.primitives;

import dfenestration.widgets.widget;

/++
 + ContainerBase with some wrappers for declarative UI.
 + See more information in the ContainerBase class.
 +/
abstract class Container(ContainedType): ContainerBase {
    ContainedType _content;

    abstract override bool onSizeAllocate() {
        if (_content is null) {
            return false;
        }
        return super.onSizeAllocate();
    }

    override Widget[] children() {
        static if (isArray!ContainedType) {
            return cast(Widget[]) _content;
        } else {
            return [cast(Widget) _content];
        }
    }

    /++
     + Apparent content.
     +/
    ContainedType content() {
        return _content;
    }
    void content(ContainedType newContent) {
        _content = newContent;
        onContentChange();
    }

    /++
     + Syntax sugar to replicate a declarative GUI.
     +/
    pragma(inline, true)
    R opIndex(this R)(ContainedType newContent...) {
        static if (isArray!ContainedType)
            content = newContent.dup;
        else
            content = newContent;
        return cast(R) this;
    }
}
