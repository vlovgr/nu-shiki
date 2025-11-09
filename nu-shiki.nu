use std repeat

const render = path self "render.js"

# Generate an image of a terminal command with its output.
#
# The output of the command should be piped as input, while
# the command to show in the image is passed explicitly. An
# image will be generated to the --output (-o) path, and if
# the file already exists, it will be overwritten.
#
# An alternative option is to provide --eval (-e) to both show
# and run the provided command for its output. Evaluation gets
# done using a default closure, or --eval-closure (-c) can be
# provided with a custom closure for evaluation. Note syntax
# highlighting might not work as expected with this option.
export def main [
  --debug (-d) # Print additional information for debug purposes
  --eval (-e) # Run the provided command to generate the output
  --eval-closure (-c): closure # The closure with which to run code
  --lang (-l): string@languages = "ansi" # The shiki language to use
  --format (-f) # Insert newlines and indentation for top-level pipes
  --output (-o): path = "~/Downloads/screenshot.png" # The output path
  --output-type (-t): string@[html jpeg pdf png webp] # The output type (defaults to guessing)
  --prompt (-p): string = "○ " # The prompt indicator including space
  --theme (-t): string@themes = "material-theme" # The shiki theme to use
  --width (-w): int # The maximum number of characters per line
  command?: string # The terminal command to show in the image
]: any -> nothing {
  let input = $in

  let output_type = $output_type | default {
    let type = match $output {
      $s if $s =~ '\.(htm|html)$' => 'html'
      $s if $s =~ '\.(jpg|jpeg)$' => 'jpeg'
      $s if $s =~ '\.pdf$' => 'pdf'
      $s if $s =~ '\.png$' => 'png'
      $s if $s =~ '\.webp$' => 'webp'
      _ => { if $debug { print "Unable to guess output type from output path." }; 'png' }
    }

    if $debug { print $"No output type specified, using ($type) for output." }
    $type
  }

  let width = $width | default {
    let columns = term size | get columns
    if $debug { print $"Using terminal columns for width: ($columns) characters." }
    $columns
  }

  if $eval {
    let eval_closure = $eval_closure | default {
      if $debug {
        print "Code will be evaluated using the default closure."
        print $'(char newline)|commands: string| nu --login --commands $commands(char newline)'
      }

      { |commands: string| nu --login --commands $commands }
    }

    let commands = $"($command) | nu-shiki --debug=($debug) --lang=r#'($lang)'# --format=($format) --output=r#'($output)'# --prompt=r#'($prompt)'# --width=($width) r#'($command)'#"
    if $debug {
      print "The following generated code will be evaluated."
      print $'(char newline)($commands)(char newline)'
    }

    do $eval_closure $commands
  } else {
    let input = $input | table --expand --width $width
    let input = try { $input | str trim } catch { $input }

    let command = $command | default '' | format $prompt $format

    let code = [
      (if ($command | is-not-empty) { $"(ansi white_dimmed)($prompt)(ansi reset)" })
      (if ($command | is-not-empty) { $command | break insert $prompt $width | nu-highlight | break replace })
      (if ($command | is-not-empty) and ($input | is-not-empty) { char newline })
      ($input)
    ] | str join

    if $debug {
      print $"The following code will be rendered in the image."
      print $"(char newline)($code)(char newline)"
    }

    let output_html = if $debug { mktemp --tmpdir --suffix .html } else { '' }

    let rendered = do { ^node $render $code $lang ($output | path expand) $output_html $output_type $theme } | complete
    if $rendered.exit_code != 0 {
      error make { msg: ($rendered.stderr | str trim) }
    } else if $debug {
      print $"HTML was saved to ($output_html)."
      print $"Image was saved to ($output)."
    }
  }
}

# The replacement character (U+FFFD).
const break = "\u{FFFD}"

# Insert the replacement character (U+FFFD) where a line break
# should be inserted after syntax highlighting. Makes sure the
# command (with prompt) does not exceed the specified width.
def "break insert" [prompt: string, width: int]: string -> string {
  $"($prompt)($in)"
  | split row (char newline)
  | enumerate
  | each { |line|
      let chunked = $line.item
      | split chars
      | chunks $width
      | each { str join }
      | str join $break

      if $line.index == 0 {
        $chunked
        | split chars
        | skip ($prompt | str length --grapheme-clusters)
        | str join
      } else {
        $chunked
      }
    }
  | str join (char newline)
}

# Replace all replacement characters (U+FFFD) with line breaks.
def "break replace" []: string -> string {
  $in | str replace --all $break (char newline)
}

# Insert newlines and indentation for top-level pipes.
# Uses crude parsing that will not always work properly.
def format [prompt: string, format: bool]: string -> string {
  if $format {
    let indent = $prompt | str length --grapheme-clusters
    let spaces = ' ' | repeat $indent | str join
    let pipe = $"(char newline)($spaces)| " | split chars

    $in
    | str trim
    | split chars
    | reduce --fold { chars: [], depth: 0, spaces: true } {|it,acc|
        match $it {
          '{' => {
            $acc
            | update chars { append '{' }
            | update depth { $in + 1 }
            | update spaces true
          }
          '}' => {
            $acc
            | update chars { append '}' }
            | update depth { $in - 1 }
            | update spaces true
          }
          ' ' if not $acc.spaces => {
            $acc
          }
          '|' if $acc.depth == 0 => {
            let spaces = $acc.chars
            | reverse
            | take while { $in == ' ' }
            | length

            $acc
            | update chars { drop $spaces | append $pipe }
            | update spaces false
          }
          _ => {
            $acc
            | update chars { append $it }
            | update spaces true
          }
        }
      }
    | get chars
    | str join
  } else {
    $in | str trim
  }
}

def languages [] {
  [
    'abap'
    'actionscript-3'
    'ada'
    'angular-html'
    'angular-ts'
    'apache'
    'apex'
    'apl'
    'applescript'
    'ara'
    'asciidoc'
    'adoc'
    'asm'
    'astro'
    'awk'
    'ballerina'
    'bat'
    'batch'
    'beancount'
    'berry'
    'be'
    'bibtex'
    'bicep'
    'blade'
    'bsl'
    '1c'
    'c'
    'cadence'
    'cdc'
    'cairo'
    'clarity'
    'clojure'
    'clj'
    'cmake'
    'cobol'
    'codeowners'
    'codeql'
    'ql'
    'coffee'
    'coffeescript'
    'common-lisp'
    'lisp'
    'coq'
    'cpp'
    'c++'
    'crystal'
    'csharp'
    'c#'
    'cs'
    'css'
    'csv'
    'cue'
    'cypher'
    'cql'
    'd'
    'dart'
    'dax'
    'desktop'
    'diff'
    'docker'
    'dockerfile'
    'dotenv'
    'dream-maker'
    'edge'
    'elixir'
    'elm'
    'emacs-lisp'
    'elisp'
    'erb'
    'erlang'
    'erl'
    'fennel'
    'fish'
    'fluent'
    'ftl'
    'fortran-fixed-form'
    'f'
    'for'
    'f77'
    'fortran-free-form'
    'f90'
    'f95'
    'f03'
    'f08'
    'f18'
    'fsharp'
    'f#'
    'fs'
    'gdresource'
    'gdscript'
    'gdshader'
    'genie'
    'gherkin'
    'git-commit'
    'git-rebase'
    'gleam'
    'glimmer-js'
    'gjs'
    'glimmer-ts'
    'gts'
    'glsl'
    'gnuplot'
    'go'
    'graphql'
    'gql'
    'groovy'
    'hack'
    'haml'
    'handlebars'
    'hbs'
    'haskell'
    'hs'
    'haxe'
    'hcl'
    'hjson'
    'hlsl'
    'html'
    'html-derivative'
    'http'
    'hurl'
    'hxml'
    'hy'
    'imba'
    'ini'
    'properties'
    'java'
    'javascript'
    'js'
    'cjs'
    'mjs'
    'jinja'
    'jison'
    'json'
    'json5'
    'jsonc'
    'jsonl'
    'jsonnet'
    'jssm'
    'fsl'
    'jsx'
    'julia'
    'jl'
    'kdl'
    'kotlin'
    'kt'
    'kts'
    'kusto'
    'kql'
    'latex'
    'lean'
    'lean4'
    'less'
    'liquid'
    'llvm'
    'log'
    'logo'
    'lua'
    'luau'
    'make'
    'makefile'
    'markdown'
    'md'
    'marko'
    'matlab'
    'mdc'
    'mdx'
    'mermaid'
    'mmd'
    'mipsasm'
    'mips'
    'mojo'
    'move'
    'narrat'
    'nar'
    'nextflow'
    'nf'
    'nginx'
    'nim'
    'nix'
    'nushell'
    'nu'
    'objective-c'
    'objc'
    'objective-cpp'
    'ocaml'
    'pascal'
    'perl'
    'php'
    'pkl'
    'plsql'
    'po'
    'pot'
    'potx'
    'polar'
    'postcss'
    'powerquery'
    'powershell'
    'ps'
    'ps1'
    'prisma'
    'prolog'
    'proto'
    'protobuf'
    'pug'
    'jade'
    'puppet'
    'purescript'
    'python'
    'py'
    'qml'
    'qmldir'
    'qss'
    'r'
    'racket'
    'raku'
    'perl6'
    'razor'
    'reg'
    'regexp'
    'regex'
    'rel'
    'riscv'
    'rosmsg'
    'rst'
    'ruby'
    'rb'
    'rust'
    'rs'
    'sas'
    'sass'
    'scala'
    'scheme'
    'scss'
    'sdbl'
    '1c-query'
    'shaderlab'
    'shader'
    'shellscript'
    'bash'
    'sh'
    'shell'
    'zsh'
    'shellsession'
    'console'
    'smalltalk'
    'solidity'
    'soy'
    'closure-templates'
    'sparql'
    'splunk'
    'spl'
    'sql'
    'ssh-config'
    'stata'
    'stylus'
    'styl'
    'svelte'
    'swift'
    'system-verilog'
    'systemd'
    'talonscript'
    'talon'
    'tasl'
    'tcl'
    'templ'
    'terraform'
    'tf'
    'tfvars'
    'tex'
    'toml'
    'ts-tags'
    'lit'
    'tsv'
    'tsx'
    'turtle'
    'twig'
    'typescript'
    'ts'
    'cts'
    'mts'
    'typespec'
    'tsp'
    'typst'
    'typ'
    'v'
    'vala'
    'vb'
    'cmd'
    'verilog'
    'vhdl'
    'viml'
    'vim'
    'vimscript'
    'vue'
    'vue-html'
    'vue-vine'
    'vyper'
    'vy'
    'wasm'
    'wenyan'
    '文言'
    'wgsl'
    'wikitext'
    'mediawiki'
    'wiki'
    'wit'
    'wolfram'
    'wl'
    'xml'
    'xsl'
    'yaml'
    'yml'
    'zenscript'
    'zig'
  ]
}

def themes [] {
  [
    'andromeeda'
    'aurora-x'
    'ayu-dark'
    'catppuccin-frappe'
    'catppuccin-latte'
    'catppuccin-macchiato'
    'catppuccin-mocha'
    'dark-plus'
    'dracula'
    'dracula-soft'
    'everforest-dark'
    'everforest-light'
    'github-dark'
    'github-dark-default'
    'github-dark-dimmed'
    'github-dark-high-contrast'
    'github-light'
    'github-light-default'
    'github-light-high-contrast'
    'gruvbox-dark-hard'
    'gruvbox-dark-medium'
    'gruvbox-dark-soft'
    'gruvbox-light-hard'
    'gruvbox-light-medium'
    'gruvbox-light-soft'
    'houston'
    'kanagawa-dragon'
    'kanagawa-lotus'
    'kanagawa-wave'
    'laserwave'
    'light-plus'
    'material-theme'
    'material-theme-darker'
    'material-theme-lighter'
    'material-theme-ocean'
    'material-theme-palenight'
    'min-dark'
    'min-light'
    'monokai'
    'night-owl'
    'nord'
    'one-dark-pro'
    'one-light'
    'plastic'
    'poimandres'
    'red'
    'rose-pine'
    'rose-pine-dawn'
    'rose-pine-moon'
    'slack-dark'
    'slack-ochin'
    'snazzy-light'
    'solarized-dark'
    'solarized-light'
    'synthwave-84'
    'tokyo-night'
    'vesper'
    'vitesse-black'
    'vitesse-dark'
    'vitesse-light'
  ]
}
