--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit & Rph
-- LICENSE: GNU GPLv3 (https://github.com/Ale32bit/sPhone-2/blob/master/LICENSE)
]]--

if sPhone then
    return
end

-- Make a FS copy before we fuck it up
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


local args = {... }
local task = {}

--BIOS

local oldp = os.pullEvent
os.pullEvent = os.pullEventRaw

local normalBoot = true

local function bootmenu()
    while true do
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        term.clear()
        term.setCursorPos(1,1)
        print("sPhone boot menu")
        print("1: Resume normal startup")
        print("2: Update sPhone")
        print("3: Quit sPhone [DEV]")
        local _,key = os.pullEvent("key")
        if key == 2 then
            break
        elseif key == 3 then
            local ok, err = pcall(setfenv(loadstring(http.get("https://raw.githubusercontent.com/Ale32bit/sPhone-2/master/src/installer.lua").readAll()),getfenv()))
            if not ok then
                printError("Failed to update")
                printError(err)
            else
                os.reboot()
            end
            break
        elseif key == 4 then
            normalBoot = false
            break
        end
    end
end

local logo = {{0,1,1,1,1},{1},{0,1,1,1,1},{0,0,0,0,0,1},{0,1,1,1,1}}
local w,h = term.getSize()

local function center(text)
    local _,y = term.getCursorPos()
    term.setCursorPos(math.ceil(w/2)-math.ceil(#text/2)+1,y)
    write(text)
end

term.setBackgroundColor(colors.blue)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)



local max = 0

for i = 1,#logo do
    if #logo[i] > max then
        max = #logo[i]
    end
end

local lwc = math.ceil(w/2-max/2)+1
local lhc = math.ceil(h/2-#logo/2)-1

paintutils.drawImage(logo,lwc,lhc)

term.setBackgroundColor(colors.blue)
term.setTextColor(colors.white)
term.setCursorPos(2,h)
write("Press ALT to enter menu")

term.setCursorPos(1,math.ceil(h/2+#logo/2))
center("sPhone 2")

term.setCursorPos(1,1)
write("Copyright (c) 2018 Ale32bit & Rph")

local timeout = os.startTimer(2.5)
while true do
    local e = {os.pullEvent() }
    if e[1] == "timer" and e[2] == timeout then
        break
    elseif e[1] == "key" and e[2] == keys.leftAlt then
        bootmenu()
        break
    end
end

os.pullEvent = oldp
sleep(0.1)
if not normalBoot then
    return false
end

local inPanic = false

-- Crash function

local function panic(reason)
    inPanic = true
    if task then
        for k in pairs(task.list()) do
            pcall(function()
                task.kill(k)
            end)
        end
    end
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1,1)
  print("sPhone crashed")
  print(reason or "Unknown reason")
end

_G.sPhone = {
  version = "2.0",
}

os.version = function()
    return "sPhone "..sPhone.version
end

function sPhone.require(lib)
    if not lib then
        return nil
    end
    if fs.exists("/.sPhone/system/libs/"..fs.getName(lib)) and not fs.isDir("/.sPhone/system/libs/"..fs.getName(lib)) then
        lib = "/.sPhone/system/libs/"..fs.getName(lib)
    elseif fs.exists("/.sPhone/system/libs/"..fs.getName(lib)..".lua") and not fs.isDir("/.sPhone/system/libs/"..fs.getName(lib)) then
        lib = "/.sPhone/system/libs/"..fs.getName(lib)..".lua"
    elseif fs.exists("/rom/apis/"..fs.getName(lib)) and not fs.isDir("/rom/apis/"..fs.getName(lib)) then
        lib = "/rom/apis/"..fs.getName(lib)
    elseif fs.exists("/rom/apis/"..fs.getName(lib))..".lua" and not fs.isDir("/rom/apis/"..fs.getName(lib)) then
        lib = "/rom/apis/"..fs.getName(lib)..".lua"
    elseif fs.exists(lib) then
        lib = lib --?
    elseif fs.exists(lib..".lua") then
        lib = lib..".lua" --?
    elseif getfenv()[lib] then
        return getfenv()[lib]
    end


    local tEnv = {}
    setmetatable( tEnv, { __index = _G } )
    local fnAPI, err = loadfile( lib, tEnv )
    if fnAPI then
        local ok, err = pcall( fnAPI )
        if not ok then
            printError( err )
            return nil
        end
    else
        printError( err )
        return nil
    end

    local tAPI = {}
    for k,v in pairs( tEnv ) do
        if k ~= "_ENV" then
            tAPI[k] =  v
        end
    end

    return tAPI
end


local function init(...)
    dofile(".sPhone/system/vfs.lua")
    dofile(".sPhone/system/utils.lua")
    local spkf = loadfile(".sPhone/system/spk.lua")
    if not spkf then
        panic("Could not load SPK module")
    end
    local ok, err = pcall(setfenv(spkf,setmetatable({nativeFS = nativeFS},{__index=getfenv()})))
    if not ok then
        printError(err)
    end
    if not fs.exists("/.sPhone/config/sPhone") then
        local ok, err = pcall(setfenv(loadfile("/.sPhone/system/setup.lua"),setmetatable({fs = nativeFS},{__index=getfenv()})))
        if not ok then
            panic(err)
        end
    end
    if not spk.exists("dan200.shell") then
        panic("Could not find home")
    end
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    spk.launch("dan200.shell")
end

-- Task Handler
local processes = {}
local toKill = {}

function task.add(func,label)
    if type(func) ~= "function" then
        error("bad argument #1 (expected function, got "..type(func)..")",2)
    end
    table.insert(processes,{
        process = coroutine.create(func),
        label = label or "Lua Executable",
        filter = nil,
    })
    return #processes
end

function task.kill(pid)
    if not processes[pid] then
        error("PID not found",2)
    end
    toKill[pid] = true
end

function task.list()
    local list = {}
    for k,v in pairs(processes) do
        list[k] = v.label
    end
    return list
end

task.add(function() -- OS
    local ok,err = pcall(setfenv(init,setmetatable({
        task = task,
    },{__index = getfenv()})),args)
    if not ok then
        panic(err)
    end
end)

os.queueEvent("multitask")

while processes[1] ~= nil do
    local events = {os.pullEventRaw() }
    for pid, v in pairs(processes) do
        if not v.filter or v.filter == events[1] or events[1] == "terminate" then
            local ok, par = coroutine.resume(v.process,unpack(events))
            if ok then
                v.filter = par
            else
                printError(par)
            end
        end
        if coroutine.status(v.process) == "dead" then
            toKill[pid] = true
        end
    end
    for pid in pairs(toKill) do
        processes[pid] = nil
        toKill[pid] = nil
    end
end

if inPanic then
    while true do
        coroutine.yield()
    end
end

_G.term = nil