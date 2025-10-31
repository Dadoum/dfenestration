module dfenestration.renderers.context;

import bindbc.freetype;
import bindbc.hb;

/++
 + Almost replicates Cairo's API.
 +/
interface Context {
    // void flush();

    void newPath();
    void closePath();
    // void newSubPath();

    // void pathExtents(out float x1, out float y1, out float x2, out float y2);
    void currentPoint(out float x, out float y);

    void lineTo(float x, float y);
    void relLineTo(float dx, float dy);

    void moveTo(float x, float y);
    void relMoveTo(float x, float y);

    // void arc(float xc, float yc, float radius, float a1, float a2);
    // void arcNegative(float xc, float yc, float radius, float a1, float a2);

    void curveTo(float x1, float y1, float x2, float y2, float x3, float y3);
    void relCurveTo(float x1, float y1, float x2, float y2, float x3, float y3);

    // void quadraticTo(float x1, float y1, float x2, float y2);
    void rectangle(float x, float y, float w, float h);
    void stroke();
    void strokePreserve();
    void fill();
    void fillPreserve();

    /++
     + Will be called to draw the dropshadow behind the window.
     +/
    void dropShadow(float x, float y, float w, float h, float radius, float feather);

    // void paint();
    // void clear();

    void clip();
    void clipPreserve();

    void sourceRgba(float r, float g, float b, float a);
    void sourceRgb(float r, float g, float b);

    void lineWidth(float width);

    void dash(float[] dashes, float offset);

    void save();
    void restore();

    void translate(float dx, float dy);
    void scale(float sx, float sy);
    void rotate(float radians);
    // void identityMatrix();

    // void showGlyph(RenderedGlyph glyph);
}
