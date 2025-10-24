;; extends

; Capture only braces that delimit statement blocks.
(compound_statement
    "{" @curlybraces
    (#set! @curlybraces priority 120))

(compound_statement
    "}" @curlybraces
    (#set! @curlybraces priority 120))
