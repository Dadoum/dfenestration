module dfenestration.taggedunion;

import std.stdio;
import std.meta;

template EnumMembers(E)
if (is(E == enum))
{
    alias EnumMembers = AliasSeq!();
    static foreach (M; __traits(allMembers, E))
        EnumMembers = AliasSeq!(EnumMembers, __traits(getMember, E, M));
}

/++
 + A simple tagged union type.
 + Everything is inlined as an attempt to make this structure zero-cost.
 +/
mixin template TaggedUnion(T) {
    import std.conv;
    import std.format;

    alias Tag = T;

    union Value {
        static foreach (field; EnumMembers!Tag) {
            static if (__traits(getAttributes, field).length) {
                mixin(__traits(getAttributes, field)[0].stringof ~ " " ~ field.stringof ~ ";");
            }
        }
    }

    Tag tag;
    Value value;

    @disable this();
    pragma(inline, true)
    this(typeof(this.tupleof)) {
        this.tupleof = __traits(parameters);
    }

    pragma(inline, true)
    string valueString() {
        label: final switch (tag) {
            static foreach (field; EnumMembers!Tag) {
                static if (__traits(getAttributes, field).length > 0) {
                    case field:
                        return "(" ~ mixin("value." ~ field.stringof).to!string() ~ ")";
                } else {
                    case field:
                        return "";
                }
            }
        }
    }

    pragma(inline, true)
    string toString() {
        auto ret = tag.to!string() ~ valueString();
        return ret;
    }

    pragma(inline, true)
    bool opEquals(typeof(this) b) const {
        if (tag != b.tag) {
            return false;
        }
        label: final switch (tag) {
            static foreach (field; EnumMembers!Tag) {
                static if (__traits(getAttributes, field).length > 0) {
                    case field:
                        return mixin("value." ~ field.stringof) == mixin("b.value." ~ field.stringof);
                }
            }
            static foreach (field; EnumMembers!Tag) {
                static if (__traits(getAttributes, field).length == 0) {
                    case field:
                }
            }
                return true;
        }
    }

    static foreach (field; EnumMembers!Tag) {
        static if (__traits(getAttributes, field).length) {
            mixin(
                format!q{
					pragma(inline, true)
					static typeof(this) %1$s(typeof(Value.%1$s) value) {
						Value v = { %1$s: value };
						return typeof(this)(Tag.%1$s, v);
					}

					pragma(inline, true)
					auto %1$s() {
						if (tag == Tag.%1$s) {
							return &value.%1$s;
						}
						return null;
					}
				}(field.stringof)
            );
        } else {
            mixin(
                format!q{
					// pragma(inline, true)
					// bool %1$s() {
					// 	return tag == Tag.%1$s;
					// }

					pragma(inline, true)
					static typeof(this) %1$s() {
						Value v = void;
						return typeof(this)(Tag.%1$s, v);
					}
				}(field.stringof)
            );
        }
    }
}
