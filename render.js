import captureWebsite from "capture-website";
import { codeToHtml } from "shiki";
import fs from "fs/promises";

const code = process.argv[2];
const lang = process.argv[3];
const output = process.argv[4];
const output_html = process.argv[5];
const output_type = process.argv[6];

const rendered = await codeToHtml(code, {
  lang: lang,
  theme: "material-theme",
  colorReplacements: {
    "#263238": "#1b2b34",
    "#89ddff": "#5fb3b3",
    "#c3e88d": "#99c794",
    "#c792ea": "#c594c5",
    "#eeffff": "#d8dee9",
    "#ffffff": "#8f99a3",
  },
});

const html = `<!doctype html>
<html lang="en-US">
  <head>
    <title>nu-shiki</title>
    <style>
      #view {
        display: inline-block;
      }

      pre {
        border-radius: 5px;
        margin: 0;
        padding: 12px;
      }

      span {
        font-family: "Fira Code", monospace;
        font-weight: normal;
        font-style: normal;
        font-size: 11px;
      }
    </style>
  </head>
  <body>
    <div id="view">${rendered}</div>
  </body>
</html>`;

if (output_html) {
  await fs.writeFile(output_html, html);
}

const options = {
  defaultBackground: false,
  inputType: "html",
  overwrite: true,
  type: output_type,
  ...(output_type != "pdf" && { element: "#view" }),
};

await captureWebsite.file(html, output, options);
