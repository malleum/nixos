local M = {}
local ns_id = vim.api.nvim_create_namespace("penger")

local function parse_number(str)
    local val = 1.0
    local is_annual = false
    
    if str:match("k$") then
        val = val * 1000
        str = str:sub(1, -2)
    end
    
    local num = tonumber(str)
    return num, is_annual
end

local function parse_line_value(val_str)
    local parts = vim.split(val_str, "%s+")
    local total = 0
    local ref = nil
    local percent = nil
    local is_annual = false
    
    local i = 1
    while i <= #parts do
        local part = parts[i]
        if part == "+" then
            -- ignore
        elseif part == "a" then
            is_annual = true
        elseif part:match("%%$") then
            percent = tonumber(part:sub(1, -2)) / 100.0
            i = i + 1
            if i <= #parts then
                ref = parts[i]
            end
        elseif part:match("^[%d%.]+k?$") then
            local n = 1
            if part:match("k$") then
                n = tonumber(part:sub(1, -2)) * 1000
            else
                n = tonumber(part)
            end
            if n then total = total + n end
        end
        i = i + 1
    end
    
    if is_annual then
        total = total / 12
    end
    
    return {
        fixed = total,
        percent = percent,
        ref = ref,
        is_annual = is_annual
    }
end

function M.refresh()
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    local defs = {}
    local sections = {}
    local items_map = {}
    
    local current_section_idx = nil
    
    for idx, line in ipairs(lines) do
        local str = vim.trim(line)
        local line_nr = idx - 1
        
        if str:match("^%-%-") then
            local sec_name = str:match("^%-%-%s*(.*)")
            current_section_idx = #sections + 1
            table.insert(sections, { line = line_nr, name = sec_name, total = 0 })
        elseif str ~= "" and not str:match("^#") then
            local name, rest = str:match("^(%S+)%s+(.*)$")
            if name and rest then
                local parsed = parse_line_value(rest)
                local def = { 
                    line = line_nr, 
                    name = name, 
                    parsed = parsed, 
                    section_idx = current_section_idx, 
                    raw = rest,
                    resolved_val = nil
                }
                table.insert(defs, def)
                
                if not parsed.ref then
                    def.resolved_val = parsed.fixed
                    items_map[name] = parsed.fixed
                end
            end
        end
    end
    
    local changes = true
    local loops = 0
    while changes and loops < 5 do
        changes = false
        loops = loops + 1
        for _, def in ipairs(defs) do
            if def.resolved_val == nil and def.parsed.ref then
                local ref_val = items_map[def.parsed.ref]
                if ref_val then
                    local val = def.parsed.fixed + (def.parsed.percent * ref_val)
                    if def.parsed.is_annual then
                         val = def.parsed.fixed + ((def.parsed.percent * ref_val) / 12)
                    end
                    def.resolved_val = val
                    items_map[def.name] = val
                    changes = true
                end
            end
        end
    end
    
    for _, def in ipairs(defs) do
        if def.resolved_val and def.section_idx and sections[def.section_idx] then
            sections[def.section_idx].total = sections[def.section_idx].total + def.resolved_val
        end
    end
    
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
    
    for _, def in ipairs(defs) do
        local needs_calc = def.parsed.is_annual or def.parsed.percent or (def.raw and def.raw:find("+", 1, true))
        if needs_calc and def.resolved_val then
             local val_str = string.format("  = %.2f", def.resolved_val)
             vim.api.nvim_buf_set_extmark(buf, ns_id, def.line, 0, {
                virt_text = {{val_str, "Comment"}},
                hl_mode = "combine",
             })
        end
    end

    local income = 0
    for _, sec in ipairs(sections) do
        if sec.name == "i" then
            income = sec.total
            break
        end
    end

    local running_expenses = 0
    local last_r_expenses = 0

    for _, sec in ipairs(sections) do
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Title", sec.line, 0, -1)
        
        if sec.name == "r" then
            local remaining = income - running_expenses
            last_r_expenses = running_expenses
            local total_str = string.format("  %.2f", remaining)
            vim.api.nvim_buf_set_extmark(buf, ns_id, sec.line, 0, {
                virt_text = {{total_str, "Special"}},
                hl_mode = "combine",
            })
        elseif sec.name == "t" then
            local total_str = string.format("  %.2f", running_expenses)
            vim.api.nvim_buf_set_extmark(buf, ns_id, sec.line, 0, {
                virt_text = {{total_str, "Special"}},
                hl_mode = "combine",
            })
        elseif sec.name == "rt" then
            local diff = running_expenses - last_r_expenses
            local total_str = string.format("  %.2f", diff)
            vim.api.nvim_buf_set_extmark(buf, ns_id, sec.line, 0, {
                virt_text = {{total_str, "Special"}},
                hl_mode = "combine",
            })
        else
            if sec.name ~= "i" then
                running_expenses = running_expenses + sec.total
            end
            if sec.total > 0 then
                local total_str = string.format("  %.2f", sec.total)
                vim.api.nvim_buf_set_extmark(buf, ns_id, sec.line, 0, {
                    virt_text = {{total_str, "Normal"}},
                    hl_mode = "combine",
                })
            end
        end
    end
end

function M.setup()
    vim.api.nvim_create_autocmd({"BufEnter", "TextChanged", "TextChangedI"}, {
        pattern = "*.pngr",
        callback = function()
            M.refresh()
        end,
    })
    
    vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
        pattern = "*.pngr",
        callback = function()
            vim.bo.filetype = "pngr"
            M.refresh()
        end,
    })
end

return M
