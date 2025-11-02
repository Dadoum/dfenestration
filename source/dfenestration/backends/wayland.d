module dfenestration.backends.wayland;

version (Wayland):
    import core.sys.posix.unistd;
    import core.sys.posix.sys.mman;

    import std.algorithm.mutation;
    import std.algorithm.searching;
    import std.conv;
    import std.datetime;
    import std.exception;
    import std.format;
    import std.logger;
    import std.math.rounding;
    import std.meta;
    import std.process;
    import std.typecons;

    import libasync;

    import wayland.client;
    import wayland.cursor;
    import wayland.egl;
    import wayland.native.util;
    import wayland.util;

    import derelict.util.exception;

    import cursorshape;
    import fractionalscale;
    import kdedecoration;
    import viewporter;
    import xdgactivation;
    import xdgdecoration;
    import xdgshell;
    import xdgtoplevelicon;

    import dfenestration.primitives;
    import dfenestration.taggedunion;

    import dfenestration.backends.backend;
    import dfenestration.types;
    import dfenestration.renderers.image;
    import dfenestration.renderers.nanovega.glrenderer;
    import dfenestration.renderers.vkvg.renderer;
    import dfenestration.renderers.context;
    import dfenestration.renderers.renderer;
    import dfenestration.widgets.window;

    final class WaylandBackend: Backend, VkVGRendererCompatible, NanoVegaGLRendererCompatible {
        alias RequiredProtocols =
            AliasSeq!(
                WlCompositor,
                WlOutput,
                WlSeat,
                WlShm,
                WlSubcompositor,
                XdgWmBase
            );
        alias SupportedProtocols = AliasSeq!(RequiredProtocols,
            OrgKdeKwinServerDecorationManager,
            WpCursorShapeManagerV1,
            WpFractionalScaleManagerV1,
            WpViewporter,
            XdgActivationV1,
            XdgToplevelIconManagerV1,
            ZxdgDecorationManagerV1
        );

        WlDisplay display;
        WlRegistry registry;

        Renderer renderer;

        template wlObject(T) {
            T wlObject;
        }

        alias compositor = wlObject!WlCompositor;
        alias output = wlObject!WlOutput;
        alias seat = wlObject!WlSeat;
        alias shm = wlObject!WlShm;
        alias subcompositor = wlObject!WlSubcompositor;
        alias viewporter = wlObject!WpViewporter;
        alias windowManager = wlObject!XdgWmBase;

        alias activation = wlObject!XdgActivationV1;
        // Usually not into distro specific stuff, but KDE's implementation is better so let give them what they deserve.
        alias kdeDecorationManager = wlObject!OrgKdeKwinServerDecorationManager;
        alias xdgDecorationManager = wlObject!ZxdgDecorationManagerV1;

        alias fractionalScaleManager = wlObject!WpFractionalScaleManagerV1;
        alias toplevelIconManager = wlObject!XdgToplevelIconManagerV1;

        WpCursorShapeDeviceV1 pointerShape;

        /+ nullable +/ WlPointer pointer;
        /+ nullable +/ WlKeyboard keyboard;
        /+ nullable +/ WlTouch touch;

        union _CursorShapeBackend {
            WpCursorShapeManagerV1 cursorShapeManager;
            None cursorThemeManager;
            None none;
        }
        alias CursorShapeBackend = TaggedUnion!_CursorShapeBackend;
        CursorShapeBackend cursorShapeBackend;

        WaylandWindow currentWindow = null;
        uint currentSerial = 0;
        uint enterSerial = 0;

        this() {
            super();
            display = WlDisplay.connect();
            if (display is null) {
                throw new WaylandException("Cannot create display!");
            }

            registry = display.getRegistry();
            registry.onGlobal = (WlRegistry reg, uint id, string iface, uint ver) {
                // trace(iface, " is available.");
                static foreach (WlInterface; SupportedProtocols) {
                    if (iface == WlInterface.iface.name && ver >= WlInterface.ver) {
                        wlObject!WlInterface = cast(WlInterface) reg.bind(id, WlInterface.iface, WlInterface.ver);
                        return;
                    }
                }
            };
            registry.onGlobalRemove = null; // (WlRegistry, uint) {};

            display.dispatch();

            // We don't want to register anything anymore.
            registry.onGlobal = null;

            static foreach (RequiredProtocol; RequiredProtocols) {
                if (wlObject!RequiredProtocol is null) {
                    throw new WaylandException(RequiredProtocol.stringof ~ " is not available on the system!!");
                }
            }

            windowManager.onPing = (wmBase, serial) {
                wmBase.pong(serial);
            };

            renderer = this.buildRenderer();

            if (auto cursorShapeManager = wlObject!WpCursorShapeManagerV1) {
                cursorShapeBackend = CursorShapeBackend.cursorShapeManager(cursorShapeManager);
            } else {
                try {
                    wlCursorDynLib.load();
                    if (auto shm = wlObject!WlShm) {
                        warning("Cannot use cursor-shape on this Wayland compositor. Coping with that garbage compositor.");
                        cursorShapeBackend = CursorShapeBackend.cursorThemeManager;
                    } else {
                        warning("Cannot use neither cursor-shape nor wl-shm on this Wayland compositor. Guessing no cursor is desired.");
                        cursorShapeBackend = CursorShapeBackend.none;
                    }
                } catch (SharedLibLoadException) {
                    warning("Cannot use cursor-shape on this Wayland compositor nor load libwayland-cursor. Cursor is going to be ugly!");
                    cursorShapeBackend = CursorShapeBackend.none;
                }
            }

            seat.onCapabilities((seat, capabilities) {
                alias Capabilities = WlSeat.Capability;

                if (capabilities & Capabilities.pointer) {
                    if (!pointer) {
                        pointer = seat.getPointer();

                        if (auto cursorShapeManager = cursorShapeBackend.cursorShapeManager) {
                            pointerShape = cursorShapeManager.getPointer(pointer);
                        }

                        pointer.onEnter = (pointer, serial, surface, x, y) {
                            currentSerial = serial;
                            enterSerial = serial;
                            currentWindow = cast(WaylandWindow) surface.userData();
                            currentWindow.onHoverStart(Point(cast(int) x, cast(int) y));
                        };

                        pointer.onLeave = (pointer, serial, surface) {
                            currentSerial = serial;
                            auto win = cast(WaylandWindow) surface.userData();
                            assert(win == currentWindow, "Left a surface that wasn't hovered.");
                            currentWindow = null;
                            win.onHoverEnd();
                        };

                        pointer.onMotion = (pointer, time, x, y) {
                            currentWindow.onHover(Point(cast(int) x, cast(int) y));
                        };

                        pointer.onButton = (pointer, serial, time, button, state) {
                            currentSerial = serial;
                            MouseButton mouseButton = void;
                            switch (cast(WaylandMouseButton) button) {
                                case WaylandMouseButton.left:
                                    mouseButton = MouseButton.left;
                                    break;
                                case WaylandMouseButton.right:
                                    mouseButton = MouseButton.right;
                                    break;
                                case WaylandMouseButton.middle:
                                    mouseButton = MouseButton.middle;
                                    break;
                                case WaylandMouseButton.forward:
                                    mouseButton = MouseButton.forward;
                                    break;
                                case WaylandMouseButton.back:
                                    mouseButton = MouseButton.back;
                                    break;
                                    default:
                                    mouseButton = MouseButton.unknown;
                                    break;
                            }

                            final switch (state) with (WlPointer.ButtonState) {
                                case pressed:
                                    currentWindow.onClickStart(mouseButton);
                                    break;
                                case released:
                                    currentWindow.onClickEnd(mouseButton);
                                    break;
                            }
                        };
                    }
                } else {
                    if (pointer) {
                        if (pointerShape) {
                            pointerShape.destroy();
                            pointerShape = null;
                        }

                        pointer.destroy();
                        pointer = null;
                    }
                }

                if (capabilities & Capabilities.keyboard) {
                    if (!keyboard) {
                        keyboard = seat.getKeyboard();
                    }
                } else {
                    if (keyboard) {
                        keyboard.destroy();
                        keyboard = null;
                    }
                }

                if (capabilities & Capabilities.touch) {
                    if (!touch) {
                        touch = seat.getTouch();

                        touch.onUp = (touch, serial, time, id) {
                            currentSerial = serial;
                            touchStatus = TouchStatus.end;
                        };

                        touch.onDown = (touch, serial, time, surface, id, x, y) {
                            currentSerial = serial;
                            touchWindow = cast(WaylandWindow) surface.userData();
                            touchStatus = TouchStatus.start;
                            touchLocation = Point(cast(int) x, cast(int) y);
                        };

                        touch.onMotion = (touch, time, id, x, y) {
                            touchStatus = TouchStatus.move;
                            touchLocation = Point(cast(int) x, cast(int) y);
                        };

                        touch.onFrame = (touch) {
                            enforce(touchWindow !is null);
                            final switch (touchStatus) with (TouchStatus) {
                                case start:
                                    touchWindow.onTouchStart(touchLocation);
                                    break;
                                case move:
                                    touchWindow.onTouchMove(touchLocation);
                                    break;
                                case end:
                                    touchWindow.onTouchEnd(touchLocation);
                                    break;
                            }
                        };
                    }
                } else {
                    if (touch) {
                        touch.destroy();
                        touch = null;
                    }
                }
            });

            AsyncEvent event = new AsyncEvent(super._eventLoop, display.getFd());
            bool reading = false;
            event.run((code) {
                if (display.prepareRead() != 0) {
                    display.dispatchPending();
                    return;
                }
                display.flush();

                if (display.readEvents() != 0) {
                    display.cancelRead();
                    return;
                }

                display.dispatchPending();
            });
        }

        enum TouchStatus { start, move, end }
        WaylandWindow touchWindow;
        Point touchLocation;
        TouchStatus touchStatus;

        ~this() {
            static foreach (protocol; SupportedProtocols) {
                if (wlObject!protocol) wlObject!protocol.destroy();
            }

            display.disconnect();
            display = null;
        }

        override WaylandWindow createBackendWindow(Window w) {
            return new WaylandWindow(this, w);
        }

        version (NanoVega) {
            import dfenestration.renderers.egl;

            EGLDisplay eglDisplay;

            EGLConfig eglConfig;
            EGLContext eglContext;

            void loadGL() {
                loadEGLLibrary();
                loadBasicEGLSymbols();
                eglDisplay = enforce(eglGetPlatformDisplay(
                    EGL_PLATFORM_WAYLAND_EXT,
                    cast(void*) display.proxy,
                    null
                ));
                initializeEGLForDisplay(eglDisplay, /+ out +/ eglConfig, /+ out +/ eglContext);
            }

            bool loadGLLibrary() {
                try {
                    wlEglDynLib.load();
                    return true;
                } catch (SharedLibLoadException e) {
                    return false;
                }
            }
        }

        version (VkVG) {
            public import erupted;

            /++
             + VkExtensions required for backend.
             +/
            string[] requiredExtensions() {
                return ["VK_KHR_wayland_surface"];
            }

            void loadInstanceFuncs(VkInstance instance) {
                return loadInstanceLevelFunctionsExt(instance);
            }

            bool isDeviceSuitable(VkPhysicalDevice device, uint queueFamilyIndex) {
                return cast(bool) vkGetPhysicalDeviceWaylandPresentationSupportKHR(device, queueFamilyIndex, display.native());
            }
        }
    }

    version (VkVG) {
        import erupted.platform_extensions;
        import wayland.native.client;

        alias wl_surface = wl_proxy;

        mixin Platform_Extensions!USE_PLATFORM_WAYLAND_KHR vulkanWayland;
    }

    enum WaylandMouseButton: uint {
        left = 0x110,
        right = 0x111,
        middle = 0x112,
        side = 0x113,
        extra = 0x114,
        forward = 0x115,
        back = 0x116,
        task = 0x117,
    }

    final class WaylandWindow: BackendWindow, NanoVegaGLWindow, VkVGWindow {
        WaylandBackend backend;
        Renderer renderer;
        Window window;

        WlSurface surface;
        XdgSurface xdgSurface;

        union _XdgWindow {
            None none;
            XdgToplevel toplevel;
            XdgPopup popup;
        }
        alias XdgWindow = TaggedUnion!_XdgWindow;
        XdgWindow xdgWindow = XdgWindow.none;

        union _WaylandDecoration {
            None none;
            OrgKdeKwinServerDecoration kde;
            ZxdgToplevelDecorationV1 xdg;
        }
        alias WaylandDecoration = TaggedUnion!_WaylandDecoration;

        WaylandDecoration decoration = WaylandDecoration.none;
        WpFractionalScaleV1 fractionalScale;
        WpViewport viewport;
        XdgToplevelIconV1 toplevelIcon;

        int toplevelIconMemoryFd = -1;
        WlShmPool toplevelIconMemoryPool = null;
        ubyte[] toplevelIconMap = null;
        WlBuffer toplevelIconBuffer = null;

        WaylandCursorThemeManager cursorThemeManager = void;

        this(WaylandBackend backend, Window window) {
            this.backend = backend;
            this.window = window;
            this.renderer = backend.renderer;

            if (backend.cursorShapeBackend == WaylandBackend.CursorShapeBackend.cursorThemeManager) {
                cursorThemeManager = WaylandCursorThemeManager(backend);
                resetCursorThemeManager();
            }

            if (backend.toplevelIconManager) {
                toplevelIconMemoryFd = createSharedMemoryFd!"toplevel-icon"();
                if (toplevelIconMemoryFd < 0) {
                    warning("Cannot create shared memory to store the window icon.");
                }
            } else {
                warning("Cannot set icons.");
            }
        }

        final void resetCursorThemeManager() {
            if (backend.cursorShapeBackend != WaylandBackend.CursorShapeBackend.cursorThemeManager) {
                return;
            }

            // TODO use dbus to get cursor scale and theme.
            string xCursorTheme = environment.get("XCURSOR_THEME", null);
            int xCursorScale = to!int(environment.get("XCURSOR_SIZE", "-1"));

            cursorThemeManager.setTheme(
                WlCursorTheme.load(
                    xCursorTheme,
                    xCursorScale > 0 ? xCursorScale : cast(uint) (24 * scaling),
                    backend.wlObject!WlShm
                )
            );
            invalidate();
        }

        ~this() {
            if (shown) {
                hide();
            }
        }

        void makeSurface() {
            trace("Wayland surface is being made.");
            scope(success) trace("Wayland surface has successfully been made!");
            surface = backend.compositor.createSurface();
            surface.userData = cast(void*) this;

            xdgSurface = backend.windowManager.getXdgSurface(surface);
            xdgSurface.onConfigure = &onSurfaceConfigure;

            if (_role == Role.popup && false) {
                // auto popup = xdgSurface.getPopup(_parent.xdgSurface, XdgPositioner);
                // popup.onClose = (p) => onClose();
                // xdgWindow = XdgWindow.popup(popup);
            } else {
                auto toplevel = xdgSurface.getToplevel();
                toplevel.onClose = &onToplevelClose;
                xdgWindow = XdgWindow.toplevel(toplevel);
            }

            if (auto kdeDecorationManager = backend.kdeDecorationManager) {
                trace("Decorations supported through KDE");
                auto kdeDecoration = kdeDecorationManager.create(surface);
                kdeDecoration.onMode = (decorationManager, mode) {
                    decorated = mode == OrgKdeKwinServerDecoration.Mode.server;
                    window.onResize(size);
                };

                // kdeDecoration.requestMode(OrgKdeKwinServerDecoration.Mode.none);
                decoration = WaylandDecoration.kde(kdeDecoration);
            } else if (auto xdgDecorationManager = backend.xdgDecorationManager) {
                trace("Decorations supported through XDG");
                if (auto toplevel = xdgWindow.toplevel) {
                    auto xdgDecoration = xdgDecorationManager.getToplevelDecoration(*toplevel);
                    xdgDecoration.onConfigure = (decorationManager, mode) {
                        decorated = mode == ZxdgToplevelDecorationV1.Mode.serverSide;
                        window.onResize(size);
                    };

                    // xdgDecoration.setMode(ZxdgToplevelDecorationV1.Mode.clientSide);
                    decoration = WaylandDecoration.xdg(xdgDecoration);
                }
            } else {
                warning("Cannot use system decorations.");
            }

            if (auto viewporter = backend.viewporter) {
                viewport = viewporter.getViewport(surface);
            }

            if (auto manager = backend.fractionalScaleManager) {
                fractionalScale = manager.getFractionalScale(surface);
                fractionalScale.onPreferredScale = (_, s) {
                    scaling = s / 120.;
                    reconfigure();
                };
            } else {
                warning("Cannot fractional scale the window.");
            }

            backend.display.roundtrip();

            reconfigure();

            if (auto toplevel = xdgWindow.toplevel) {
                toplevel.onConfigure = &onToplevelConfigure;
            } // else if (auto popup = xdgWindow.popup) {
            //     // popup.onConfigure = (pop)
            // }
            configureMaximized();

            renderer.initializeWindow(this);
            renderer.draw(this);
        }

        void reconfigure() {
            configureMaximized();
            configureScaling();
            configureDecorated();
            configureMinimumSize();
            configureMaximumSize();
            configureResizable();
            configurePosition();
            configureParent();
            configureSize();
            configureTitle();
            configureIcon();
            surface.commit();
        }

        void onSurfaceConfigure(XdgSurface s, uint serial) {
            s.ackConfigure(serial);
        }

        void onToplevelClose(XdgToplevel tl) {
            window.onCloseRequest();
        }

        Size userSizeFromPixelSize(Size sz) {
            if (sz == Size.zero) {
                return Size.zero;
            }

            if (useEmulatedResizeBorders) {
                sz.width -= resizeMarginSize;
                sz.height -= resizeMarginSize;
            }

            return sz;
        }

        void onToplevelConfigure(XdgToplevel tl, int width, int height, wl_array* statesC) {
            assert(shown, "Window is not shown but it got configured.");
            scope newSize = Size(cast(uint) width, cast(uint) height);

            if (newSize != size) {
                size = newSize;
            }

            scope states = (cast(XdgToplevel.State*) statesC.data)[0..statesC.size / XdgToplevel.State.sizeof];

            bool isMaximized = false;
            bool isActivated = false; // which we'll treat as isFocused as focus should treated separately for widgets

            foreach (state; states) {
                switch (state) {
                    case XdgToplevel.State.maximized:
                        isMaximized = true;
                        break;
                    case XdgToplevel.State.activated:
                        isActivated = true;
                        break;
                    default:
                        break;
                }
            }

            if (isMaximized != maximized) {
                maximized = isMaximized;
            }

            if (isActivated != _focused) {
                _focused = isActivated;
                onFocusedChange(isActivated);
            }
        }

        pragma(inline, true)
        bool useEmulatedResizeBorders() {
            return /+ resizable && +/ !decorated;
        }

        void paint(Context context) {
            const scaling = scaling();

            context.save();
            scope(exit) context.restore();

            context.scale(scaling, scaling);

            if (useEmulatedResizeBorders) {
                context.sourceRgba(0, 0, 0, .15);
                context.dropShadow(resizeMarginSize, resizeMarginSize, size.width, size.height, 0, resizeMarginSize);
                context.translate(resizeMarginSize, resizeMarginSize);
            }

            context.rectangle(0, 0, size.tupleof);
            context.clip();

            window.paint(context);
        }

        bool dirty = false;
        void invalidate() {
            if (dirty || !surface) {
                return;
            }

            dirty = true;

            backend.runInMainThread({
                renderer.draw(this);
                surface.commit();
                dirty = false;
            });
        }

        union _WaylandMousePos {
            None outsideWindow;
            Point insideWindow;
            ResizeEdge resizeEdge;
        }
        alias WaylandMousePos = TaggedUnion!_WaylandMousePos;
        WaylandMousePos mousePos = WaylandMousePos.outsideWindow;
        Role _role;

        void role(Role role) {
            _role = role;
            if (shown) {
                hide();
                show();
            }
        }

        void onHoverStart(Point location) {
            // HACK:
            // Dragging a window sends hover end. Dropping it send hover start without sending a corresponding hover.
            // As such, we need to remember of the last hover location, and to do that we will just change the tag of
            // the tagged union structure, and thus when it will set back as inside the window, without resetting the
            // content of the structure.
            onHover(location);
        }

        void onHoverEnd() {
            if (auto mouseLocation = mousePos.insideWindow()) {
                window.onHoverEnd(*mouseLocation);
            }
        }

        ResizeEdge resizeEdge(Point location) {
            auto sz = _userSize;
            const edgeSize = 2 * resizeMarginSize;

            const leftEdge = location.x < edgeSize;
            const topEdge = location.y < edgeSize;
            if (topEdge && leftEdge) {
                cursor = CursorType.nwResize;
                return ResizeEdge.topLeft;
            }
            const rightEdge = location.x > sz.width - edgeSize;
            if (topEdge && rightEdge) {
                cursor = CursorType.neResize;
                return ResizeEdge.topRight;
            }
            const bottomEdge = location.y > sz.height - edgeSize;
            if (bottomEdge && leftEdge) {
                return ResizeEdge.bottomLeft;
            }
            if (bottomEdge && rightEdge) {
                return ResizeEdge.bottomRight;
            }

            if (topEdge) {
                return ResizeEdge.top;
            }

            if (leftEdge) {
                return ResizeEdge.left;
            }

            if (rightEdge) {
                return ResizeEdge.right;
            }

            if (bottomEdge) {
                return ResizeEdge.bottom;
            }

            assert(false, "Impossible edge touched.");
        }

        void onHover(Point location) {
            if (useEmulatedResizeBorders) {
                auto sz = _userSize;
                if (resizable && !Rectangle(resizeMarginSize, resizeMarginSize, sz.tupleof).contains(location)) {
                    if (auto mouseLocation = mousePos.insideWindow()) {
                        window.onHoverEnd(*mouseLocation);
                    }

                    auto resizeEdge = resizeEdge(location);
                    mousePos = WaylandMousePos.resizeEdge(resizeEdge);

                    final switch (resizeEdge) {
                        case ResizeEdge.topLeft:
                            cursor = CursorType.nwResize;
                            break;
                        case ResizeEdge.topRight:
                            cursor = CursorType.neResize;
                            break;
                        case ResizeEdge.bottomLeft:
                            cursor = CursorType.swResize;
                            break;
                        case ResizeEdge.bottomRight:
                            cursor = CursorType.seResize;
                            break;
                        case ResizeEdge.top:
                            cursor = CursorType.nResize;
                            break;
                        case ResizeEdge.left:
                            cursor = CursorType.wResize;
                            break;
                        case ResizeEdge.right:
                            cursor = CursorType.eResize;
                            break;
                        case ResizeEdge.bottom:
                            cursor = CursorType.sResize;
                            break;
                    }
                    return;
                }

                location.x -= resizeMarginSize;
                location.y -= resizeMarginSize;
            }

            if (mousePos.tag != WaylandMousePos.Tag.insideWindow) {
                window.onHoverStart(location);
            }

            mousePos = WaylandMousePos.insideWindow(location);
            window.onHover(location);
        }

        void onTouchStart(Point location) {
            if (useEmulatedResizeBorders) {
                auto sz = size;
                if (!Rectangle(resizeMarginSize, resizeMarginSize, sz.tupleof).contains(location)) {
                    window.resizeDrag(resizeEdge(location));
                    return;
                }
                location.x -= resizeMarginSize;
                location.y -= resizeMarginSize;
            }

            window.onTouchStart(location);
        }

        void onTouchMove(Point location) {
            if (useEmulatedResizeBorders) {
                auto sz = _logicalSize;
                if (!Rectangle(resizeMarginSize, resizeMarginSize, sz.tupleof).contains(location)) {
                    return;
                }
                location.x -= resizeMarginSize;
                location.y -= resizeMarginSize;
            }

            window.onTouchMove(location);
        }

        void onTouchEnd(Point location) {
            if (useEmulatedResizeBorders) {
                auto sz = _logicalSize;
                if (!Rectangle(resizeMarginSize, resizeMarginSize, sz.tupleof).contains(location)) {
                    return;
                }
                location.x -= resizeMarginSize;
                location.y -= resizeMarginSize;
            }

            window.onTouchEnd(location);
        }

        void onClickStart(MouseButton button) {
            if (auto mouseLocation = mousePos.insideWindow) {
                window.onClickStart(*mouseLocation, button);
                return;
            }

            if (auto resizeEdge = mousePos.resizeEdge) {
                window.resizeDrag(*resizeEdge);
                return;
            }

            enforce(false, "The click position is outside the window??");
        }

        void onClickEnd(MouseButton button) {
            if (auto mouseLocation = mousePos.insideWindow) {
                window.onClickEnd(*mouseLocation, button);
            }
        }

        string _title;
        string title() {
            return _title;
        }
        void title(string value) {
            _title = value;
            configureTitle();
            window.onTitleChange(value);
        }
        void configureTitle() {
            if (auto toplevel = xdgWindow.toplevel) {
                toplevel.setTitle(_title);
            }
        }

        void cursor(CursorType type) {
            if (backend.pointerShape) {
                WpCursorShapeDeviceV1.Shape cursorShape;
                with (CursorType) switch (type) {
                    default:
                    case default_:
                        cursorShape = WpCursorShapeDeviceV1.Shape.default_;
                        break;
                    case contextMenu:
                        cursorShape = WpCursorShapeDeviceV1.Shape.contextMenu;
                        break;
                    case help:
                        cursorShape = WpCursorShapeDeviceV1.Shape.help;
                        break;
                    case pointer:
                        cursorShape = WpCursorShapeDeviceV1.Shape.pointer;
                        break;
                    case progress:
                        cursorShape = WpCursorShapeDeviceV1.Shape.progress;
                        break;
                    case wait:
                        cursorShape = WpCursorShapeDeviceV1.Shape.wait;
                        break;
                    case cell:
                        cursorShape = WpCursorShapeDeviceV1.Shape.cell;
                        break;
                    case crosshair:
                        cursorShape = WpCursorShapeDeviceV1.Shape.crosshair;
                        break;
                    case text:
                        cursorShape = WpCursorShapeDeviceV1.Shape.text;
                        break;
                    case verticalText:
                        cursorShape = WpCursorShapeDeviceV1.Shape.verticalText;
                        break;
                    case alias_:
                        cursorShape = WpCursorShapeDeviceV1.Shape.alias_;
                        break;
                    case copy:
                        cursorShape = WpCursorShapeDeviceV1.Shape.copy;
                        break;
                    case move:
                        cursorShape = WpCursorShapeDeviceV1.Shape.move;
                        break;
                    case noDrop:
                        cursorShape = WpCursorShapeDeviceV1.Shape.noDrop;
                        break;
                    case notAllowed:
                        cursorShape = WpCursorShapeDeviceV1.Shape.notAllowed;
                        break;
                    case grab:
                        cursorShape = WpCursorShapeDeviceV1.Shape.grab;
                        break;
                    case grabbing:
                        cursorShape = WpCursorShapeDeviceV1.Shape.grabbing;
                        break;
                    case eResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.eResize;
                        break;
                    case nResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.nResize;
                        break;
                    case neResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.neResize;
                        break;
                    case nwResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.nwResize;
                        break;
                    case sResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.sResize;
                        break;
                    case seResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.seResize;
                        break;
                    case swResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.swResize;
                        break;
                    case wResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.wResize;
                        break;
                    case ewResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.ewResize;
                        break;
                    case nsResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.nsResize;
                        break;
                    case neswResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.neswResize;
                        break;
                    case nwseResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.nwseResize;
                        break;
                    case colResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.colResize;
                        break;
                    case rowResize:
                        cursorShape = WpCursorShapeDeviceV1.Shape.rowResize;
                        break;
                    case allScroll:
                        cursorShape = WpCursorShapeDeviceV1.Shape.allScroll;
                        break;
                    case zoomIn:
                        cursorShape = WpCursorShapeDeviceV1.Shape.zoomIn;
                        break;
                    case zoomOut:
                        cursorShape = WpCursorShapeDeviceV1.Shape.zoomOut;
                        break;
                }
                backend.pointerShape.setShape(backend.enterSerial, cursorShape);
            } else if (backend.cursorShapeBackend == WaylandBackend.CursorShapeBackend.cursorThemeManager) {
                cursorThemeManager.setCursor(backend.pointer, backend.enterSerial, type);
            }
        }

        Point _position;
        void position(Point value) {
            _position = value;
            configurePosition();
            window.onMove(value);
        }
        Point position() {
            return _position;
        }
        void configurePosition() {
            if (auto popup = xdgWindow.popup) {
                auto position = _position.scale(scaling);
                // positioner.setPosition(position.tupleof);
            }
        }

        Size _userSize;
        Size _logicalSize;
        Size _pixelSize;
        Size size() {
            return _userSize;
        }
        void size(Size value) {
            if (value == Size.zero) return;
            _userSize = value;
            configureSize();
            window.onResize(value);
        }

        void configureSize() {
            if (!xdgSurface) {
                return;
            }

            auto scaling = scaling();
            _logicalSize = _userSize;
            if (useEmulatedResizeBorders) {
                auto trueBorderSize = cast(int) (2 * resizeMarginSize);
                _logicalSize.width += trueBorderSize;
                _logicalSize.height += trueBorderSize;
                _pixelSize = _logicalSize.scale(scaling);
                xdgSurface.setWindowGeometry(
                    resizeMarginSize,
                    resizeMarginSize,
                    _userSize.tupleof,
                );
            } else {
                _pixelSize = _logicalSize.scale(scaling);
                xdgSurface.setWindowGeometry(0, 0, _logicalSize.tupleof);
            }

            if (viewport) {
                viewport.setDestination(_logicalSize.tupleof);
            }

            if (!renderer) {
                return;
            }
            renderer.resize(this, _pixelSize.tupleof);
        }

        Size _minimumSize = Size(20, 20);
        Size minimumSize() {
            if (!resizable) {
                return size;
            }

            return _minimumSize;
        }
        void minimumSize(Size value) {
            assert(value.width > 0 && value.height > 0, "minimumSize should be higher than 0");
            _minimumSize = value;
            configureMinimumSize();
        }
        void configureMinimumSize() {
            if (auto toplevel = xdgWindow.toplevel) {
                if (resizable) {
                    toplevel.setMinSize(_minimumSize.tupleof);
                }
            }
        }

        Size _maximumSize;
        Size maximumSize() {
            if (!resizable) {
                return size;
            }

            return _maximumSize;
        }
        void maximumSize(Size value) {
            assert(value.width >= 0 && value.height >= 0, "maximumSize should be higher or equal to 0");
            _maximumSize = value;
            configureMaximumSize();
        }
        void configureMaximumSize() {
            if (auto toplevel = xdgWindow.toplevel) {
                if (resizable) {
                    toplevel.setMaxSize(_maximumSize.tupleof);
                }
            }
        }

        bool _resizable = true;
        bool resizable() {
            return _resizable;
        }
        void resizable(bool value) {
            _resizable = value;
            configureResizable();
        }
        void configureResizable() {
            if (!_resizable) {
                if (auto toplevel = xdgWindow.toplevel) {
                    auto size = size();
                    toplevel.setMinSize(size.tupleof);
                    toplevel.setMaxSize(size.tupleof);
                }
            }
        }

        bool _decorated = false;
        bool decorated() {
            if (decoration == WaylandDecoration.none) {
                return false;
            }

            return _decorated;
        }
        void decorated(bool value) {
            _decorated = value;
            if (value != _decorated) {
                configureDecorated();
            }
        }
        void configureDecorated() {
            if (auto decorations = decoration.xdg) {
                if (_decorated) {
                    decorations.setMode(ZxdgToplevelDecorationV1.Mode.serverSide);
                } else {
                    decorations.setMode(ZxdgToplevelDecorationV1.Mode.clientSide);
                }
            } else if (auto decorations = decoration.kde) {
                if (_decorated) {
                    decorations.requestMode(OrgKdeKwinServerDecoration.Mode.server);
                } else {
                    decorations.requestMode(OrgKdeKwinServerDecoration.Mode.none);
                }
            }
        }

        Nullable!Pixbuf _image;
        Nullable!Pixbuf icon() {
            return _image;
        }
        void icon(Nullable!Pixbuf value) {
            _image = value;


            if (auto manager = backend.toplevelIconManager) {
                if (toplevelIcon) {
                    toplevelIcon.destroy();
                    toplevelIcon = null;
                }

                if (toplevelIconBuffer) {
                    toplevelIconBuffer.destroy();
                    toplevelIconBuffer = null;
                }

                if (!value.isNull()) {
                    if (toplevelIconMemoryFd >= 0) {
                        auto image = value.get();
                        auto buffer = image.buffer;
                        auto len = buffer.length;

                        if (len != toplevelIconMap.length || !toplevelIconMap) {
                            if (toplevelIconMap != null) {
                                munmap(toplevelIconMap.ptr, toplevelIconMap.length);
                                toplevelIconMap = null;
                            }

                            ftruncate(toplevelIconMemoryFd, len);

                            auto mapResult = mmap(null, len, PROT_READ | PROT_WRITE, MAP_SHARED, toplevelIconMemoryFd, 0);

                            if (mapResult == MAP_FAILED) {
                                warning("Failed to set the icon: image mapping failure");
                                return;
                            }

                            toplevelIconMap = cast(ubyte[]) mapResult[0..len];
                            if (toplevelIconMemoryPool) {
                                toplevelIconMemoryPool.resize(cast(int) len);
                            } else {
                                toplevelIconMemoryPool = backend.shm.createPool(toplevelIconMemoryFd, cast(int) len);
                            }
                        }

                        toplevelIconMap[] = image.buffer;
                        toplevelIconBuffer = toplevelIconMemoryPool.createBuffer(0, image.width, image.height, 0, image.format.toWlShmFormat());
                        toplevelIcon = manager.createIcon();
                        toplevelIcon.addBuffer(toplevelIconBuffer, 1);
                    }
                }
            }

            configureIcon();
        }
        void configureIcon() {
            if (auto manager = backend.toplevelIconManager) {
                if (auto toplevel = xdgWindow.toplevel) {
                    manager.setIcon(*toplevel, toplevelIcon);
                }
            }
        }

        WaylandWindow _parent;
        void parent(BackendWindow window) {
            auto waylandWindow = cast(WaylandWindow) window;
            enforce(waylandWindow !is null, "Tried to reparent a Wayland window to a non-Wayland window.");

            if (isChildWindow(waylandWindow)) {
                errorf("Failed to assign the window %x as a parent of %x: doing so would create a loop.", cast(void*) waylandWindow, cast(void*) this);
                return;
            }

            _parent = waylandWindow;

            configureParent();
            if (shown) {
                hide();
                show();
            }
        }
        /// Checks whether window is a child of this window.
        bool isChildWindow(WaylandWindow window) {
            return !(window._parent is null || (window._parent != this && !isChildWindow(window._parent)));
        }
        void configureParent() {
            if (!_parent) {
                return;
            }

            if (auto toplevel = xdgWindow.toplevel) {
                if (auto parentToplevel = _parent.xdgWindow.toplevel) {
                    toplevel.setParent(*parentToplevel);
                } else {
                    warningf("Tried to set the XdgToplevel %x parent to the currently hidden window/XdgPopup %x", cast(void*) this, cast(void*) _parent);
                }
            }
        }

        bool shown;
        void show() {
            if (shown) {
                return;
            }

            makeSurface();
            shown = true;
        }
        void hide() {
            if (!shown) {
                return;
            }

            if (renderer) {
                renderer.cleanup(this);
            }
            if (!backend || !backend.display) {
                return;
            }
            if (auto toplevel = xdgWindow.toplevel) {
                toplevel.destroy();
            } else if (auto popup = xdgWindow.popup) {
                popup.destroy();
            }
            xdgWindow = XdgWindow.none;

            if (auto kdeDecoration = decoration.kde) {
                kdeDecoration.destroy();
            } else if (auto xdgDecoration = decoration.xdg) {
                xdgDecoration.destroy();
            }
            decoration = decoration.none;
            if (fractionalScale) {
                fractionalScale.destroy();
            }
            xdgSurface.destroy();
            // if (subsurface) {
            //     subsurface.destroy();
            // }
            surface.destroy();
            shown = false;
        }

        void present() {
            if (!backend.activation) {
                warning("Cannot present window: the Wayland compositor does not support xdg-activation.");
                return;
            }

            auto activationToken = backend.activation.getActivationToken();
            activationToken.setSerial(backend.currentSerial, backend.seat);
            activationToken.setSurface(surface);
            activationToken.onDone = (XdgActivationTokenV1 activationToken, string token) => backend.activation.activate(token, surface);
            activationToken.commit();
        }
        bool _focused;
        bool focused() {
            return _focused;
        }
        void onFocusedChange(bool val) {
            window.onFocusedChange(val);
        }

        void minimize() {
            if (auto toplevel = xdgWindow.toplevel) {
                toplevel.setMinimized();
            }
        }

        bool _maximized = false;
        bool maximized() {
            return _maximized;
        }
        void maximized(bool value) {
            auto orig = _maximized;
            _maximized = value;
            configureMaximized();
            if (value != orig) {
                window.onMaximizeChange();
            }
        }
        void configureMaximized() {
            if (auto toplevel = xdgWindow.toplevel) {
                if (_maximized) toplevel.setMaximized();
                else toplevel.unsetMaximized();
            }
        }

        double _opacity = 1.;
        double opacity() {
            warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
            return _opacity;
        }
        void opacity(double value) {
            warning(__PRETTY_FUNCTION__, " has not been implemented for class ", typeof(this).stringof);
            _opacity = value;
        }

        enum resizeMarginSize = 16;
        uint resizeMarginPixelSize() {
            return cast(uint) ceil(resizeMarginSize * scaling());
        }

        double _scaling = 1.;
        double scaling() {
            return _scaling;
        }
        void scaling(double value) {
            auto orig = _scaling;
            _scaling = value;
            configureScaling();
            configureSize();
            resetCursorThemeManager();

            debug {
                if (viewport) {
                    trace("Fractional scaling enabled: scaling = ", _scaling);
                } else {
                    trace("Integer scaling enabled: scaling = ", _scaling);
                }
            }
            if (orig != value) {
                window.onScalingChange(_scaling);
            }
        }
        void configureScaling() {
            if (!viewport) {
                _scaling = ceil(_scaling);
                uint scaling = cast(uint) _scaling;
                surface.setBufferScale(scaling);
            } else {

            }
        }

        void moveDrag() {
            if (auto toplevel = xdgWindow.toplevel) {
                toplevel.move(backend.seat, backend.currentSerial);
            }
        }
        void resizeDrag(ResizeEdge edge) {
            if (auto toplevel = xdgWindow.toplevel) {
                XdgToplevel.ResizeEdge xdgEdge;
                final switch (edge) with (ResizeEdge) {
                    case topLeft:
                        xdgEdge = XdgToplevel.ResizeEdge.topLeft;
                        break;
                    case topRight:
                        xdgEdge = XdgToplevel.ResizeEdge.topRight;
                        break;
                    case bottomLeft:
                        xdgEdge = XdgToplevel.ResizeEdge.bottomLeft;
                        break;
                    case bottomRight:
                        xdgEdge = XdgToplevel.ResizeEdge.bottomRight;
                        break;
                    case top:
                        xdgEdge = XdgToplevel.ResizeEdge.top;
                        break;
                    case bottom:
                        xdgEdge = XdgToplevel.ResizeEdge.bottom;
                        break;
                    case left:
                        xdgEdge = XdgToplevel.ResizeEdge.left;
                        break;
                    case right:
                        xdgEdge = XdgToplevel.ResizeEdge.right;
                        break;
                }
                toplevel.resize(backend.seat, backend.currentSerial, xdgEdge);
            }
        }

        void showWindowControlMenu(Point location) {
            if (auto toplevel = xdgWindow.toplevel) {
                if (useEmulatedResizeBorders) {
                    location.x += resizeMarginPixelSize;
                    location.y += resizeMarginPixelSize;
                }
                toplevel.showWindowMenu(backend.seat, backend.currentSerial, location.tupleof);
            } else {
                warning("Can't show the window control menu for that window.");
            }
        }

        Size canvasSize() {
            return _pixelSize;
        }

        version (NanoVega) {
            import bindbc.gles.egl;
            import bindbc.opengl;

            import dfenestration.renderers.egl;
            import arsd.nanovega;

            EGLSurface eglSurface;

            WlEglWindow eglWindow;

            NVGContext _nvgContext;

            ref NVGContext nvgContext() {
                return _nvgContext;
            }

            void createWindowGL(uint width, uint height) {
                assert(surface !is null);
                assert(backend.eglDisplay !is null);
                assert(backend.eglConfig !is null);

                eglWindow = new WlEglWindow(surface, width, height);
                checkError();

                EGLint[5] attributes = [
                    EGL_GL_COLORSPACE, EGL_GL_COLORSPACE_LINEAR, // or use EGL_GL_COLORSPACE_SRGB for sRGB framebuffer
                    EGL_RENDER_BUFFER, EGL_BACK_BUFFER,
                    EGL_NONE,
                ];
                eglSurface = enforce(eglCreateWindowSurface(backend.eglDisplay, backend.eglConfig, cast(ANativeWindow*) eglWindow.native, attributes.ptr));
                checkError();

                synchronized {
                    setAsCurrentContextGL();
                    loadOpenGLInCurrentContext();
                }

                eglSwapInterval(backend.eglDisplay, 1);

                debug {
                    import bindbc.opengl;
                    if (glDebugMessageCallback) {
                        glDebugMessageCallback(&nvgDebugLog, null);
                        checkError();
                        glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
                    } else {
                        warning("Can't output debug messages.");
                    }
                }
            }

            bool setAsCurrentContextGL() {
                if (!eglSurface) {
                    return false;
                }
                bool ret = eglMakeCurrent(backend.eglDisplay, eglSurface, eglSurface, backend.eglContext) == EGL_TRUE;
                checkError();
                return ret;
            }

            void swapBuffersGL() {
                if (!eglSurface) {
                    return;
                }
                eglSwapBuffers(backend.eglDisplay, eglSurface).enforce();
                checkError();
            }

            void resizeGL(uint width, uint height) {
                if (!eglWindow) {
                    return;
                }
                eglWindow.resize(width, height, 0, 0);
                checkError();
            }

            void cleanupGL() {
                if (eglSurface) {
                    eglDestroySurface(backend.eglDisplay, eglSurface);
                    checkError();
                    eglSurface = EGL_NO_SURFACE;
                }
                if (eglWindow) {
                    eglWindow.destroy();
                    checkError();
                    eglWindow = null;
                }
            }
        }

        version (VkVG) {
            import erupted;

            VkVGRendererProperties _vkvgRendererProperties;
            VkVGRendererProperties* vkvgRendererProperties() {
                return &_vkvgRendererProperties;
            }

            VkResult createSurface(VkInstance instance, const VkAllocationCallbacks* allocator, out VkSurfaceKHR vkSurface) {
                VkWaylandSurfaceCreateInfoKHR createInfo = {
                    flags: 0,
                    display: backend.display.native(),
                    surface: surface.proxy()
                };
                return vkCreateWaylandSurfaceKHR(instance, &createInfo, allocator, &vkSurface);
            }
        }
    }

class WaylandBackendBuilder: BackendBuilder {
    WaylandBackend __instance;

    ushort evaluate() {
        if (environment.get("XDG_SESSION_TYPE") == "wayland") {
            try {
                wlClientDynLib.load();
                return 2;
            } catch (SharedLibLoadException e) {
                error("Your environment tells us to use Wayland, but libwayland-client isn't installed. Falling back.");
                trace("More information: ", e);
            }
        }
        return 0;
    }

    WaylandBackend instance() {
        if (!__instance) {
            __instance = new WaylandBackend();
        }
        return __instance;
    }
}

static this() {
    registerBackend("wayland", new WaylandBackendBuilder());
}

class WaylandException : Exception
{
    this(string msg, string file = __FILE__, int line = __LINE__)
    @safe pure nothrow
    {
        super(msg, file, line);
    }
}

version (linux) {
    extern (C) {
        enum MFD_CLOEXEC = 1U;
        int memfd_create(const(char)* name, uint flags);
    }
} else version (FreeBSD) {
    import core.sys.freebsd.sys.mman;
} else {
    import core.sys.posix.sys.mman;
    import std.random;
}

pragma(inline, true)
int createSharedMemoryFd(string debugName)() {
    version (linux) {
        return memfd_create(debugName, MFD_CLOEXEC);
    } else version (FreeBSD) {
        return shm_open(SHM_ANON, O_CREAT | O_EXCL | O_RDWR | O_CLOEXEC, octal!"600");
    } else {
        auto name = format!"df-%s-%d\0"(debugName, unpredictableSeed()).ptr;
        return shm_open(name, O_CREAT | O_EXCL | O_RDWR | O_CLOEXEC, octal!"600");
    }
}

// "macros"
pragma(inline, true) {
    private Point scale(Point point, double scaling) {
        return Point(cast(int) (point.x * scaling), cast(int) (point.y * scaling));
    }

    private Point unscale(Point point, double scaling) {
        return Point(cast(int) (point.x / scaling), cast(int) (point.y / scaling));
    }

    private Size scale(Size size, double scaling) {
        return Size(cast(uint) (size.width * scaling), cast(uint) (size.height * scaling));
    }

    private Size unscale(Size size, double scaling) {
        return Size(cast(uint) (size.width / scaling), cast(uint) (size.height / scaling));
    }
}

pragma(inline, true) WlShm.Format toWlShmFormat(Pixbuf.Format format) {
    with (Pixbuf.Format) switch (format) {
        case rgba8888:
            return WlShm.Format.rgba8888;
        case c8:
            return WlShm.Format.c8;
        default:
            assert(false, "Not implemented");
    }
}

pragma(inline, true)
string adwaitaName(CursorType cursorType) {
    with (CursorType) switch (cursorType) {
        default:
        case default_:
            return "default";
        case contextMenu:
            return "context-menu";
        case help:
            return "help";
        case pointer:
            return "pointer";
        case progress:
            return "progress";
        case wait:
            return "wait";
        case cell:
            return "cell";
        case crosshair:
            return "crosshair";
        case text:
            return "text";
        case verticalText:
            return "verticalText";
        case alias_:
            return "alias";
        case copy:
            return "copy";
        case move:
            return "move";
        case noDrop:
            return "no-drop";
        case notAllowed:
            return "not-allowed";
        case grab:
            return "grab";
        case grabbing:
            return "grabbing";
        case eResize:
            return "e-resize";
        case nResize:
            return "n-resize";
        case neResize:
            return "ne-resize";
        case nwResize:
            return "nw-resize";
        case sResize:
            return "s-resize";
        case seResize:
            return "se-resize";
        case swResize:
            return "sw-resize";
        case wResize:
            return "w-resize";
        case ewResize:
            return "ew-resize";
        case nsResize:
            return "ns-resize";
        case neswResize:
            return "nesw-resize";
        case nwseResize:
            return "nwse-resize";
        case colResize:
            return "col-resize";
        case rowResize:
            return "row-resize";
        case allScroll:
            return "all-scroll";
        case zoomIn:
            return "zoom-in";
        case zoomOut:
            return "zoom-out";
    }
}

struct WaylandCursorThemeManager {
    WlCursorTheme cursorTheme;
    WlCursor[CursorType] cursors;

    WlSurface cursorSurface;

    this(WaylandBackend backend) {
        cursorSurface = backend.compositor.createSurface();
    }

    void setTheme(WlCursorTheme cursorTheme) {
        if (this.cursorTheme) {
            this.cursorTheme.destroy();
        }
        this.cursorTheme = cursorTheme;

        foreach (cursor; cursors) {
            cursor.destroy();
        }

        cursors.clear();

        static foreach (cursorTypeName; __traits(allMembers, CursorType)) {{
            enum cursorType = __traits(getMember, CursorType, cursorTypeName);
            if (auto cursor = cursorTheme.cursor(cursorType.adwaitaName)) {
                cursors[cursorType] = cursor;
            }
        }}
    }

    @disable this();
    @disable this(this);

    ~this() {
        if (cursorSurface) {
            cursorSurface.destroy();
        }
        foreach (cursor; cursors) {
            cursor.destroy();
        }
        if (cursorTheme) {
            cursorTheme.destroy();
        }
    }

    void setCursor(WlPointer pointer, uint serial, CursorType cursorType) {
        if (auto cursor = cursorType in cursors) {
            auto image = cursor.images[0];
            if (!image) return;
            auto buffer = image.buffer;
            if (!buffer) return;
            pointer.setCursor(serial, cursorSurface, image.hotspotX, image.hotspotY);
            cursorSurface.attach(buffer, 0, 0);
            cursorSurface.damage(0, 0, image.width, image.height);
            cursorSurface.commit();
        }
    }
}
