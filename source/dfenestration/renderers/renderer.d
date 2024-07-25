module dfenestration.renderers.renderer;

import std.meta;

import dfenestration.primitives;
import dfenestration.backends.backend;
import dfenestration.renderers.context;

/++
 + A renderer is an object that's initialized to make a Context to draw on.
 +/
abstract class Renderer {
    /// Called when a new window is created.
    abstract void initializeWindow(BackendWindow window);

    /// Called when a window is deleted.
    abstract void cleanup(BackendWindow window);

    /// Called when a window is resized.
    abstract void resize(BackendWindow window, uint width, uint height);

    /++
     + Called when a window needs to be drawn.
     + It should call window's paint function with the context, and doesn't have to make any operation on the surface
     + before calling it.
     + IT HAS TO SUPPORT SCALING, AND ADJUST THE CANVAS SIZE APPROPRIATELY (see NanoVega's BaseRenderer for reference).
     +/
    abstract void draw(BackendWindow window);
}

/++
 + When making a renderer, create an interface implementing BackendCompatibleWith!YourRendererClass, with all the
 + functions your renderer needs for it to work.
 + This will allow the toolkit to recognize that all toolkits that implement your interface are compatible with your
 + renderer class.
 +
 + So don't implement that in a custom backend, instead implement the one that is defined in the renderer module.
 +/
template BackendCompatibleWith(T: Renderer) {
    static if (is(T)) {
        interface BackendCompatibleWith {}
    } else {
        alias BackendCompatibleWith = AliasSeq!();
    }
}
