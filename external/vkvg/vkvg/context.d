module vkvg.context;

version(VkVG):

import std.logger;
import std.string;

import dfenestration.renderers.context;
// import dfenestration.renderers.text.textlayouter;

import vkvg;

class VkVGContext: Context {
    VkvgContext handle;

    this(Surface surface) {
        handle = vkvg_create(surface.handle);
    }

    ~this() {
        vkvg_destroy(handle);
    }

    void dropShadow(float x, float y, float w, float h, float radius, float feather) {
        // FIXME: Vulkan dropshadow
        // warning("void dropShadow(float x, float y, float w, float h, float radius, float feather) not implemented for VkVG.");
        save();
        scope(exit) restore();

        sourceRgb(0, 0, 0);
        rectangle(x - 1, y - 1, w + 2, h + 2);
        fill();
    }

    void flush() {
        vkvg_flush(handle);
    }

    void newPath() {
        vkvg_new_path(handle);
    }

    void closePath() {
        vkvg_close_path(handle);
    }

    void newSubPath() {
        vkvg_new_sub_path(handle);
    }

    void pathExtents(out float x1, out float y1, out float x2, out float y2) {
        vkvg_path_extents(handle, &x1, &y1, &x2, &y2);
    }

    void currentPoint(out float x, out float y) {
        vkvg_get_current_point(handle, &x, &y);
    }

    void lineTo(float x, float y) {
        vkvg_line_to(handle, x, y);
    }

    void relLineTo(float dx, float dy) {
        vkvg_rel_line_to(handle, dx, dy);
    }

    void moveTo(float x, float y) {
        vkvg_move_to(handle, x, y);
    }

    void relMoveTo(float x, float y) {
        vkvg_rel_move_to(handle, x, y);
    }

    void arc(float xc, float yc, float radius, float a1, float a2) {
        vkvg_arc(handle, xc, yc, radius, a1, a2);
    }

    void arcNegative(float xc, float yc, float radius, float a1, float a2) {
        vkvg_arc_negative(handle, xc, yc, radius, a1, a2);
    }

    void curveTo(float x1, float y1, float x2, float y2, float x3, float y3) {
        vkvg_curve_to(handle, x1, y1, x2, y2, x3, y3);
    }

    void relCurveTo(float x1, float y1, float x2, float y2, float x3, float y3) {
        vkvg_rel_curve_to(handle, x1, y1, x2, y2, x3, y3);
    }

    void quadraticTo(float x1, float y1, float x2, float y2) {
        vkvg_quadratic_to(handle, x1, y1, x2, y2);
    }

    void rectangle(float x, float y, float w, float h) {
        vkvg_rectangle(handle, x, y, w, h);
    }

    void stroke() {
        vkvg_stroke(handle);
    }

    void strokePreserve() {
        vkvg_stroke_preserve(handle);
    }

    void fill() {
        vkvg_fill(handle);
    }

    void fillPreserve() {
        vkvg_fill_preserve(handle);
    }

    void paint() {
        vkvg_paint(handle);
    }

    void clear() {
        vkvg_clear(handle);//use vkClearAttachment to speed up clearing surf
    }

    void reclip() {
        vkvg_reset_clip(handle);
    }

    void clip() {
        vkvg_clip(handle);
    }

    void clipPreserve() {
        vkvg_clip_preserve(handle);
    }

    void sourceColor(uint c) {
        vkvg_set_source_color(handle, c);
    }

    void sourceRgba(float r, float g, float b, float a) {
        vkvg_set_source_rgba(handle, r, g, b, a);
    }

    void sourceRgb(float r, float g, float b) {
        vkvg_set_source_rgb(handle, r, g, b);
    }

    void lineWidth(float width) {
        vkvg_set_line_width(handle, width);
    }

    //void lineCap(LineCap cap) {
    //    vkvg_set_line_cap(handle, cap);
    //}
    //
    //void lineJoin(LineJoin join) {
    //    vkvg_set_line_join(handle, join);
    //}
    //
    //void sourceSurface(Surface surf, float x, float y) {
    //    vkvg_set_source_surface(handle, surf.handle, x, y);
    //}
    //
    //void source(Pattern pat) {
    //    vkvg_set_source(handle, pat.handle);
    //}
    //
    //void operator(Operator op) {
    //    vkvg_set_operator(handle, op);
    //}
    //
    //void fillRule(FillRule fr) {
    //    vkvg_set_fill_rule(handle, fr);
    //}

    void dash(float[] dashes, float offset) {
        vkvg_set_dash(handle, dashes.ptr, cast(uint) dashes.length, 0);
    }

    float[] dash(out float offset) {
        uint length;
        float* array;
        vkvg_get_dash(handle, array, &length, &offset);
        return array[0..length];
    }

    float lineWidth() {
        return vkvg_get_line_width(handle);
    }

    //LineCap lineCap() {
    //    return vkvg_get_line_cap(handle);
    //}

    //LineJoin lineJoin() {
    //    return vkvg_get_line_join(handle);
    //}

    //Operator operator() {
    //    return vkvg_get_operator(handle);
    //}

    //FillRule fillRule() {
    //    return vkvg_get_fill_rule(handle);
    //}

    //Pattern* source() {
    //     vkvg_get_source(handle);
    //}

    void save() {
        vkvg_save(handle);
    }

    void restore() {
        reclip();
        vkvg_restore(handle);
    }

    void translate(float dx, float dy) {
        vkvg_translate(handle, dx, dy);
    }

    void scale(float sx, float sy) {
        vkvg_scale(handle, sx, sy);
    }

    void rotate(float radians) {
        vkvg_rotate(handle, radians);
    }

    //void transform(const Matrix* matrix) {
    //    vkvg_transform(handle, matrix);
    //}
    //
    //void matrix(const Matrix* matrix) {
    //    vkvg_set_matrix(handle, matrix);
    //}
    //
    //void matrix(const Matrix* matrix) {
    //    vkvg_get_matrix(handle, matrix);
    //}

    void identityMatrix() {
        vkvg_identity_matrix(handle);
    }

    void selectFontFace(string name) {
        vkvg_select_font_face(handle, name.toStringz);
    }

    void selectFontPath(string path) {
        warning("selectFontPath not implemented for vkvg.Context");
        // vkvg_select_font_path(handle, path.toStringz);
    }

    void fontSize(uint size) {
        vkvg_set_font_size(handle, size);
    }

    //void showGlyph(RenderedGlyph glyph) {
    //    warning("Not implemented");
    //}

    //void textExtents(string text, TextExtents* extents) {
    //    vkvg_text_extents(handle, text.toStringz, extents);
    //}
    //
    //void fontExtents(TextExtents* extents) {
    //    vkvg_font_extents(handle, extents);
    //}
    //
    //Text* textRunCreate(string text) {
    //     vkvg_text_run_create(handle, text.toStringz);
    //}

}
