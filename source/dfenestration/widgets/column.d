module dfenestration.widgets.column;

import std.logger;
import std.typecons;

import dfenestration.widgets.container;
import dfenestration.widgets.widget;

/++
 + Column of widgets. First it will try to give them their minimum size proportionally, then their natural size
 + (whilst preserving continuity).
 +/
class Column: Container!(Widget[]), UsesData!ColumnData {
    struct _ {
        @TriggerWindowSizeAllocation uint spacing = 0;
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
        const spacing = spacing();
        alloc.height -= (_content.length - 1) * spacing;

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

        size_t expandedWidgetCount = 0;

        foreach (idx, widget; _content) {
            auto widgetSize = PreferredSize();

            widget.preferredSize(
                widgetSize.minimumWidth,
                widgetSize.naturalWidth,
                widgetSize.minimumHeight,
                widgetSize.naturalHeight
            );

            preferredSizes[idx] = tuple(widget, widgetSize);

            totalMinimumSize += widgetSize.minimumHeight;
            totalNaturalSize += widgetSize.naturalHeight;

            if (widget.columnData().expand) {
                expandedWidgetCount += 1;
                totalMinimumExpandSize += widgetSize.minimumHeight;
                totalNaturalExpandSize += widgetSize.naturalHeight;
            }
        }
        bool hasExpandedWidget = expandedWidgetCount > 0;

        if (totalMinimumSize == 0) {
            foreach (ref couple; preferredSizes) {
                couple[1].minimumHeight = 1;
                if (couple[0].columnData().expand) {
                    totalMinimumExpandSize += 1;
                }
            }
            totalMinimumSize = cast(uint) preferredSizes.length;
        } else if (totalMinimumExpandSize == 0) {
            foreach (ref couple; preferredSizes) {
                if (couple[0].columnData().expand) {
                    couple[1].minimumHeight = 1;
                    totalMinimumExpandSize += 1;
                }
            }
        }

        if (totalMinimumSize >= alloc.height) {
            // give to each widgets the same proportion of height
            uint allocatedHeight = 0;
            foreach (size; preferredSizes) {
                uint height = (size[1].minimumHeight * alloc.height) / totalMinimumSize;
                sizeAllocate(Rectangle(0, allocatedHeight, alloc.width, height), size[0]);
                allocatedHeight += height + spacing;
            }
        } else if (/+ +/ !hasExpandedWidget || totalNaturalSize > alloc.height) {
            uint allocatedHeight = 0;
            foreach (size; preferredSizes) {
                uint height;
                if (totalNaturalSize == totalMinimumSize) {
                    height = (size[1].minimumHeight * alloc.height) / totalMinimumSize;
                } else {
                    height = size[1].minimumHeight + ((size[1].naturalHeight - size[1].minimumHeight) * (alloc.height - totalMinimumSize)) / (totalNaturalSize - totalMinimumSize);
                }
                sizeAllocate(Rectangle(0, allocatedHeight, alloc.width, height), size[0]);
                allocatedHeight += height + spacing;
            }
        } else {
            uint allocatedHeight = 0;
            uint totalUnexpandedSize = totalNaturalSize - totalNaturalExpandSize;

            foreach (size; preferredSizes) {
                auto widget = size[0];
                auto prefSize = size[1];

                auto columnData = widget.columnData();

                uint height;
                if (columnData.expand) {
                    if (totalNaturalExpandSize == 0) {
                        height = (alloc.height - totalUnexpandedSize) / expandedWidgetCount;
                    } else {
                        height = (size[1].naturalHeight * (alloc.height -  totalUnexpandedSize)) / totalNaturalExpandSize;
                    }
                } else {
                    height = size[1].naturalHeight;
                }
                sizeAllocate(Rectangle(0, allocatedHeight, alloc.width, height), size[0]);
                allocatedHeight += height + spacing;
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
        minimumHeight = cast(uint) (_content.length - 1) * spacing;
        naturalHeight = cast(uint) (_content.length - 1) * spacing;

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

            if (minimumWidth < widgetMinimumWidth) {
                minimumWidth = widgetMinimumWidth;
            }
            if (naturalWidth < widgetNaturalWidth) {
                naturalWidth = widgetNaturalWidth;
            }
            minimumHeight += widgetMinimumHeight;
            naturalHeight += widgetNaturalHeight;
        }
    }
}

class ColumnData: ContainerData {
    bool expand = false;
}

ColumnData columnData(Widget widget) {
    if (ColumnData columnData = cast(ColumnData) widget.parentData) {
        return columnData;
    }
    ColumnData columnData = new ColumnData();
    widget.parentData = columnData;
    return columnData;
}
