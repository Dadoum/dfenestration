import std.logger;

import dfenestration.widgets.aligner;
import dfenestration.widgets.button;
import dfenestration.widgets.column;
import dfenestration.widgets.test;
import dfenestration.widgets.text;
import dfenestration.widgets.window;
import dfenestration.primitives;

int main() {
	(cast() sharedLog).logLevel = LogLevel.trace;

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

					new Button()
						.pressed((_) => info("Click registered!"))
					[
                        new Aligner()
                        [
                            new Text("Hello!!")
                        ]
					]
				]
			],
		];

    version (Wayland) {
        // force client-side decorations
        import dfenestration.backends.wayland;
        if (auto wayland = cast(WaylandBackend) window.backend) {
            wayland.xdgDecorationManager = null;
            wayland.kdeDecorationManager = null;
        }
    }

	return window.run();
}

/+ Some test code:


    auto childWin =
        new class Window { override void onCloseRequest() { this.hide(); } }
            .title("Hello")
            .size(Size(200, 200)) [
            new Test()
        ];
    childWin.backendWindow.parent = window.backendWindow;
    window.show();
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
