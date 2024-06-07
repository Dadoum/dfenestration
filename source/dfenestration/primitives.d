module dfenestration.primitives;

import std.algorithm.comparison;

struct Point {
    int x;
    int y;

    enum zero = Point(0, 0);
}

struct Size {
    uint width;
    uint height;

    enum zero = Size(0, 0);
}

struct Rectangle {
    Point location;
    pragma(inline, true) ref int x() => location.x;
    pragma(inline, true) ref int y() => location.y;

    Size size;
    pragma(inline, true) ref uint width() => size.width;
    pragma(inline, true) ref uint height() => size.height;

    this(Point location, Size size) {
        this.location = location;
        this.size = size;
    }

    this(int x, int y, uint width, uint height) {
        location.x = x;
        location.y = y;
        size.width = width;
        size.height = height;
    }

    enum zero = Rectangle(Point.zero, Size.zero);
}

Rectangle intersect(Rectangle rect1, Rectangle rect2) {
    Rectangle ret;
    ret.x = max(rect1.x, rect2.x);
    ret.y = max(rect1.y, rect2.y);
    ret.width = max(rect1.x + rect1.width, rect2.x + rect2.width) - ret.x;
    ret.width = max(rect1.y + rect1.height, rect2.y + rect2.height) - ret.y;
    return ret;
}

bool contains(Rectangle rect, Point point) {
    return rect.x <= point.x &&
        rect.y <= point.y &&
        rect.x + rect.width >= point.x &&
        rect.y + rect.height >= point.y;
}
