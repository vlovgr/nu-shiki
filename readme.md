# :framed_picture: nu-shiki

Generate images of terminal commands with their outputs using [Node.js](https://nodejs.org) and [Shiki](https://shiki.style/).

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
