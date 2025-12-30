-- Highlight XML-style tags (e.g., <example>, </example>) in markdown
-- Pattern matches: <tag>, </tag>, <tag-name>, <tag_name>, <tag123>
local pattern = [[<\/\?[a-zA-Z][a-zA-Z0-9_-]*>]]

-- Use buffer-local match to auto-cleanup when buffer is unloaded
vim.fn.matchadd("MarkdownXmlTag", pattern)
