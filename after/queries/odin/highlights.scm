;; extends 

;; (#set! conceal "⦃")
;; [ "(" ")" "[" "]" "{" "}"] @braces
;; [ "{" "}"] @curlybraces

;; (if_statement condition:(binary_expression(operator) @andSymbol (#eq? @andSymbol "&&"))(#set! conceal "∆"))
;; (if_statement condition:(binary_expression(operator) @orSymbol (#eq? @orSymbol "||"))(#set! conceal "∨"))

; Simply match all curly braces
[ "{" "}"] @curlybraces
(#eq? @curlybraces)

; Procedures 

;; (procedure_declaration(procedure(block("{")@procOpeningBrace)))
;; (procedure_declaration(procedure(block("}")@procClosingBrace)))

; Fors

;; (for_statement consequence:(block("{")@forOpeningBrace))
;; (for_statement consequence:(block("}")@forClosingBrace))
;; (for_statement initializer:(assignment_statement) (";") @forAssignmentSemicolon)

; Ifs
; Note: We only need to handle nested if-statements because they're not allowed
; at the file scope in Odin.

;; (if_statement consequence:(block("{")@ifStatementOpeningBrace))
;; (if_statement consequence:(block("}")@ifStatementClosingBrace))
;; (if_statement(else_clause consequence:(block("{")@elseClauseOpeningBrace)))
;; (if_statement(else_clause consequence:(block("}")@elseClauseClosingBrace)))

; Switches

;; (switch_statement ("{") @switchOpeningBrace)
;; (switch_statement ("}") @switchClosingBrace)

; Foreigns

;; (foreign_block (block("{") @foreignOpeningBrace))
;; (foreign_block (block("}") @foreignClosingBrace))

; Structs

;; (struct_declaration ("{") @structOpeningBrace)
;; (struct_declaration ("}") @structClosingBrace)

; Enums

;; (enum_declaration ("{") @enumOpeningBrace)
;; (enum_declaration ("}") @enumClosingBrace)
