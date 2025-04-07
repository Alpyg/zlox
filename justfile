alias i := interpret
alias r := repl

repl:
  zig build run

interpret PATH:
  zig build run -- {{PATH}}
