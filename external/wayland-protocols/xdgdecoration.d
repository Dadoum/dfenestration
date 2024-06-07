/++
 +  Module generated by wayland:scanner-v0.3.1 for xdg_decoration_unstable_v1 protocol
 +    xml protocol:   xdg-decoration-unstable-v1.xml
 +    generated code: client
 +/
module xdgdecoration;

/+
 +  Protocol copyright:
 +
 +  Copyright © 2018 Simon Ser
 +
 +  Permission is hereby granted, free of charge, to any person obtaining a
 +  copy of this software and associated documentation files (the "Software"),
 +  to deal in the Software without restriction, including without limitation
 +  the rights to use, copy, modify, merge, publish, distribute, sublicense,
 +  and/or sell copies of the Software, and to permit persons to whom the
 +  Software is furnished to do so, subject to the following conditions:
 +
 +  The above copyright notice and this permission notice (including the next
 +  paragraph) shall be included in all copies or substantial portions of the
 +  Software.
 +
 +  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 +  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 +  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
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

import xdgshell;

/++
 +  window decoration manager
 +
 +  This interface allows a compositor to announce support for server-side
 +  decorations.
 +
 +  A window decoration is a set of window controls as deemed appropriate by
 +  the party managing them, such as user interface components used to move,
 +  resize and change a window's state.
 +
 +  A client can use this protocol to request being decorated by a supporting
 +  compositor.
 +
 +  If compositor and client do not negotiate the use of a server-side
 +  decoration using this protocol, clients continue to self-decorate as they
 +  see fit.
 +
 +  Warning! The protocol described in this file is experimental and
 +  backward incompatible changes may be made. Backward compatible changes
 +  may be added together with the corresponding interface version bump.
 +  Backward incompatible changes are done by bumping the version number in
 +  the protocol and interface names and resetting the interface version.
 +  Once the protocol is to be declared stable, the 'z' prefix and the
 +  version number in the protocol and interface names are removed and the
 +  interface version number is reset.
 +/
final class ZxdgDecorationManagerV1 : WlProxy
{
    /// Version of xdg_decoration_unstable_v1.zxdg_decoration_manager_v1
    enum ver = 1;

    /// Build a ZxdgDecorationManagerV1 from a native object.
    private this(wl_proxy* native)
    {
        super(native);
    }

    /// Interface object that creates ZxdgDecorationManagerV1 objects.
    static immutable(WlProxyInterface) iface()
    {
        return zxdgDecorationManagerV1Iface;
    }

    /// Op-code of ZxdgDecorationManagerV1.destroy.
    enum destroyOpCode = 0;
    /// Op-code of ZxdgDecorationManagerV1.getToplevelDecoration.
    enum getToplevelDecorationOpCode = 1;

    /// Version of xdg_decoration_unstable_v1 protocol introducing ZxdgDecorationManagerV1.destroy.
    enum destroySinceVersion = 1;
    /// Version of xdg_decoration_unstable_v1 protocol introducing ZxdgDecorationManagerV1.getToplevelDecoration.
    enum getToplevelDecorationSinceVersion = 1;

    /++
     +  destroy the decoration manager object
     +
     +  Destroy the decoration manager. This doesn't destroy objects created
     +  with the manager.
     +/
    void destroy()
    {
        wl_proxy_marshal(
            proxy, destroyOpCode
        );
        super.destroyNotify();
    }

    /++
     +  create a new toplevel decoration object
     +
     +  Create a new decoration object associated with the given toplevel.
     +
     +  Creating an xdg_toplevel_decoration from an xdg_toplevel which has a
     +  buffer attached or committed is a client error, and any attempts by a
     +  client to attach or manipulate a buffer prior to the first
     +  xdg_toplevel_decoration.configure event must also be treated as
     +  errors.
     +/
    ZxdgToplevelDecorationV1 getToplevelDecoration(XdgToplevel toplevel)
    {
        auto _pp = wl_proxy_marshal_constructor(
            proxy, getToplevelDecorationOpCode,
            ZxdgToplevelDecorationV1.iface.native, null, toplevel.proxy
        );
        if (!_pp) return null;
        auto _p = WlProxy.get(_pp);
        if (_p) return cast(ZxdgToplevelDecorationV1)_p;
        return new ZxdgToplevelDecorationV1(_pp);
    }
}

/++
 +  decoration object for a toplevel surface
 +
 +  The decoration object allows the compositor to toggle server-side window
 +  decorations for a toplevel surface. The client can request to switch to
 +  another mode.
 +
 +  The xdg_toplevel_decoration object must be destroyed before its
 +  xdg_toplevel.
 +/
final class ZxdgToplevelDecorationV1 : WlProxy
{
    /// Version of xdg_decoration_unstable_v1.zxdg_toplevel_decoration_v1
    enum ver = 1;

    /// Build a ZxdgToplevelDecorationV1 from a native object.
    private this(wl_proxy* native)
    {
        super(native);
        wl_proxy_add_listener(proxy, cast(void_func_t*)&wl_d_zxdg_toplevel_decoration_v1_listener, null);
    }

    /// Interface object that creates ZxdgToplevelDecorationV1 objects.
    static immutable(WlProxyInterface) iface()
    {
        return zxdgToplevelDecorationV1Iface;
    }

    /// Op-code of ZxdgToplevelDecorationV1.destroy.
    enum destroyOpCode = 0;
    /// Op-code of ZxdgToplevelDecorationV1.setMode.
    enum setModeOpCode = 1;
    /// Op-code of ZxdgToplevelDecorationV1.unsetMode.
    enum unsetModeOpCode = 2;

    /// Version of xdg_decoration_unstable_v1 protocol introducing ZxdgToplevelDecorationV1.destroy.
    enum destroySinceVersion = 1;
    /// Version of xdg_decoration_unstable_v1 protocol introducing ZxdgToplevelDecorationV1.setMode.
    enum setModeSinceVersion = 1;
    /// Version of xdg_decoration_unstable_v1 protocol introducing ZxdgToplevelDecorationV1.unsetMode.
    enum unsetModeSinceVersion = 1;

    /// xdg_decoration_unstable_v1 protocol version introducing ZxdgToplevelDecorationV1.onConfigure.
    enum onConfigureSinceVersion = 1;

    /// Event delegate signature of ZxdgToplevelDecorationV1.onConfigure.
    alias OnConfigureEventDg = void delegate(ZxdgToplevelDecorationV1 zxdgToplevelDecorationV1,
                                             Mode mode);

    enum Error : uint
    {
        /// xdg_toplevel has a buffer attached before configure
        unconfiguredBuffer = 0,
        /// xdg_toplevel already has a decoration object
        alreadyConstructed = 1,
        /// xdg_toplevel destroyed before the decoration object
        orphaned = 2,
    }

    /++
     +  window decoration modes
     +
     +  These values describe window decoration modes.
     +/
    enum Mode : uint
    {
        /// no server-side window decoration
        clientSide = 1,
        /// server-side window decoration
        serverSide = 2,
    }

    /++
     +  destroy the decoration object
     +
     +  Switch back to a mode without any server-side decorations at the next
     +  commit.
     +/
    void destroy()
    {
        wl_proxy_marshal(
            proxy, destroyOpCode
        );
        super.destroyNotify();
    }

    /++
     +  set the decoration mode
     +
     +  Set the toplevel surface decoration mode. This informs the compositor
     +  that the client prefers the provided decoration mode.
     +
     +  After requesting a decoration mode, the compositor will respond by
     +  emitting an xdg_surface.configure event. The client should then update
     +  its content, drawing it without decorations if the received mode is
     +  server-side decorations. The client must also acknowledge the configure
     +  when committing the new content $(LPAREN)see xdg_surface.ack_configure$(RPAREN).
     +
     +  The compositor can decide not to use the client's mode and enforce a
     +  different mode instead.
     +
     +  Clients whose decoration mode depend on the xdg_toplevel state may send
     +  a set_mode request in response to an xdg_surface.configure event and wait
     +  for the next xdg_surface.configure event to prevent unwanted state.
     +  Such clients are responsible for preventing configure loops and must
     +  make sure not to send multiple successive set_mode requests with the
     +  same decoration mode.
     +/
    void setMode(Mode mode)
    {
        wl_proxy_marshal(
            proxy, setModeOpCode, mode
        );
    }

    /++
     +  unset the decoration mode
     +
     +  Unset the toplevel surface decoration mode. This informs the compositor
     +  that the client doesn't prefer a particular decoration mode.
     +
     +  This request has the same semantics as set_mode.
     +/
    void unsetMode()
    {
        wl_proxy_marshal(
            proxy, unsetModeOpCode
        );
    }

    /++
     +  suggest a surface change
     +
     +  The configure event asks the client to change its decoration mode. The
     +  configured state should not be applied immediately. Clients must send an
     +  ack_configure in response to this event. See xdg_surface.configure and
     +  xdg_surface.ack_configure for details.
     +
     +  A configure event can be sent at any time. The specified mode must be
     +  obeyed by the client.
     +/
    void onConfigure(OnConfigureEventDg dg)
    {
        _onConfigure = dg;
    }

    private OnConfigureEventDg _onConfigure;
}

private:

immutable WlProxyInterface zxdgDecorationManagerV1Iface;
immutable WlProxyInterface zxdgToplevelDecorationV1Iface;

immutable final class ZxdgDecorationManagerV1Iface : WlProxyInterface
{
    this(immutable wl_interface* native)
    {
        super(native);
    }
    override WlProxy makeProxy(wl_proxy* proxy) immutable
    {
        return new ZxdgDecorationManagerV1(proxy);
    }
}

immutable final class ZxdgToplevelDecorationV1Iface : WlProxyInterface
{
    this(immutable wl_interface* native)
    {
        super(native);
    }
    override WlProxy makeProxy(wl_proxy* proxy) immutable
    {
        return new ZxdgToplevelDecorationV1(proxy);
    }
}

immutable wl_interface[] wl_ifaces;

enum zxdgDecorationManagerV1Index = 0;
enum zxdgToplevelDecorationV1Index = 1;

shared static this()
{
    auto ifaces = new wl_interface[2];

    auto msgTypes = [
        null,
        &ifaces[zxdgToplevelDecorationV1Index],
        cast(wl_interface*)XdgToplevel.iface.native,
    ];

    auto zxdg_decoration_manager_v1_requests = [
        wl_message("destroy", "", &msgTypes[0]),
        wl_message("get_toplevel_decoration", "no", &msgTypes[1]),
    ];
    ifaces[zxdgDecorationManagerV1Index].name = "zxdg_decoration_manager_v1";
    ifaces[zxdgDecorationManagerV1Index].version_ = 1;
    ifaces[zxdgDecorationManagerV1Index].method_count = 2;
    ifaces[zxdgDecorationManagerV1Index].methods = zxdg_decoration_manager_v1_requests.ptr;

    auto zxdg_toplevel_decoration_v1_requests = [
        wl_message("destroy", "", &msgTypes[0]),
        wl_message("set_mode", "u", &msgTypes[0]),
        wl_message("unset_mode", "", &msgTypes[0]),
    ];
    auto zxdg_toplevel_decoration_v1_events = [
        wl_message("configure", "u", &msgTypes[0]),
    ];
    ifaces[zxdgToplevelDecorationV1Index].name = "zxdg_toplevel_decoration_v1";
    ifaces[zxdgToplevelDecorationV1Index].version_ = 1;
    ifaces[zxdgToplevelDecorationV1Index].method_count = 3;
    ifaces[zxdgToplevelDecorationV1Index].methods = zxdg_toplevel_decoration_v1_requests.ptr;
    ifaces[zxdgToplevelDecorationV1Index].event_count = 1;
    ifaces[zxdgToplevelDecorationV1Index].events = zxdg_toplevel_decoration_v1_events.ptr;

    import std.exception : assumeUnique;
    wl_ifaces = assumeUnique(ifaces);

    zxdgDecorationManagerV1Iface = new immutable ZxdgDecorationManagerV1Iface( &wl_ifaces[zxdgDecorationManagerV1Index] );
    zxdgToplevelDecorationV1Iface = new immutable ZxdgToplevelDecorationV1Iface( &wl_ifaces[zxdgToplevelDecorationV1Index] );
}

extern(C) nothrow
{

    struct zxdg_toplevel_decoration_v1_listener
    {
        void function(void* data,
                      wl_proxy* proxy,
                      uint mode) configure;
    }

    __gshared wl_d_zxdg_toplevel_decoration_v1_listener = zxdg_toplevel_decoration_v1_listener (&wl_d_on_zxdg_toplevel_decoration_v1_configure);

    void wl_d_on_zxdg_toplevel_decoration_v1_configure(void* data,
                                                       wl_proxy* proxy,
                                                       uint mode)
    {
        nothrowFnWrapper!({
            auto _p = WlProxy.get(proxy);
            assert(_p, "listener stub without proxy");
            auto _i = cast(ZxdgToplevelDecorationV1)_p;
            assert(_i, "listener stub proxy is not ZxdgToplevelDecorationV1");
            if (_i._onConfigure)
            {
                _i._onConfigure(_i, cast(ZxdgToplevelDecorationV1.Mode)mode);
            }
        });
    }
}
