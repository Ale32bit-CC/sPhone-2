--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit & Rph
-- LICENSE: GNU GPLv3 (https://github.com/Ale32bit/sPhone-2/blob/master/LICENSE)
]]--

-- SPKv2

-- Apps path
-- .sPhone/apps/<id>

-- Config
-- .../<id>/spk.cfg
-- { name = "", author = "", version = "", type = "" }

if spk then
    return
end

_G.spk = {}
local systemApps = {
    "sPhone.shell",
    "sPhone.home",
    "sPhone.accountCreator",
}

local VBApps = {
    "sPhone.accountCreator",
}

function spk.launch(id,...)
    if type(id) ~= "string" then
        error("bad argument #1 (expected string, got "..type(id)..")",2)
    end

    if not fs.exists("/.sPhone/apps/"..id) then
        error("SPK not found",2)
    end
    if not fs.exists("/.sPhone/apps/"..id.."/spk.cfg") or fs.isDir("/.sPhone/apps/"..id.."/spk.cfg") then
        error("Invalid SPK config",2)
    end

    local f = fs.open("/.sPhone/apps/"..id.."/spk.cfg","r")
    local config = textutils.unserialize(f.readAll())
    f.close()

    if not config then
        error("Corrupted SPK config",2)
    end

    config.name = config.name or id
    config.author = config.author or ""
    config.version = config.version or "1.0"
    config.type = config.type or "generic"

    local main = loadfile("/.sPhone/apps/"..id.."/main.lua")
    if not main then
        error("Could not load SPK",2)
    end

    local _tENV = {
        task = nil,
        sPhone = sPhone,
        appdata = dofile('/.sPhone/system/appdata.lua')(id, nativeFS),
        nativeFS = nil,
    }

    for _,v in ipairs(systemApps) do
        if id == v then
            for _,b in ipairs(VBApps) do
                if id == b then
                    _tENV.fs = nativeFS
                    _tENV.task = task
                end
            end
        end
    end

    local ok, err = pcall(setfenv(main,setmetatable(
        _tENV,{__index = getfenv()}
    )),...)
    if not ok then
        printError(err)
        return false
    end
    return true
end

function spk.list()
    local l = {}
    for _,v in ipairs(fs.list("/.sPhone/apps")) do
        if fs.isDir("/.sPhone/apps/"..v) then
            table.insert(l,v)
        end
    end
    return l
end

function spk.exists(id)
    if type(id) ~= "string" then
        error("bad argument (expected string, got "..type(id)..")",2)
    end
    if fs.exists("/.sPhone/apps/"..id) then
        return true
    end
    return false
end

function spk.install(path)
    if type(path) ~= "string" then
        error("bad argument (expected string, got "..type(path)..")",2)
    end

    if not fs.exists(path) then
        error("File not found",2)
    end

    if fs.isDir(path) then
        error("Path is directory",2)
    end

    local f = fs.open(path,"r")
    local file = textutils.unserialize(f.readAll())
    f.close()

    if not file then
        error("Invalid SPK",2)
    end

    local config = file.config
    local files = file.files

    if not config or not files then
        error("Invalid SPK file",2)
    end

    if not config.id then
        error("Invalid SPK file",2)
    end

    local setupCheck = false
    if fs.exists("/.sPhone/config/setupMode") and not fs.isDir("/.sPhone/config/setupMode") then
        local f = fs.open("/.sPhone/config/setupMode","r")
        if f.readLine() == "true" then
            setupCheck = true
        end
        f.close()
    end

    if not setupCheck then
        for _,v in ipairs(systemApps) do
            if config.id == v then
                error("Cannot alter system SPK")
            end
        end
    end

    local function writeFile(patha,contenta) -- from Compress
        local file = nativeFS.open(patha,"w")
        file.write(contenta)
        file.close()
    end
    local function writeDown(inputa,dira)
        for i,v in pairs(inputa) do
            if type(v) == "table" then
                writeDown(v,dira.."/"..i)
            elseif type(v) == "string" then
                writeFile(dira.."/"..i,v)
            end
        end
    end

    writeDown(files,"/.sPhone/apps/"..config.id)

    local f = nativeFS.open("/.sPhone/apps/"..config.id.."/spk.cfg","w")
    f.write(textutils.serialize(config))
    f.close()

    nativeFS.makeDir("/.sPhone/appdata/"..config.id)

    return config.id
end

function spk.uninstall(id)
    if type(path) ~= "string" then
        error("bad argument (expected string, got "..type(path)..")",2)
    end

    if not fs.exists(".sPhone/apps/"..path) then
        error("ID not found",2)
    end

    for _,v in ipairs(systemApps) do
        if id == v then
            error("Cannot uninstall system app",2)
        end
    end

    nativeFS.delete("/.sPhone/apps/"..id)
    nativeFS.delete("/.sPhone/appdata/"..id)

    return true
end

function spk.getInfo(id)
    if type(id) ~= "string" then
        error("bad argument (expected string, got "..type(id)..")",2)
    end
    if not fs.exists("/.sPhone/apps/"..id.."/spk.cfg") then
        return nil
    end
    local f = fs.open("/.sPhone/apps/"..id.."/spk.cfg","r")
    local config = textutils.unserialize(f.readAll())
    f.close()
    return {
        id = id,
        name= config.name or id,
        author= config.author or "Unknown",
        version= config.version or "1.0",
        type= config.type or "generic",
    }
end

function spk.canAlter(id)
    for _,v in ipairs(systemApps) do
        if id == v then
            return false
        end
    end
    return true
end