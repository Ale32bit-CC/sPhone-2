--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit & Rph
-- LICENSE: GNU GPLv3 (https://github.com/Ale32bit/sPhone-2/blob/master/LICENSE)
]]--

-- Installer

local files = {
    [".sPhone/system/init.lua"] = "system/init.lua",
    [".sPhone/system/vfs.lua"] = "system/vfs.lua",
    [".sPhone/system/spk.lua"] = "system/spk.lua",
    [".sPhone/system/appdata.lua"] = "system/appdata.lua",
    [".sPhone/system/setup.lua"] = "system/setup.lua",
    [".sPhone/system/utils.lua"] = "system/utils.lua",
    [".sPhone/system/lock.lua"] = "system/lock.lua",

    [".sPhone/system/libs/sha256.lua"] = "system/libs/sha256.lua",

    [".sPhone/sdk/build.lua"] = "sdk/build.lua",


    [".sPhone/installer/spks/sPhone.shell.spk"] = "installer/spks/sPhone.shell.spk",
    [".sPhone/installer/spks/sPhone.home.spk"] = "installer/spks/sPhone.home.spk",
    [".sPhone/installer/spks/sPhone.accountManager.spk"] = "installer/spks/sPhone.accountManager.spk",

    ["startup"] = "startup.lua"
}

local base = "https://raw.githubusercontent.com/Ale32bit/sPhone-2/master/src/"

if fs.isReadOnly("/.sPhone") then
    error("Cannot update while sPhone is running!",0)
end

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

local f = fs.open("/.sPhone/config/uptodate","w")
f.write("true")
f.close()

print("sPhone 2 installed")
