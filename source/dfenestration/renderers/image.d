module dfenestration.renderers.image;

import std.range;

struct Image {
    enum Format {
        rgba8888
    }

    struct Pixel(Format format) {
        static if (format == Format.rgba8888) {
            ubyte r;
            ubyte g;
            ubyte b;
            ubyte a;
        } else {
            static assert(false, "Unknown format");
        }
    }

    uint width;
    uint height;

    Format format;
    ubyte[/* width * height * pixelSize(format) */] buffer;

    pragma(inline, true)
    auto pixels() {
        return buffer.chunks(pixelSize(format));
    }

    pragma(inline, true)
    auto lines() {
        return pixels().chunks(width);
    }

    // auto columns() {
    //     return lines().transposed();
    // }
}

struct RGBAPixel {
    ushort red;
    ushort green;
    ushort blue;
    ushort alpha;
}

size_t pixelSize(Image.Format format) {
    final switch (format) {
        static foreach (formatIdentifier;  __traits(allMembers, Image.Format)) {
            static foreach (formatC; [__traits(getMember, Image.Format, formatIdentifier)]) {
                case formatC:
                    return Image.Pixel!formatC.sizeof;
            }
        }
    }
}
