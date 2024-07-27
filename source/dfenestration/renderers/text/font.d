module dfenestration.renderers.text.font;

import dfenestration.renderers.text.freetype;

struct Face {
    @disable this();
    this(this) {
        FT_Reference_Face(face);
    }
    ~this() {
        FT_Done_Face(face);
    }

    FT_Face face;
    ubyte[] underlyingData;

    this(FT_Library library, FT_Open_Args openArguments, ubyte[] underlyingData) {
        // Keep the memory block referenced.
        this.underlyingData = underlyingData;

        this(library, openArguments);
    }

    this(FT_Library library, FT_Open_Args openArguments) {
        FT_Open_Face(library, &openArguments, 0, &face).enforce();
    }
    alias face this;
}

/+
struct Font {
    FT_Face[(FT_STYLE_FLAG_ITALIC | FT_STYLE_FLAG_BOLD) + 1] faces;
    /+ nullable +/ FT_Face regularFace() {
        return faces[0];
    }
    /+ nullable +/ FT_Face italicFace() {
        return faces[FT_STYLE_FLAG_ITALIC];
    }
    /+ nullable +/ FT_Face boldFace() {
        return faces[FT_STYLE_FLAG_BOLD];
    }
    /+ nullable +/ FT_Face italicBoldFace() {
        return faces[FT_STYLE_FLAG_ITALIC | FT_STYLE_FLAG_BOLD];
    }

    ubyte[] underlyingData;

    @disable this();
    this(this) {

    }
    ~this() {

    }

    this(FT_Library library, FT_Open_Args openArguments, ubyte[] underlyingData) {
        FT_Face face;
        FT_Open_Face(library, &openArguments, -1, &face).enforce();
        long faceCount = face.num_faces;
        FT_Done_Face(face);

        uint remainingFacesToFill = faces.length;
        foreach (long faceIndex; 0..faceCount) {
            FT_Open_Face(library, &openArguments, faceIndex, &face).enforce();
            if (faces[face.style_flags] != null) {
                FT_Done_Face(face);
                continue;
            }
            faces[face.style_flags] = face;
            remainingFacesToFill -= 1;
            if (remainingFacesToFill == 0) {
                break;
            }
        }
    }
}
+/
