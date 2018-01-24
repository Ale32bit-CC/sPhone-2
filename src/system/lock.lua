--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit & Rph
-- LICENSE: GNU GPLv3 (https://github.com/Ale32bit/sPhone-2/blob/master/LICENSE)
]]--

local f = fs.open("/.sPhone/config/sPhone","r")
local config = textutils.unserialize(f.readAll())
f.close()

if not config.password then
    return
end

local sha256 = sPhone.require("sha256").sha256

local oldp = os.pullEvent
os.pullEvent = os.pullEventRaw

local w,h = term.getSize()

local center = function(txt)
    local _,y = term.getCursorPos()
    term.setCursorPos(math.ceil(w/2)-math.ceil(#txt/2)+1,y)
    write(txt)
end

local pw = nil
term.setBackgroundColor(colors.blue)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,2)
center("sPhone 2")
term.setCursorPos(1,h/2-4)
center("Welcome back, "..sPhone.username or "User")
term.setCursorPos(1,h/2-1)
center("Insert password")
local curr = term.current()
local inputW = window.create(term.current(),3,h/2,w-3,1,true)
while true do
    term.redirect(inputW)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    pw = read("*")
    term.redirect(curr)
    term.setCursorPos(3,h/2)
    print(string.rep("*",#pw))
    if sha256(pw) == config.password then
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        os.pullEvent = oldp
        break
    else
        term.setCursorPos(3,h/2+2)
        term.setTextColor(colors.red)
        center("Wrong password")
    end
end