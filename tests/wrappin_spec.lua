local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)

local wrappin = require("scripts.wrappin")

local function assert_lines(expected, label)
    local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    if not vim.deep_equal(actual, expected) then
        error(label .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual))
    end
end

local function with_buffer(lines, fn)
    vim.cmd("enew!")
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    fn()
    vim.cmd("bwipeout!")
end

local function test_wraps_single_long_line()
    with_buffer({
        "alpha beta gamma delta",
    }, function()
        wrappin.run({
            start_line = 0,
            end_line = 0,
            max_width = 16,
        })

        assert_lines({
            "alpha beta gamma",
            "delta",
        }, "wrappin.run should wrap a single long line")
    end)
end

local function test_preserves_multi_line_paragraph_content()
    with_buffer({
        "Our goal is to extend the functionality of agentic coding agents by creating",
        "mods in the Odin programming language. Each mod should strive to be a single, monolithic sourcefile that implements one core feature, or set of related features.",
    }, function()
        wrappin.run({
            start_line = 0,
            end_line = 1,
        })

        assert_lines({
            "Our goal is to extend the functionality of agentic coding agents by creating mods in the Odin programming language. Each mod should strive to be a single, monolithic sourcefile that implements one core feature, or set of related features.",
        }, "wrappin.run should keep all selected paragraph text")
    end)
end

local function test_visual_selection_works_on_first_invocation()
    with_buffer({
        "alpha beta gamma delta",
    }, function()
        vim.cmd("delmarks < >")
        vim.cmd.normal({ args = { "ggV" }, bang = true })

        wrappin.run_visual_selection({
            max_width = 16,
        })

        local ok = vim.wait(1000, function()
            return vim.api.nvim_buf_line_count(0) == 2
        end)

        if not ok then
            error("wrappin.run_visual_selection did not apply on the first visual invocation")
        end

        assert_lines({
            "alpha beta gamma",
            "delta",
        }, "wrappin.run_visual_selection should use the live visual range")
    end)
end

local function run_all()
    test_wraps_single_long_line()
    test_preserves_multi_line_paragraph_content()
    test_visual_selection_works_on_first_invocation()
end

run_all()
