local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)

local function fresh_visrep()
    local loaded = package.loaded["scripts.visrep"]
    if loaded and loaded._reset_for_tests then
        loaded._reset_for_tests()
    end
    package.loaded["scripts.visrep"] = nil
    return require("scripts.visrep")
end

local function assert_eq(actual, expected, label)
    if not vim.deep_equal(actual, expected) then
        error(label .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual))
    end
end

local function assert_true(value, label)
    if not value then
        error(label .. "\nexpected truthy value")
    end
end

local function with_patched_fn(name, replacement, fn)
    local original = vim.fn[name]
    vim.fn[name] = replacement
    local ok, err = xpcall(fn, debug.traceback)
    vim.fn[name] = original
    if not ok then
        error(err)
    end
end

local function with_suppressed_echo(fn)
    local original = vim.api.nvim_echo
    vim.api.nvim_echo = function() end
    local ok, err = xpcall(fn, debug.traceback)
    vim.api.nvim_echo = original
    if not ok then
        error(err)
    end
end

local function with_buffer(lines, fn)
    vim.cmd("enew!")
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    local ok, err = xpcall(fn, debug.traceback)
    vim.cmd("bwipeout!")
    if not ok then
        error(err)
    end
end

local function set_visual_marks(start_row, start_col, end_row, end_col)
    vim.fn.setpos("'<", { 0, start_row, start_col + 1, 0 })
    vim.fn.setpos("'>", { 0, end_row, end_col + 1, 0 })
end

local function run_with_keys(queue, fn)
    local index = 0
    with_patched_fn("getchar", function()
        index = index + 1
        local value = queue[index]
        if value == nil then
            error("getchar queue exhausted")
        end
        return value
    end, fn)
end

local function test_build_literal_core_encodes_unicode()
    local visrep = fresh_visrep()
    assert_eq(
        visrep._test.build_literal_core("aé🙂"),
        "\\%u0061\\%u00E9\\%U0001F642",
        "build_literal_core should encode ASCII, BMP, and astral codepoints"
    )
end

local function test_marks_to_range_normalizes_order_and_uses_exclusive_utf8_end()
    local visrep = fresh_visrep()

    with_buffer({ "hé🙂z" }, function()
        local emoji_col = vim.str_byteindex("hé🙂z", 2)
        local accent_col = vim.str_byteindex("hé🙂z", 1)
        local range = visrep._test.marks_to_range(0, { 1, emoji_col }, { 1, accent_col })

        assert_eq(range.srow, 0, "marks_to_range should convert rows to 0-based indices")
        assert_eq(range.scol, accent_col, "marks_to_range should normalize reversed start/end columns")
        assert_eq(range.ecol, emoji_col + 4, "marks_to_range should convert the last UTF-8 byte start to an exclusive end")
    end)
end

local function test_build_match_index_separates_boundary_and_anywhere_matches()
    local visrep = fresh_visrep()

    with_buffer({ "cat scatter bobcat cat", "cat" }, function()
        local patterns = visrep._test.build_patterns("cat")
        local by_any, by_bnd, nav_any, nav_bnd = visrep._test.build_match_index(
            0,
            vim.api.nvim_buf_get_lines(0, 0, -1, false),
            vim.regex(patterns.pattern_any),
            vim.regex(patterns.pattern_word)
        )

        assert_eq(#nav_any, 5, "anywhere mode should include substring matches")
        assert_eq(#nav_bnd, 3, "boundary mode should keep only whole-word matches")
        assert_eq(#by_any[0], 4, "anywhere mode should index all matches on the first line")
        assert_eq(#by_bnd[0], 2, "boundary mode should only keep two matches on the first line")
    end)
end

local function test_filter_by_scope_handles_charwise_and_block_ranges()
    local visrep = fresh_visrep()
    local nav = {
        { lnum = 0, col0 = 0, col1 = 3 },
        { lnum = 0, col0 = 5, col1 = 8 },
        { lnum = 1, col0 = 2, col1 = 4 },
        { lnum = 2, col0 = 2, col1 = 5 },
    }

    local _, charwise_nav = visrep._test.filter_by_scope({}, nav, {
        srow = 0,
        scol = 4,
        erow = 1,
        ecol = 4,
    })
    assert_eq(#charwise_nav, 2, "charwise scope should keep only matches fully inside the span")
    assert_eq(charwise_nav[1].col0, 5, "charwise scope should keep the later first-line match")
    assert_eq(charwise_nav[2].lnum, 1, "charwise scope should keep the end-row match")

    local _, block_nav = visrep._test.filter_by_scope({}, nav, {
        srow = 0,
        scol = 2,
        erow = 2,
        ecol = 5,
        block = true,
    })
    assert_eq(#block_nav, 2, "block scope should enforce the same column band on each row")
    assert_eq(block_nav[1].lnum, 1, "block scope should skip the first-line out-of-band match")
    assert_eq(block_nav[2].lnum, 2, "block scope should keep later in-band matches")
end

local function test_build_replaced_line_and_apply_replacements()
    local visrep = fresh_visrep()

    assert_eq(
        visrep._test.build_replaced_line("abc abc abc", {
            { col0 = 0, col1 = 3 },
            { col0 = 4, col1 = 7 },
            { col0 = 8, col1 = 11 },
        }, "x"),
        "x x x",
        "build_replaced_line should splice replacement text between unmatched spans"
    )

    with_buffer({ "alpha beta", "beta alpha" }, function()
        visrep._test.apply_replacements_by_line(0, {
            [0] = { { col0 = 6, col1 = 10 } },
            [1] = { { col0 = 0, col1 = 4 } },
        }, "X")

        assert_eq(
            vim.api.nvim_buf_get_lines(0, 0, -1, false),
            { "alpha X", "X alpha" },
            "apply_replacements_by_line should rewrite only the targeted rows"
        )
    end)
end

local function test_replace_selected_region_handles_multiline_replacement()
    local visrep = fresh_visrep()

    with_buffer({ "aa one", "two bb" }, function()
        local ok = visrep._test.replace_selected_region(0, {
            srow = 0,
            scol = 3,
            erow = 1,
            ecol_excl = 3,
        }, "X\nY")

        assert_true(ok, "replace_selected_region should report success for populated selections")
        assert_eq(
            vim.api.nvim_buf_get_lines(0, 0, -1, false),
            { "aa X", "Y bb" },
            "replace_selected_region should preserve prefix/suffix around multiline replacements"
        )
    end)
end

local function test_choose_separator_skips_pattern_and_replacement_bytes()
    local visrep = fresh_visrep()
    assert_eq(
        visrep._test.choose_separator("alpha/beta", "gamma#delta"),
        "%",
        "choose_separator should skip separators already present in the pattern or replacement"
    )
end

local function test_run_replaces_whole_words_by_default()
    local visrep = fresh_visrep()

    with_buffer({ "cat scatter bobcat cat" }, function()
        vim.api.nvim_win_set_cursor(0, { 1, 4 })
        set_visual_marks(1, 0, 1, 2)

        with_suppressed_echo(function()
            run_with_keys({ string.byte("d"), string.byte("o"), string.byte("g"), 13 }, function()
                visrep.run()
            end)
        end)

        assert_eq(
            vim.api.nvim_buf_get_lines(0, 0, -1, false)[1],
            "dog scatter bobcat dog",
            "run should default keyword selections to boundary-only replacement"
        )
        assert_eq(
            vim.api.nvim_win_get_cursor(0),
            { 1, 4 },
            "run should restore the cursor after applying replacements"
        )
    end)
end

local function test_run_tab_toggles_to_anywhere_mode()
    local visrep = fresh_visrep()

    with_buffer({ "cat scatter bobcat cat" }, function()
        set_visual_marks(1, 0, 1, 2)

        with_suppressed_echo(function()
            run_with_keys({ 9, string.byte("d"), string.byte("o"), string.byte("g"), 13 }, function()
                visrep.run()
            end)
        end)

        assert_eq(
            vim.api.nvim_buf_get_lines(0, 0, -1, false)[1],
            "dog sdogter bobdog dog",
            "run should replace substring matches after toggling to anywhere mode"
        )
    end)
end

local function test_run_replaces_utf8_selections_without_byte_artifacts()
    local visrep = fresh_visrep()

    with_buffer({ "hé hé" }, function()
        local col = vim.str_byteindex("hé hé", 1)
        set_visual_marks(1, col, 1, col)

        with_suppressed_echo(function()
            run_with_keys({ string.byte("o"), 13 }, function()
                visrep.run()
            end)
        end)

        assert_eq(
            vim.api.nvim_buf_get_lines(0, 0, -1, false)[1],
            "ho ho",
            "run should replace whole UTF-8 characters rather than leaving byte fragments"
        )
    end)
end

local function test_run_uses_prompt_path_for_multiline_selections()
    local visrep = fresh_visrep()

    with_buffer({ "aa one", "two bb" }, function()
        set_visual_marks(1, 3, 2, 2)

        with_suppressed_echo(function()
            with_patched_fn("input", function()
                return "X\nY"
            end, function()
                visrep.run()
            end)
        end)

        assert_eq(
            vim.api.nvim_buf_get_lines(0, 0, -1, false),
            { "aa X", "Y bb" },
            "run should use the prompt path for multiline selections and preserve surrounding text"
        )
    end)
end

local function run_all()
    test_build_literal_core_encodes_unicode()
    test_marks_to_range_normalizes_order_and_uses_exclusive_utf8_end()
    test_build_match_index_separates_boundary_and_anywhere_matches()
    test_filter_by_scope_handles_charwise_and_block_ranges()
    test_build_replaced_line_and_apply_replacements()
    test_replace_selected_region_handles_multiline_replacement()
    test_choose_separator_skips_pattern_and_replacement_bytes()
    test_run_replaces_whole_words_by_default()
    test_run_tab_toggles_to_anywhere_mode()
    test_run_replaces_utf8_selections_without_byte_artifacts()
    test_run_uses_prompt_path_for_multiline_selections()
end

run_all()
