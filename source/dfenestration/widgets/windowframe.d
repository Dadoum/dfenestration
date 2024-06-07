module dfenestration.widgets.windowframe;

import dfenestration.widgets.bin;
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

    this() {
        import dfenestration.widgets.test;;
        super.content = new Column() [
            new WindowHandle() [
                new Row() [
                    // TODO: use EllipsisText
                    titleText = new Text("DEVELOPER ERROR - SET THE TITLE FIRST").layoutProperties!Row(/+ expand +/ true),
                    // new Spacer().layoutProperties!Row(/+ expand +/ true),
                    new Test().size(Size(24, 24))
                ]
            ],
            contentBin = new Bin().layoutProperties!Column(/+ expand +/ true)[
                nullWidget
            ]
        ];
    }

    override Widget content() {
        return contentBin.content;
    }

    override void content(Widget w) {
        contentBin.content = w;
    }

    override void draw(Context context) {
        // context.sourceRgb(1, 1, 1);
        // context.rectangle(0, 0, allocation.size.tupleof);
        // context.fill();
    }

    string title() { return titleText.text; }
    void title(string value) { titleText.text = value; }
}
