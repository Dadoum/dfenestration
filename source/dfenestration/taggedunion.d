module dfenestration.taggedunion;

import std.stdio;
import std.meta;

alias None = AliasSeq!();

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
struct TaggedUnion(Value) {
    import std.conv;
    import std.string;
    import std.format;

    private alias elements = __traits(allMembers, Value);
    private enum elementCount = elements.length;

    mixin(`enum Tag {` ~
        [elements].join(", ") ~
    `}`);

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
            static foreach (element; elements) {
                static if (!is(typeof(__traits(getMember, Value, element)) == None)) {
                    case __traits(getMember, Tag, element):
                        return "(" ~ __traits(child, value, element).to!string() ~ ")";
                }
            }
            static foreach (element; elements) {
                static if (is(typeof(__traits(getMember, Value, element)) == None)) {
                    case __traits(getMember, Tag, element):
                }
            }
                return "";
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
            static foreach (element; elements) {
                static if (!is(typeof(__traits(getMember, Value, element)) == None)) {
                    case __traits(getMember, Tag, element):
                        return __traits(child, value, element) == __traits(child, b.value, element);
                }
            }
            static foreach (element; elements) {
                static if (is(typeof(__traits(getMember, Value, element)) == None)) {
                    case __traits(getMember, Tag, element):
                }
            }
                return true;
        }
    }

    static foreach (element; elements) {
        static if (!is(typeof(__traits(getMember, Value, element)) == None)) {
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
				}(element)
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
				}(element)
            );
        }
    }
}
