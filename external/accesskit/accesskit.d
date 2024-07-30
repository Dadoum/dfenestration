module accesskit;
/**
 * Copyright 2023 The AccessKit Authors. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (found in
 * the LICENSE-APACHE file) or the MIT license (found in
 * the LICENSE-MIT file), at your option.
 */

import core.stdc.config;

extern (C):

/**
 * An action to be taken on an accessibility node.
 *
 * In contrast to [`DefaultActionVerb`], these describe what happens to the
 * object, e.g. "focus".
 */
enum accesskit_action
{
    // __cplusplus

    /**
     * Do the default action for an object, typically this means "click".
     */
    default_ = 0,
    focus = 1,
    blur = 2,
    collapse = 3,
    expand = 4,
    /**
     * Requires [`ActionRequest::data`] to be set to [`ActionData::CustomAction`].
     */
    customAction = 5,
    /**
     * Decrement a numeric value by one step.
     */
    decrement = 6,
    /**
     * Increment a numeric value by one step.
     */
    increment = 7,
    hideTooltip = 8,
    showTooltip = 9,
    /**
     * Delete any selected text in the control's text value and
     * insert the specified value in its place, like when typing or pasting.
     * Requires [`ActionRequest::data`] to be set to [`ActionData::Value`].
     */
    replaceSelectedText = 10,
    scrollBackward = 11,
    scrollDown = 12,
    scrollForward = 13,
    scrollLeft = 14,
    scrollRight = 15,
    scrollUp = 16,
    /**
     * Scroll any scrollable containers to make the target object visible
     * on the screen.  Optionally set [`ActionRequest::data`] to
     * [`ActionData::ScrollTargetRect`].
     */
    scrollIntoView = 17,
    /**
     * Scroll the given object to a specified point in the tree's container
     * (e.g. window). Requires [`ActionRequest::data`] to be set to
     * [`ActionData::ScrollToPoint`].
     */
    scrollToPoint = 18,
    /**
     * Requires [`ActionRequest::data`] to be set to
     * [`ActionData::SetScrollOffset`].
     */
    setScrollOffset = 19,
    /**
     * Requires [`ActionRequest::data`] to be set to
     * [`ActionData::SetTextSelection`].
     */
    setTextSelection = 20,
    /**
     * Don't focus this node, but set it as the sequential focus navigation
     * starting point, so that pressing Tab moves to the next element
     * following this one, for example.
     */
    setSequentialFocusNavigationStartingPoint = 21,
    /**
     * Replace thescaling value of the control with the specified value and
     * reset the selection, if applicable. Requires [`ActionRequest::data`]
     * to be set to [`ActionData::Value`] or [`ActionData::NumericValue`].
     */
    setValue = 22,
    showContextMenu = 23
}

alias accesskit_action = ubyte;
// __cplusplus

enum accesskit_aria_current
{
    // __cplusplus

    false_ = 0,
    true_ = 1,
    page = 2,
    step = 3,
    location = 4,
    date = 5,
    time = 6
}

alias accesskit_aria_current = ubyte;
// __cplusplus

enum accesskit_auto_complete
{
    // __cplusplus

    inline = 0,
    list = 1,
    both = 2
}

alias accesskit_auto_complete = ubyte;
// __cplusplus

enum accesskit_checked
{
    // __cplusplus

    false_ = 0,
    true_ = 1,
    mixed = 2
}

alias accesskit_checked = ubyte;
// __cplusplus

/**
 * Describes the action that will be performed on a given node when
 * executing the default action, which is a click.
 *
 * In contrast to [`Action`], these describe what the user can do on the
 * object, e.g. "press", not what happens to the object as a result.
 * Only one verb can be used at a time to describe the default action.
 */
enum accesskit_default_action_verb
{
    // __cplusplus

    click = 0,
    focus = 1,
    check = 2,
    uncheck = 3,
    /**
     * A click will be performed on one of the node's ancestors.
     * This happens when the node itself is not clickable, but one of its
     * ancestors has click handlers attached which are able to capture the click
     * as it bubbles up.
     */
    clickAncestor = 4,
    jump = 5,
    open = 6,
    press = 7,
    select = 8,
    unselect = 9
}

alias accesskit_default_action_verb = ubyte;
// __cplusplus

enum accesskit_has_popup
{
    // __cplusplus

    true_ = 0,
    menu = 1,
    listbox = 2,
    tree = 3,
    grid = 4,
    dialog = 5
}

alias accesskit_has_popup = ubyte;
// __cplusplus

/**
 * Indicates if a form control has invalid input or if a web DOM element has an
 * [`aria-invalid`] attribute.
 *
 * [`aria-invalid`]: https://www.w3.org/TR/wai-aria-1.1/#aria-invalid
 */
enum accesskit_invalid
{
    // __cplusplus

    true_ = 0,
    grammar = 1,
    spelling = 2
}

alias accesskit_invalid = ubyte;
// __cplusplus

enum accesskit_list_style
{
    // __cplusplus

    circle = 0,
    disc = 1,
    image = 2,
    numeric = 3,
    square = 4,
    /**
     * Language specific ordering (alpha, roman, cjk-ideographic, etc...)
     */
    other = 5
}

alias accesskit_list_style = ubyte;
// __cplusplus

enum accesskit_live
{
    // __cplusplus

    off = 0,
    polite = 1,
    assertive = 2
}

alias accesskit_live = ubyte;
// __cplusplus

enum accesskit_orientation
{
    // __cplusplus

    /**
     * E.g. most toolbars and separators.
     */
    horizontal = 0,
    /**
     * E.g. menu or combo box.
     */
    vertical = 1
}

alias accesskit_orientation = ubyte;
// __cplusplus

/**
 * The type of an accessibility node.
 *
 * The majority of these roles come from the ARIA specification. Reference
 * the latest draft for proper usage.
 *
 * Like the AccessKit schema as a whole, this list is largely taken
 * from Chromium. However, unlike Chromium's alphabetized list, this list
 * is ordered roughly by expected usage frequency (with the notable exception
 * of [`Role::Unknown`]). This is more efficient in serialization formats
 * where integers use a variable-length encoding.
 */
enum accesskit_role
{
    // __cplusplus

    unknown = 0,
    inlineTextBox = 1,
    cell = 2,
    staticText = 3,
    image = 4,
    link = 5,
    row = 6,
    listItem = 7,
    /**
     * Contains the bullet, number, or other marker for a list item.
     */
    listMarker = 8,
    treeItem = 9,
    listBoxOption = 10,
    menuItem = 11,
    menuListOption = 12,
    paragraph = 13,
    /**
     * A generic container that should be ignored by assistive technologies
     * and filtered out of platform accessibility trees. Equivalent to the ARIA
     * `none` or `presentation` role, or to an HTML `div` with no role.
     */
    genericContainer = 14,
    checkBox = 15,
    radioButton = 16,
    textInput = 17,
    button = 18,
    defaultButton = 19,
    pane = 20,
    rowHeader = 21,
    columnHeader = 22,
    column = 23,
    rowGroup = 24,
    list = 25,
    table = 26,
    tableHeaderContainer = 27,
    layoutTableCell = 28,
    layoutTableRow = 29,
    layoutTable = 30,
    switch_ = 31,
    toggleButton = 32,
    menu = 33,
    multilineTextInput = 34,
    searchInput = 35,
    dateInput = 36,
    dateTimeInput = 37,
    weekInput = 38,
    monthInput = 39,
    timeInput = 40,
    emailInput = 41,
    numberInput = 42,
    passwordInput = 43,
    phoneNumberInput = 44,
    urlInput = 45,
    abbr = 46,
    alert = 47,
    alertDialog = 48,
    application = 49,
    article = 50,
    audio = 51,
    banner = 52,
    blockquote = 53,
    canvas = 54,
    caption = 55,
    caret = 56,
    code = 57,
    colorWell = 58,
    comboBox = 59,
    editableComboBox = 60,
    complementary = 61,
    comment = 62,
    contentDeletion = 63,
    contentInsertion = 64,
    contentInfo = 65,
    definition = 66,
    descriptionList = 67,
    descriptionListDetail = 68,
    descriptionListTerm = 69,
    details = 70,
    dialog = 71,
    directory = 72,
    disclosureTriangle = 73,
    document = 74,
    embeddedObject = 75,
    emphasis = 76,
    feed = 77,
    figureCaption = 78,
    figure = 79,
    footer = 80,
    footerAsNonLandmark = 81,
    form = 82,
    grid = 83,
    group = 84,
    header = 85,
    headerAsNonLandmark = 86,
    heading = 87,
    iframe = 88,
    iframePresentational = 89,
    imeCandidate = 90,
    keyboard = 91,
    legend = 92,
    lineBreak = 93,
    listBox = 94,
    log = 95,
    main = 96,
    mark = 97,
    marquee = 98,
    math = 99,
    menuBar = 100,
    menuItemCheckBox = 101,
    menuItemRadio = 102,
    menuListPopup = 103,
    meter = 104,
    navigation = 105,
    note = 106,
    pluginObject = 107,
    portal = 108,
    pre = 109,
    progressIndicator = 110,
    radioGroup = 111,
    region = 112,
    rootWebArea = 113,
    ruby = 114,
    rubyAnnotation = 115,
    scrollBar = 116,
    scrollView = 117,
    search = 118,
    section = 119,
    slider = 120,
    spinButton = 121,
    splitter = 122,
    status = 123,
    strong = 124,
    suggestion = 125,
    svgRoot = 126,
    tab = 127,
    tabList = 128,
    tabPanel = 129,
    term = 130,
    time = 131,
    timer = 132,
    titleBar = 133,
    toolbar = 134,
    tooltip = 135,
    tree = 136,
    treeGrid = 137,
    video = 138,
    webView = 139,
    window = 140,
    pdfActionableHighlight = 141,
    pdfRoot = 142,
    graphicsDocument = 143,
    graphicsObject = 144,
    graphicsSymbol = 145,
    docAbstract = 146,
    docAcknowledgements = 147,
    docAfterword = 148,
    docAppendix = 149,
    docBackLink = 150,
    docBiblioEntry = 151,
    docBibliography = 152,
    docBiblioRef = 153,
    docChapter = 154,
    docColophon = 155,
    docConclusion = 156,
    docCover = 157,
    docCredit = 158,
    docCredits = 159,
    docDedication = 160,
    docEndnote = 161,
    docEndnotes = 162,
    docEpigraph = 163,
    docEpilogue = 164,
    docErrata = 165,
    docExample = 166,
    docFootnote = 167,
    docForeword = 168,
    docGlossary = 169,
    docGlossRef = 170,
    docIndex = 171,
    docIntroduction = 172,
    docNoteRef = 173,
    docNotice = 174,
    docPageBreak = 175,
    docPageFooter = 176,
    docPageHeader = 177,
    docPageList = 178,
    docPart = 179,
    docPreface = 180,
    docPrologue = 181,
    docPullquote = 182,
    docQna = 183,
    docSubtitle = 184,
    docTip = 185,
    docToc = 186,
    /**
     * Behaves similar to an ARIA grid but is primarily used by Chromium's
     * `TableView` and its subclasses, so they can be exposed correctly
     * on certain platforms.
     */
    listGrid = 187,
    /**
     * This is just like a multi-line document, but signals that assistive
     * technologies should implement behavior specific to a VT-100-style
     * terminal.
     */
    terminal = 188
}

alias accesskit_role = ubyte;
// __cplusplus

enum accesskit_sort_direction
{
    // __cplusplus

    unsorted = 0,
    ascending = 1,
    descending = 2,
    other = 3
}

alias accesskit_sort_direction = ubyte;
// __cplusplus

enum accesskit_text_align
{
    // __cplusplus

    left = 0,
    right = 1,
    center = 2,
    justify = 3
}

alias accesskit_text_align = ubyte;
// __cplusplus

enum accesskit_text_decoration
{
    // __cplusplus

    solid = 0,
    dotted = 1,
    dashed = 2,
    double_ = 3,
    wavy = 4
}

alias accesskit_text_decoration = ubyte;
// __cplusplus

enum accesskit_text_direction
{
    // __cplusplus

    leftToRight = 0,
    rightToLeft = 1,
    topToBottom = 2,
    bottomToTop = 3
}

alias accesskit_text_direction = ubyte;
// __cplusplus

enum accesskit_vertical_offset
{
    // __cplusplus

    subscript = 0,
    superscript = 1
}

alias accesskit_vertical_offset = ubyte;
// __cplusplus

struct accesskit_action_handler;

struct accesskit_node;

struct accesskit_node_builder;

struct accesskit_node_class_set;

struct accesskit_tree;

struct accesskit_tree_update;

struct accesskit_unix_adapter;

alias accesskit_node_id = c_ulong;

struct accesskit_node_ids
{
    size_t length;
    const(accesskit_node_id)* values;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_node_id
{
    bool has_value;
    accesskit_node_id value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_double
{
    bool has_value;
    double value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_index
{
    bool has_value;
    size_t value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_color
{
    bool has_value;
    uint value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_text_decoration
{
    bool has_value;
    accesskit_text_decoration value;
}

struct accesskit_lengths
{
    size_t length;
    const(ubyte)* values;
}

struct accesskit_opt_coords
{
    bool has_value;
    size_t length;
    const(float)* values;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_bool
{
    bool has_value;
    bool value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_invalid
{
    bool has_value;
    accesskit_invalid value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_checked
{
    bool has_value;
    accesskit_checked value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_live
{
    bool has_value;
    accesskit_live value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_default_action_verb
{
    bool has_value;
    accesskit_default_action_verb value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_text_direction
{
    bool has_value;
    accesskit_text_direction value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_orientation
{
    bool has_value;
    accesskit_orientation value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_sort_direction
{
    bool has_value;
    accesskit_sort_direction value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_aria_current
{
    bool has_value;
    accesskit_aria_current value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_auto_complete
{
    bool has_value;
    accesskit_auto_complete value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_has_popup
{
    bool has_value;
    accesskit_has_popup value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_list_style
{
    bool has_value;
    accesskit_list_style value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_text_align
{
    bool has_value;
    accesskit_text_align value;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_vertical_offset
{
    bool has_value;
    accesskit_vertical_offset value;
}

/**
 * A 2D affine transform. Derived from
 * [kurbo](https://github.com/linebender/kurbo).
 */
struct accesskit_affine
{
    double[6] _0;
}

/**
 * A rectangle. Derived from [kurbo](https://github.com/linebender/kurbo).
 */
struct accesskit_rect
{
    /**
     * The minimum x coordinate (left edge).
     */
    double x0;
    /**
     * The minimum y coordinate (top edge in y-down spaces).
     */
    double y0;
    /**
     * The maximum x coordinate (right edge).
     */
    double x1;
    /**
     * The maximum y coordinate (bottom edge in y-down spaces).
     */
    double y1;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_rect
{
    bool has_value;
    accesskit_rect value;
}

struct accesskit_text_position
{
    accesskit_node_id node;
    size_t character_index;
}

struct accesskit_text_selection
{
    accesskit_text_position anchor;
    accesskit_text_position focus;
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_text_selection
{
    bool has_value;
    accesskit_text_selection value;
}

/**
 * Use `accesskit_custom_action_new` to create this struct. Do not reallocate
 * `description`.
 *
 * When you get this struct, you are responsible for freeing `description`.
 */
struct accesskit_custom_action
{
    int id;
    char* description;
}

struct accesskit_custom_actions
{
    size_t length;
    accesskit_custom_action* values;
}

/**
 * A 2D point. Derived from [kurbo](https://github.com/linebender/kurbo).
 */
struct accesskit_point
{
    /**
     * The x coordinate.
     */
    double x;
    /**
     * The y coordinate.
     */
    double y;
}

enum accesskit_action_data_Tag
{
    customAction = 0,
    value = 1,
    numericValue = 2,
    scrollTargetRect = 3,
    scrollToPoint = 4,
    setScrollOffset = 5,
    setTextSelection = 6
}

struct accesskit_action_data
{
    accesskit_action_data_Tag tag;

    union
    {
        struct
        {
            int custom_action;
        }

        struct
        {
            char* value;
        }

        struct
        {
            double numeric_value;
        }

        struct
        {
            accesskit_rect scroll_target_rect;
        }

        struct
        {
            accesskit_point scroll_to_point;
        }

        struct
        {
            accesskit_point set_scroll_offset;
        }

        struct
        {
            accesskit_text_selection set_text_selection;
        }
    }
}

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */
struct accesskit_opt_action_data
{
    bool has_value;
    accesskit_action_data value;
}

struct accesskit_action_request
{
    accesskit_action action;
    accesskit_node_id target;
    accesskit_opt_action_data data;
}

alias accesskit_action_handler_callback = void function (
    const(accesskit_action_request)* request,
    void* userdata);

/**
 * A 2D vector. Derived from [kurbo](https://github.com/linebender/kurbo).
 *
 * This is intended primarily for a vector in the mathematical sense,
 * but it can be interpreted as a translation, and converted to and
 * from a point (vector relative to the origin) and size.
 */
struct accesskit_vec2
{
    /**
     * The x-coordinate.
     */
    double x;
    /**
     * The y-coordinate.
     */
    double y;
}

/**
 * A 2D size. Derived from [kurbo](https://github.com/linebender/kurbo).
 */
struct accesskit_size
{
    /**
     * The width.
     */
    double width;
    /**
     * The height.
     */
    double height;
}

alias accesskit_tree_update_factory_userdata = void*;

/**
 * This function can't return a null pointer. Ownership of the returned value
 * will be transferred to the caller.
 */
alias accesskit_tree_update_factory = accesskit_tree_update* function (
    accesskit_tree_update_factory_userdata);

/**
 * Represents an optional value.
 *
 * If `has_value` is false, do not read the `value` field.
 */

// __cplusplus

accesskit_node_class_set* accesskit_node_class_set_new ();

void accesskit_node_class_set_free (accesskit_node_class_set* set);

void accesskit_node_free (accesskit_node* node);

accesskit_role accesskit_node_role (const(accesskit_node)* node);

accesskit_role accesskit_node_builder_role (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_role (
    accesskit_node_builder* builder,
    accesskit_role value);

bool accesskit_node_supports_action (
    const(accesskit_node)* node,
    accesskit_action action);

bool accesskit_node_builder_supports_action (
    const(accesskit_node_builder)* builder,
    accesskit_action action);

void accesskit_node_builder_add_action (
    accesskit_node_builder* builder,
    accesskit_action action);

void accesskit_node_builder_remove_action (
    accesskit_node_builder* builder,
    accesskit_action action);

void accesskit_node_builder_clear_actions (accesskit_node_builder* builder);

bool accesskit_node_is_hovered (const(accesskit_node)* node);

bool accesskit_node_is_hidden (const(accesskit_node)* node);

bool accesskit_node_is_linked (const(accesskit_node)* node);

bool accesskit_node_is_multiselectable (const(accesskit_node)* node);

bool accesskit_node_is_required (const(accesskit_node)* node);

bool accesskit_node_is_visited (const(accesskit_node)* node);

bool accesskit_node_is_busy (const(accesskit_node)* node);

bool accesskit_node_is_live_atomic (const(accesskit_node)* node);

bool accesskit_node_is_modal (const(accesskit_node)* node);

bool accesskit_node_is_touch_transparent (const(accesskit_node)* node);

bool accesskit_node_is_read_only (const(accesskit_node)* node);

bool accesskit_node_is_disabled (const(accesskit_node)* node);

bool accesskit_node_is_bold (const(accesskit_node)* node);

bool accesskit_node_is_italic (const(accesskit_node)* node);

bool accesskit_node_clips_children (const(accesskit_node)* node);

bool accesskit_node_is_line_breaking_object (const(accesskit_node)* node);

bool accesskit_node_is_page_breaking_object (const(accesskit_node)* node);

bool accesskit_node_is_spelling_error (const(accesskit_node)* node);

bool accesskit_node_is_grammar_error (const(accesskit_node)* node);

bool accesskit_node_is_search_match (const(accesskit_node)* node);

bool accesskit_node_is_suggestion (const(accesskit_node)* node);

bool accesskit_node_builder_is_hovered (const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_hovered (accesskit_node_builder* builder);

void accesskit_node_builder_clear_hovered (accesskit_node_builder* builder);

bool accesskit_node_builder_is_hidden (const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_hidden (accesskit_node_builder* builder);

void accesskit_node_builder_clear_hidden (accesskit_node_builder* builder);

bool accesskit_node_builder_is_linked (const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_linked (accesskit_node_builder* builder);

void accesskit_node_builder_clear_linked (accesskit_node_builder* builder);

bool accesskit_node_builder_is_multiselectable (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_multiselectable (
    accesskit_node_builder* builder);

void accesskit_node_builder_clear_multiselectable (
    accesskit_node_builder* builder);

bool accesskit_node_builder_is_required (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_required (accesskit_node_builder* builder);

void accesskit_node_builder_clear_required (accesskit_node_builder* builder);

bool accesskit_node_builder_is_visited (const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_visited (accesskit_node_builder* builder);

void accesskit_node_builder_clear_visited (accesskit_node_builder* builder);

bool accesskit_node_builder_is_busy (const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_busy (accesskit_node_builder* builder);

void accesskit_node_builder_clear_busy (accesskit_node_builder* builder);

bool accesskit_node_builder_is_live_atomic (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_live_atomic (accesskit_node_builder* builder);

void accesskit_node_builder_clear_live_atomic (accesskit_node_builder* builder);

bool accesskit_node_builder_is_modal (const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_modal (accesskit_node_builder* builder);

void accesskit_node_builder_clear_modal (accesskit_node_builder* builder);

bool accesskit_node_builder_is_touch_transparent (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_touch_transparent (
    accesskit_node_builder* builder);

void accesskit_node_builder_clear_touch_transparent (
    accesskit_node_builder* builder);

bool accesskit_node_builder_is_read_only (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_read_only (accesskit_node_builder* builder);

void accesskit_node_builder_clear_read_only (accesskit_node_builder* builder);

bool accesskit_node_builder_is_disabled (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_disabled (accesskit_node_builder* builder);

void accesskit_node_builder_clear_disabled (accesskit_node_builder* builder);

bool accesskit_node_builder_is_bold (const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_bold (accesskit_node_builder* builder);

void accesskit_node_builder_clear_bold (accesskit_node_builder* builder);

bool accesskit_node_builder_is_italic (const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_italic (accesskit_node_builder* builder);

void accesskit_node_builder_clear_italic (accesskit_node_builder* builder);

bool accesskit_node_builder_clips_children (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_clips_children (
    accesskit_node_builder* builder);

void accesskit_node_builder_clear_clips_children (
    accesskit_node_builder* builder);

bool accesskit_node_builder_is_line_breaking_object (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_is_line_breaking_object (
    accesskit_node_builder* builder);

void accesskit_node_builder_clear_is_line_breaking_object (
    accesskit_node_builder* builder);

bool accesskit_node_builder_is_page_breaking_object (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_is_page_breaking_object (
    accesskit_node_builder* builder);

void accesskit_node_builder_clear_is_page_breaking_object (
    accesskit_node_builder* builder);

bool accesskit_node_builder_is_spelling_error (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_is_spelling_error (
    accesskit_node_builder* builder);

void accesskit_node_builder_clear_is_spelling_error (
    accesskit_node_builder* builder);

bool accesskit_node_builder_is_grammar_error (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_is_grammar_error (
    accesskit_node_builder* builder);

void accesskit_node_builder_clear_is_grammar_error (
    accesskit_node_builder* builder);

bool accesskit_node_builder_is_search_match (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_is_search_match (
    accesskit_node_builder* builder);

void accesskit_node_builder_clear_is_search_match (
    accesskit_node_builder* builder);

bool accesskit_node_builder_is_suggestion (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_is_suggestion (accesskit_node_builder* builder);

void accesskit_node_builder_clear_is_suggestion (
    accesskit_node_builder* builder);

accesskit_node_ids accesskit_node_children (const(accesskit_node)* node);

accesskit_node_ids accesskit_node_builder_children (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_children (
    accesskit_node_builder* builder,
    size_t length,
    const(accesskit_node_id)* values);

void accesskit_node_builder_push_child (
    accesskit_node_builder* builder,
    accesskit_node_id item);

void accesskit_node_builder_clear_children (accesskit_node_builder* builder);

accesskit_node_ids accesskit_node_controls (const(accesskit_node)* node);

accesskit_node_ids accesskit_node_builder_controls (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_controls (
    accesskit_node_builder* builder,
    size_t length,
    const(accesskit_node_id)* values);

void accesskit_node_builder_push_controlled (
    accesskit_node_builder* builder,
    accesskit_node_id item);

void accesskit_node_builder_clear_controls (accesskit_node_builder* builder);

accesskit_node_ids accesskit_node_details (const(accesskit_node)* node);

accesskit_node_ids accesskit_node_builder_details (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_details (
    accesskit_node_builder* builder,
    size_t length,
    const(accesskit_node_id)* values);

void accesskit_node_builder_push_detail (
    accesskit_node_builder* builder,
    accesskit_node_id item);

void accesskit_node_builder_clear_details (accesskit_node_builder* builder);

accesskit_node_ids accesskit_node_described_by (const(accesskit_node)* node);

accesskit_node_ids accesskit_node_builder_described_by (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_described_by (
    accesskit_node_builder* builder,
    size_t length,
    const(accesskit_node_id)* values);

void accesskit_node_builder_push_described_by (
    accesskit_node_builder* builder,
    accesskit_node_id item);

void accesskit_node_builder_clear_described_by (
    accesskit_node_builder* builder);

accesskit_node_ids accesskit_node_flow_to (const(accesskit_node)* node);

accesskit_node_ids accesskit_node_builder_flow_to (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_flow_to (
    accesskit_node_builder* builder,
    size_t length,
    const(accesskit_node_id)* values);

void accesskit_node_builder_push_flow_to (
    accesskit_node_builder* builder,
    accesskit_node_id item);

void accesskit_node_builder_clear_flow_to (accesskit_node_builder* builder);

accesskit_node_ids accesskit_node_labelled_by (const(accesskit_node)* node);

accesskit_node_ids accesskit_node_builder_labelled_by (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_labelled_by (
    accesskit_node_builder* builder,
    size_t length,
    const(accesskit_node_id)* values);

void accesskit_node_builder_push_labelled_by (
    accesskit_node_builder* builder,
    accesskit_node_id item);

void accesskit_node_builder_clear_labelled_by (accesskit_node_builder* builder);

accesskit_node_ids accesskit_node_radio_group (const(accesskit_node)* node);

accesskit_node_ids accesskit_node_builder_radio_group (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_radio_group (
    accesskit_node_builder* builder,
    size_t length,
    const(accesskit_node_id)* values);

void accesskit_node_builder_push_to_radio_group (
    accesskit_node_builder* builder,
    accesskit_node_id item);

void accesskit_node_builder_clear_radio_group (accesskit_node_builder* builder);

accesskit_opt_node_id accesskit_node_active_descendant (
    const(accesskit_node)* node);

accesskit_opt_node_id accesskit_node_builder_active_descendant (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_active_descendant (
    accesskit_node_builder* builder,
    accesskit_node_id value);

void accesskit_node_builder_clear_active_descendant (
    accesskit_node_builder* builder);

accesskit_opt_node_id accesskit_node_error_message (
    const(accesskit_node)* node);

accesskit_opt_node_id accesskit_node_builder_error_message (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_error_message (
    accesskit_node_builder* builder,
    accesskit_node_id value);

void accesskit_node_builder_clear_error_message (
    accesskit_node_builder* builder);

accesskit_opt_node_id accesskit_node_in_page_link_target (
    const(accesskit_node)* node);

accesskit_opt_node_id accesskit_node_builder_in_page_link_target (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_in_page_link_target (
    accesskit_node_builder* builder,
    accesskit_node_id value);

void accesskit_node_builder_clear_in_page_link_target (
    accesskit_node_builder* builder);

accesskit_opt_node_id accesskit_node_member_of (const(accesskit_node)* node);

accesskit_opt_node_id accesskit_node_builder_member_of (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_member_of (
    accesskit_node_builder* builder,
    accesskit_node_id value);

void accesskit_node_builder_clear_member_of (accesskit_node_builder* builder);

accesskit_opt_node_id accesskit_node_next_on_line (const(accesskit_node)* node);

accesskit_opt_node_id accesskit_node_builder_next_on_line (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_next_on_line (
    accesskit_node_builder* builder,
    accesskit_node_id value);

void accesskit_node_builder_clear_next_on_line (
    accesskit_node_builder* builder);

accesskit_opt_node_id accesskit_node_previous_on_line (
    const(accesskit_node)* node);

accesskit_opt_node_id accesskit_node_builder_previous_on_line (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_previous_on_line (
    accesskit_node_builder* builder,
    accesskit_node_id value);

void accesskit_node_builder_clear_previous_on_line (
    accesskit_node_builder* builder);

accesskit_opt_node_id accesskit_node_popup_for (const(accesskit_node)* node);

accesskit_opt_node_id accesskit_node_builder_popup_for (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_popup_for (
    accesskit_node_builder* builder,
    accesskit_node_id value);

void accesskit_node_builder_clear_popup_for (accesskit_node_builder* builder);

accesskit_opt_node_id accesskit_node_table_header (const(accesskit_node)* node);

accesskit_opt_node_id accesskit_node_builder_table_header (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_header (
    accesskit_node_builder* builder,
    accesskit_node_id value);

void accesskit_node_builder_clear_table_header (
    accesskit_node_builder* builder);

accesskit_opt_node_id accesskit_node_table_row_header (
    const(accesskit_node)* node);

accesskit_opt_node_id accesskit_node_builder_table_row_header (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_row_header (
    accesskit_node_builder* builder,
    accesskit_node_id value);

void accesskit_node_builder_clear_table_row_header (
    accesskit_node_builder* builder);

accesskit_opt_node_id accesskit_node_table_column_header (
    const(accesskit_node)* node);

accesskit_opt_node_id accesskit_node_builder_table_column_header (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_column_header (
    accesskit_node_builder* builder,
    accesskit_node_id value);

void accesskit_node_builder_clear_table_column_header (
    accesskit_node_builder* builder);

/**
 * Only call this function with a string that originated from AccessKit.
 */
void accesskit_string_free (char* string);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_name (const(accesskit_node)* node);

char* accesskit_node_description (const(accesskit_node)* node);

char* accesskit_node_value (const(accesskit_node)* node);

char* accesskit_node_access_key (const(accesskit_node)* node);

char* accesskit_node_class_name (const(accesskit_node)* node);

char* accesskit_node_font_family (const(accesskit_node)* node);

char* accesskit_node_html_tag (const(accesskit_node)* node);

char* accesskit_node_inner_html (const(accesskit_node)* node);

char* accesskit_node_keyboard_shortcut (const(accesskit_node)* node);

char* accesskit_node_language (const(accesskit_node)* node);

char* accesskit_node_placeholder (const(accesskit_node)* node);

char* accesskit_node_role_description (const(accesskit_node)* node);

char* accesskit_node_state_description (const(accesskit_node)* node);

char* accesskit_node_tooltip (const(accesskit_node)* node);

char* accesskit_node_url (const(accesskit_node)* node);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_name (const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_name (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_name (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_description (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_description (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_description (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_value (const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_value (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_value (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_access_key (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_access_key (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_access_key (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_class_name (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_class_name (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_class_name (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_font_family (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_font_family (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_font_family (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_html_tag (const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_html_tag (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_html_tag (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_inner_html (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_inner_html (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_inner_html (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_keyboard_shortcut (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_keyboard_shortcut (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_keyboard_shortcut (
    accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_language (const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_language (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_language (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_placeholder (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_placeholder (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_placeholder (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_role_description (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_role_description (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_role_description (
    accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_state_description (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_state_description (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_state_description (
    accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_tooltip (const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_tooltip (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_tooltip (accesskit_node_builder* builder);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_node_builder_url (const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing the memory pointed by `value`.
 */
void accesskit_node_builder_set_url (
    accesskit_node_builder* builder,
    const(char)* value);

void accesskit_node_builder_clear_url (accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_scroll_x (const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_scroll_x (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_scroll_x (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_scroll_x (accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_scroll_x_min (const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_scroll_x_min (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_scroll_x_min (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_scroll_x_min (
    accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_scroll_x_max (const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_scroll_x_max (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_scroll_x_max (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_scroll_x_max (
    accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_scroll_y (const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_scroll_y (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_scroll_y (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_scroll_y (accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_scroll_y_min (const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_scroll_y_min (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_scroll_y_min (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_scroll_y_min (
    accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_scroll_y_max (const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_scroll_y_max (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_scroll_y_max (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_scroll_y_max (
    accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_numeric_value (const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_numeric_value (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_numeric_value (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_numeric_value (
    accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_min_numeric_value (
    const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_min_numeric_value (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_min_numeric_value (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_min_numeric_value (
    accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_max_numeric_value (
    const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_max_numeric_value (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_max_numeric_value (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_max_numeric_value (
    accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_numeric_value_step (
    const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_numeric_value_step (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_numeric_value_step (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_numeric_value_step (
    accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_numeric_value_jump (
    const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_numeric_value_jump (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_numeric_value_jump (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_numeric_value_jump (
    accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_font_size (const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_font_size (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_font_size (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_font_size (accesskit_node_builder* builder);

accesskit_opt_double accesskit_node_font_weight (const(accesskit_node)* node);

accesskit_opt_double accesskit_node_builder_font_weight (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_font_weight (
    accesskit_node_builder* builder,
    double value);

void accesskit_node_builder_clear_font_weight (accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_table_row_count (
    const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_table_row_count (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_row_count (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_table_row_count (
    accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_table_column_count (
    const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_table_column_count (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_column_count (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_table_column_count (
    accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_table_row_index (
    const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_table_row_index (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_row_index (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_table_row_index (
    accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_table_column_index (
    const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_table_column_index (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_column_index (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_table_column_index (
    accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_table_cell_column_index (
    const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_table_cell_column_index (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_cell_column_index (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_table_cell_column_index (
    accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_table_cell_column_span (
    const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_table_cell_column_span (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_cell_column_span (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_table_cell_column_span (
    accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_table_cell_row_index (
    const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_table_cell_row_index (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_cell_row_index (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_table_cell_row_index (
    accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_table_cell_row_span (
    const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_table_cell_row_span (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_table_cell_row_span (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_table_cell_row_span (
    accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_hierarchical_level (
    const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_hierarchical_level (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_hierarchical_level (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_hierarchical_level (
    accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_size_of_set (const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_size_of_set (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_size_of_set (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_size_of_set (accesskit_node_builder* builder);

accesskit_opt_index accesskit_node_position_in_set (
    const(accesskit_node)* node);

accesskit_opt_index accesskit_node_builder_position_in_set (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_position_in_set (
    accesskit_node_builder* builder,
    size_t value);

void accesskit_node_builder_clear_position_in_set (
    accesskit_node_builder* builder);

accesskit_opt_color accesskit_node_color_value (const(accesskit_node)* node);

accesskit_opt_color accesskit_node_builder_color_value (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_color_value (
    accesskit_node_builder* builder,
    uint value);

void accesskit_node_builder_clear_color_value (accesskit_node_builder* builder);

accesskit_opt_color accesskit_node_background_color (
    const(accesskit_node)* node);

accesskit_opt_color accesskit_node_builder_background_color (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_background_color (
    accesskit_node_builder* builder,
    uint value);

void accesskit_node_builder_clear_background_color (
    accesskit_node_builder* builder);

accesskit_opt_color accesskit_node_foreground_color (
    const(accesskit_node)* node);

accesskit_opt_color accesskit_node_builder_foreground_color (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_foreground_color (
    accesskit_node_builder* builder,
    uint value);

void accesskit_node_builder_clear_foreground_color (
    accesskit_node_builder* builder);

accesskit_opt_text_decoration accesskit_node_overline (
    const(accesskit_node)* node);

accesskit_opt_text_decoration accesskit_node_builder_overline (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_overline (
    accesskit_node_builder* builder,
    accesskit_text_decoration value);

void accesskit_node_builder_clear_overline (accesskit_node_builder* builder);

accesskit_opt_text_decoration accesskit_node_strikethrough (
    const(accesskit_node)* node);

accesskit_opt_text_decoration accesskit_node_builder_strikethrough (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_strikethrough (
    accesskit_node_builder* builder,
    accesskit_text_decoration value);

void accesskit_node_builder_clear_strikethrough (
    accesskit_node_builder* builder);

accesskit_opt_text_decoration accesskit_node_underline (
    const(accesskit_node)* node);

accesskit_opt_text_decoration accesskit_node_builder_underline (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_underline (
    accesskit_node_builder* builder,
    accesskit_text_decoration value);

void accesskit_node_builder_clear_underline (accesskit_node_builder* builder);

accesskit_lengths accesskit_node_character_lengths (
    const(accesskit_node)* node);

accesskit_lengths accesskit_node_builder_character_lengths (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_character_lengths (
    accesskit_node_builder* builder,
    size_t length,
    const(ubyte)* values);

void accesskit_node_builder_clear_character_lengths (
    accesskit_node_builder* builder);

accesskit_lengths accesskit_node_word_lengths (const(accesskit_node)* node);

accesskit_lengths accesskit_node_builder_word_lengths (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_word_lengths (
    accesskit_node_builder* builder,
    size_t length,
    const(ubyte)* values);

void accesskit_node_builder_clear_word_lengths (
    accesskit_node_builder* builder);

accesskit_opt_coords accesskit_node_character_positions (
    const(accesskit_node)* node);

accesskit_opt_coords accesskit_node_builder_character_positions (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_character_positions (
    accesskit_node_builder* builder,
    size_t length,
    const(float)* values);

void accesskit_node_builder_clear_character_positions (
    accesskit_node_builder* builder);

accesskit_opt_coords accesskit_node_character_widths (
    const(accesskit_node)* node);

accesskit_opt_coords accesskit_node_builder_character_widths (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_character_widths (
    accesskit_node_builder* builder,
    size_t length,
    const(float)* values);

void accesskit_node_builder_clear_character_widths (
    accesskit_node_builder* builder);

accesskit_opt_bool accesskit_node_is_expanded (const(accesskit_node)* node);

accesskit_opt_bool accesskit_node_builder_is_expanded (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_expanded (
    accesskit_node_builder* builder,
    bool value);

void accesskit_node_builder_clear_expanded (accesskit_node_builder* builder);

accesskit_opt_bool accesskit_node_is_selected (const(accesskit_node)* node);

accesskit_opt_bool accesskit_node_builder_is_selected (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_selected (
    accesskit_node_builder* builder,
    bool value);

void accesskit_node_builder_clear_selected (accesskit_node_builder* builder);

accesskit_opt_invalid accesskit_node_invalid (const(accesskit_node)* node);

accesskit_opt_invalid accesskit_node_builder_invalid (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_invalid (
    accesskit_node_builder* builder,
    accesskit_invalid value);

void accesskit_node_builder_clear_invalid (accesskit_node_builder* builder);

accesskit_opt_checked accesskit_node_checked (const(accesskit_node)* node);

accesskit_opt_checked accesskit_node_builder_checked (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_checked (
    accesskit_node_builder* builder,
    accesskit_checked value);

void accesskit_node_builder_clear_checked (accesskit_node_builder* builder);

accesskit_opt_live accesskit_node_live (const(accesskit_node)* node);

accesskit_opt_live accesskit_node_builder_live (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_live (
    accesskit_node_builder* builder,
    accesskit_live value);

void accesskit_node_builder_clear_live (accesskit_node_builder* builder);

accesskit_opt_default_action_verb accesskit_node_default_action_verb (
    const(accesskit_node)* node);

accesskit_opt_default_action_verb accesskit_node_builder_default_action_verb (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_default_action_verb (
    accesskit_node_builder* builder,
    accesskit_default_action_verb value);

void accesskit_node_builder_clear_default_action_verb (
    accesskit_node_builder* builder);

accesskit_opt_text_direction accesskit_node_text_direction (
    const(accesskit_node)* node);

accesskit_opt_text_direction accesskit_node_builder_text_direction (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_text_direction (
    accesskit_node_builder* builder,
    accesskit_text_direction value);

void accesskit_node_builder_clear_text_direction (
    accesskit_node_builder* builder);

accesskit_opt_orientation accesskit_node_orientation (
    const(accesskit_node)* node);

accesskit_opt_orientation accesskit_node_builder_orientation (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_orientation (
    accesskit_node_builder* builder,
    accesskit_orientation value);

void accesskit_node_builder_clear_orientation (accesskit_node_builder* builder);

accesskit_opt_sort_direction accesskit_node_sort_direction (
    const(accesskit_node)* node);

accesskit_opt_sort_direction accesskit_node_builder_sort_direction (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_sort_direction (
    accesskit_node_builder* builder,
    accesskit_sort_direction value);

void accesskit_node_builder_clear_sort_direction (
    accesskit_node_builder* builder);

accesskit_opt_aria_current accesskit_node_aria_current (
    const(accesskit_node)* node);

accesskit_opt_aria_current accesskit_node_builder_aria_current (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_aria_current (
    accesskit_node_builder* builder,
    accesskit_aria_current value);

void accesskit_node_builder_clear_aria_current (
    accesskit_node_builder* builder);

accesskit_opt_auto_complete accesskit_node_auto_complete (
    const(accesskit_node)* node);

accesskit_opt_auto_complete accesskit_node_builder_auto_complete (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_auto_complete (
    accesskit_node_builder* builder,
    accesskit_auto_complete value);

void accesskit_node_builder_clear_auto_complete (
    accesskit_node_builder* builder);

accesskit_opt_has_popup accesskit_node_has_popup (const(accesskit_node)* node);

accesskit_opt_has_popup accesskit_node_builder_has_popup (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_has_popup (
    accesskit_node_builder* builder,
    accesskit_has_popup value);

void accesskit_node_builder_clear_has_popup (accesskit_node_builder* builder);

accesskit_opt_list_style accesskit_node_list_style (
    const(accesskit_node)* node);

accesskit_opt_list_style accesskit_node_builder_list_style (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_list_style (
    accesskit_node_builder* builder,
    accesskit_list_style value);

void accesskit_node_builder_clear_list_style (accesskit_node_builder* builder);

accesskit_opt_text_align accesskit_node_text_align (
    const(accesskit_node)* node);

accesskit_opt_text_align accesskit_node_builder_text_align (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_text_align (
    accesskit_node_builder* builder,
    accesskit_text_align value);

void accesskit_node_builder_clear_text_align (accesskit_node_builder* builder);

accesskit_opt_vertical_offset accesskit_node_vertical_offset (
    const(accesskit_node)* node);

accesskit_opt_vertical_offset accesskit_node_builder_vertical_offset (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_vertical_offset (
    accesskit_node_builder* builder,
    accesskit_vertical_offset value);

void accesskit_node_builder_clear_vertical_offset (
    accesskit_node_builder* builder);

const(accesskit_affine)* accesskit_node_transform (const(accesskit_node)* node);

const(accesskit_affine)* accesskit_node_builder_transform (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_transform (
    accesskit_node_builder* builder,
    accesskit_affine value);

void accesskit_node_builder_clear_transform (accesskit_node_builder* builder);

accesskit_opt_rect accesskit_node_bounds (const(accesskit_node)* node);

accesskit_opt_rect accesskit_node_builder_bounds (
    const(accesskit_node_builder)* builder);

void accesskit_node_builder_set_bounds (
    accesskit_node_builder* builder,
    accesskit_rect value);

void accesskit_node_builder_clear_bounds (accesskit_node_builder* builder);

accesskit_opt_text_selection accesskit_node_text_selection (
    const(accesskit_node)* node);

accesskit_opt_text_selection accesskit_node_builder_text_selection (
    const(accesskit_node_builder)* builder);

void accesskit_builder_set_text_selection (
    accesskit_node_builder* builder,
    accesskit_text_selection value);

void accesskit_node_builder_clear_text_selection (
    accesskit_node_builder* builder);

accesskit_custom_action accesskit_custom_action_new (
    int id,
    const(char)* description);

void accesskit_custom_actions_free (accesskit_custom_actions* value);

/**
 * Caller is responsible for freeing the returned value.
 */
accesskit_custom_actions* accesskit_node_custom_actions (
    const(accesskit_node)* node);

/**
 * Caller is responsible for freeing the returned value.
 */
const(accesskit_custom_actions)* accesskit_node_builder_custom_actions (
    const(accesskit_node_builder)* builder);

/**
 * Caller is responsible for freeing `values`.
 */
void accesskit_node_builder_set_custom_actions (
    accesskit_node_builder* builder,
    size_t length,
    const(accesskit_custom_action)* values);

void accesskit_node_builder_push_custom_action (
    accesskit_node_builder* builder,
    accesskit_custom_action item);

void accesskit_node_builder_clear_custom_actions (
    accesskit_node_builder* builder);

accesskit_node_builder* accesskit_node_builder_new (accesskit_role role);

/**
 * Converts an `accesskit_node_builder` to an `accesskit_node`, freeing the
 * memory in the process.
 */
accesskit_node* accesskit_node_builder_build (
    accesskit_node_builder* builder,
    accesskit_node_class_set* classes);

/**
 * Only call this function if you have to abort the building of a node.
 *
 * If you called `accesskit_node_builder_build`, don't call this function.
 */
void accesskit_node_builder_free (accesskit_node_builder* builder);

accesskit_tree* accesskit_tree_new (accesskit_node_id root);

void accesskit_tree_free (accesskit_tree* tree);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_tree_get_app_name (const(accesskit_tree)* tree);

void accesskit_tree_set_app_name (accesskit_tree* tree, const(char)* app_name);

void accesskit_tree_clear_app_name (accesskit_tree* tree);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_tree_get_toolkit_name (const(accesskit_tree)* tree);

void accesskit_tree_set_toolkit_name (
    accesskit_tree* tree,
    const(char)* toolkit_name);

void accesskit_tree_clear_toolkit_name (accesskit_tree* tree);

/**
 * Caller must call `accesskit_string_free` with the return value.
 */
char* accesskit_tree_get_toolkit_version (const(accesskit_tree)* tree);

void accesskit_tree_set_toolkit_version (
    accesskit_tree* tree,
    const(char)* toolkit_version);

void accesskit_tree_clear_toolkit_version (accesskit_tree* tree);

accesskit_tree_update* accesskit_tree_update_with_focus (
    accesskit_node_id focus);

accesskit_tree_update* accesskit_tree_update_with_capacity_and_focus (
    size_t capacity,
    accesskit_node_id focus);

void accesskit_tree_update_free (accesskit_tree_update* update);

/**
 * Appends the provided node to the tree update's list of nodes.
 * Takes ownership of `node`.
 */
void accesskit_tree_update_push_node (
    accesskit_tree_update* update,
    accesskit_node_id id,
    accesskit_node* node);

void accesskit_tree_update_set_tree (
    accesskit_tree_update* update,
    accesskit_tree* tree);

void accesskit_tree_update_clear_tree (accesskit_tree_update* update);

void accesskit_tree_update_set_focus (
    accesskit_tree_update* update,
    accesskit_node_id focus);

accesskit_action_handler* accesskit_action_handler_new (
    accesskit_action_handler_callback callback,
    void* userdata);

void accesskit_action_handler_free (accesskit_action_handler* handler);

accesskit_affine accesskit_affine_identity ();

accesskit_affine accesskit_affine_flip_y ();

accesskit_affine accesskit_affine_flip_x ();

accesskit_affine accesskit_affine_scale (double s);

accesskit_affine accesskit_affine_scale_non_uniform (double s_x, double s_y);

accesskit_affine accesskit_affine_rotate (double th);

accesskit_affine accesskit_affine_translate (accesskit_vec2 p);

accesskit_affine accesskit_affine_map_unit_square (accesskit_rect rect);

double accesskit_affine_determinant (accesskit_affine affine);

accesskit_affine accesskit_affine_inverse (accesskit_affine affine);

accesskit_rect accesskit_affine_transform_rect_bbox (
    accesskit_affine affine,
    accesskit_rect rect);

bool accesskit_affine_is_finite (const(accesskit_affine)* affine);

bool accesskit_affine_is_nan (const(accesskit_affine)* affine);

accesskit_vec2 accesskit_point_to_vec2 (accesskit_point point);

accesskit_rect accesskit_rect_from_points (
    accesskit_point p0,
    accesskit_point p1);

accesskit_rect accesskit_rect_from_origin_size (
    accesskit_point origin,
    accesskit_size size);

accesskit_rect accesskit_rect_with_origin (
    accesskit_rect rect,
    accesskit_point origin);

accesskit_rect accesskit_rect_with_size (
    accesskit_rect rect,
    accesskit_size size);

double accesskit_rect_width (const(accesskit_rect)* rect);

double accesskit_rect_height (const(accesskit_rect)* rect);

double accesskit_rect_min_x (const(accesskit_rect)* rect);

double accesskit_rect_max_x (const(accesskit_rect)* rect);

double accesskit_rect_min_y (const(accesskit_rect)* rect);

double accesskit_rect_max_y (const(accesskit_rect)* rect);

accesskit_point accesskit_rect_origin (const(accesskit_rect)* rect);

accesskit_size accesskit_rect_size (const(accesskit_rect)* rect);

accesskit_rect accesskit_rect_abs (const(accesskit_rect)* rect);

double accesskit_rect_area (const(accesskit_rect)* rect);

bool accesskit_rect_is_empty (const(accesskit_rect)* rect);

bool accesskit_rect_contains (
    const(accesskit_rect)* rect,
    accesskit_point point);

accesskit_rect accesskit_rect_union (
    const(accesskit_rect)* rect,
    accesskit_rect other);

accesskit_rect accesskit_rect_union_pt (
    const(accesskit_rect)* rect,
    accesskit_point pt);

accesskit_rect accesskit_rect_intersect (
    const(accesskit_rect)* rect,
    accesskit_rect other);

accesskit_vec2 accesskit_size_to_vec2 (accesskit_size size);

accesskit_point accesskit_vec2_to_point (accesskit_vec2 vec2);

accesskit_size accesskit_vec2_to_size (accesskit_vec2 vec2);

/**
 * Memory is also freed when calling this function.
 */

/**
 * This function takes ownership of `initial_state` and `handler`.
 *
 * # Safety
 *
 * `view` must be a valid, unreleased pointer to an `NSView`.
 */

/**
 * This function takes ownership of `update`.
 * You must call `accesskit_macos_queued_events_raise` on the returned pointer.
 */

/**
 * Update the tree state based on whether the window is focused.
 *
 * You must call `accesskit_macos_queued_events_raise` on the returned pointer.
 */

/**
 * Returns a pointer to an `NSArray`. Ownership of the pointer is not
 * transferred.
 */

/**
 * Returns a pointer to an `NSObject`. Ownership of the pointer is not
 * transferred.
 */

/**
 * Returns a pointer to an `NSObject`. Ownership of the pointer is not
 * transferred.
 */

/**
 * This function takes ownership of `handler`.
 *
 * # Safety
 *
 * `view` must be a valid, unreleased pointer to an `NSView`.
 */

/**
 * This function takes ownership of `handler`.
 *
 * # Safety
 *
 * `window` must be a valid, unreleased pointer to an `NSWindow`.
 *
 * # Panics
 *
 * This function panics if the specified window doesn't currently have
 * a content view.
 */

/**
 * This function takes ownership of `update`.
 * You must call `accesskit_macos_queued_events_raise` on the returned pointer.
 */

/**
 * You must call `accesskit_macos_queued_events_raise` on the returned pointer.
 * It can be null if the adapter is not active.
 */

/**
 * Update the tree state based on whether the window is focused.
 *
 * You must call `accesskit_macos_queued_events_raise` on the returned pointer.
 * It can be null if the adapter is not active.
 */

/**
 * Modifies the specified class, which must be a subclass of `NSWindow`,
 * to include an `accessibilityFocusedUIElement` method that calls
 * the corresponding method on the window's content view. This is needed
 * for windowing libraries such as SDL that place the keyboard focus
 * directly on the window rather than the content view.
 *
 * # Safety
 *
 * This function is declared unsafe because the caller must ensure that the
 * code for this library is never unloaded from the application process,
 * since it's not possible to reverse this operation. It's safest
 * if this library is statically linked into the application's main executable.
 * Also, this function assumes that the specified class is a subclass
 * of `NSWindow`.
 */

/**
 * This function will take ownership of the pointer returned by `source`, which
 * can't be null.
 *
 * `source` can be called from any thread.
 */
accesskit_unix_adapter* accesskit_unix_adapter_new (
    accesskit_tree_update_factory source,
    void* source_userdata,
    accesskit_action_handler* handler);

void accesskit_unix_adapter_free (accesskit_unix_adapter* adapter);

void accesskit_unix_adapter_set_root_window_bounds (
    const(accesskit_unix_adapter)* adapter,
    accesskit_rect outer,
    accesskit_rect inner);

/**
 * This function takes ownership of `update`.
 */
void accesskit_unix_adapter_update_if_active (
    const(accesskit_unix_adapter)* adapter,
    accesskit_tree_update_factory update_factory,
    void* update_factory_userdata);

/**
 * Update the tree state based on whether the window is focused.
 */
void accesskit_unix_adapter_update_window_focus_state (
    const(accesskit_unix_adapter)* adapter,
    bool is_focused);

/**
 * You don't need to call this if you use `accesskit_windows_adapter_new`.
 */

/**
 * Memory is also freed when calling this function.
 */

/**
 * This function takes ownership of all pointers passed to it.
 */

/**
 * This function takes ownership of `update`.
 * You must call `accesskit_windows_queued_events_raise` on the returned
 * pointer.
 */

/**
 * Update the tree state based on whether the window is focused.
 *
 * You must call `accesskit_windows_queued_events_raise` on the returned
 * pointer.
 */

/**
 * This function takes ownership of `handler`.
 */

/**
 * This function takes ownership of `update`.
 * You must call `accesskit_windows_queued_events_raise` on the returned
 * pointer.
 */

/**
 * You must call `accesskit_windows_queued_events_raise` on the returned
 * pointer. It can be null if the adapter is not active.
 */

// extern "C"
// __cplusplus

/* ACCESSKIT_H */
