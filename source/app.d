import std.logger;

import dfenestration.widgets.widget;
import dfenestration.widgets.column;
import dfenestration.widgets.container;
import dfenestration.widgets.test;
import dfenestration.widgets.text;
import dfenestration.widgets.window;
import dfenestration.widgets.windowhandle;
import dfenestration.primitives;

int main() {
	import std.logger;
	(cast() sharedLog).logLevel = LogLevel.trace;

	import dfenestration.widgets.aligner;
	import dfenestration.widgets.button;

	auto window =
		new Window()
			.title("Dfenestration example")
		[
			new Aligner()
			[
				new Column()
					.spacing(8)
				[
					new Test()
						.size(Size(200, 200))
						.naturalSize(Size(300, 300)),

					new class Button { override void onPress(Point, MouseButton) { info("Click registered!"); } }
					[
						new Test()
							.size(Size(24, 24))
					]
				]
			],
		];

	// force client-side decorations
	import dfenestration.backends.wayland;
	if (auto wayland = cast(WaylandBackend) window.backend) {
		wayland.xdgDecorationManager = null;
		wayland.kdeDecorationManager = null;
	}

	return window.run();
}

/+ Some test code:


	auto childWin = new Window().title("Hello") [
		new Test()
	];
	childWin.backendWindow.parent = window.backendWindow;
	childWin.show();

	import std.datetime;
	import std.logger;
	info("wait ", __LINE__);
	window.backend.planCallback(MonoTime.currTime() + 1.seconds, () => info("Hello 1 secs"));
	info("wait ", __LINE__);
	window.backend.planCallback(MonoTime.currTime() + 3.seconds, () => info("Hello 3 secs"));
	info("wait ", __LINE__);
	window.backend.planCallback(MonoTime.currTime() + 2.seconds, () => info("Hello 2 secs"));
	info("wait ", __LINE__);
	window.backend.planCallback(MonoTime.currTime() + 5.seconds, () => info("Hello 5 secs"));
	info("wait ", __LINE__);
	window.backend.planCallback(MonoTime.currTime() + 2.seconds, () => info("Hello 2 secs"));

+/
