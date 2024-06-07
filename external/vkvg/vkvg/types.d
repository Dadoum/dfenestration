module vkvg.types;

version(VkVG):

import core.stdc.stdint;

enum Status {
    success = 0,
    noMemory,
    invalidRestore,
    noCurrentPoint,
    invalidMatrix,
    invalidStatus,
    nullPointer,
    invalidString,
    invalidPathData,
    readError,
    writeError,
    surfaceFinished,
    surfaceTypeMismatch,
    patternTypeMismatch,
    patternInvalidGradient,
    invalidContent,
    invalidFormat,
    invalidVisual,
    fileNotFound,
    invalidDash,
    invalidRect,
    timeout,
}

enum Direction {
    horizontal	= 0,
    vertical	= 1
}

enum Format {
    argb32,
    rgb24,
    a8,
    a1
}

enum Extend {
    none,
    repeat,
    reflect,
    pad
}


enum Filter {
    fast,
    good,
    best,
    nearest,
    bilinear,
    gaussian,
}


enum PatternType {
    solid,
    surface,
    linear,
    radial,
    mesh,
    rasterSource,
}


enum LineCap {
    butt,
    round,
    square
}

enum LineJoin {
    miter,
    round,
    bevel
}


enum FillRule {
    evenOdd,
    nonZero
}

struct Color {
    float r;
    float g;
    float b;
    float a;
}

enum Operator {
    clear,
    source,
    over,
    difference,
    max,
}

struct FontExtents {
    float ascent;
    float descent;
    float height;
    float maxXAdvance;
    float maxYAdvance;
}

struct TextExtents {
    float xBearing;
    float yBearing;
    float width;
    float height;
    float xAdvance;
    float yAdvance;
}

debug {
    struct DebugStats {
        uint32_t	sizePoints;
        uint32_t	sizePathes;
        uint32_t	sizeVertices;
        uint32_t	sizeIndices;
        uint32_t	sizeVBO;
        uint32_t	sizeIBO;
    }
}
