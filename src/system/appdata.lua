--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit & Rph
-- LICENSE: GNU GPLv3 (https://github.com/Ale32bit/sPhone-2/blob/master/LICENSE)
]]--

return function(app, nativeFS)
    local obj = {}
    obj.db = {}
    if not fs.exists('/.sPhone/appdata') then
        fs.makeDir('/.sPhone/appdata')
    end
    if not fs.exists('/.sPhone/appdata/' .. app) then
        fs.makeDir('/.sPhone/appdata/' .. app)
    end
    if not fs.exists('/.sPhone/appdata/' .. app .. '/files') then
        fs.makeDir('/.sPhone/appdata/' .. app .. '/files')
    end
    if not fs.exists('/.sPhone/appdata/' .. app .. '/database.tab') then
        local handle = fs.open('/.sPhone/appdata/' .. app .. '/database.tab','w')
        handle.write('{}')
        handle.close()
    end
    local handle = fs.open('/.sPhone/appdata/' .. app .. '/database.tab','r')
    local db = textutils.unserialise(handle.readAll())
    handle.close()
    function obj.getFile(file)
        local actualDir = '/.sPhone/appdata/' .. app .. '/files/' .. string.gsub(file, '/','%%')
        if not fs.exists(actualDir) then
            error("Invalid file!", 2)
        end
        local handle = fs.open(actualDir,'r')
        local data = handle.readAll()
        handle.close()
        return data
    end
    function obj.writeFile(file, data)
        local actualDir = '/.sPhone/appdata/' .. app .. '/files/' .. string.gsub(file, '/','%%')
        local handle = fs.open(actualDir,'w')
        handle.write(data)
        handle.close()
        return true
    end
    function obj.exists(file)
        local actualDir = '/.sPhone/appdata/' .. app .. '/files/' .. string.gsub(file, '/','%%')
        return fs.exists(actualDir)
    end
    function obj.db.get(key, default)
        if not db[key] then
            return default
        else
            return db[key]
        end
    end
    function obj.db.set(key, value)
        db[key] = value
        local handle = fs.open('/.sPhone/appdata/' .. app .. '/database.tab','w')
        handle.write(textutils.serialise(db))
        handle.close()
    end
    return obj
end