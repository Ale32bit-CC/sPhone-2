--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit & Rph
-- LICENSE: GNU GPLv3 (https://github.com/Ale32bit/sPhone-2/blob/master/LICENSE)
]]--

if fs.exists("/.sPhone/config/sPhone") then
    return
end

local oldp = os.pullEvent
os.pullEvent = os.pullEventRaw
local sha256 = sPhone.require("sha256").sha256

local w,h = term.getSize()

local center = function(txt)
    local _,y = term.getCursorPos()
    term.setCursorPos(math.ceil(w/2)-math.ceil(#txt/2)+1,y)
    write(txt)
end

local function slow(y,...)
    local args = {...}
    term.setBackgroundColor(colors.blue)
    for i = 1,#args do
        term.setCursorPos(1,y-1+i)
        term.setTextColor(colors.lightBlue)
        center(args[i])
    end
    sleep(0.07)
    for i = 1,#args do
        term.setCursorPos(1,y-1+i)
        term.setTextColor(colors.white)
        center(args[i])
    end
end

term.setBackgroundColor(colors.black)
term.clear()
sleep(0.59)
term.setBackgroundColor(colors.gray)
term.clear()
sleep(0.09)
term.setBackgroundColor(colors.blue)
term.clear()

sleep(0.7)
slow(5,"Welcome to sPhone!")

sleep(1.5)
slow(8,"Just a second installing","system applications...")

for _,v in ipairs(fs.list("/.sPhone/installer/spks")) do
    local id = spk.install("/.sPhone/installer/spks/"..v)
    term.setCursorPos(1,11)
    term.clearLine()
    term.setTextColor(colors.white)
    center(id)
    sleep(0.1)
end

sleep(1)
slow(15,"Here we go")

sleep(2)

term.setBackgroundColor(colors.blue)
term.clear()
slow(2,"sPhone Setup")
slow(5,"What's your username?")
local current = term.current()
local usernameInput = window.create(term.current(),3,7,w-3,1,true)
usernameInput.setBackgroundColor(colors.blue)
usernameInput.setTextColor(colors.white)
usernameInput.clear()
usernameInput.setCursorPos(1,1)
term.redirect(usernameInput)
local username = read()
term.redirect(current)
term.setCursorPos(3,7)
print(username)
slow(10,"Insert a password","(Leave blank for none)")
local passwordInput = window.create(term.current(),3,13,w-3,1,true)
passwordInput.setBackgroundColor(colors.blue)
passwordInput.setTextColor(colors.white)
passwordInput.clear()
passwordInput.setCursorPos(1,1)
term.redirect(passwordInput)
local password = read("*")
term.redirect(current)
term.setCursorPos(3,13)
if password == "" then
    term.setTextColor(colors.lightGray)
    print("None")
    term.setTextColor(colors.white)
else
    print(string.rep("*",#password))
end

local f = fs.open("/.sPhone/config/sPhone","w")
f.write(textutils.serialize({
    username = username,
    password = sha256(password),
}))
f.close()

slow(h-1,"sPhone is now ready!")

sleep(2)

os.pullEvent = oldp