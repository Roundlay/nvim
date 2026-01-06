-- Highlight XML-style tags (e.g., <example>, </example>) in markdown
-- Pattern matches: <tag>, </tag>, <tag-name>, <tag_name>, <tag123>
local pattern = [[<\/\?[a-zA-Z][a-zA-Z0-9_-]*>]]

-- Use buffer-local match to auto-cleanup when buffer is unloaded
vim.fn.matchadd("MarkdownXmlTag", pattern)

-- Inline code spans inside raw HTML blocks are not parsed by the markdown
-- grammar; add a lightweight regex match so backticks stay highlighted.
local inline_code_pattern = [[\v`[^`\n]+`]]
vim.fn.matchadd("MarkdownInlineCode", inline_code_pattern, 90)

-- Prevent underline styling on bracket markers like "[+]" when they are not
-- followed by link/reference syntax.
local bracket_plain_pattern = [[\v\[[^]\n]+\]\ze(\s*$|\s*[^([:])]]
vim.fn.matchadd("MarkdownBracketPlain", bracket_plain_pattern, 120)
