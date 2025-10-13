# :framed_picture: nu-shiki

Generate images of terminal commands with their outputs using [Node.js](https://nodejs.org) and [Shiki](https://shiki.style/).

For more background, check out [Generating Images of Nushell Commands](https://vlovgr.se/posts/nu-shiki).

## Setup

Make sure you have [Git](https://git-scm.com), [Node.js](https://nodejs.org) and [Nushell](https://www.nushell.sh) installed, and then run the following.

```nushell
git clone git@github.com:vlovgr/nu-shiki.git
cd nu-shiki
npm install
use nu-shiki.nu
```

You can optionally modify [`render.js`](render.js) with your own customizations (e.g. the font to use).

## Usage

You can then use `nu-shiki` to generate images (defaults to `~/Downloads/screenshot.png`).

```nushell
let command = "http get https://jsonplaceholder.typicode.com/posts | where userId == 1 | first 3 | select id title"

http get https://jsonplaceholder.typicode.com/posts
| where userId == 1
| first 3
| select id title
| nu-shiki --format $command
```

<img width="599" height="204" alt="screenshot" src="https://github.com/user-attachments/assets/10e322e7-5bfd-4608-96dd-379123cfc070"/>

There is also the option to use `--eval` to both show and run the provided command.

```nushell
nu-shiki --format --eval $command
```

<img width="599" height="204" alt="screenshot" src="https://github.com/user-attachments/assets/3a8b5e52-1ca2-47d1-87cb-e8fe4c2ba854"/>

Note syntax highlighting and colors may not always render as expected with this option.

Using the `--lang` option, you can render images of code in all <a href="https://shiki.style/languages">supported languages</a>.
