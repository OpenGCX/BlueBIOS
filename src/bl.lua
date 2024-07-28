::sof::

local component = component or require("component") ---@diagnostic disable-line: undefined-global
local computer = computer or require("computer") ---@diagnostic disable-line: undefined-global

local gpu, res_x, res_y
-- known issues:
-- crashing on two drives with the same label
-- shell on no drive

gpu = component.proxy(component.list("gpu")())
res_x, res_y = gpu.getResolution()

local shift = false
local caps_lock = false

local function invert(boolean)
    if boolean then
        if gpu.getDepth() > 1 then
            gpu.setBackground(0x9cc3db)
            gpu.setForeground(0x003150)
        else
            gpu.setBackground(0xFFFFFF)
            gpu.setForeground(0x000000)
        end
    else
        if gpu.getDepth() > 1 then
            gpu.setBackground(0x003150)
            gpu.setForeground(0x9cc3db)
        else
            gpu.setBackground(0x000000)
            gpu.setForeground(0xFFFFFF)
        end
    end
end

invert(false)

local row_1 = { y = math.ceil(res_y/2) - 2, button_offset = 4, button_height = 1, opts = {}, optcount = 0 }
if gpu.getDepth() > 1 then
    _G.row_2 = { y = math.ceil(res_y/2) + 2, button_offset = 2, button_height = 0, opts = { "Power off", computer.getArchitecture(), "Internet boot", "Rename", "Format" }, optcount = 5 }
else
    _G.row_2 = { y = math.ceil(res_y/2) + 2, button_offset = 2, button_height = 0, opts = { "Halt", "Shell", "Netboot", "Rename", "Format" }, optcount = 5 }
end

local fdrive = component.list("filesystem")()
local boot_opts = {}
local selected_drive

row_1.opts = {}
if component.list("filesystem")() then
    for i in pairs(component.list("filesystem")) do
        local label = component.invoke(i, "getLabel")
        if label == "tmpfs" then
            goto continue
        end
        label = (label ~= nil and label) or string.sub(i, 1, 5)
        boot_opts[i] = 0
        for _, j in ipairs(component.invoke(i, "list", "/")) do
            if j == "init.lua" then
                boot_opts[i] = boot_opts[i] + 1
            elseif j == "OS.lua" then
                boot_opts[i] = boot_opts[i] + 2
            end
        end
        if not selected_drive then
            selected_drive = label
        end
        row_1.opts[i] = label
        row_1.optcount = row_1.optcount + 1
        ::continue::
    end
else
    blue.fn.shell()
    computer.shutdown(1)
end

local selected_row = row_1
local selected_button = 1

::render::

if component.list("filesystem")() ~= fdrive then
    goto sof
end

gpu.fill(1, 1, res_x, res_y, " ")

if selected_button < 1 then
    gpu.set(1, res_y, tostring(true))
    selected_button = selected_row.optcount
elseif selected_button > selected_row.optcount then
    gpu.set(1, res_y, tostring(false))
    selected_button = 1
end

local button_count = 0

local function render_row(row)
    local render_string = ""
    local opt_renders = {}
    local opt_render
    for _, j in pairs(row.opts) do
        button_count = button_count + 1
        opt_render = string.rep(" ", row.button_offset) .. j .. string.rep(" ", row.button_offset)
        opt_renders[#opt_renders+1] = opt_render
        render_string = render_string .. opt_render
    end
    button_count = 0
    return render_string, opt_renders
end

local row_1_string, row_1_opts = render_row(row_1)
local row_2_string, row_2_opts = render_row(row_2)

if selected_row == row_1 then
    local count = 0
    for i, j in pairs(row_1.opts) do
        count = count + 1
        local test_1 = (j == string.match(row_1_opts[selected_button], "^%s*(.-)%s*$"))
        local test_2 = count == selected_button
        if test_1 and test_2 then
            selected_drive = i
            break
        end
    end
end

gpu.set(math.ceil(res_x/2)-math.ceil(#row_1_string/2), row_1.y, row_1_string)
gpu.set(math.ceil(res_x/2)-math.ceil(#row_2_string/2), row_2.y, row_2_string)
if gpu.getDepth() > 1 then
    gpu.set(math.ceil(res_x/2)-math.ceil(75/2), res_y, "Use ← ↑ → ↓ to move cursor; Enter to confirm option; CTRL+ALT+C to shutdown")
else
    gpu.set(math.ceil(res_x/2)-math.ceil(26/2), res_y, "Use ← ↑ → ↓ to move cursor")
end

if selected_row == row_1 then
    _G.button_string = row_1_opts[selected_button] or row_1_opts[#row_1_opts]
    _G.full_string = row_1_string
    _G.determined_x = math.ceil(res_x/2)-math.ceil(#row_1_string/2)
    _G.determined_y = row_1.y
else
    _G.button_string = row_2_opts[selected_button] or row_2_opts[#row_2_opts]
    _G.full_string = row_2_string
    _G.determined_x = math.ceil(res_x/2)-math.ceil(#row_2_string/2)
    _G.determined_y = row_2.y
end

local pos1

if selected_row == row_1 then
    pos1 = string.find(full_string, button_string)
else
    pos1 = string.find(full_string, button_string)
end

invert(true)
gpu.set(determined_x+pos1-1, determined_y, button_string)
if selected_row.button_height > 0 then
    for i=1,selected_row.button_height do
        local text = string.rep(" ", #button_string)
        gpu.set(determined_x+pos1-1, determined_y-i, text)
        gpu.set(determined_x+pos1-1, determined_y+i, text)
    end
end
invert(false)

repeat
    local event, _, _, code = computer.pullSignal()
    if event == "key_down" then
        if code == 200 then
            selected_row = row_1
        elseif code == 208 then
            selected_row = row_2
        elseif code == 203 then
            selected_button = selected_button - 1
        elseif code == 205 then
            selected_button = selected_button + 1
        elseif code == 42 or code == 54 then
            shift = true
        elseif code == 58 then
            caps_lock = not caps_lock
        elseif code == 28 then
            if selected_row == row_1 then
                local text = "Booting..."
                gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                if blue.vb.boot_drive == selected_drive then
                    break
                end
                local drive = component.proxy(selected_drive)
                local label = drive.getLabel()
                local function initialize_file(file)
                    local handle = drive.open(file)
                    if handle then
                        local data = drive.read(handle, math.huge)
                        return data
                    end
                end
                if not label then
                    label = "N/A"
                end
                if boot_opts[selected_drive] == 1 then
                    blue.vb.init = initialize_file("/init.lua")
                else
                    blue.vb.init = initialize_file("/OS.lua")
                end
                blue.vb.boot_label = label
                blue.vb.boot_drive = selected_drive
                computer.setBootAddress(selected_drive)
                break
            else
                if selected_button == 1 then
                    computer.shutdown()
                elseif selected_button == 2 then
                    blue.fn.shell()
                elseif selected_button == 3 then
                    break
                elseif selected_button == 4 then
                    local text = "New label: " -- 11 characters
                    gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                    repeat
                        gpu.setForeground(0xFFFFFF)
                        gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                        local event, clipboard, char, code = computer.pullSignal()
                        if event == "key_down" then
                            if code == 42 or code == 54 then
                                shift = true
                            elseif code == 58 then
                                caps_lock = not caps_lock
                            elseif code == 14 then
                                if #text > 11 then
                                    text = string.sub(text, 1, #text-1)
                                    gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                end
                            elseif (char > 31 and char < 127) then
                                if shift or caps_lock then
                                    text = text .. string.upper(string.char(char))
                                else
                                    text = text .. string.char(char)
                                end
                            elseif code == 28 then
                                local label = string.sub(text, 12, #text)
                                local result, reason
                                if label == "" then
                                    result, reason = pcall(component.invoke, selected_drive, "setLabel", nil)
                                else
                                    result, reason = pcall(component.invoke, selected_drive, "setLabel", label)
                                end
                                if not result then
                                    gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                    text = "An error has occured: " .. reason
                                    gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                                    computer.pullSignal()computer.pullSignal()
                                    invert(false)
                                    break
                                else
                                    invert(false)
                                    break
                                end
                            end
                        elseif event == "key_up" then
                            if code == 42 or code == 54 then
                                shift = false
                            end
                        elseif event == "clipboard" then
                            text = text .. clipboard
                        end
                    until false
                    goto sof
                elseif selected_button == 5 then
                    gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                    gpu.setForeground(0xFFFFFF)
                    local label = component.invoke(selected_drive, "getLabel")
                    local text = "Format " .. (label ~= nil and label or "N/A") .. " (" .. selected_drive .. ")? (Y/N)"
                    gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                    repeat
                        local event, _, char = computer.pullSignal()
                        if event == "key_down" then
                            if string.char(char) == "y" then
                                gpu.fill(1, math.ceil(res_y/2)+5, res_x, 1, " ")
                                text = "Formatting..."
                                local remove_time = computer.uptime()
                                gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                                local fs = component.proxy(selected_drive)
                                local function format(path)
                                    for _, i in ipairs(fs.list(path ~= nil and path or "/")) do
                                        if string.match(i, "/$") ~= nil then
                                            format("/" .. (path ~= nil and path or "") .. i)
                                        else
                                            fs.remove("/" .. (path ~= nil and path or "") .. i)
                                        end
                                    end
                                end
                                fs.setLabel(nil)
                                format()
                                if remove_time == computer.uptime() then
                                    text = "Formatted in less than a second"
                                else
                                    text = "Formatted in " .. computer.uptime()-remove_time .. " seconds"
                                end
                                gpu.set(math.ceil(res_x/2)-math.ceil(#text/2), math.ceil(res_y/2)+5, text)
                                computer.pullSignal()computer.pullSignal()
                                break
                            else
                                break
                            end
                        end
                    until false
                    goto sof
                end
            end
        end
    elseif event == "key_up" then
        if code == 42 or code == 54 then
            shift = false
        end
    end
    goto render
until false
