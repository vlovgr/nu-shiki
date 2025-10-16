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
  --lang (-l) = "ansi" # The shiki language to use
  --format (-f) # Insert newlines and indentation for top-level pipes
  --output (-o): path = "~/Downloads/screenshot.png" # The output path
  --prompt (-p): string = "○ " # The prompt indicator including space
  --width (-w): int # The maximum number of characters per line
  command?: string # The terminal command to show in the image
]: any -> nothing {
  let input = $in

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

    let rendered = do { ^node $render $code $lang ($output | path expand) } | complete
    if $rendered.exit_code != 0 {
      error make { msg: ($rendered.stderr | str trim) }
    } else if $debug {
      print $"Image successfully saved to ($output)."
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
