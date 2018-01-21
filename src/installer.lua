--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit
-- LICENSE: GNU GPLv3 (https://github.com/Ale32bit/sPhone-2/blob/master/LICENSE)
]]--

-- Installer

local files = {
    [".sPhone/system/init.lua"] = "system/init.lua",
    [".sPhone/system/vfs.lua"] = "system/vfs.lua",
    [".sPhone/system/spk.lua"] = "system/spk.lua",
    [".sPhone/system/appdata.lua"] = "system/appdata.lua",
    [".sPhone/sdk/build.lua"] = "sdk/build.lua",
    ["startup"] = "startup.lua"
}

local base = "https://raw.githubusercontent.com/Ale32bit/sPhone-2/master/src/"

print("Installing sPhone 2...")

for path,url in pairs(files) do
    print("Fetching "..base..url)
    local h = http.get(base..url)
    if h then
        local f = fs.open(path,"w")
        f.write(h.readAll())
        f.close()
        h.close()
        print("Installed as "..path)
    else
        printError("Could not fetch "..base..url)
    end
end

print("sPhone 2 installed")