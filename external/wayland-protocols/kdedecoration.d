/++
 +  Module generated by wayland:scanner-v0.3.1 for server_decoration protocol
 +    xml protocol:   stdin
 +    generated code: client
 +/
module kdedecoration;
/+
 +  Protocol copyright:
 +
 +  SPDX-FileCopyrightText: 2015 Martin Gräßlin
 +
 +  SPDX-License-Identifier: LGPL-2.1-or-later
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
 +  Server side window decoration manager
 +
 +  This interface allows to coordinate whether the server should create
 +  a server-side window decoration around a wl_surface representing a
 +  shell surface $(LPAREN)wl_shell_surface or similar$(RPAREN). By announcing support
 +  for this interface the server indicates that it supports server
 +  side decorations.
 +
 +  Use in conjunction with zxdg_decoration_manager_v1 is undefined.
 +/
final class OrgKdeKwinServerDecorationManager : WlProxy
{
    /// Version of server_decoration.org_kde_kwin_server_decoration_manager
    enum ver = 1;

    /// Build a OrgKdeKwinServerDecorationManager from a native object.
    private this(wl_proxy* native)
    {
        super(native);
        wl_proxy_add_listener(proxy, cast(void_func_t*)&wl_d_org_kde_kwin_server_decoration_manager_listener, null);
    }

    /// Interface object that creates OrgKdeKwinServerDecorationManager objects.
    static @property immutable(WlProxyInterface) iface()
    {
        return orgKdeKwinServerDecorationManagerIface;
    }

    /// Op-code of OrgKdeKwinServerDecorationManager.create.
    enum createOpCode = 0;

    /// Version of server_decoration protocol introducing OrgKdeKwinServerDecorationManager.create.
    enum createSinceVersion = 1;

    /// server_decoration protocol version introducing OrgKdeKwinServerDecorationManager.onDefaultMode.
    enum onDefaultModeSinceVersion = 1;

    /// Event delegate signature of OrgKdeKwinServerDecorationManager.onDefaultMode.
    alias OnDefaultModeEventDg = void delegate(OrgKdeKwinServerDecorationManager orgKdeKwinServerDecorationManager,
                                               uint mode);

    /// Possible values to use in request_mode and the event mode.
    enum Mode : uint
    {
        /// Undecorated: The surface is not decorated at all, neither server nor client-side. An example is a popup surface which should not be decorated.
        none = 0,
        /// Client-side decoration: The decoration is part of the surface and the client.
        client = 1,
        /// Server-side decoration: The server embeds the surface into a decoration frame.
        server = 2,
    }

    /// Destroy this OrgKdeKwinServerDecorationManager object.
    void destroy()
    {
        wl_proxy_destroy(proxy);
        super.destroyNotify();
    }

    /++
     +  Create a server-side decoration object for a given surface
     +
     +  When a client creates a server-side decoration object it indicates
     +  that it supports the protocol. The client is supposed to tell the
     +  server whether it wants server-side decorations or will provide
     +  client-side decorations.
     +
     +  If the client does not create a server-side decoration object for
     +  a surface the server interprets this as lack of support for this
     +  protocol and considers it as client-side decorated. Nevertheless a
     +  client-side decorated surface should use this protocol to indicate
     +  to the server that it does not want a server-side deco.
     +/
    OrgKdeKwinServerDecoration create(WlSurface surface)
    {
        auto _pp = wl_proxy_marshal_constructor(
            proxy, createOpCode, OrgKdeKwinServerDecoration.iface.native, null,
            surface.proxy
        );
        if (!_pp) return null;
        auto _p = WlProxy.get(_pp);
        if (_p) return cast(OrgKdeKwinServerDecoration)_p;
        return new OrgKdeKwinServerDecoration(_pp);
    }

    /++
     +  The default mode used on the server
     +
     +  This event is emitted directly after binding the interface. It contains
     +  the default mode for the decoration. When a new server decoration object
     +  is created this new object will be in the default mode until the first
     +  request_mode is requested.
     +
     +  The server may change the default mode at any time.
     +/
    @property void onDefaultMode(OnDefaultModeEventDg dg)
    {
        _onDefaultMode = dg;
    }

    private OnDefaultModeEventDg _onDefaultMode;
}

/// release the server decoration object
final class OrgKdeKwinServerDecoration : WlProxy
{
    /// Version of server_decoration.org_kde_kwin_server_decoration
    enum ver = 1;

    /// Build a OrgKdeKwinServerDecoration from a native object.
    private this(wl_proxy* native)
    {
        super(native);
        wl_proxy_add_listener(proxy, cast(void_func_t*)&wl_d_org_kde_kwin_server_decoration_listener, null);
    }

    /// Interface object that creates OrgKdeKwinServerDecoration objects.
    static @property immutable(WlProxyInterface) iface()
    {
        return orgKdeKwinServerDecorationIface;
    }

    /// Op-code of OrgKdeKwinServerDecoration.release.
    enum releaseOpCode = 0;
    /// Op-code of OrgKdeKwinServerDecoration.requestMode.
    enum requestModeOpCode = 1;

    /// Version of server_decoration protocol introducing OrgKdeKwinServerDecoration.release.
    enum releaseSinceVersion = 1;
    /// Version of server_decoration protocol introducing OrgKdeKwinServerDecoration.requestMode.
    enum requestModeSinceVersion = 1;

    /// server_decoration protocol version introducing OrgKdeKwinServerDecoration.onMode.
    enum onModeSinceVersion = 1;

    /// Event delegate signature of OrgKdeKwinServerDecoration.onMode.
    alias OnModeEventDg = void delegate(OrgKdeKwinServerDecoration orgKdeKwinServerDecoration,
                                        uint mode);

    /// Possible values to use in request_mode and the event mode.
    enum Mode : uint
    {
        /// Undecorated: The surface is not decorated at all, neither server nor client-side. An example is a popup surface which should not be decorated.
        none = 0,
        /// Client-side decoration: The decoration is part of the surface and the client.
        client = 1,
        /// Server-side decoration: The server embeds the surface into a decoration frame.
        server = 2,
    }

    /// Destroy this OrgKdeKwinServerDecoration object.
    void destroy()
    {
        wl_proxy_destroy(proxy);
        super.destroyNotify();
    }

    /// release the server decoration object
    void release()
    {
        wl_proxy_marshal(
            proxy, releaseOpCode
        );
        super.destroyNotify();
    }

    /// The decoration mode the surface wants to use.
    void requestMode(uint mode)
    {
        wl_proxy_marshal(
            proxy, requestModeOpCode, mode
        );
    }

    /++
     +  The new decoration mode applied by the server
     +
     +  This event is emitted directly after the decoration is created and
     +  represents the base decoration policy by the server. E.g. a server
     +  which wants all surfaces to be client-side decorated will send Client,
     +  a server which wants server-side decoration will send Server.
     +
     +  The client can request a different mode through the decoration request.
     +  The server will acknowledge this by another event with the same mode. So
     +  even if a server prefers server-side decoration it's possible to force a
     +  client-side decoration.
     +
     +  The server may emit this event at any time. In this case the client can
     +  again request a different mode. It's the responsibility of the server to
     +  prevent a feedback loop.
     +/
    @property void onMode(OnModeEventDg dg)
    {
        _onMode = dg;
    }

    private OnModeEventDg _onMode;
}

private:

immutable WlProxyInterface orgKdeKwinServerDecorationManagerIface;
immutable WlProxyInterface orgKdeKwinServerDecorationIface;

immutable final class OrgKdeKwinServerDecorationManagerIface : WlProxyInterface
{
    this(immutable wl_interface* native)
    {
        super(native);
    }
    override WlProxy makeProxy(wl_proxy* proxy) immutable
    {
        return new OrgKdeKwinServerDecorationManager(proxy);
    }
}

immutable final class OrgKdeKwinServerDecorationIface : WlProxyInterface
{
    this(immutable wl_interface* native)
    {
        super(native);
    }
    override WlProxy makeProxy(wl_proxy* proxy) immutable
    {
        return new OrgKdeKwinServerDecoration(proxy);
    }
}

immutable wl_interface[] wl_ifaces;

enum orgKdeKwinServerDecorationManagerIndex = 0;
enum orgKdeKwinServerDecorationIndex = 1;

shared static this()
{
    auto ifaces = new wl_interface[2];

    auto msgTypes = [
        null,
        &ifaces[orgKdeKwinServerDecorationIndex],
        cast(wl_interface*)WlSurface.iface.native,
    ];

    auto org_kde_kwin_server_decoration_manager_requests = [
        wl_message("create", "no", &msgTypes[1]),
    ];
    auto org_kde_kwin_server_decoration_manager_events = [
        wl_message("default_mode", "u", &msgTypes[0]),
    ];
    ifaces[orgKdeKwinServerDecorationManagerIndex].name = "org_kde_kwin_server_decoration_manager";
    ifaces[orgKdeKwinServerDecorationManagerIndex].version_ = 1;
    ifaces[orgKdeKwinServerDecorationManagerIndex].method_count = 1;
    ifaces[orgKdeKwinServerDecorationManagerIndex].methods = org_kde_kwin_server_decoration_manager_requests.ptr;
    ifaces[orgKdeKwinServerDecorationManagerIndex].event_count = 1;
    ifaces[orgKdeKwinServerDecorationManagerIndex].events = org_kde_kwin_server_decoration_manager_events.ptr;

    auto org_kde_kwin_server_decoration_requests = [
        wl_message("release", "", &msgTypes[0]),
        wl_message("request_mode", "u", &msgTypes[0]),
    ];
    auto org_kde_kwin_server_decoration_events = [
        wl_message("mode", "u", &msgTypes[0]),
    ];
    ifaces[orgKdeKwinServerDecorationIndex].name = "org_kde_kwin_server_decoration";
    ifaces[orgKdeKwinServerDecorationIndex].version_ = 1;
    ifaces[orgKdeKwinServerDecorationIndex].method_count = 2;
    ifaces[orgKdeKwinServerDecorationIndex].methods = org_kde_kwin_server_decoration_requests.ptr;
    ifaces[orgKdeKwinServerDecorationIndex].event_count = 1;
    ifaces[orgKdeKwinServerDecorationIndex].events = org_kde_kwin_server_decoration_events.ptr;

    import std.exception : assumeUnique;
    wl_ifaces = assumeUnique(ifaces);

    orgKdeKwinServerDecorationManagerIface = new immutable OrgKdeKwinServerDecorationManagerIface( &wl_ifaces[orgKdeKwinServerDecorationManagerIndex] );
    orgKdeKwinServerDecorationIface = new immutable OrgKdeKwinServerDecorationIface( &wl_ifaces[orgKdeKwinServerDecorationIndex] );
}

extern(C) nothrow
{
    struct org_kde_kwin_server_decoration_manager_listener
    {
        void function(void* data,
                      wl_proxy* proxy,
                      uint mode) default_mode;
    }

    __gshared wl_d_org_kde_kwin_server_decoration_manager_listener = org_kde_kwin_server_decoration_manager_listener (&wl_d_on_org_kde_kwin_server_decoration_manager_default_mode);

    void wl_d_on_org_kde_kwin_server_decoration_manager_default_mode(void* data,
                                                                     wl_proxy* proxy,
                                                                     uint mode)
    {
        nothrowFnWrapper!({
            auto _p = WlProxy.get(proxy);
            assert(_p, "listener stub without proxy");
            auto _i = cast(OrgKdeKwinServerDecorationManager)_p;
            assert(_i, "listener stub proxy is not OrgKdeKwinServerDecorationManager");
            if (_i._onDefaultMode)
            {
                _i._onDefaultMode(_i, mode);
            }
        });
    }

    struct org_kde_kwin_server_decoration_listener
    {
        void function(void* data,
                      wl_proxy* proxy,
                      uint mode) mode;
    }

    __gshared wl_d_org_kde_kwin_server_decoration_listener = org_kde_kwin_server_decoration_listener (&wl_d_on_org_kde_kwin_server_decoration_mode);

    void wl_d_on_org_kde_kwin_server_decoration_mode(void* data,
                                                     wl_proxy* proxy,
                                                     uint mode)
    {
        nothrowFnWrapper!({
            auto _p = WlProxy.get(proxy);
            assert(_p, "listener stub without proxy");
            auto _i = cast(OrgKdeKwinServerDecoration)_p;
            assert(_i, "listener stub proxy is not OrgKdeKwinServerDecoration");
            if (_i._onMode)
            {
                _i._onMode(_i, mode);
            }
        });
    }
}