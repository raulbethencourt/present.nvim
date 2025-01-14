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
local create_floating_win = function(config)
    -- Create an immutable scratch buffer that is wiped once hidden
    local buf = vim.api.nvim_create_buf(false, true)

    -- Create floating window
    local win = vim.api.nvim_open_win(buf, true, config)

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

    local width = vim.o.columns
    local height = vim.o.lines

    ---@type vim.api.keyset.win_config[]
    local windows = {
        background = {
            relative = "editor",
            width = width,
            height = height,
            style = "minimal",
            col = 0,
            row = 0,
            zindex = 1
        },
        header = {
            relative = "editor",
            width = width,
            height = 1,
            style = "minimal",
            border = "rounded",
            col = 0,
            row = 0,
            zindex = 2
        },
        body = {
            relative = "editor",
            width = width - 11,
            height = height - 3,
            style = "minimal",
            col = 8,
            row = 5,
            zindex = 2
        },
        -- footer = {}
    }

    local background_float = create_floating_win(windows.background)
    local header_float = create_floating_win(windows.header)
    local body_float = create_floating_win(windows.body)

    vim.bo[header_float.buf].filetype = "markdown"
    vim.bo[body_float.buf].filetype = "markdown"

    local set_slide_content = function(idx)
        local slide = parsed.slides[idx]

        local padding = string.rep(" ", (width - #slide.title) / 2)
        local title = padding .. slide.title
        vim.api.nvim_buf_set_lines(header_float.buf, 0, -1, false, { title })
        vim.api.nvim_buf_set_lines(body_float.buf, 0, -1, false, slide.body)
    end

    local current_slide = 1
    vim.keymap.set("n", "n", function()
        current_slide = math.min(current_slide + 1, #parsed.slides)
        set_slide_content(current_slide)
    end, {
        buffer = body_float.buf
    })

    vim.keymap.set("n", "p", function()
        current_slide = math.max(current_slide - 1, 1)
        set_slide_content(current_slide)
    end, {
        buffer = body_float.buf
    })

    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(body_float.win, true)
    end, {
        buffer = body_float.buf
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
        buffer = body_float.buf,
        callback = function()
            -- Reset the values when we are done with the presentation
            for option, config in pairs(restore) do
                vim.opt[option] = config.original
            end

            pcall(vim.api.nvim_win_close, header_float.win, true)
            pcall(vim.api.nvim_win_close, background_float.win, true)
        end
    })

    set_slide_content(current_slide)
end

M.init { bufnr = 9 }

-- vim.print(parse_slides {
--     "# Hello",
--     "this is something else",
--     "# World",
--     "this is another else",
--     "## yeah",
-- })

return M
