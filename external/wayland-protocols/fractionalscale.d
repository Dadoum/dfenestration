/++
 +  Module generated by wayland:scanner-v0.3.1 for fractional_scale_v1 protocol
 +    xml protocol:   fractional-scale-v1.xml
 +    generated code: client
 +/
module fractionalscale;
/+
 +  Protocol copyright:
 +
 +  Copyright © 2022 Kenny Levinsen
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

/++
 +  fractional surface scale information
 +
 +  A global interface for requesting surfaces to use fractional scales.
 +/
final class WpFractionalScaleManagerV1 : WlProxy
{
    /// Version of fractional_scale_v1.wp_fractional_scale_manager_v1
    enum ver = 1;

    /// Build a WpFractionalScaleManagerV1 from a native object.
    private this(wl_proxy* native)
    {
        super(native);
    }

    /// Interface object that creates WpFractionalScaleManagerV1 objects.
    static @property immutable(WlProxyInterface) iface()
    {
        return wpFractionalScaleManagerV1Iface;
    }

    /// Op-code of WpFractionalScaleManagerV1.destroy.
    enum destroyOpCode = 0;
    /// Op-code of WpFractionalScaleManagerV1.getFractionalScale.
    enum getFractionalScaleOpCode = 1;

    /// Version of fractional_scale_v1 protocol introducing WpFractionalScaleManagerV1.destroy.
    enum destroySinceVersion = 1;
    /// Version of fractional_scale_v1 protocol introducing WpFractionalScaleManagerV1.getFractionalScale.
    enum getFractionalScaleSinceVersion = 1;

    enum Error : uint
    {
        /// the surface already has a fractional_scale object associated
        fractionalScaleExists = 0,
    }

    /++
     +  unbind the fractional surface scale interface
     +
     +  Informs the server that the client will not be using this protocol
     +  object anymore. This does not affect any other objects,
     +  wp_fractional_scale_v1 objects included.
     +/
    void destroy()
    {
        wl_proxy_marshal(
            proxy, destroyOpCode
        );
        super.destroyNotify();
    }

    /++
     +  extend surface interface for scale information
     +
     +  Create an add-on object for the the wl_surface to let the compositor
     +  request fractional scales. If the given wl_surface already has a
     +  wp_fractional_scale_v1 object associated, the fractional_scale_exists
     +  protocol error is raised.
     +/
    WpFractionalScaleV1 getFractionalScale(WlSurface surface)
    {
        auto _pp = wl_proxy_marshal_constructor(
            proxy, getFractionalScaleOpCode, WpFractionalScaleV1.iface.native,
            null, surface.proxy
        );
        if (!_pp) return null;
        auto _p = wl_proxy_get_user_data(_pp);
        if (_p) return cast(WpFractionalScaleV1)_p;
        return new WpFractionalScaleV1(_pp);
    }
}

/++
 +  fractional scale interface to a wl_surface
 +
 +  An additional interface to a wl_surface object which allows the compositor
 +  to inform the client of the preferred scale.
 +/
final class WpFractionalScaleV1 : WlProxy
{
    /// Version of fractional_scale_v1.wp_fractional_scale_v1
    enum ver = 1;

    /// Build a WpFractionalScaleV1 from a native object.
    private this(wl_proxy* native)
    {
        super(native);
        wl_proxy_add_listener(proxy, cast(void_func_t*)&wl_d_wp_fractional_scale_v1_listener, cast(void*) this);
    }

    /// Interface object that creates WpFractionalScaleV1 objects.
    static @property immutable(WlProxyInterface) iface()
    {
        return wpFractionalScaleV1Iface;
    }

    /// Op-code of WpFractionalScaleV1.destroy.
    enum destroyOpCode = 0;

    /// Version of fractional_scale_v1 protocol introducing WpFractionalScaleV1.destroy.
    enum destroySinceVersion = 1;

    /// fractional_scale_v1 protocol version introducing WpFractionalScaleV1.onPreferredScale.
    enum onPreferredScaleSinceVersion = 1;

    /// Event delegate signature of WpFractionalScaleV1.onPreferredScale.
    alias OnPreferredScaleEventDg = void delegate(WpFractionalScaleV1 wpFractionalScaleV1,
                                                  uint scale);

    /++
     +  remove surface scale information for surface
     +
     +  Destroy the fractional scale object. When this object is destroyed,
     +  preferred_scale events will no longer be sent.
     +/
    void destroy()
    {
        wl_proxy_marshal(
            proxy, destroyOpCode
        );
        super.destroyNotify();
    }

    /++
     +  notify of new preferred scale
     +
     +  Notification of a new preferred scale for this surface that the
     +  compositor suggests that the client should use.
     +
     +  The sent scale is the numerator of a fraction with a denominator of 120.
     +/
    @property void onPreferredScale(OnPreferredScaleEventDg dg)
    {
        _onPreferredScale = dg;
    }

    private OnPreferredScaleEventDg _onPreferredScale;
}

private:

immutable WlProxyInterface wpFractionalScaleManagerV1Iface;
immutable WlProxyInterface wpFractionalScaleV1Iface;

immutable final class WpFractionalScaleManagerV1Iface : WlProxyInterface
{
    this(immutable wl_interface* native)
    {
        super(native);
    }
    override WlProxy makeProxy(wl_proxy* proxy) immutable
    {
        return new WpFractionalScaleManagerV1(proxy);
    }
}

immutable final class WpFractionalScaleV1Iface : WlProxyInterface
{
    this(immutable wl_interface* native)
    {
        super(native);
    }
    override WlProxy makeProxy(wl_proxy* proxy) immutable
    {
        return new WpFractionalScaleV1(proxy);
    }
}

immutable wl_interface[] wl_ifaces;

enum wpFractionalScaleManagerV1Index = 0;
enum wpFractionalScaleV1Index = 1;

shared static this()
{
    auto ifaces = new wl_interface[2];

    auto msgTypes = [
        null,
        &ifaces[wpFractionalScaleV1Index],
        cast(wl_interface*)WlSurface.iface.native,
    ];

    auto wp_fractional_scale_manager_v1_requests = [
        wl_message("destroy", "", &msgTypes[0]),
        wl_message("get_fractional_scale", "no", &msgTypes[1]),
    ];
    ifaces[wpFractionalScaleManagerV1Index].name = "wp_fractional_scale_manager_v1";
    ifaces[wpFractionalScaleManagerV1Index].version_ = 1;
    ifaces[wpFractionalScaleManagerV1Index].method_count = 2;
    ifaces[wpFractionalScaleManagerV1Index].methods = wp_fractional_scale_manager_v1_requests.ptr;

    auto wp_fractional_scale_v1_requests = [
        wl_message("destroy", "", &msgTypes[0]),
    ];
    auto wp_fractional_scale_v1_events = [
        wl_message("preferred_scale", "u", &msgTypes[0]),
    ];
    ifaces[wpFractionalScaleV1Index].name = "wp_fractional_scale_v1";
    ifaces[wpFractionalScaleV1Index].version_ = 1;
    ifaces[wpFractionalScaleV1Index].method_count = 1;
    ifaces[wpFractionalScaleV1Index].methods = wp_fractional_scale_v1_requests.ptr;
    ifaces[wpFractionalScaleV1Index].event_count = 1;
    ifaces[wpFractionalScaleV1Index].events = wp_fractional_scale_v1_events.ptr;

    import std.exception : assumeUnique;
    wl_ifaces = assumeUnique(ifaces);

    wpFractionalScaleManagerV1Iface = new immutable WpFractionalScaleManagerV1Iface( &wl_ifaces[wpFractionalScaleManagerV1Index] );
    wpFractionalScaleV1Iface = new immutable WpFractionalScaleV1Iface( &wl_ifaces[wpFractionalScaleV1Index] );
}

extern(C) nothrow
{

    struct wp_fractional_scale_v1_listener
    {
        void function(void* data,
                      wl_proxy* proxy,
                      uint scale) preferred_scale;
    }

    __gshared wl_d_wp_fractional_scale_v1_listener = wp_fractional_scale_v1_listener (&wl_d_on_wp_fractional_scale_v1_preferred_scale);

    void wl_d_on_wp_fractional_scale_v1_preferred_scale(void* data,
                                                        wl_proxy* proxy,
                                                        uint scale)
    {
        nothrowFnWrapper!({
            auto _p = data;
            assert(_p, "listener stub without the right userdata");
            auto _i = cast(WpFractionalScaleV1)_p;
            assert(_i, "listener stub proxy is not WpFractionalScaleV1");
            if (_i._onPreferredScale)
            {
                _i._onPreferredScale(_i, scale);
            }
        });
    }
}
