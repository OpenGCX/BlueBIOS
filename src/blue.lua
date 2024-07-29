local component = component ---@diagnostic disable-line: undefined-global
local computer = computer ---@diagnostic disable-line: undefined-global

computer.setArchitecture("Lua 5.4")

local gpu, res_x, res_y, access_drive, initialize, bl_bin, centrize, boot_address, boot_drive, result, state, handle, boot_time, event, code, internet, request, data, shift, caps_lock, letter, char, command, reason, chunk, isReadOnly, clipboard
gpu = component.proxy(component.list("gpu")())
gpu.bind(component.proxy(component.list("screen")()).address)

_G.blue = {}
blue.vb = {}
blue.fn = {}
res_x, res_y = gpu.getResolution()

if gpu.getDepth() > 1 then
    gpu.setForeground(0x9cc3db)
    gpu.setBackground(0x003150)
end

access_drive = function(drive, action, file, extra_arg) if extra_arg then return pcall(component.invoke, drive, action, file, extra_arg) else return pcall(component.invoke, drive, action, file) end end

function initialize(drive, opt_file)
    state, handle = access_drive(drive, "open", opt_file)
    if state then
        data = ""
        ::parse::
        _, chunk = access_drive(drive, "read", handle, math.maxinteger)
        if chunk then
            data = data .. chunk
            goto parse
        end
        access_drive(drive, "close", handle)
        return data
    else
        return false
    end
end

function centrize(message)
    gpu.fill(1, 1, res_x, res_y, " ")
    return gpu.set(math.ceil(res_x/2-#message/2), math.ceil(res_y/2),  message)
end

function blue.fn.shell()
    _G.buffer = {}
    _G.print = function(text)
        for _ in string.gmatch(tostring(text), "[^\r\n]+") do
            if #tostring(text) > res_x then
                for i=1,math.ceil(#tostring(text)/res_x) do
                    buffer[#buffer+1] = string.sub(tostring(text), (i == 1 and 1) or res_x * (i-1), res_x*i)
                end
            else
                buffer[#buffer+1] = tostring(text)
            end
        end
    end

    buffer[1] = "bootloader> "
    shift = false
    caps_lock = false
    command = ""

    ::render::
    centrize("")

    if gpu.getDepth() < 1 then
        gpu.setBackground(0x003150)
    end

    for i=1,res_y do
        if buffer[#buffer-i+1] then
            if i == 1 and gpu.getDepth() < 1 then
                gpu.setForeground(0xaec5d4)
                gpu.set(1, res_y-i+1, buffer[#buffer-i+1])
                gpu.setForeground(0x9cc3db)
            else
                gpu.set(1, res_y-i+1, buffer[#buffer-i+1])
            end
        end
    end

    event, _, char, code = computer.pullSignal(1)
    if not char then
        if event == "key_down" then
            if code == 42 or code == 54 then
                shift = true
            elseif code == 58 then
                caps_lock = not caps_lock
            end
        elseif event == "key_up" then
            if code == 42 or code == 54 then
                shift = false
            end
        end
    else
        if event == "key_down" then
            if code == 28 then
                if command == "exit" then
                    return
                elseif command == "reboot" then
                    computer.shutdown(1)
                elseif command == "shutdown" then
                    computer.shutdown()
                end
                result, reason = pcall(load(command))
                if reason then
                    for _ in string.gmatch(reason, "[^\r\n]+") do
                        if #reason > res_x then
                            for i=1,math.ceil(#reason/res_x) do
                                buffer[#buffer+1] = string.sub(reason, (i == 1 and 1) or res_x * (i-1), res_x*i)
                            end
                        else
                            buffer[#buffer+1] = reason
                        end
                    end
                end
                buffer[#buffer+1] = "bootloader> "
                command = ""
                goto render
            elseif code == 14 then
                if #buffer[#buffer] > 12 then
                    command = string.sub(command, 1, #command-1)
                    buffer[#buffer] = string.sub(buffer[#buffer], 1, #buffer[#buffer]-1)
                end
                goto render
            elseif (char < 127 and char > 31) then
                letter = string.char(char)
                if shift or caps_lock then
                    letter = string.upper(letter)
                end
                buffer[#buffer] = buffer[#buffer] .. letter
                command = command .. letter
            end
        elseif event == "clipboard" then
            buffer[#buffer] = buffer[#buffer] .. char
            command = command .. char
        end
    end

    goto render
end

centrize("Hold ALT to stay in bootloader")

_G.eeprom = component.proxy(component.list("eeprom")())

function computer.getBootAddress()
    return eeprom.getData()
end

function computer.setBootAddress(address)
    return eeprom.setData(address)
end

boot_address = computer.getBootAddress()
blue.vb.init = initialize(boot_address, "/init.lua")

if not blue.vb.init or blue.vb.init == "" then
    blue.vb.init = initialize(boot_address, "/OS.lua")
end

if blue.vb.init and blue.vb.init ~= "" and component.invoke(boot_address, "getLabel") ~= "tmpfs" then
    blue.vb.boot_drive = boot_address
else
    for i in pairs(component.list("filesystem")) do
        blue.vb.init = initialize(i, "/init.lua")
        blue.vb.boot_drive = i
        if not blue.vb.init or blue.vb.init == "" then
            blue.vb.init = initialize(i, "/OS.lua")
        end
        if blue.vb.init and blue.vb.init ~= "" then
            computer.setBootAddress(i)
            break
        end
    end
end

::plugins::

blue.vb.boot_label = component.invoke(blue.vb.boot_drive, "getLabel")
result = component.invoke(blue.vb.boot_drive, "list", "/bios/plugins/")
_, isReadOnly = access_drive(blue.vb.boot_drive, "isReadOnly")

if result then
    for _, j in ipairs(result) do
        if not j:match(".*/$") then
            handle = component.invoke(blue.vb.boot_drive, "open", "/bios/plugins/" .. j)
            load(component.invoke(blue.vb.boot_drive, "read", handle, math.huge) or "")()
        end
    end
else
    if not isReadOnly then
        state = pcall(component.invoke, blue.vb.boot_drive, "makeDirectory", "/bios/plugins/")
        if state then
            goto plugins
        end
    end
end

boot_time = computer.uptime()

if not blue.vb.init then
    goto bios
end

repeat
    event, _, _, code = computer.pullSignal(1)
    if event == "key_down" and code == (56 or 184) then
        goto bios
    end
until boot_time+1 <= computer.uptime()

::boot::

if gpu.getDepth() > 1 then
    centrize("Booting to " .. (blue.vb.boot_label ~= nil and blue.vb.boot_label or "N/A") .. " (" .. blue.vb.boot_drive .. ")")
else
    centrize("Booting to " .. (blue.vb.boot_label ~= nil and blue.vb.boot_label or "N/A"))
end
load(blue.vb.init)()

::bios::

bl_bin = initialize(boot_drive, "/bios/bl.bin")

if bl_bin then
    goto eof
end

for i in component.list("filesystem") do
    bl_bin = initialize(i, "/bios/bl.bin")
    if bl_bin and bl_bin ~= "" then
        goto eof
    end
end

if not bl_bin or bl_bin == "" then
    internet = component.list("internet")()
    if internet then
        if component.invoke(internet, "isHttpEnabled") then
            request = component.invoke(internet, "request", "https://raw.githubusercontent.com/OpenGCX/BlueBIOS/main/binaries/bl.bin")
            if request then
                data = ""
                ::parse::
                chunk = request.read()
                if chunk then
                    data = data .. chunk
                    goto parse
                end
                if data and data ~= "" then
                    bl_bin = data
                    if blue.vb.boot_drive then
                        if not isReadOnly then
                            state, handle = access_drive(blue.vb.boot_drive, "open", "/bios/bl.bin", "w")
                            if state then
                                access_drive(blue.vb.boot_drive, "write", handle, bl_bin)
                                access_drive(blue.vb.boot_drive, "close", handle)
                            end
                        end
                    end
                end
            end
        end
    end
end

::eof::

if bl_bin and bl_bin ~= "" then
    load(bl_bin)()
else
    centrize("")
    blue.fn.shell()
end

if blue.vb.init and blue.vb.init ~= "" then
    goto boot
else
    computer.shutdown(1)
end
