local component = component ---@diagnostic disable-line: undefined-global
local computer = computer ---@diagnostic disable-line: undefined-global

local gpu, res_x, res_y, access_drive, initialize, bl_bin, centrize, eeprom, boot_address, init, boot_drive, boot_label, result, state, handle, boot_time, bios, event, code, internet, request, data, shell, shift, caps_lock, letter, char, command, reason, chunk
gpu = component.proxy(component.list("gpu")())
gpu.bind(component.proxy(component.list("screen")()).address)

res_x, res_y = gpu.getResolution()
gpu.setForeground(0x9cc3db)
gpu.setBackground(0x003150)

access_drive = function(drive, action, file, extra_arg) if extra_arg then return pcall(component.invoke, drive, action, file, extra_arg) else return pcall(component.invoke, drive, action, file) end end

function initialize(drive, opt_file)
    if opt_file then
        state, handle = access_drive(drive, "open", opt_file)
    else
        state, handle = access_drive(drive, "open", "/init.lua")
    end
    if state then
        _, data = access_drive(drive, "read", handle, math.maxinteger)
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

function shell()
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

    for i=1,res_y do
        if buffer[#buffer-i+1] then
            gpu.set(1, res_y-i+1, buffer[#buffer-i+1])
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
        end
    end

    goto render
end

centrize("Hold ALT to stay in bootloader")

eeprom = component.proxy(component.list("eeprom")())

function computer.getBootAddress()
    return eeprom.getData()
end

function computer.setBootAddress(address)
    return eeprom.setData(address)
end

boot_address = computer.getBootAddress()
init = initialize(boot_address)

if init then
    boot_drive = boot_address
else
    for i in pairs(component.list("filesystem")) do
        init = initialize(i)
        boot_drive = i
        if init then
            computer.setBootAddress(i)
            break
        end
    end
end

::plugins::

boot_label = component.invoke(boot_drive, "getLabel")
result = component.invoke(boot_drive, "list", "/bios/plugins/")

if result then
    for _, j in ipairs(result) do
        if not j:match(".*/$") then
            handle = component.invoke(boot_drive, "open", "/bios/plugins/" .. j)
            load(component.invoke(boot_drive, "read", handle, math.huge) or "")()
        end
    end
else
    state = pcall(component.invoke, boot_drive, "makeDirectory", "/bios/plugins/")
    if state then
        goto plugins
    end
end

boot_time = computer.uptime()

if not init then
    goto bios
end

if not bios then
    repeat
        event, _, _, code = computer.pullSignal(1)
        if event == "key_down" and code == (56 or 184) then
            bios = true
            break
        end
    until boot_time+1 <= computer.uptime()
end

::boot::

if not bios then
    centrize("Booting to " .. (boot_label ~= nil and boot_label or "N/A") .. " (" .. boot_drive .. ")")
    return load(init)()
end

::bios::

bios = false
bl_bin = initialize(boot_address, "/bios/bl.bin")

if bl_bin then
    goto eof
end

if boot_drive then
    for i in component.list("filesystem") do
        bl_bin = initialize(i, "/bios/bl.bin")
        if bl_bin then
            break
        end
    end
end

if not bl_bin then
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
                if data then
                    bl_bin = data
                    if boot_drive then
                        state, handle = access_drive(boot_drive, "open", "/bios/bl.bin", "w")
                        if state then
                            access_drive(boot_drive, "write", handle, bl_bin)
                            access_drive(boot_drive, "close", handle)
                        end
                    end
                end
            end
        end
    end
end

::eof::

if bl_bin then
    load(bl_bin)()
else
    centrize("")
    shell()
end

goto boot
