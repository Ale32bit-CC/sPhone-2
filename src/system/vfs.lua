--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit & Rph
-- LICENSE: GNU GPLv3 (https://github.com/Ale32bit/sPhone-2/blob/master/LICENSE)
]]--

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

local function fileSystem(path)
    local path = fs.combine("",path)
    if path:match("([^/]+)") == ".sPhone" then
        return true
    end
    return false
end

_G.fs.delete = function(path)
    if fileSystem(path) then
        error("Access denied",0)
    end
    return nativeFS.delete(path)
end

_G.fs.move = function(from,to)
    if fileSystem(from) or fileSystem(to) then
        error("Access denied",0)
    end
    return nativeFS.move(from,to)
end

_G.fs.copy = function(from,to)
    if fileSystem(to) then
       error("Access denied",2)
    end
    return nativeFS.copy(from,to)
end

_G.fs.open = function(path,mode)
    if fileSystem(path) then
        if mode:sub(1,1) == "w" or mode:sub(1,1) == "a" then
            return nil
        end
    end
    return nativeFS.open(path,mode)
end

_G.fs.isReadOnly = function(path)
    if fileSystem(path) then
        return true
    end
    return nativeFS.isReadOnly(path)
end

_G.fs.makeDir = function(path)
    if fileSystem(path) then
        error("Access denied",2)
    end
    return nativeFS.makeDir(path)
end