module vkvg.c;

version(VkVG):

import dynamicloader;

version (Windows) {
    version (MinGW) {
        enum libvkvg = LibImport("libvkvg.dll");
    } else {
        enum libvkvg = LibImport("vkvg.dll");
    }
} else version (OSX) {
    enum libvkvg = LibImport("libvkvg.dylib");
} else {
    enum libvkvg = LibImport("libvkvg.so");
}

import core.stdc.stdint;
import erupted;

    mixin makeBindings;

    struct vkvg_text_t;
    struct vkvg_context_t;
    struct vkvg_surface_t;
    struct vkvg_device_t;
    struct vkvg_pattern_t;

    enum Matrix identityMatrix = {1,0,0,1,0,0};

    struct Matrix {
        float xx; float yx;
        float xy; float yy;
        float x0; float y0;
    }

@libvkvg extern (C):

// debug {
//     DebugStats vkvg_device_get_stats (vkvg_device_t* dev);
//     DebugStats vkvg_device_reset_stats (vkvg_device_t* dev);
// }

void vkvg_matrix_init_identity (Matrix *matrix);
void vkvg_matrix_init (Matrix *matrix,
float xx, float yx,
float xy, float yy,
float x0, float y0);
void vkvg_matrix_init_translate (Matrix *matrix, float tx, float ty);
void vkvg_matrix_init_scale (Matrix *matrix, float sx, float sy);
void vkvg_matrix_init_rotate (Matrix *matrix, float radians);
void vkvg_matrix_translate (Matrix *matrix, float tx, float ty);
void vkvg_matrix_scale (Matrix *matrix, float sx, float sy);
void vkvg_matrix_rotate (Matrix *matrix, float radians);
void vkvg_matrix_multiply (Matrix *result, const Matrix *a, const Matrix *b);
void vkvg_matrix_transform_distance (const Matrix *matrix, float *dx, float *dy);
void vkvg_matrix_transform_point (const Matrix *matrix, float *x, float *y);
// Status vkvg_matrix_invert (Matrix *matrix);

vkvg_device_t* vkvg_device_create (VkSampleCountFlags samples, bool deferredResolve);
vkvg_device_t* vkvg_device_create_from_vk (VkInstance inst, VkPhysicalDevice phy, VkDevice vkdev, uint32_t qFamIdx, uint32_t qIndex);
vkvg_device_t* vkvg_device_create_from_vk_multisample (VkInstance inst, VkPhysicalDevice phy, VkDevice vkdev, uint32_t qFamIdx, uint32_t qIndex, VkSampleCountFlags samples, bool deferredResolve);
void vkvg_device_destroy (vkvg_device_t* dev);
// Status vkvg_device_status (vkvg_device_t* dev);
vkvg_device_t* vkvg_device_reference (vkvg_device_t* dev);
uint32_t vkvg_device_get_reference_count (vkvg_device_t* dev);
void vkvg_device_set_dpy (vkvg_device_t* dev, int hdpy, int vdpy);
void vkvg_device_get_dpy (vkvg_device_t* dev, int* hdpy, int* vdpy);

vkvg_surface_t* vkvg_surface_create (vkvg_device_t* dev, uint32_t width, uint32_t height);
vkvg_surface_t* vkvg_surface_create_from_image (vkvg_device_t* dev, const char* filePath);
vkvg_surface_t* vkvg_surface_create_for_VkhImage (vkvg_device_t* dev, void* vkhImg);
vkvg_surface_t* vkvg_surface_reference (vkvg_surface_t* surf);
uint32_t vkvg_surface_get_reference_count (vkvg_surface_t* surf);
void vkvg_surface_destroy (vkvg_surface_t* surf);
void vkvg_surface_clear (vkvg_surface_t* surf);
VkImage	vkvg_surface_get_vk_image (vkvg_surface_t* surf);
VkFormat vkvg_surface_get_vk_format (vkvg_surface_t* surf);
uint32_t vkvg_surface_get_width (vkvg_surface_t* surf);
uint32_t vkvg_surface_get_height (vkvg_surface_t* surf);
void vkvg_surface_write_to_png (vkvg_surface_t* surf, const char* path);
void vkvg_surface_write_to_memory (vkvg_surface_t* surf, const ubyte* bitmap);
// void vkvg_multisample_surface_resolve (vkvg_surface_t* surf);
vkvg_context_t* vkvg_create (vkvg_surface_t* surf);
void vkvg_destroy (vkvg_context_t* ctx);
vkvg_context_t* vkvg_reference (vkvg_context_t* ctx);
uint32_t vkvg_get_reference_count (vkvg_context_t* ctx);
void vkvg_flush (vkvg_context_t* ctx);
void vkvg_new_path (vkvg_context_t* ctx);
void vkvg_close_path (vkvg_context_t* ctx);
void vkvg_new_sub_path (vkvg_context_t* ctx);
void vkvg_path_extents (vkvg_context_t* ctx, float *x1, float *y1, float *x2, float *y2);
void vkvg_get_current_point (vkvg_context_t* ctx, float* x, float* y);
void vkvg_line_to (vkvg_context_t* ctx, float x, float y);
void vkvg_rel_line_to (vkvg_context_t* ctx, float dx, float dy);
void vkvg_move_to (vkvg_context_t* ctx, float x, float y);
void vkvg_rel_move_to (vkvg_context_t* ctx, float x, float y);
void vkvg_arc (vkvg_context_t* ctx, float xc, float yc, float radius, float a1, float a2);
void vkvg_arc_negative (vkvg_context_t* ctx, float xc, float yc, float radius, float a1, float a2);
void vkvg_curve_to (vkvg_context_t* ctx, float x1, float y1, float x2, float y2, float x3, float y3);
void vkvg_rel_curve_to (vkvg_context_t* ctx, float x1, float y1, float x2, float y2, float x3, float y3);
void vkvg_quadratic_to (vkvg_context_t* ctx, float x1, float y1, float x2, float y2);
void vkvg_rectangle(vkvg_context_t* ctx, float x, float y, float w, float h);
void vkvg_stroke (vkvg_context_t* ctx);
void vkvg_stroke_preserve (vkvg_context_t* ctx);
void vkvg_fill (vkvg_context_t* ctx);
void vkvg_fill_preserve (vkvg_context_t* ctx);
void vkvg_paint (vkvg_context_t* ctx);
void vkvg_clear (vkvg_context_t* ctx);//use vkClearAttachment to speed up clearing surf
void vkvg_reset_clip (vkvg_context_t* ctx);
void vkvg_clip (vkvg_context_t* ctx);
void vkvg_clip_preserve (vkvg_context_t* ctx);
void vkvg_set_source_color (vkvg_context_t* ctx, uint32_t c);
void vkvg_set_source_rgba (vkvg_context_t* ctx, float r, float g, float b, float a);
void vkvg_set_source_rgb (vkvg_context_t* ctx, float r, float g, float b);
void vkvg_set_line_width (vkvg_context_t* ctx, float width);
// void vkvg_set_line_cap (vkvg_context_t* ctx, LineCap cap);
// void vkvg_set_line_join (vkvg_context_t* ctx, LineJoin join);
void vkvg_set_source_surface (vkvg_context_t* ctx, vkvg_surface_t* surf, float x, float y);
void vkvg_set_source (vkvg_context_t* ctx, vkvg_pattern_t* pat);
// void vkvg_set_operator (vkvg_context_t* ctx, Operator op);
// void vkvg_set_fill_rule (vkvg_context_t* ctx, FillRule fr);
void vkvg_set_dash (vkvg_context_t* ctx, const float* dashes, uint32_t num_dashes, float offset);
void vkvg_get_dash (vkvg_context_t* ctx, const float *dashes, uint32_t* num_dashes, float* offset);
float vkvg_get_line_width (vkvg_context_t* ctx);
// LineCap vkvg_get_line_cap (vkvg_context_t* ctx);
// LineJoin vkvg_get_line_join (vkvg_context_t* ctx);
// Operator vkvg_get_operator (vkvg_context_t* ctx);
// FillRule vkvg_get_fill_rule (vkvg_context_t* ctx);
vkvg_pattern_t* vkvg_get_source (vkvg_context_t* ctx);
void vkvg_save (vkvg_context_t* ctx);
void vkvg_restore (vkvg_context_t* ctx);
void vkvg_translate (vkvg_context_t* ctx, float dx, float dy);
void vkvg_scale (vkvg_context_t* ctx, float sx, float sy);
void vkvg_rotate (vkvg_context_t* ctx, float radians);
void vkvg_transform (vkvg_context_t* ctx, const Matrix* matrix);
void vkvg_set_matrix (vkvg_context_t* ctx, const Matrix* matrix);
void vkvg_get_matrix (vkvg_context_t* ctx, const Matrix* matrix);
void vkvg_identity_matrix (vkvg_context_t* ctx);
void vkvg_select_font_face (vkvg_context_t* ctx, const char* name);
// void vkvg_select_font_path (vkvg_context_t* ctx, const char* path);
void vkvg_set_font_size (vkvg_context_t* ctx, uint32_t size);
void vkvg_show_text (vkvg_context_t* ctx, const char* text);
// void vkvg_text_extents (vkvg_context_t* ctx, const char* text, TextExtents* extents);
// void vkvg_font_extents (vkvg_context_t* ctx, TextExtents* extents);
void vkvg_show_text_run (vkvg_context_t* ctx, vkvg_text_t* textRun);
// void vkvg_set_source_color_name (vkvg_context_t* ctx, const char* color);

vkvg_text_t* vkvg_text_run_create (vkvg_context_t* ctx, const char* text);
void vkvg_text_run_destroy (vkvg_text_t* textRun);
// void vkvg_text_run_get_extents (vkvg_text_t* textRun, TextExtents* extents);

vkvg_pattern_t* vkvg_pattern_reference (vkvg_pattern_t* pat);
uint32_t vkvg_pattern_get_reference_count (vkvg_pattern_t* pat);
vkvg_pattern_t* vkvg_pattern_create_for_surface (vkvg_surface_t* surf);
vkvg_pattern_t* vkvg_pattern_create_linear (float x0, float y0, float x1, float y1);
void vkvg_pattern_edit_linear (vkvg_pattern_t* pat, float x0, float y0, float x1, float y1);
void vkvg_pattern_get_linear_points (vkvg_pattern_t* pat, float* x0, float* y0, float* x1, float* y1);
vkvg_pattern_t* vkvg_pattern_create_radial (float cx0, float cy0, float radius0,
float cx1, float cy1, float radius1);
void vkvg_pattern_edit_radial (vkvg_pattern_t* pat,
float cx0, float cy0, float radius0,
float cx1, float cy1, float radius1);
void vkvg_pattern_destroy (vkvg_pattern_t* pat);
void vkvg_pattern_add_color_stop (vkvg_pattern_t* pat, float offset, float r, float g, float b, float a);
// void vkvg_pattern_set_extend (vkvg_pattern_t* pat, Extend extend);
// void vkvg_pattern_set_filter (vkvg_pattern_t* pat, Filter filter);
// Extend vkvg_pattern_get_extend (vkvg_pattern_t* pat);
// Filter vkvg_pattern_get_filter (vkvg_pattern_t* pat);
// PatternType vkvg_pattern_get_type (vkvg_pattern_t* pat);

void* vkvg_get_device_requirements(VkPhysicalDeviceFeatures *pEnabledFeatures);
void* vkvg_get_required_instance_extensions(const char** pExtensions, uint32_t* pExtCount);
