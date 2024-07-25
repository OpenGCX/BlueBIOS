local component = component ---@diagnostic disable-line: undefined-global
local computer = computer ---@diagnostic disable-line: undefined-global

local eeprom = component.proxy(component.list("eeprom")())
local gpu = component.proxy(component.list("gpu")())

local res_x, res_y = gpu.getResolution()
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x003150)

gpu.fill(1, 1, res_x, res_y, " ")

local line_count = 0
local new_line = function(text) line_count = line_count + 1; return gpu.set(1, line_count, text) end

function _G.reboot()
    new_line("=> This computer will reboot in 3 seconds")
    local time = computer.uptime()

    repeat until time+3 <= computer.uptime()
    new_line("=> Rebooting...")

    computer.shutdown(true)
end

new_line("Attempting to download Blue BIOS from the internet...")
if not component.list("internet")() then
    new_line("ERR No internet component")
    reboot()
end

local internet = component.proxy(component.list("internet")())

if not internet.isHttpEnabled() then
    new_line("ERR Http is disabled in your configuration")
    reboot()
end

local request = internet.request("https://raw.githubusercontent.com/OpenGCX/BlueBIOS/main/binaries/blue.bin")

if request then
    new_line("SUCCESS Fetched data")
    local data = ""
    local chunk
    ::parse::
    chunk = request.read()
    if chunk then
        data = data .. chunk
        goto parse
    end
    if data then
        new_line("Attempting to flash data...")
        local result, reason = pcall(component.invoke, eeprom.address, "set", data)
        if not result then
            new_line("ERR " .. tostring(reason))
            reboot()
        end
        new_line("SUCCESS Flashed EEPROM")
        eeprom.setLabel("Blue BIOS")
        new_line("SUCCESS Set EEPROM label to 'Blue BIOS'")
        reboot()
    end
    new_line("ERR An unexpected error has occured: requested data not available")
end

reboot()
