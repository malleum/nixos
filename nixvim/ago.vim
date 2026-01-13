if exists("b:current_syntax")
  finish
endif

" --- Keywords ---
syntax keyword agoKeyword des aluid frio pergo omitto redeo
syntax keyword agoConditional si est
syntax keyword agoRepeat pro dum
syntax keyword agoInclude in inporto
syntax keyword agoBoolean verum falsus
syntax keyword agoConstant inanis id

" --- Matches ---

" 1. Function/Method Calls
" Logic: Match an identifier, but ONLY if it is followed by optional whitespace and a '('
" \v       = very magic mode (standard regex)
" \s* = allow optional space between name and (
" \ze\(    = zero-width match end (check for '(', but don't highlight it as part of the function name)
syntax match agoFunctionCall "\v[A-Za-z_][A-Za-z_0-9]*\s*\ze("

" 2. Comments (Priority: Keep this after keywords/calls to prevent matching inside comments)
syntax match agoComment "#.*$"

" 3. Numbers
syntax match agoNumber "\v<[MCDLXIV]+>"
syntax match agoFloat "\v\d*\.\d+"
syntax match agoNumber "\v\d+"

" 4. Definition Names (after 'des')
" Logic: Lookbehind for 'des', then match the name
syntax match agoFunctionDef "\v(des\s+)@<=[A-Za-z_][A-Za-z_0-9]*"

" 5. Operators & Delimiters
syntax match agoOperator ":="
syntax match agoOperator "="
syntax match agoOperator "+\|-\|*\|/\|%\|^\|&\||"
syntax match agoOperator "?:"
syntax match agoOperator "\.\\."
syntax match agoOperator "\.<"

" Added: Angle brackets for comparisons
syntax match agoOperator "[<>]"

" Added: Delimiters
syntax match agoDelimiter "[(){}\[\]]"

" --- Strings ---
syntax region agoString start=/'/ skip=/\\'/ end=/'/

" --- Linking ---
highlight default link agoKeyword      Keyword
highlight default link agoConditional  Conditional
highlight default link agoRepeat       Repeat
highlight default link agoInclude      Include
highlight default link agoBoolean      Boolean
highlight default link agoConstant     Constant
highlight default link agoComment      Comment
highlight default link agoString       String
highlight default link agoNumber       Number
highlight default link agoFloat        Float
highlight default link agoOperator     Operator

" New Links
highlight default link agoDelimiter    Delimiter
highlight default link agoFunctionCall Function
highlight default link agoFunctionDef  Function

let b:current_syntax = "ago"
