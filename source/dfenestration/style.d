module dfenestration.style;

import std.algorithm.searching;
import std.format;
import std.logger;

import hairetsu;

struct Style {
    FontFamily _fontFamily;

    FontFaceInfo[string] _faceInfos;
    Font[string] _fonts;

    this(FontFamily fontFamily) {
        this.fontFamily = fontFamily;
    }

    FontFamily fontFamily() => _fontFamily;

    void fontFamily(FontFamily family) {
        _fontFamily = family;

        assert(fontFamily.faces.length > 0, "The selected font family does not contain any face!");

        size_t rangeStart = 0;
        string fontFamilyName = fontFamily.familyName();
        if (fontFamily.faces[0].name.startsWith(fontFamilyName)) {
            rangeStart = fontFamilyName.length + 1;
        }

        foreach (faceInfo; fontFamily.faces) {
            _faceInfos[faceInfo.name[rangeStart..$]] = faceInfo;
        }

        _fonts.clear();
    }

    private Font fontFinder(string knownName, string[] possibleNames)() {
        if (auto font = knownName in _fonts) {
            return *font;
        }

        static foreach (possibleFaceName; possibleNames) {
            if (auto faceInfo = possibleFaceName in _faceInfos) {
                auto font = faceInfo.realize();
                _fonts[knownName] = font;
                return font;
            }
        }

        _fonts[knownName] = null;
        return null;
    }

    alias regularFont = fontFinder!("Regular", ["Regular", "Roman", "Normal", "Book"]);
    alias boldFont = fontFinder!("Bold", ["Bold"]);
    alias italicFont = fontFinder!("Italic", ["Italic"]);
    alias monospaceFont = fontFinder!("Monospace", ["Monospace"]);

    Font getFontVariant(string variantName) {
        if (auto font = variantName in _fonts) {
            return *font;
        }

       if (auto faceInfo = variantName in _faceInfos) {
           auto font = faceInfo.realize();
           _fonts[variantName] = font;
           return font;
       }

        _fonts[variantName] = null;
        return null;
    }
}
