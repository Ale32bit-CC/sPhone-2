--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit
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


local newFS = {}
