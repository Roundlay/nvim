local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)

local wrappin = require("scripts.wrappin")

local function assert_lines(expected, label)
    local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    if not vim.deep_equal(actual, expected) then
        error(label .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual))
    end
end

local function assert_cursor(expected_line, expected_col, label)
    local actual = vim.api.nvim_win_get_cursor(0)
    if actual[1] ~= expected_line or actual[2] ~= expected_col then
        error(label .. "\nexpected: " .. vim.inspect({ expected_line, expected_col }) .. "\nactual:   " .. vim.inspect(actual))
    end
end

local function with_buffer(lines, fn)
    wrappin._reset_for_tests()
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

local function test_reflows_comment_block_and_restores_exact_original()
    with_buffer({
        "-- alpha beta gamma delta epsilon",
    }, function()
        wrappin.run({
            start_line = 0,
            end_line = 0,
            max_width = 18,
        })

        assert_lines({
            "-- alpha beta",
            "-- gamma delta",
            "-- epsilon",
        }, "wrappin.run should wrap line comments with repeated prefixes")

        wrappin.run({
            start_line = 0,
            end_line = 2,
            max_width = 18,
        })

        assert_lines({
            "-- alpha beta gamma delta epsilon",
        }, "wrappin.run should restore the exact original text for tracked wrapped regions")
    end)
end

local function test_reflows_bullet_with_hanging_indent()
    with_buffer({
        "  - alpha beta gamma delta epsilon",
        "  zeta eta",
    }, function()
        wrappin.run({
            start_line = 0,
            end_line = 1,
            max_width = 18,
        })

        assert_lines({
            "  - alpha beta",
            "    gamma delta",
            "    epsilon zeta",
            "    eta",
        }, "wrappin.run should reflow bullet lists with hanging indents")
    end)
end

local function test_keeps_numbered_items_separate()
    with_buffer({
        "  1. alpha beta gamma delta",
        "  2. epsilon zeta eta theta",
    }, function()
        wrappin.run({
            start_line = 0,
            end_line = 1,
            max_width = 18,
        })

        assert_lines({
            "  1. alpha beta",
            "     gamma delta",
            "  2. epsilon zeta",
            "     eta theta",
        }, "wrappin.run should keep numbered items in separate blocks")
    end)
end

local function test_inherits_list_schema_from_context()
    with_buffer({
        "  - alpha beta gamma",
        "  delta epsilon zeta eta theta",
    }, function()
        wrappin.run({
            start_line = 1,
            end_line = 1,
            max_width = 16,
        })

        assert_lines({
            "  - alpha beta gamma",
            "    delta",
            "    epsilon zeta",
            "    eta theta",
        }, "wrappin.run should inherit a list continuation schema from the surrounding context")
    end)
end

local function test_inherits_comment_schema_for_prose_continuation()
    with_buffer({
        "                // alpha beta gamma",
        "                delta epsilon zeta eta theta",
    }, function()
        wrappin.run({
            start_line = 1,
            end_line = 1,
            max_width = 40,
        })

        assert_lines({
            "                // alpha beta gamma",
            "                // delta epsilon zeta",
            "                // eta theta",
        }, "wrappin.run should keep inheriting nearby comment schema for real prose continuations")
    end)
end

local function test_does_not_inherit_comment_schema_onto_code()
    with_buffer({
        "                // BRANCH",
        "                } else if (demand->entries[j].priority_class == key_entry.priority_class && demand->entries[j].priority_sort_key > key_entry.priority_sort_key) {",
        "                    swap = 1;",
        "                }",
    }, function()
        wrappin.run({
            start_line = 1,
            end_line = 1,
            max_width = 72,
        })

        assert_lines({
            "                // BRANCH",
            "                } else if (demand->entries[j].priority_class ==",
            "                key_entry.priority_class &&",
            "                demand->entries[j].priority_sort_key >",
            "                key_entry.priority_sort_key) {",
            "                    swap = 1;",
            "                }",
        }, "wrappin.run should not borrow a surrounding comment schema for selected code")
    end)
end

local function test_preserves_markdown_heading_prefix()
    with_buffer({
        "### alpha beta gamma delta epsilon",
    }, function()
        wrappin.run({
            start_line = 0,
            end_line = 0,
            max_width = 20,
        })

        assert_lines({
            "### alpha beta gamma",
            "    delta epsilon",
        }, "wrappin.run should preserve markdown heading prefixes instead of stripping them")
    end)
end

local function test_invalidates_exact_restore_after_edits()
    with_buffer({
        "  - alpha beta gamma delta epsilon",
    }, function()
        wrappin.run({
            start_line = 0,
            end_line = 0,
            max_width = 18,
        })

        vim.api.nvim_buf_set_lines(0, 1, 2, false, {
            "    gamma XX delta",
        })

        wrappin.run({
            start_line = 0,
            end_line = 2,
            max_width = 18,
        })

        assert_lines({
            "  - alpha beta",
            "    gamma XX delta",
            "    epsilon",
        }, "wrappin.run should invalidate exact restore after edits and reflow the current text instead")
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

        local mode = vim.api.nvim_get_mode().mode
        if mode == "v" or mode == "V" or mode == "\22" then
            error("wrappin.run_visual_selection should leave visual mode after applying the transform")
        end

        assert_lines({
            "alpha beta gamma",
            "delta",
        }, "wrappin.run_visual_selection should use the live visual range")
        assert_cursor(1, 0, "wrappin.run_visual_selection should restore the cursor to the transformed block")
    end)
end

local function run_all()
    test_wraps_single_long_line()
    test_reflows_comment_block_and_restores_exact_original()
    test_reflows_bullet_with_hanging_indent()
    test_keeps_numbered_items_separate()
    test_inherits_list_schema_from_context()
    test_inherits_comment_schema_for_prose_continuation()
    test_does_not_inherit_comment_schema_onto_code()
    test_preserves_markdown_heading_prefix()
    test_invalidates_exact_restore_after_edits()
    test_visual_selection_works_on_first_invocation()
end

run_all()
