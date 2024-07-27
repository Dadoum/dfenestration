module nanovegacontext;

import std.logger;

import dfenestration.renderers.context;

import arsd.nanovega;

// version = NVGClipHack;

class NanoVegaContext: Context {
    NVGContext context;

    this(NVGContext context) {
        this.context = context;
        context.newPath();
    }

    // void flush() => context.flush(__traits(parameters));

    void newPath() {
        version (NVGClipHack) nvgClipWorkaround.reset();
        context.newPath(__traits(parameters));
    }
    void closePath() => context.closePath(__traits(parameters));
    // void newSubPath() => context.newSubPath(__traits(parameters));

    // void pathExtents(out float x1, out float y1, out float x2, out float y2) => context.pathExtents(__traits(parameters));
    void currentPoint(out float x, out float y) {
        x = this.x;
        y = this.y;
    }

    float x;
    float y;
    void lineTo(float x, float y) {
        version (NVGClipHack) {
            nvgClipWorkaround = Rect(0, 0, 0, 0);
        }
        this.x = x;
        this.y = y;
        context.lineTo(__traits(parameters));
    }
    void relLineTo(float dx, float dy) {
        version (NVGClipHack) {
            nvgClipWorkaround = Rect(0, 0, 0, 0);
        }
        this.x = x + dx;
        this.y = y + dy;
        context.lineTo(this.x, this.y);
    }

    void moveTo(float x, float y) {
        version (NVGClipHack) {
            nvgClipWorkaround = Rect(0, 0, 0, 0);
        }
        this.x = x;
        this.y = y;
        context.moveTo(__traits(parameters));
    }
    void relMoveTo(float dx, float dy) {
        version (NVGClipHack) {
            nvgClipWorkaround = Rect(0, 0, 0, 0);
        }
        this.x = x + dx;
        this.y = y + dy;
        context.lineTo(this.x, this.y);
    }

    // void arc(float xc, float yc, float radius, float a1, float a2) => context.arc(__traits(parameters));
    // void arcNegative(float xc, float yc, float radius, float a1, float a2) => context.arcNegative(__traits(parameters));

    void curveTo(float x1, float y1, float x2, float y2, float x3, float y3) {
        version (NVGClipHack) {
            nvgClipWorkaround = Rect(0, 0, 0, 0);
        }
        this.x = x3;
        this.y = y3;
        context.bezierTo(__traits(parameters));
    }
    void relCurveTo(float dx1, float dy1, float dx2, float dy2, float dx3, float dy3) {
        version (NVGClipHack) {
            nvgClipWorkaround = Rect(0, 0, 0, 0);
        }
        context.bezierTo(x + dx1, y + dy1, x + dx2, y + dy2, dx3 + x, dy3 + y);
        this.x = x + dx3;
        this.y = y + dy3;
    }

    // void quadraticTo(float x1, float y1, float x2, float y2) => context.quadTo(__traits(parameters));
    version (NVGClipHack) {
        struct Rect {
            float x = -1; float y = -1; float w = -1; float h = -1;
            void reset() {
                this = Rect.init;
            }
            bool isInit() => this != Rect.init;
        }
        Rect nvgClipWorkaround;
    }
    void rectangle(float x, float y, float w, float h) {
        version (NVGClipHack) {
            if (nvgClipWorkaround.isInit()) {
                error("Clip attempted with multiple rectangles: cannot apply the hacky fix.");
                nvgClipWorkaround = Rect(0, 0, 0, 0);
            } else {
                // HACK: works for one rectangle, the performance penalty for more than one is too much.
                nvgClipWorkaround = Rect(x, y, w, h);
            }
        }
        context.rect(__traits(parameters));
    }

    void dropShadow(float x, float y, float w, float h, float radius, float feather) {
        context.save();
        context.reset();
        // context.beginPath();
        context.rect(0, 0, context.width, context.height);
        context.fillPaint = context.boxGradient(x, y, w, h, radius, feather, color, nvgRGBA(256, 0, 0, 0));
        // context.fill();

        context.fill();
        // context.closePath();
        // context.reset();
        context.restore();
    }

    void stroke() {
        context.stroke(__traits(parameters));
        newPath();
    }
    void strokePreserve() {
        context.stroke(__traits(parameters));
    }
    void fill() {
        context.closePath();
        context.fill(__traits(parameters));
        newPath();
    }
    void fillPreserve() {
        context.fill(__traits(parameters));
    }

    // void paint() => context.paint(__traits(parameters));
    // void clear() => context.clear(__traits(parameters));

    void clip() {
        version (NVGClipHack) {
            if (nvgClipWorkaround.isInit() && nvgClipWorkaround != Rect(0, 0, 0, 0)) {
                // info(nvgClipWorkaround);
                context.newPath();
                // nvgClipWorkaround.w += 1;
                // nvgClipWorkaround.y -= 1;
                // nvgClipWorkaround.h -= 1;
                context.rect(
                    nvgClipWorkaround.x + 1,
                    nvgClipWorkaround.y,
                    nvgClipWorkaround.w - 1,
                    nvgClipWorkaround.h - 1
                );
            }
        }
        context.clip(__traits(parameters));
        newPath();
    }
    void clipPreserve() {
        context.clip(__traits(parameters));
    }

    NVGColor color;
    void sourceRgba(float r, float g, float b, float a) {
        color = nvgRGBAf(r, g, b, a);
        context.fillColor = color;
        context.strokeColor = color;
    }
    void sourceRgb(float r, float g, float b) {
        color = nvgRGBf(r, g, b);
        context.fillColor = color;
        context.strokeColor = color;
    }

    void lineWidth(float width) => context.strokeWidth(__traits(parameters));

    void dash(float[] dashes, float offset) {
        context.lineDash = dashes;
        context.lineDashStart = offset;
    }

    void save() {
        version (NVGClipHack) {
            nvgClipWorkaround.reset();
        }
        context.save(__traits(parameters));
    }
    void restore() {
        version (NVGClipHack) {
            nvgClipWorkaround.reset();
        }
        context.restore(__traits(parameters));
    }

    void translate(float dx, float dy) {
        version (NVGClipHack) {
            if (nvgClipWorkaround.isInit()) {
                nvgClipWorkaround.x += dx;
                nvgClipWorkaround.y += dy;
            }
        }
        context.translate(__traits(parameters));
    }
    void scale(float sx, float sy) {
        version (NVGClipHack) {
            if (nvgClipWorkaround.isInit()) {
                nvgClipWorkaround.x *= sx;
                nvgClipWorkaround.y *= sy;
                nvgClipWorkaround.w *= sx;
                nvgClipWorkaround.h *= sy;
            }
        }
        context.scale(__traits(parameters));
    }
    void rotate(float radians) {
        version (NVGClipHack) {
            nvgClipWorkaround.reset();
        }
        context.rotate(__traits(parameters));
    }
    // void identityMatrix();

    void selectFontFace(string name) {
        error("Font config support not implemented, cannot load ", name, " (ignoring)");
    }
    void selectFontPath(string path) {
        auto ret = context.createFont("font", path);
        if (ret == -1) {
            throw new NanoVegaException("Cannot load that font!!");
        }
        context.fontFaceId = ret;
    }
    void fontSize(uint size) {
        context.fontSize = size;
    }
    void showText(string text) {
        // TODO implement that code in a sensible way to ensure that it could be reproduced perfectly in another backend
        float[] bounds = new float[4];
        context.textBounds(0, 0, text, bounds);
        context.text(x + bounds[0], y + bounds[3] - bounds[1], text);
    }
}

class NanoVegaException : Exception
{
    this(string msg, string file = __FILE__, int line = __LINE__)
    @safe pure nothrow
    {
        super(msg, file, line);
    }
} 

