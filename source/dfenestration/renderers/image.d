module dfenestration.renderers.image;

import std.range;

struct Pixbuf {
    enum Format {
        rgbaFFFF,
        rgba8888,
        c8
    }

    struct Pixel(Format format) {
        static if (format == Format.rgbaFFFF) {
            float r;
            float g;
            float b;
            float a;
        } else static if (format == Format.rgba8888) {
            ubyte r;
            ubyte g;
            ubyte b;
            ubyte a;
        } else static if (format == Format.c8) {
            ubyte w;
        } else {
            static assert(false, "Unknown format");
        }
    }

    uint width;
    uint height;

    Format format;
    ubyte[/* width * height * pixelSize(format) */] buffer;

    this(uint width, uint height, Format format) {
        buffer = new ubyte[](width * height * pixelSize(format));
        this.width = width;
        this.height = height;
        this.format = format;
    }

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

    Pixbuf opBinary(string op : "*")(RGBA rgba) {
        Pixbuf image = Pixbuf(width, height, Format.rgbaFFFF);
        RGBA pixel = void;
        foreach (pixelOut, pixelIn; image.pixels().lockstep(pixels)) {
            pixel = RGBA(pixelIn, format) * rgba;
            pixelOut[] = (cast(ubyte*) &pixel)[0..RGBA.sizeof];
        }
        return image;
    }
}

struct RGBA {
    float red;
    float green;
    float blue;
    float alpha;

    pragma(inline, true)
    this(ubyte[] pixel, Pixbuf.Format format) {
        with(Pixbuf.Format) final switch (format) {
            case rgbaFFFF:
                this = *cast(RGBA*) pixel.ptr;
                break;
            case rgba8888:
                red = pixel[0] / cast(float) ubyte.max;
                green = pixel[1] / cast(float) ubyte.max;
                blue = pixel[2] / cast(float) ubyte.max;
                alpha = pixel[3] / cast(float) ubyte.max;
                break;
            case c8:
                red = 1.0;
                green = 1.0;
                blue = 1.0;
                alpha = pixel[0] / cast(float) ubyte.max;
                break;
        }
    }

    pragma(inline, true)
    this(float r, float g, float b, float a) {
        this.red = r;
        this.green = g;
        this.blue = b;
        this.alpha = a;
    }

    RGBA opBinary(string op: "*")(RGBA b) {
        return RGBA(this.red * b.red, this.green * b.green, this.blue * b.blue, this.alpha * b.alpha);
    }
}

size_t pixelSize(Pixbuf.Format format) {
    final switch (format) {
        static foreach (formatIdentifier;  __traits(allMembers, Pixbuf.Format)) {
            static foreach (formatC; [__traits(getMember, Pixbuf.Format, formatIdentifier)]) {
                case formatC:
                    return Pixbuf.Pixel!formatC.sizeof;
            }
        }
    }
}
