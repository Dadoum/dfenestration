module dfenestration.types;

// TODO: implement that with a mixin for a tagged union with a custom case with Icon, but too lazy to do that now.

// Copied from Wayland, and since Wayland is light I hope everyone agreed to implement those icons.
enum CursorType {
    /// default cursor
    default_,
    /// a context menu is available for the object under the cursor
    contextMenu,
    /// help is available for the object under the cursor
    help,
    /// pointer that indicates a link or another interactive element
    pointer,
    /// progress indicator
    progress,
    /// program is busy, user should wait
    wait,
    /// a cell or set of cells may be selected
    cell,
    /// simple crosshair
    crosshair,
    /// text may be selected
    text,
    /// vertical text may be selected
    verticalText,
    /// drag-and-drop: alias of/shortcut to something is to be created
    alias_,
    /// drag-and-drop: something is to be copied
    copy,
    /// drag-and-drop: something is to be moved
    move,
    /// drag-and-drop: the dragged item cannot be dropped at the current cursor location
    noDrop,
    /// drag-and-drop: the requested action will not be carried out
    notAllowed,
    /// drag-and-drop: something can be grabbed
    grab,
    /// drag-and-drop: something is being grabbed
    grabbing,
    /// resizing: the east border is to be moved
    eResize,
    /// resizing: the north border is to be moved
    nResize,
    /// resizing: the north-east corner is to be moved
    neResize,
    /// resizing: the north-west corner is to be moved
    nwResize,
    /// resizing: the south border is to be moved
    sResize,
    /// resizing: the south-east corner is to be moved
    seResize,
    /// resizing: the south-west corner is to be moved
    swResize,
    /// resizing: the west border is to be moved
    wResize,
    /// resizing: the east and west borders are to be moved
    ewResize,
    /// resizing: the north and south borders are to be moved
    nsResize,
    /// resizing: the north-east and south-west corners are to be moved
    neswResize,
    /// resizing: the north-west and south-east corners are to be moved
    nwseResize,
    /// resizing: that the item/column can be resized horizontally
    colResize,
    /// resizing: that the item/row can be resized vertically
    rowResize,
    /// something can be scrolled in any direction
    allScroll,
    /// something can be zoomed in
    zoomIn,
    /// something can be zoomed out
    zoomOut,
    // @Pixbuf custom
}

enum MouseButton {
    left = 0,
    right = 1,
    middle = 2,
    forward = 3,
    back = 4,
    unknown = -1
}
