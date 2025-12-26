-- blink.cmp plugin configuration (cleaned line endings)

-- TODO: Set up sources

-- [ ] How can we include any open buffer/window as a source? E.g. docs or help open in split.

return {
    'saghen/blink.cmp',

    enabled = true,
    lazy = true,
    event = 'InsertCharPre',
    version = '*',
    opts = {
        keymap = {
            preset = 'default',
            ['<C-\\>'] = {'select_and_accept', 'fallback'},
            ['<C-CR>'] = {'select_and_accept', 'fallback'},
            ['<C-p>'] = {'select_prev', 'fallback'},
            ['<C-n>'] = {'select_next', 'fallback'},
        },
        completion = {
            list = {
                selection = {
                    preselect = false,
                    auto_insert = false,
                },
            },
            menu = {
                border = {
                    { "█", "BlinkCmpMenuBorder" },
                    { "▀", "BlinkCmpMenuBorder" },
                    { "█", "BlinkCmpMenuBorder" },
                    { "█", "BlinkCmpMenuBorder" },
                    { "█", "BlinkCmpMenuBorder" },
                    { "▄", "BlinkCmpMenuBorder" },
                    { "█", "BlinkCmpMenuBorder" },
                    { "█", "BlinkCmpMenuBorder" },
                },
                scrollbar = true,
                draw = {
                    columns = { { 'label', 'label_description', gap = 1 }, { 'kind' } },
                    align_to = 'label',
                    padding = { 1, 1 },
                    gap = 1,
                    cursorline_priority = 10000,
                    components = {
                        kind = {
                            width = { fill = true },
                            ellipsis = true,
                            text = function(ctx)
                                return ctx.kind
                            end,
                            highlight = function(ctx)
                                return ctx.kind_hl
                            end,
                        },

                        label = {
                            width = { fill = true, min = 33, max = 33 },
                            text = function(ctx)
                                return ctx.label .. ctx.label_detail
                            end,
                        },

                        label_description = {
                            width = { fill = true },
                            text = function(ctx)
                                return ctx.label_description
                            end,
                            highlight = 'BlinkCmpLabelDescription',
                        },

                        source_name = {
                            width = { fill = true },
                            text = function(ctx)
                                return ctx.source_name
                            end,
                            highlight = 'BlinkCmpSource',
                        },

                        source_id = {
                            width = { fill = true },
                            text = function(ctx)
                                return ctx.source_id
                            end,
                            highlight = 'BlinkCmpSource',
                        },
                    },
                },
            },
            ghost_text = {
                enabled = false,
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 0,
                draw = function(opts) opts.default_implementation() end,
                window = {
                    min_width = 40,
                    max_width = 40,
                    -- max_height = 15,
                    border = {
                        { "█", "BlinkCmpDocBorder" },
                        { "▀", "BlinkCmpDocBorder" },
                        { "█", "BlinkCmpDocBorder" },
                        { "█", "BlinkCmpDocBorder" },
                        { "█", "BlinkCmpDocBorder" },
                        { "▄", "BlinkCmpDocBorder" },
                        { "█", "BlinkCmpDocBorder" },
                        { "█", "BlinkCmpDocBorder" },
                    },
                    winhighlight = table.concat({
                        "Normal:BlinkCmpDoc",
                        "FloatBorder:BlinkCmpDocBorder",
                        "EndOfBuffer:BlinkCmpDoc",
                        "Identifier:VscodePopupIdentifier",
                        "Function:VscodePopupFunction",
                        "Statement:VscodePopupKeyword",
                        "Keyword:VscodePopupKeyword",
                        "Conditional:VscodePopupKeyword",
                        "Repeat:VscodePopupKeyword",
                        "Exception:VscodePopupKeyword",
                        "Type:VscodePopupType",
                        "StorageClass:VscodePopupType",
                        "Structure:VscodePopupType",
                        "Typedef:VscodePopupType",
                        "String:VscodePopupString",
                        "Character:VscodePopupString",
                        "Number:VscodePopupNumber",
                        "Float:VscodePopupNumber",
                        "Boolean:VscodePopupConstant",
                        "Constant:VscodePopupConstant",
                        "Operator:VscodePopupOperator",
                        "Delimiter:VscodePopupPunctuation",
                        "PreProc:VscodePopupKeyword",
                        "Include:VscodePopupKeyword",
                        "Define:VscodePopupKeyword",
                        "Macro:VscodePopupKeyword",
                        "@function:VscodePopupFunction",
                        "@method:VscodePopupFunction",
                        "@function.builtin:VscodePopupFunction",
                        "@type:VscodePopupType",
                        "@type.builtin:VscodePopupType",
                        "@keyword:VscodePopupKeyword",
                        "@keyword.function:VscodePopupKeyword",
                        "@keyword.return:VscodePopupKeyword",
                        "@string:VscodePopupString",
                        "@string.escape:VscodePopupString",
                        "@string.special:VscodePopupString",
                        "@number:VscodePopupNumber",
                        "@float:VscodePopupNumber",
                        "@boolean:VscodePopupConstant",
                        "@constant:VscodePopupConstant",
                        "@constant.builtin:VscodePopupConstant",
                        "@operator:VscodePopupOperator",
                        "@variable:VscodePopupIdentifier",
                        "@variable.builtin:VscodePopupIdentifier",
                        "@property:VscodePopupIdentifier",
                        "@field:VscodePopupIdentifier",
                        "@parameter:VscodePopupIdentifier",
                        "@punctuation.delimiter:VscodePopupPunctuation",
                        "@punctuation.bracket:VscodePopupPunctuation",
                        "@punctuation.special:VscodePopupPunctuation",
                        "@markup.heading:VscodeHoverHeading",
                        "@markup.raw:VscodeHoverCode",
                        "@markup.raw.block:VscodeHoverCode",
                        "@markup.raw.delimiter:VscodeHoverMuted",
                        "@markup.link:VscodeHoverLink",
                        "@markup.link.label:VscodeHoverLink",
                        "@markup.link.url:VscodeHoverMuted",
                        "@markup.strong:VscodeHoverStrong",
                        "@markup.italic:VscodeHoverItalic",
                        "@punctuation.delimiter:VscodeHoverMuted",
                        "markdownH1:VscodeHoverHeading",
                        "markdownH2:VscodeHoverHeading",
                        "markdownH3:VscodeHoverHeading",
                        "markdownH4:VscodeHoverHeading",
                        "markdownH5:VscodeHoverHeading",
                        "markdownH6:VscodeHoverHeading",
                        "markdownHeadingDelimiter:VscodeHoverHeading",
                        "markdownCode:VscodeHoverCode",
                        "markdownCodeDelimiter:VscodeHoverMuted",
                        "markdownCodeBlock:VscodeHoverCode",
                        "markdownCodeBlockDelimiter:VscodeHoverMuted",
                        "markdownRule:VscodeHoverMuted",
                        "markdownUrl:VscodeHoverLink",
                        "markdownLinkText:VscodeHoverLink",
                        "markdownId:VscodeHoverMuted",
                        "markdownBold:VscodeHoverStrong",
                        "markdownItalic:VscodeHoverItalic",
                        "markdownBlockquote:VscodeHoverMuted",
                        "markdownListMarker:VscodeHoverNormal",
                        "markdownOrderedListMarker:VscodeHoverNormal",
                    }, ","),
                    scrollbar = true,
                },
            },
            keyword = {
                range = 'full',
            },
        },
        signature = {
            window = {
                border = {
                    { "█", "BlinkCmpSignatureHelpBorder" },
                    { "▀", "BlinkCmpSignatureHelpBorder" },
                    { "█", "BlinkCmpSignatureHelpBorder" },
                    { "█", "BlinkCmpSignatureHelpBorder" },
                    { "█", "BlinkCmpSignatureHelpBorder" },
                    { "▄", "BlinkCmpSignatureHelpBorder" },
                    { "█", "BlinkCmpSignatureHelpBorder" },
                    { "█", "BlinkCmpSignatureHelpBorder" },
                },
                winhighlight = table.concat({
                    "Normal:BlinkCmpSignatureHelp",
                    "FloatBorder:BlinkCmpSignatureHelpBorder",
                    "Identifier:VscodePopupIdentifier",
                    "Function:VscodePopupFunction",
                    "Statement:VscodePopupKeyword",
                    "Keyword:VscodePopupKeyword",
                    "Conditional:VscodePopupKeyword",
                    "Repeat:VscodePopupKeyword",
                    "Exception:VscodePopupKeyword",
                    "Type:VscodePopupType",
                    "StorageClass:VscodePopupType",
                    "Structure:VscodePopupType",
                    "Typedef:VscodePopupType",
                    "String:VscodePopupString",
                    "Character:VscodePopupString",
                    "Number:VscodePopupNumber",
                    "Float:VscodePopupNumber",
                    "Boolean:VscodePopupConstant",
                    "Constant:VscodePopupConstant",
                    "Operator:VscodePopupOperator",
                    "Delimiter:VscodePopupPunctuation",
                    "PreProc:VscodePopupKeyword",
                    "Include:VscodePopupKeyword",
                    "Define:VscodePopupKeyword",
                    "Macro:VscodePopupKeyword",
                    "@function:VscodePopupFunction",
                    "@method:VscodePopupFunction",
                    "@function.builtin:VscodePopupFunction",
                    "@type:VscodePopupType",
                    "@type.builtin:VscodePopupType",
                    "@keyword:VscodePopupKeyword",
                    "@keyword.function:VscodePopupKeyword",
                    "@keyword.return:VscodePopupKeyword",
                    "@string:VscodePopupString",
                    "@string.escape:VscodePopupString",
                    "@string.special:VscodePopupString",
                    "@number:VscodePopupNumber",
                    "@float:VscodePopupNumber",
                    "@boolean:VscodePopupConstant",
                    "@constant:VscodePopupConstant",
                    "@constant.builtin:VscodePopupConstant",
                    "@operator:VscodePopupOperator",
                    "@variable:VscodePopupIdentifier",
                    "@variable.builtin:VscodePopupIdentifier",
                    "@property:VscodePopupIdentifier",
                    "@field:VscodePopupIdentifier",
                    "@parameter:VscodePopupIdentifier",
                    "@punctuation.delimiter:VscodePopupPunctuation",
                    "@punctuation.bracket:VscodePopupPunctuation",
                    "@punctuation.special:VscodePopupPunctuation",
                }, ","),
            },
        },
        sources = {
            default = { 'lsp', 'path', 'snippets' },
        },
    },
    opts_extend = { 'sources.default' },
    config = function(_, opts)
        local blink_ok, blink = pcall(require, "blink.cmp")
        if not blink_ok then
            blink_ok, blink = pcall(require, "blink-cmp")
        end
        if not blink_ok then
            vim.notify(vim.inspect(blink), vim.log.levels.ERROR)
            return
        end
        blink.setup(opts)
    end,
}
