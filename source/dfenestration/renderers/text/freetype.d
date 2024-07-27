module dfenestration.renderers.text.freetype;

import std.format;
import std.string;

public import bindbc.freetype;

package void enforce(FT_Error error, string func = __FUNCTION__, string file = __FILE__, int line = __LINE__) {
    if (error) {
        throw new FreeTypeException(format!"%s: %s"(func, FT_Error_String(error).fromStringz()), file, line);
    }
}

class FreeTypeException: Exception {
    this(string msg, string file = __FILE__, int line = __LINE__) @safe pure nothrow {
        super(msg, file, line);
    }
}
