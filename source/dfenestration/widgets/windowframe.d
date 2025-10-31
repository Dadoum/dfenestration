module dfenestration.widgets.windowframe;

import dfenestration.widgets.aligner;
import dfenestration.widgets.bin;
import dfenestration.widgets.buttonbase;
import dfenestration.widgets.column;
import dfenestration.widgets.container;
import dfenestration.widgets.row;
import dfenestration.widgets.spacer;
import dfenestration.widgets.text;
import dfenestration.widgets.widget;
import dfenestration.widgets.windowhandle;

/++
 + A container emulating some window decoration if the backend doesn't provide it.
 +/
class WindowFrame: Bin {
    mixin State;

    Text titleText;
    Bin contentBin;

    uint additionalWidth;
    uint additionalHeight;

    this() {
        import dfenestration.widgets.test;

        super.content = new Column() [
            new WindowHandle() [
                new Row() [
                    // TODO: RTL
                    new Aligner()
                        .horizontalAlignment(Alignment.left)
                        .layoutProperties!Row(/+ expand +/ true) [
                        // TODO: add window icon
                        // TODO: finish EllipsisText
                        titleText = new Text("DFENESTRATION ERROR - SET THE TITLE FIRST")
                            .selectable(false),
                    ],
                    // new Spacer().layoutProperties!Row(/+ expand +/ true),
                    new class ButtonBase { override void onPress(Point location, MouseButton button) => window.minimize(); } [
                        new Test()
                            .size(Size(24, 24))
                    ],
                    new class ButtonBase { override void onPress(Point location, MouseButton button) { window.maximized = !window.maximized; } } [
                        new Test()
                            .size(Size(24, 24))
                    ],
                    new class ButtonBase { override void onPress(Point location, MouseButton button) => window.close(); } [
                        new Test()
                            .size(Size(24, 24))
                    ]
                ]
            ],
            contentBin = new Bin().layoutProperties!Column(/+ expand +/ true) [
                nullWidget
            ]
        ];
        uint _, __;
        preferredSize(_, additionalWidth, __, additionalHeight);

    }

    @StateGetter
    override Widget content() {
        return contentBin.content;
    }

    @StateSetter
    override WindowFrame content(Widget w) {
        contentBin.content = w;
        scheduleWindowSizeAllocation();
        return this;
    }

    string title() { return titleText.text; }
    void title(string value) { titleText.text = value; }
}
