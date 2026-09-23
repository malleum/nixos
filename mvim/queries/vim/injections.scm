; extends
; neovim's bundled queries don't inject the comment grammar; nvim-treesitter's
; do. This lets TODO/NOTE/FIXME badges (lua/mvim/todo.lua) work here too.
((comment) @injection.content
  (#set! injection.language "comment"))
