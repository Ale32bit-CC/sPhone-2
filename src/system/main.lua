-- sPhone 2.0

local args = {...}

-- Crash function

local function panic(reason)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1,1)
  print("sPhone crashed")
  print(reason or "Unknwon error")
  while true do
    sleep(3600)
  end
end

_G.sPhone = {
  version = "2.0",
}

function sPhone.require(lib)
    if not lib then
        return nil
    end
    if fs.exists("/.sPhone/system/libs/"..fs.getName(lib)) and not fs.isDir("/.sPhone/system/libs/"..fs.getName(lib)) then
        lib = "/.sPhone/system/libs/"..fs.getName(lib)
    elseif fs.exists("/rom/apis/"..fs.getName(lib)) and not fs.isDir("/rom/apis/"..fs.getName(lib)) then
        lib = "/rom/apis/"..fs.getName(lib)
    elseif fs.exists(lib) then
        lib = lib --?
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
    print(table.concat(({...})[1]," "))
end

-- Task Handler
local task = {}
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