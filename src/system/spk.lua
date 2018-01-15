--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit
-- LICENSE: GNU GPLv3 (https://github.com/Ale32bit/sPhone-2/blob/master/LICENSE)
]]--

-- SPKv2

-- Apps path
-- .sPhone/apps/<id>

-- Config
-- .../<id>/spk.cfg
-- { name = "", author = "", version = "", type = "" }

local function deepCopy(table)
    local tab = {}
    for i,v in pairs(table) do
        if i ~= "_G" then
            if type(v) == "table" then
                tab[i] = deepCopy(v)
            else
                tab[i] = v
            end
        end
    end
    return tab
end
local nativeFS = deepCopy(_G.fs)

_G.spk = {}
local systemApps = {
    "sphone.config"
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
    local ok, err = pcall(setfenv(main,setmetatable(
        {
            task = nil,
            sPhone = sPhone,
            appdata = dofile('./sPhone/appdata.lua')(id, nativeFS)
        },{__index = getfenv()}
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
        if not fs.isDir("/.sPhone/apps/"..v) then
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

    local function writeFile(patha,contenta) -- from Compress
        local file = fs.open(patha,"w")
        file.write(contenta)
        file.close()
    end
    function writeDown(inputa,dira)
        for i,v in pairs(inputa) do
            if type(v) == "table" then
                writeDown(v,dira.."/"..i)
            elseif type(v) == "string" then
                writeFile(dira.."/"..i,v)
            end
        end
    end

    writeDown(files,"/.sPhone/apps/"..config.id)

    local f = fs.open("/.sPhone/apps/"..config.id.."/spk.cfg","w")
    f.write(textutils.serialize(config))
    f.close()

    fs.makeDir("/.sPhone/appdata/"..config.id)

    return config.id
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