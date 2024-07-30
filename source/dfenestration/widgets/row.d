module dfenestration.widgets.row;

import dfenestration.widgets.container;
import dfenestration.widgets.widget;

import std.typecons;
import std.logger;

/++
 + Row of widgets. First it will try to give them their minimum size proportionally, then their natural size
 + (whilst preserving continuity).
 +/
class Row: Container!(Widget[]), UsesData!RowData {
    struct _ {
        uint spacing;
    }
    mixin State!_;

    override bool onSizeAllocate() {
        if (!super.onSizeAllocate()) {
            return false;
        }

        if (_content.length == 0) {
            return true;
        }

        auto alloc = allocation();

        struct PreferredSize {
            uint minimumWidth;
            uint naturalWidth;
            uint minimumHeight;
            uint naturalHeight;
        }

        alias SizedWidget = Tuple!(Widget, PreferredSize);

        SizedWidget[] preferredSizes = new SizedWidget[](_content.length);

        uint totalMinimumSize = 0;
        uint totalNaturalSize = 0;
        uint totalMinimumExpandSize = 0;
        uint totalNaturalExpandSize = 0;

        bool hasExpandedWidget = false;
        foreach (idx, widget; _content) {
            auto widgetSize = PreferredSize();

            widget.preferredSize(
                widgetSize.minimumWidth,
                widgetSize.naturalWidth,
                widgetSize.minimumHeight,
                widgetSize.naturalHeight
            );

            preferredSizes[idx] = tuple(widget, widgetSize);

            totalMinimumSize += widgetSize.minimumWidth;
            totalNaturalSize += widgetSize.naturalWidth;

            if (widget.rowData().expand) {
                hasExpandedWidget = true;
                totalMinimumExpandSize += widgetSize.minimumWidth;
                totalNaturalExpandSize += widgetSize.naturalWidth;
            }
        }

        if (totalMinimumSize == 0) {
            foreach (ref couple; preferredSizes) {
                couple[1].minimumWidth = 1;
                if (couple[0].rowData().expand) {
                    totalMinimumExpandSize += 1;
                }
            }
            totalMinimumSize = cast(uint) preferredSizes.length;
        } else if (totalMinimumExpandSize == 0) {
            foreach (ref couple; preferredSizes) {
                if (couple[0].rowData().expand) {
                    couple[1].minimumWidth = 1;
                    totalMinimumExpandSize += 1;
                }
            }
        }

        if (totalNaturalSize == 0) {
            foreach (ref couple; preferredSizes) {
                couple[1].naturalWidth = 1;
                if (couple[0].rowData().expand) {
                    totalNaturalExpandSize += 1;
                }
            }
            totalNaturalSize = cast(uint) preferredSizes.length;
        } else if (totalNaturalExpandSize == 0) {
            foreach (ref couple; preferredSizes) {
                if (couple[0].rowData().expand) {
                    couple[1].naturalWidth = 1;
                    totalNaturalExpandSize += 1;
                }
            }
        }

        if (totalMinimumSize >= alloc.width) {
            // give to each widgets the same proportion of height
            uint allocatedWidth = 0;
            foreach (size; preferredSizes) {
                uint width = (size[1].minimumWidth * alloc.width) / totalMinimumSize;
                sizeAllocate(Rectangle(allocatedWidth, 0, width, alloc.height), size[0]);
                allocatedWidth += width;
            }
        } else if (!hasExpandedWidget || totalNaturalSize > alloc.width) {
            uint allocatedWidth = 0;
            foreach (size; preferredSizes) {
                uint width;
                if (totalNaturalSize - totalMinimumSize == 0) {
                    width = (size[1].minimumWidth * alloc.width) / totalMinimumSize;
                } else {
                    width = size[1].minimumWidth + ((size[1].naturalWidth - size[1].minimumWidth) * (alloc.width - totalMinimumSize)) / (totalNaturalSize - totalMinimumSize);
                }
                sizeAllocate(Rectangle(allocatedWidth, 0, width, alloc.height), size[0]);
                allocatedWidth += width;
            }
        } else {
            uint allocatedWidth = 0;
            uint totalUnexpandedSize = totalNaturalSize - totalNaturalExpandSize;

            foreach (size; preferredSizes) {
                auto widget = size[0];
                auto prefSize = size[1];

                auto rowData = widget.rowData();

                uint width;
                if (rowData.expand) {
                    // TODO: see why -1 is needed here.
                    width = (size[1].naturalWidth * (alloc.width - totalUnexpandedSize)) / totalNaturalExpandSize - 1;
                } else {
                    width = size[1].naturalWidth;
                }
                sizeAllocate(Rectangle(allocatedWidth, 0, width, alloc.height), size[0]);
                allocatedWidth += width;
            }
        }

        return true;
    }

    override void preferredSize(
        out uint minimumWidth,
        out uint naturalWidth,
        out uint minimumHeight,
        out uint naturalHeight
    ) {
        minimumWidth = 0;
        naturalWidth = 0;
        minimumHeight = 0;
        naturalHeight = 0;

        if (_content.length == 0) {
            return;
        }

        foreach (widget; _content) {
            uint widgetMinimumWidth;
            uint widgetNaturalWidth;
            uint widgetMinimumHeight;
            uint widgetNaturalHeight;

            widget.preferredSize(
                widgetMinimumWidth,
                widgetNaturalWidth,
                widgetMinimumHeight,
                widgetNaturalHeight
            );

            if (minimumHeight < widgetMinimumHeight) {
                minimumHeight = widgetMinimumHeight;
            }
            if (naturalHeight < widgetNaturalHeight) {
                naturalHeight = widgetNaturalHeight;
            }
            minimumWidth += widgetMinimumWidth;
            naturalWidth += widgetNaturalWidth;
        }
    }
}

class RowData: ContainerData {
    bool expand = false;
}

RowData rowData(Widget widget) {
    if (RowData rowData = cast(RowData) widget.parentData) {
        return rowData;
    }
    RowData rowData = new RowData();
    widget.parentData = rowData;
    return rowData;
}
