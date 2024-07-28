# Dfenestration

A general cross-platform desktop GUI toolkit in D, inspired of the GTK+ 2 philosophy.

"Why this old philosophy instead of something more modern?" you might say.

Because there are already a lot of modern toolkits in trendy programming languages.

Whereas traditional frameworks are becoming rarer, and harder to use with the time.

My answer is to make a framework with a somewhat old architecture. Surely not optimal 
but good enough and easy to use.

## WIP

- bug, windows are not appearing.
- Font shaping
- Pop-up support/multiple windows. xdg-toplevel-drag.
- click, touch, scroll, gestures!
- focus management (nextFocus, previousFocus), accels
- fractional scaling

## Known bugs

- OpenGL backend's NanoVega clips incorrectly, leaving one pixel wide errors on every 
clipping operation.

## Support

Wayland with relatively recent protocols.

X11 (TODO)

## Roadmap

- Platform support

  |                     | Software | OpenGL      | Vulkan      | Metal |
  |---------------------|----------|-------------|-------------|-------|
  | Wayland (xdg-shell) |          | OK          | OK          | -     |
  | X11                 |          | wip         |             | -     |
  | Windows             |          |             |             | -     |
  | macOS               |          | not planned | not planned |       |

For now, other platforms are not planned. I used xdg-shell for Wayland as it is
seemingly the one here to stay. Even if it lacks some features when compared to
wl-shell-surface.

- Accessibility
  - [ ] Access-kit
  - [ ] AT-SPI (Linux)
  - [ ] Windows
  - [ ] macOS

Wayland is the first to be supported since it's the most barebones one. By taking care of
it first the toolkit won't make any assumption about any feature support in the
implementation.

Priority:

- Platform support: Wayland support (Software and OpenGL) with xdg-decorations support
- Button and text widgets
- Styling?
- Platform support: X11 support (with any renderer)
- Making a TextLine widget
- Making a ScrollView widget
- Accessibility: AT-SPI
- Fractional scaling on Wayland
- Platform support: Windows (with any renderer)
- Accessibility: Windows
- Theming (theme engines, affecting defaults and draws)
- Example: Port a complex widget from GTK+ 2
- **Stabilise API**
- Platform support: macOS (Software)
- Accessibility: macOS
- Blur effects on Windows, macOS and KDE

## Example code

```d
// too early stage 
```

## Credits

- Name shamelessly stolen from fsckboy on Hacker News
- VkVG by Jean-Pierre Bruyère
- NanoVega by Adam D. Ruppe
