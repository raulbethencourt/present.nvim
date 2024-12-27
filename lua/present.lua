local M = {}

M.setup = function()
    -- nothing...
end

---@class present.Slides
---@field slides present.Slide[]: The slides of the file

---@class present.Slide
---@field title string: The title of the slide
---@field body string[]: The body of the slide


---Takes some lines and parses them
---@param lines string[]: The lines in the buffer
---@return present.Slides
---
local parse_slides = function(lines)
    local slides = { slides = {} }
    local current_slide = {
        title = "",
        body = {}
    }

    local separator = "^#"

    for _, line in ipairs(lines) do
        if line:find(separator) then
            if #current_slide.title > 0 then
                table.insert(slides.slides, current_slide)
            end

            current_slide = {
                title = line,
                body = {}
            }
        else
            -- TODO: Continue 8:10
            table.insert(current_slide.body, line)
        end
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
        vim.api.nvim_buf_set_lines(float_win.buf, 0, -1, false, parsed.slides[current_slide].body)
    end, {
        buffer = float_win.buf
    })

    vim.keymap.set("n", "p", function()
        current_slide = math.max(current_slide - 1, 1)
        vim.api.nvim_buf_set_lines(float_win.buf, 0, -1, false, parsed.slides[current_slide].body)
    end, {
        buffer = float_win.buf
    })

    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(float_win.win, true)
    end, {
        buffer = float_win.buf
    })

    local restore = {
        cmdheight = {
            original = vim.o.cmdheight,
            actual = 0
        }
    }
    -- Set the options we want during presentation
    for option, config in pairs(restore) do
        vim.opt[option] = config.actual
    end

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = float_win.buf,
        callback = function()
            -- Reset the values when we are done with the presentation
            for option, config in pairs(restore) do
                vim.opt[option] = config.original
            end
        end
    })

    vim.api.nvim_buf_set_lines(float_win.buf, 0, -1, false, parsed.slides[1].body)
end

M.init { bufnr = 38 }

-- vim.print(parse_slides {
--     "# Hello",
--     "this is something else",
--     "# World",
--     "this is another else",
--     "## yeah",
-- })

return M
