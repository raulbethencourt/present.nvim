local M = {}

M.setup = function()
    -- nothing...
end

---@class present.Slides
---@fields slides string[]: The slides of the file

---Takes some lines and parses them
---@param lines string[]: The lines in the buffer
---@return present.Slides
---
local parse_slides = function(lines)
    local slides = { slides = {} }
    local current_slide = {}

    local separator = "^#"

    --- TODO: Continue...
    --- Time 10:41

    for _, line in ipairs(lines) do
        if line:find(separator) then
            if #current_slide > 0 then
                table.insert(slides.slides, current_slide)
            end

            current_slide = {}
        end

        table.insert(current_slide, line)
    end

    table.insert(slides.slides, current_slide)

    return slides
end

---Return a floating window
---@param opts? {[any]?:integer}
---@return [any]
---
local create_floating_win = function(opts)
    opts = opts or {}

    -- Create an immutable scratch buffer that is wiped once hidden
    local buf = vim.api.nvim_create_buf(false, true)

    -- Create a floating window using the scratch buffer postioned in the middle
    local height = opts.height or vim.o.lines
    local width = opts.width or vim.o.columns
    local row = math.ceil((vim.o.lines - height) / 2)
    local col = math.ceil((vim.o.columns - width) / 2)

    ---@diagnostic disable-next-line: param-type-mismatch
    local win = vim.api.nvim_open_win(buf, true, {
        style = "minimal",
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = 'rounded'
    })
    return { buf = buf, win = win }
end

---Start with the presentation
---@param opts? {[any]?:integer}
---
M.init = function(opts)
    opts = opts or {}
    opts.bufnr = opts.bufnr or 0

    local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
    local parsed = parse_slides(lines)
    local float_win = create_floating_win()

    local current_slide = 1
    vim.keymap.set("n", "n", function()
        current_slide = math.min(current_slide + 1, #parsed.slides)
        vim.api.nvim_buf_set_lines(float_win.buf, 0, -1, false, parsed.slides[current_slide])
    end, {
        buffer = float_win.buf
    })

    vim.keymap.set("n", "p", function()
        current_slide = math.max(current_slide - 1, 1)
        vim.api.nvim_buf_set_lines(float_win.buf, 0, -1, false, parsed.slides[current_slide])
    end, {
        buffer = float_win.buf
    })

    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(float_win.win, true)
    end, {
        buffer = float_win.buf
    })

    -- TODO: continue 3:35 ...

    vim.api.nvim_buf_set_lines(float_win.buf, 0, -1, false, parsed.slides[1])
end

-- M.init { bufnr = 9 }

-- vim.print(parse_slides {
--     "# Hello",
--     "this is something else",
--     "# World",
--     "this is another else",
--     "## yeah",
-- })

return M
