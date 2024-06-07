/++
 +  Module generated by wayland:scanner-v0.3.1 for cursor_shape_v1 protocol
 +    xml protocol:   cursor-shape-v1.xml
 +    generated code: client
 +/
module cursorshape;
/+
 +  Protocol copyright:
 +
 +  Copyright 2018 The Chromium Authors
 +  Copyright 2023 Simon Ser
 +
 +  Permission is hereby granted, free of charge, to any person obtaining a
 +  copy of this software and associated documentation files (the "Software"),
 +  to deal in the Software without restriction, including without limitation
 +  the rights to use, copy, modify, merge, publish, distribute, sublicense,
 +  and/or sell copies of the Software, and to permit persons to whom the
 +  Software is furnished to do so, subject to the following conditions:
 +  The above copyright notice and this permission notice (including the next
 +  paragraph) shall be included in all copies or substantial portions of the
 +  Software.
 +  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 +  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 +  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 +  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 +  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 +  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 +  DEALINGS IN THE SOFTWARE.
 +/
/+
 +  Bindings copyright:
 +
 +  Copyright © 2017-2019 Rémi Thebault
 +/
import wayland.client;
import wayland.native.client;
import wayland.native.util;
import wayland.util;

import std.exception : enforce;
import std.string : fromStringz, toStringz;

/++
 +  cursor shape manager
 +
 +  This global offers an alternative, optional way to set cursor images. This
 +  new way uses enumerated cursors instead of a wl_surface like
 +  wl_pointer.set_cursor does.
 +
 +  Warning! The protocol described in this file is currently in the testing
 +  phase. Backward compatible changes may be added together with the
 +  corresponding interface version bump. Backward incompatible changes can
 +  only be done by creating a new major version of the extension.
 +/
final class WpCursorShapeManagerV1 : WlProxy
{
    /// Version of cursor_shape_v1.wp_cursor_shape_manager_v1
    enum ver = 1;

    /// Build a WpCursorShapeManagerV1 from a native object.
    private this(wl_proxy* native)
    {
        super(native);
    }

    /// Interface object that creates WpCursorShapeManagerV1 objects.
    static @property immutable(WlProxyInterface) iface()
    {
        return wpCursorShapeManagerV1Iface;
    }

    /// Op-code of WpCursorShapeManagerV1.destroy.
    enum destroyOpCode = 0;
    /// Op-code of WpCursorShapeManagerV1.getPointer.
    enum getPointerOpCode = 1;
    /// Op-code of WpCursorShapeManagerV1.getTabletToolV2.
    enum getTabletToolV2OpCode = 2;

    /// Version of cursor_shape_v1 protocol introducing WpCursorShapeManagerV1.destroy.
    enum destroySinceVersion = 1;
    /// Version of cursor_shape_v1 protocol introducing WpCursorShapeManagerV1.getPointer.
    enum getPointerSinceVersion = 1;
    /// Version of cursor_shape_v1 protocol introducing WpCursorShapeManagerV1.getTabletToolV2.
    enum getTabletToolV2SinceVersion = 1;

    /++
     +  destroy the manager
     +
     +  Destroy the cursor shape manager.
     +/
    void destroy()
    {
        wl_proxy_marshal(
            proxy, destroyOpCode
        );
        super.destroyNotify();
    }

    /++
     +  manage the cursor shape of a pointer device
     +
     +  Obtain a wp_cursor_shape_device_v1 for a wl_pointer object.
     +/
    WpCursorShapeDeviceV1 getPointer(WlPointer pointer)
    {
        auto _pp = wl_proxy_marshal_constructor(
            proxy, getPointerOpCode, WpCursorShapeDeviceV1.iface.native, null,
            pointer.proxy
        );
        if (!_pp) return null;
        auto _p = WlProxy.get(_pp);
        if (_p) return cast(WpCursorShapeDeviceV1)_p;
        return new WpCursorShapeDeviceV1(_pp);
    }

    // /++
    //  +  manage the cursor shape of a tablet tool device
    //  +
    //  +  Obtain a wp_cursor_shape_device_v1 for a zwp_tablet_tool_v2 object.
    //  +/
    // WpCursorShapeDeviceV1 getTabletToolV2(ZwpTabletToolV2 tabletTool)
    // {
    //     auto _pp = wl_proxy_marshal_constructor(
    //         proxy, getTabletToolV2OpCode, WpCursorShapeDeviceV1.iface.native,
    //         null, tabletTool.proxy
    //     );
    //     if (!_pp) return null;
    //     auto _p = WlProxy.get(_pp);
    //     if (_p) return cast(WpCursorShapeDeviceV1)_p;
    //     return new WpCursorShapeDeviceV1(_pp);
    // }
}

/++
 +  cursor shape for a device
 +
 +  This interface advertises the list of supported cursor shapes for a
 +  device, and allows clients to set the cursor shape.
 +/
final class WpCursorShapeDeviceV1 : WlProxy
{
    /// Version of cursor_shape_v1.wp_cursor_shape_device_v1
    enum ver = 1;

    /// Build a WpCursorShapeDeviceV1 from a native object.
    private this(wl_proxy* native)
    {
        super(native);
    }

    /// Interface object that creates WpCursorShapeDeviceV1 objects.
    static @property immutable(WlProxyInterface) iface()
    {
        return wpCursorShapeDeviceV1Iface;
    }

    /// Op-code of WpCursorShapeDeviceV1.destroy.
    enum destroyOpCode = 0;
    /// Op-code of WpCursorShapeDeviceV1.setShape.
    enum setShapeOpCode = 1;

    /// Version of cursor_shape_v1 protocol introducing WpCursorShapeDeviceV1.destroy.
    enum destroySinceVersion = 1;
    /// Version of cursor_shape_v1 protocol introducing WpCursorShapeDeviceV1.setShape.
    enum setShapeSinceVersion = 1;

    /++
     +  cursor shapes
     +
     +  This enum describes cursor shapes.
     +
     +  The names are taken from the CSS W3C specification:
     +  https://w3c.github.io/csswg-drafts/css-ui/#cursor
     +/
    enum Shape : uint
    {
        /// default cursor
        default_ = 1,
        /// a context menu is available for the object under the cursor
        contextMenu = 2,
        /// help is available for the object under the cursor
        help = 3,
        /// pointer that indicates a link or another interactive element
        pointer = 4,
        /// progress indicator
        progress = 5,
        /// program is busy, user should wait
        wait = 6,
        /// a cell or set of cells may be selected
        cell = 7,
        /// simple crosshair
        crosshair = 8,
        /// text may be selected
        text = 9,
        /// vertical text may be selected
        verticalText = 10,
        /// drag-and-drop: alias of/shortcut to something is to be created
        alias_ = 11,
        /// drag-and-drop: something is to be copied
        copy = 12,
        /// drag-and-drop: something is to be moved
        move = 13,
        /// drag-and-drop: the dragged item cannot be dropped at the current cursor location
        noDrop = 14,
        /// drag-and-drop: the requested action will not be carried out
        notAllowed = 15,
        /// drag-and-drop: something can be grabbed
        grab = 16,
        /// drag-and-drop: something is being grabbed
        grabbing = 17,
        /// resizing: the east border is to be moved
        eResize = 18,
        /// resizing: the north border is to be moved
        nResize = 19,
        /// resizing: the north-east corner is to be moved
        neResize = 20,
        /// resizing: the north-west corner is to be moved
        nwResize = 21,
        /// resizing: the south border is to be moved
        sResize = 22,
        /// resizing: the south-east corner is to be moved
        seResize = 23,
        /// resizing: the south-west corner is to be moved
        swResize = 24,
        /// resizing: the west border is to be moved
        wResize = 25,
        /// resizing: the east and west borders are to be moved
        ewResize = 26,
        /// resizing: the north and south borders are to be moved
        nsResize = 27,
        /// resizing: the north-east and south-west corners are to be moved
        neswResize = 28,
        /// resizing: the north-west and south-east corners are to be moved
        nwseResize = 29,
        /// resizing: that the item/column can be resized horizontally
        colResize = 30,
        /// resizing: that the item/row can be resized vertically
        rowResize = 31,
        /// something can be scrolled in any direction
        allScroll = 32,
        /// something can be zoomed in
        zoomIn = 33,
        /// something can be zoomed out
        zoomOut = 34,
    }

    enum Error : uint
    {
        /// the specified shape value is invalid
        invalidShape = 1,
    }

    /++
     +  destroy the cursor shape device
     +
     +  Destroy the cursor shape device.
     +
     +  The device cursor shape remains unchanged.
     +/
    void destroy()
    {
        wl_proxy_marshal(
            proxy, destroyOpCode
        );
        super.destroyNotify();
    }

    /++
     +  set device cursor to the shape
     +
     +  Sets the device cursor to the specified shape. The compositor will
     +  change the cursor image based on the specified shape.
     +
     +  The cursor actually changes only if the input device focus is one of
     +  the requesting client's surfaces. If any, the previous cursor image
     +  $(LPAREN)surface or shape$(RPAREN) is replaced.
     +
     +  The "shape" argument must be a valid enum entry, otherwise the
     +  invalid_shape protocol error is raised.
     +
     +  This is similar to the wl_pointer.set_cursor and
     +  zwp_tablet_tool_v2.set_cursor requests, but this request accepts a
     +  shape instead of contents in the form of a surface. Clients can mix
     +  set_cursor and set_shape requests.
     +
     +  The serial parameter must match the latest wl_pointer.enter or
     +  zwp_tablet_tool_v2.proximity_in serial number sent to the client.
     +  Otherwise the request will be ignored.
     +/
    void setShape(uint serial,
                  Shape shape)
    {
        wl_proxy_marshal(
            proxy, setShapeOpCode, serial, shape
        );
    }
}

private:

immutable WlProxyInterface wpCursorShapeManagerV1Iface;
immutable WlProxyInterface wpCursorShapeDeviceV1Iface;

immutable final class WpCursorShapeManagerV1Iface : WlProxyInterface
{
    this(immutable wl_interface* native)
    {
        super(native);
    }
    override WlProxy makeProxy(wl_proxy* proxy) immutable
    {
        return new WpCursorShapeManagerV1(proxy);
    }
}

immutable final class WpCursorShapeDeviceV1Iface : WlProxyInterface
{
    this(immutable wl_interface* native)
    {
        super(native);
    }
    override WlProxy makeProxy(wl_proxy* proxy) immutable
    {
        return new WpCursorShapeDeviceV1(proxy);
    }
}

immutable wl_interface[] wl_ifaces;

enum wpCursorShapeManagerV1Index = 0;
enum wpCursorShapeDeviceV1Index = 1;

shared static this()
{
    auto ifaces = new wl_interface[2];

    auto msgTypes = [
        null,
        null,
        &ifaces[wpCursorShapeDeviceV1Index],
        cast(wl_interface*)WlPointer.iface.native,
        &ifaces[wpCursorShapeDeviceV1Index],
        // cast(wl_interface*)ZwpTabletToolV2.iface.native,
    ];

    auto wp_cursor_shape_manager_v1_requests = [
        wl_message("destroy", "", &msgTypes[0]),
        wl_message("get_pointer", "no", &msgTypes[2]),
        wl_message("get_tablet_tool_v2", "no", &msgTypes[4]),
    ];
    ifaces[wpCursorShapeManagerV1Index].name = "wp_cursor_shape_manager_v1";
    ifaces[wpCursorShapeManagerV1Index].version_ = 1;
    ifaces[wpCursorShapeManagerV1Index].method_count = 3;
    ifaces[wpCursorShapeManagerV1Index].methods = wp_cursor_shape_manager_v1_requests.ptr;

    auto wp_cursor_shape_device_v1_requests = [
        wl_message("destroy", "", &msgTypes[0]),
        wl_message("set_shape", "uu", &msgTypes[0]),
    ];
    ifaces[wpCursorShapeDeviceV1Index].name = "wp_cursor_shape_device_v1";
    ifaces[wpCursorShapeDeviceV1Index].version_ = 1;
    ifaces[wpCursorShapeDeviceV1Index].method_count = 2;
    ifaces[wpCursorShapeDeviceV1Index].methods = wp_cursor_shape_device_v1_requests.ptr;

    import std.exception : assumeUnique;
    wl_ifaces = assumeUnique(ifaces);

    wpCursorShapeManagerV1Iface = new immutable WpCursorShapeManagerV1Iface( &wl_ifaces[wpCursorShapeManagerV1Index] );
    wpCursorShapeDeviceV1Iface = new immutable WpCursorShapeDeviceV1Iface( &wl_ifaces[wpCursorShapeDeviceV1Index] );
}

extern(C) nothrow
{

}
