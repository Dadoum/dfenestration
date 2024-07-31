module dfenestration.widgets.aligner;

import dfenestration.widgets.bin;
import dfenestration.widgets.widget;

class Aligner: Bin {
    struct _ {
        Alignment horizontalAlignment = Alignment.center;
        Alignment verticalAlignment = Alignment.center;
    }
    mixin State!_;

    this() {
        //
    }

    override bool onSizeAllocate() {
        if (!super.onSizeAllocate()) {
            return false;
        }

        Rectangle allocation = allocation();

        uint minimumWidth, naturalWidth, minimumHeight, naturalHeight;
        content.preferredSize(minimumWidth, naturalWidth, minimumHeight, naturalHeight);

        void computeCoordinates(
            uint naturalLength,
            Alignment requestedAlignment,
            uint requestedLength,
            out uint position,
            out uint length) {
            if (requestedLength < naturalLength || requestedAlignment == Alignment.fill) {
                position = 0;
                length = requestedLength;
                return;
            }
            length = naturalLength;
            switch (requestedAlignment) {
                case Alignment.left:
                    position = 0;
                    break;
                case Alignment.center:
                    position = (requestedLength - naturalLength) / 2;
                    break;
                case Alignment.right:
                    position = requestedLength - naturalLength;
                    break;
                default:
                    assert(0);
            }
        }

        uint x, y, width, height;
        computeCoordinates(naturalWidth, horizontalAlignment, allocation.width, x, width);
        computeCoordinates(naturalHeight, verticalAlignment, allocation.height, y, height);

        sizeAllocate(Rectangle(x, y, width, height), _content);
        return true;
    }
}

enum Alignment {
    left,
    center,
    right,
    fill
}
