local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)

local function fresh_numberline()
    local loaded = package.loaded["scripts.numberline"]
    if loaded and loaded._reset_for_tests then
        loaded._reset_for_tests()
    end
    package.loaded["scripts.numberline"] = nil
    return require("scripts.numberline")
end

local function assert_eq(actual, expected, label)
    if actual ~= expected then
        error(label .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual))
    end
end

local function with_buffer(lines, opts, fn)
    vim.cmd("enew!")
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.bo.buftype = opts.buftype or ""
    vim.bo.filetype = opts.filetype or ""
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_set_option_value("number", opts.number == true, { win = 0 })
    vim.api.nvim_set_option_value("relativenumber", opts.relativenumber == true, { win = 0 })
    fn()
    vim.cmd("bwipeout!")
end

local function test_render_line_formats_cursor_and_relative_rows()
    local numberline = fresh_numberline()

    assert_eq(
        numberline._test.render_line(3, 42, 0, 1),
        "%#LineNrPrefix#0%#CursorLineNr#42%#LineNr# %*",
        "render_line should zero-pad cursor lines and use CursorLineNr"
    )

    assert_eq(
        numberline._test.render_line(3, 42, -7, 1),
        "%#LineNrPrefix#00%#LineNr#7%#LineNr# %*",
        "render_line should use relative numbers when enabled"
    )

    assert_eq(
        numberline._test.render_line(3, 42, -7, 0),
        "%#LineNrPrefix#0%#LineNr#42%#LineNr# %*",
        "render_line should fall back to absolute numbers when relative mode is disabled"
    )
end

local function test_render_line_builds_large_numbers_lazily()
    local numberline = fresh_numberline()

    assert_eq(
        numberline._test.render_line(5, 12345, 0, 1),
        "%#LineNrPrefix#%#CursorLineNr#12345%#LineNr# %*",
        "render_line should support numbers beyond the eager cache without changing formatting"
    )
end

local function test_update_window_applies_statuscolumn_for_numbered_buffers()
    local numberline = fresh_numberline()
    local lines = {}
    for index = 1, 120 do
        lines[index] = "alpha"
    end

    with_buffer(lines, {
        number = true,
        relativenumber = true,
    }, function()
        numberline._test.update_window(0)

        assert_eq(
            vim.api.nvim_get_option_value("statuscolumn", { win = 0 }),
            "%!v:lua.FormatLineNr(3,1)",
            "update_window should install the cached statuscolumn expression"
        )

        assert_eq(
            vim.api.nvim_get_option_value("numberwidth", { win = 0 }),
            5,
            "update_window should widen the number column to digit width plus padding"
        )
    end)
end

local function test_update_window_clears_stale_statuscolumn_for_excluded_buffers()
    local numberline = fresh_numberline()

    with_buffer({ "help text" }, {
        buftype = "nofile",
        number = true,
        relativenumber = true,
    }, function()
        vim.api.nvim_set_option_value("statuscolumn", "stale", { win = 0 })
        numberline._test.update_window(0)

        assert_eq(
            vim.api.nvim_get_option_value("statuscolumn", { win = 0 }),
            "",
            "update_window should clear stale statuscolumn values for excluded buffers"
        )
    end)
end

local function test_update_window_tracks_cursorline_state_per_window()
    local numberline = fresh_numberline()

    with_buffer({ "alpha", "beta", "gamma" }, {
        number = true,
        relativenumber = true,
    }, function()
        local source_win = vim.api.nvim_get_current_win()
        vim.api.nvim_set_option_value("cursorline", false, { win = source_win })
        vim.api.nvim_set_option_value("cursorlineopt", "line", { win = source_win })
        vim.api.nvim_win_set_var(source_win, "_nl_user_cursorlineopt", "line")

        vim.cmd("vsplit")
        local target_win = vim.api.nvim_get_current_win()
        vim.api.nvim_set_option_value("cursorline", false, { win = target_win })
        vim.api.nvim_set_option_value("cursorlineopt", "screenline", { win = target_win })
        pcall(vim.api.nvim_win_del_var, target_win, "_nl_user_cursorlineopt")

        vim.api.nvim_set_current_win(source_win)
        numberline._test.update_window(target_win)

        assert_eq(
            vim.api.nvim_get_option_value("cursorline", { win = target_win }),
            true,
            "update_window should enable cursorline for the target window"
        )

        assert_eq(
            vim.api.nvim_get_option_value("cursorlineopt", { win = target_win }),
            "number",
            "update_window should force target cursorlineopt to number"
        )

        local ok_target, saved_target = pcall(vim.api.nvim_win_get_var, target_win, "_nl_user_cursorlineopt")
        assert_eq(ok_target, true, "target window should retain its own cursorlineopt backup")
        assert_eq(saved_target, "screenline", "target window backup should match its pre-update cursorlineopt")

        local saved_source = vim.api.nvim_win_get_var(source_win, "_nl_user_cursorlineopt")
        assert_eq(saved_source, "line", "update_window should not overwrite the source window backup")

        vim.api.nvim_win_close(target_win, true)
    end)
end

local function run_all()
    test_render_line_formats_cursor_and_relative_rows()
    test_render_line_builds_large_numbers_lazily()
    test_update_window_applies_statuscolumn_for_numbered_buffers()
    test_update_window_clears_stale_statuscolumn_for_excluded_buffers()
    test_update_window_tracks_cursorline_state_per_window()
end

run_all()
