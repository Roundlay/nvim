;; extends 

;; (#set! conceal "⦃")
;; [ "(" ")" "[" "]" "{" "}"] @braces
;; [ "{" "}"] @curlybraces
;; (if_statement condition:(binary_expression(operator) @andSymbol (#eq? @andSymbol "&&"))(#set! conceal "∆"))
;; (if_statement condition:(binary_expression(operator) @orSymbol (#eq? @orSymbol "||"))(#set! conceal "∨"))

; Load Procedures
; Procedure Declarations

(const_declaration name:(const_identifier) value:(proc_literal (block("{") @procOpeningBrace)))
(const_declaration name:(const_identifier) value:(proc_literal (block("}") @procClosingBrace)))

; For Statements

(for_statement body: (block("{"("\n")) @nestedOpeningBrace) (#eq? @nestedOpeningBrace "{") )
(for_statement body: (block("\n"("}") @nestedClosingBrace) (#eq? @nestedClosingBrace "}")))
(for_statement initializer:(var_declaration) (";") @forStatementSemicolon)

; If Statements
; Note: We only need to handle nested if-statements because they're not allowed
; at the file scope in Odin.

(if_statement if_true:(block("{"("\n")) @nestedIfTrueOpeningBrace (#eq? @nestedIfTrueOpeningBrace "{")))
(if_statement if_true:(block("\n"("}") @nestedIfTrueClosingBrace (#eq? @nestedIfTrueClosingBrace "}"))))
(if_statement if_false:(block("{"("\n")) @nestedIfFalseOpeningBrace))
(if_statement if_false:(block("\n"("}") @nestedIfFalseClosingBrace)))

; Switch Statements

(switch_statement body:(("{") @switchStatement) (#eq? @switchStatement "{"))
(switch_statement body:(("}") @switchStatement) (#eq? @switchStatement "}"))
