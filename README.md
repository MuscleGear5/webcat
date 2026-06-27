# webcat

**`cat` for the web.** Render web pages and markdown right in your terminal — with **real inline images**, not just URLs.

webcat fetches a page, strips away the nav/ads/clutter, renders the text beautifully, and draws the images *in place* using your terminal's graphics protocol (kitty / sixel / iTerm2), with a Unicode-block fallback for plain terminals.

```sh
webcat https://github.com/alibaba/page-agent
```

## Why

`curl | less` gives you HTML soup. Reader-mode tools give you text but drop the images. webcat gives you the clean article *and* the pictures, in document order, without leaving the terminal. Great over SSH, on a phone (Termux), or anywhere a browser is overkill.

## How it works

webcat is a small orchestrator over three excellent tools:

| Stage | Tool | Job |
|-------|------|-----|
| Fetch & clean | [defuddle](https://github.com/kepano/defuddle) | URL → clean markdown |
| Text | [glow](https://github.com/charmbracelet/glow) | render the markdown |
| Images | [chafa](https://hpjansson.org/chafa/) | draw each image inline |

It walks the markdown in order, sending text to glow and image URLs to chafa, so everything lands where it belongs.

### Backends

webcat has two rendering engines, selectable with `--engine`:

- **`stitch`** (**default**) — glow for text + chafa for images, stitched together. Most compatible: chafa auto-detects the widest range of terminal graphics protocols. Only needs glow and chafa.
- **`mdcat`** — if [mdcat](https://github.com/swsnr/mdcat) is installed, it renders text *and* inline images natively in a single pass. webcat finds it on `PATH` or in `~/.cargo/bin`. Note: mdcat supports fewer terminals than chafa, so images may not appear everywhere.
- **`auto`** — use mdcat if present, else fall back to stitch.

If images don't render with one engine, try the other: `--engine stitch` is the safe bet.

## Install

```sh
git clone https://github.com/MuscleGear5/webcat
cd webcat
./install.sh
```

The installer detects your platform (Termux, Debian/Ubuntu, Fedora, Arch, macOS), installs the dependencies, and drops `webcat` into `~/.local/bin`.

### Manual install

Install the deps yourself, then copy the script:

```sh
# deps (pick your platform)
pkg install glow chafa            # Termux
brew install glow chafa           # macOS
sudo apt install glow chafa       # Debian/Ubuntu
npm install -g defuddle           # all platforms (needed for URLs)

install -m 755 webcat ~/.local/bin/webcat
```

> **Termux note:** npm CLIs ship a `#!/usr/bin/env node` shebang, but Termux has no `/usr/bin/env`. The installer runs `termux-fix-shebang` on defuddle automatically; if you install by hand, run it yourself.

## Usage

```sh
webcat <url>              # fetch a web page, render text + images
webcat <file.md>          # render a local markdown file
cat file.md | webcat      # render markdown from stdin
webcat <url> -w 80        # set render width (columns)
webcat <url> --img-height 10   # smaller images (default 14 rows)
webcat <url> --no-images  # text only
webcat --help
```

## Terminal image support

Images render at full fidelity in terminals that speak a graphics protocol —
**kitty**, **sixel**, **iTerm2**, and modern Termux builds. chafa auto-detects
this. In a plain terminal you still get a recognizable Unicode-block rendering.

**Sizing is fit-down-only:** small images (icons, badges) keep their true
natural size — they're never blown up — while large or tall images are scaled
down to fit. Width is capped to your terminal; large-image height is capped by
`--img-height` (default 24 rows).

**All image types render**, including **SVG** (e.g. shields.io badges, which
webcat rasterizes to PNG via `rsvg-convert`/ImageMagick), `data:` URIs, and
local image files referenced from a local markdown file.

## Dependencies

- **python3** — runs webcat (no third-party Python packages)
- **glow** — markdown text rendering
- **chafa** — terminal image rendering
- **defuddle** — URL → markdown (only needed for URLs; local `.md` works without it)
- **librsvg** (`rsvg-convert`) or **ImageMagick** — optional; rasterizes SVG images so they render

## License

MIT — see [LICENSE](LICENSE).

## Credits

Stands entirely on the shoulders of [defuddle](https://github.com/kepano/defuddle),
[glow](https://github.com/charmbracelet/glow), and [chafa](https://hpjansson.org/chafa/).
