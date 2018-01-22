--[[
-- sPhone 2.0 for ComputerCraft
-- Copyright (c) 2018 Ale32bit & Rph
-- LICENSE: GNU GPLv3 (https://github.com/Ale32bit/sPhone-2/blob/master/LICENSE)
]]--

function _G.read( _sReplaceChar, _tHistory, _fnComplete, _sDefault )
    if _sReplaceChar ~= nil and type( _sReplaceChar ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sReplaceChar ) .. ")", 2 )
    end
    if _tHistory ~= nil and type( _tHistory ) ~= "table" then
        error( "bad argument #2 (expected table, got " .. type( _tHistory ) .. ")", 2 )
    end
    if _fnComplete ~= nil and type( _fnComplete ) ~= "function" then
        error( "bad argument #3 (expected function, got " .. type( _fnComplete ) .. ")", 2 )
    end
    if _sDefault ~= nil and type( _sDefault ) ~= "string" then
        error( "bad argument #4 (expected string, got " .. type( _sDefault ) .. ")", 2 )
    end
    term.setCursorBlink( true )

    local sLine
    if type( _sDefault ) == "string" then
        sLine = _sDefault
    else
        sLine = ""
    end
    local nHistoryPos
    local nPos = #sLine
    if _sReplaceChar then
        _sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
    end

    local tCompletions
    local nCompletion
    local function recomplete()
        if _fnComplete and nPos == string.len(sLine) then
            tCompletions = _fnComplete( sLine )
            if tCompletions and #tCompletions > 0 then
                nCompletion = 1
            else
                nCompletion = nil
            end
        else
            tCompletions = nil
            nCompletion = nil
        end
    end

    local function uncomplete()
        tCompletions = nil
        nCompletion = nil
    end

    local w = term.getSize()
    local sx = term.getCursorPos()

    local function redraw( _bClear )
        local nScroll = 0
        if sx + nPos >= w then
            nScroll = (sx + nPos) - w
        end

        local cx,cy = term.getCursorPos()
        term.setCursorPos( sx, cy )
        local sReplace = (_bClear and " ") or _sReplaceChar
        if sReplace then
            term.write( string.rep( sReplace, math.max( string.len(sLine) - nScroll, 0 ) ) )
        else
            term.write( string.sub( sLine, nScroll + 1 ) )
        end

        if nCompletion then
            local sCompletion = tCompletions[ nCompletion ]
            local oldText, oldBg
            if not _bClear then
                oldText = term.getTextColor()
                term.setTextColor( colors.gray )
            end
            if sReplace then
                term.write( string.rep( sReplace, string.len( sCompletion ) ) )
            else
                term.write( sCompletion )
            end
            if not _bClear then
                term.setTextColor( oldText )
            end
        end

        term.setCursorPos( sx + nPos - nScroll, cy )
    end

    local function clear()
        redraw( true )
    end

    recomplete()
    redraw()

    local function acceptCompletion()
        if nCompletion then
            -- Clear
            clear()

            -- Find the common prefix of all the other suggestions which start with the same letter as the current one
            local sCompletion = tCompletions[ nCompletion ]
            sLine = sLine .. sCompletion
            nPos = string.len( sLine )

            -- Redraw
            recomplete()
            redraw()
        end
    end
    while true do
        local sEvent, param = os.pullEvent()
        if sEvent == "char" then
            -- Typed key
            clear()
            sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
            nPos = nPos + 1
            recomplete()
            redraw()

        elseif sEvent == "paste" then
            -- Pasted text
            clear()
            sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
            nPos = nPos + string.len( param )
            recomplete()
            redraw()

        elseif sEvent == "key" then
            if param == keys.enter then
                -- Enter
                if nCompletion then
                    clear()
                    uncomplete()
                    redraw()
                end
                break

            elseif param == keys.left then
                -- Left
                if nPos > 0 then
                    clear()
                    nPos = nPos - 1
                    recomplete()
                    redraw()
                end

            elseif param == keys.right then
                -- Right
                if nPos < string.len(sLine) then
                    -- Move right
                    clear()
                    nPos = nPos + 1
                    recomplete()
                    redraw()
                else
                    -- Accept autocomplete
                    acceptCompletion()
                end

            elseif param == keys.up or param == keys.down then
                -- Up or down
                if nCompletion then
                    -- Cycle completions
                    clear()
                    if param == keys.up then
                        nCompletion = nCompletion - 1
                        if nCompletion < 1 then
                            nCompletion = #tCompletions
                        end
                    elseif param == keys.down then
                        nCompletion = nCompletion + 1
                        if nCompletion > #tCompletions then
                            nCompletion = 1
                        end
                    end
                    redraw()

                elseif _tHistory then
                    -- Cycle history
                    clear()
                    if param == keys.up then
                        -- Up
                        if nHistoryPos == nil then
                            if #_tHistory > 0 then
                                nHistoryPos = #_tHistory
                            end
                        elseif nHistoryPos > 1 then
                            nHistoryPos = nHistoryPos - 1
                        end
                    else
                        -- Down
                        if nHistoryPos == #_tHistory then
                            nHistoryPos = nil
                        elseif nHistoryPos ~= nil then
                            nHistoryPos = nHistoryPos + 1
                        end
                    end
                    if nHistoryPos then
                        sLine = _tHistory[nHistoryPos]
                        nPos = string.len( sLine )
                    else
                        sLine = ""
                        nPos = 0
                    end
                    uncomplete()
                    redraw()

                end

            elseif param == keys.backspace then
                -- Backspace
                if nPos > 0 then
                    clear()
                    sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
                    nPos = nPos - 1
                    recomplete()
                    redraw()
                end

            elseif param == keys.home then
                -- Home
                if nPos > 0 then
                    clear()
                    nPos = 0
                    recomplete()
                    redraw()
                end

            elseif param == keys.delete then
                -- Delete
                if nPos < string.len(sLine) then
                    clear()
                    sLine = string.sub( sLine, 1, nPos ) .. string.sub( sLine, nPos + 2 )
                    recomplete()
                    redraw()
                end

            elseif param == keys["end"] then
                -- End
                if nPos < string.len(sLine ) then
                    clear()
                    nPos = string.len(sLine)
                    recomplete()
                    redraw()
                end

            elseif param == keys.tab then
                -- Tab (accept autocomplete)
                acceptCompletion()

            end

        elseif sEvent == "term_resize" then
            -- Terminal resized
            w = term.getSize()
            redraw()

        end
    end

    local cx, cy = term.getCursorPos()
    term.setCursorBlink( false )
    term.setCursorPos( w + 1, cy )
    print()

    return sLine
end

-- SHELL API

local parentTerm = term.current()

local bExit = false
local sDir = ""
local sPath = ".:/rom/programs"
local tAliases = {}
local tCompletionInfo = {}
local tProgramStack = {}

shell = {}
local function createShellEnv( sDir )
    local tEnv = {}
    tEnv[ "shell" ] = shell
    tEnv[ "multishell" ] = multishell

    local package = {}
    package.loaded = {
        _G = _G,
        bit32 = bit32,
        coroutine = coroutine,
        math = math,
        package = package,
        string = string,
        table = table,
    }
    package.path = "?;?.lua;?/init.lua;/rom/modules/main/?;/rom/modules/main/?.lua;/rom/modules/main/?/init.lua"
    if turtle then
        package.path = package.path..";/rom/modules/turtle/?;/rom/modules/turtle/?.lua;/rom/modules/turtle/?/init.lua"
    elseif command then
        package.path = package.path..";/rom/modules/command/?;/rom/modules/command/?.lua;/rom/modules/command/?/init.lua"
    end
    package.config = "/\n;\n?\n!\n-"
    package.preload = {}
    package.loaders = {
        function( name )
            if package.preload[name] then
                return package.preload[name]
            else
                return nil, "no field package.preload['" .. name .. "']"
            end
        end,
        function( name )
            local fname = string.gsub(name, "%.", "/")
            local sError = ""
            for pattern in string.gmatch(package.path, "[^;]+") do
                local sPath = string.gsub(pattern, "%?", fname)
                if sPath:sub(1,1) ~= "/" then
                    sPath = fs.combine(sDir, sPath)
                end
                if fs.exists(sPath) and not fs.isDir(sPath) then
                    local fnFile, sError = loadfile( sPath, tEnv )
                    if fnFile then
                        return fnFile, sPath
                    else
                        return nil, sError
                    end
                else
                    if #sError > 0 then
                        sError = sError .. "\n"
                    end
                    sError = sError .. "no file '" .. sPath .. "'"
                end
            end
            return nil, sError
        end
    }

    local sentinel = {}
    local function require( name )
        if type( name ) ~= "string" then
            error( "bad argument #1 (expected string, got " .. type( name ) .. ")", 2 )
        end
        if package.loaded[name] == sentinel then
            error("Loop detected requiring '" .. name .. "'", 0)
        end
        if package.loaded[name] then
            return package.loaded[name]
        end

        local sError = "Error loading module '" .. name .. "':"
        for n,searcher in ipairs(package.loaders) do
            local loader, err = searcher(name)
            if loader then
                package.loaded[name] = sentinel
                local result = loader( err )
                if result ~= nil then
                    package.loaded[name] = result
                    return result
                else
                    package.loaded[name] = true
                    return true
                end
            else
                sError = sError .. "\n" .. err
            end
        end
        error(sError, 2)
    end

    tEnv["package"] = package
    tEnv["require"] = require

    return tEnv
end

-- Colours
local promptColour, textColour, bgColour
if term.isColour() then
    promptColour = colours.yellow
    textColour = colours.white
    bgColour = colours.black
else
    promptColour = colours.white
    textColour = colours.white
    bgColour = colours.black
end

local function run( _sCommand, ... )
    local sPath = shell.resolveProgram( _sCommand )
    if sPath ~= nil then
        tProgramStack[#tProgramStack + 1] = sPath
        if multishell then
            local sTitle = fs.getName( sPath )
            if sTitle:sub(-4) == ".lua" then
                sTitle = sTitle:sub(1,-5)
            end
            multishell.setTitle( multishell.getCurrent(), sTitle )
        end
        local sDir = fs.getDir( sPath )
        local result = os.run( createShellEnv( sDir ), sPath, ... )
        tProgramStack[#tProgramStack] = nil
        if multishell then
            if #tProgramStack > 0 then
                local sTitle = fs.getName( tProgramStack[#tProgramStack] )
                if sTitle:sub(-4) == ".lua" then
                    sTitle = sTitle:sub(1,-5)
                end
                multishell.setTitle( multishell.getCurrent(), sTitle )
            else
                multishell.setTitle( multishell.getCurrent(), "shell" )
            end
        end
        return result
    else
        printError( "No such program" )
        return false
    end
end

local function tokenise( ... )
    local sLine = table.concat( { ... }, " " )
    local tWords = {}
    local bQuoted = false
    for match in string.gmatch( sLine .. "\"", "(.-)\"" ) do
        if bQuoted then
            table.insert( tWords, match )
        else
            for m in string.gmatch( match, "[^ \t]+" ) do
                table.insert( tWords, m )
            end
        end
        bQuoted = not bQuoted
    end
    return tWords
end

-- Install shell API
function shell.run( ... )
    local tWords = tokenise( ... )
    local sCommand = tWords[1]
    if sCommand then
        return run( sCommand, table.unpack( tWords, 2 ) )
    end
    return false
end

function shell.exit()
    bExit = true
end

function shell.dir()
    return sDir
end

function shell.setDir( _sDir )
    if type( _sDir ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sDir ) .. ")", 2 )
    end
    if not fs.isDir( _sDir ) then
        error( "Not a directory", 2 )
    end
    sDir = _sDir
end

function shell.path()
    return sPath
end

function shell.setPath( _sPath )
    if type( _sPath ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sPath ) .. ")", 2 )
    end
    sPath = _sPath
end

function shell.resolve( _sPath )
    if type( _sPath ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sPath ) .. ")", 2 )
    end
    local sStartChar = string.sub( _sPath, 1, 1 )
    if sStartChar == "/" or sStartChar == "\\" then
        return fs.combine( "", _sPath )
    else
        return fs.combine( sDir, _sPath )
    end
end

local function pathWithExtension( _sPath, _sExt )
    local nLen = #sPath
    local sEndChar = string.sub( _sPath, nLen, nLen )
    -- Remove any trailing slashes so we can add an extension to the path safely
    if sEndChar == "/" or sEndChar == "\\" then
        _sPath = string.sub( _sPath, 1, nLen - 1 )
    end
    return _sPath .. "." .. _sExt
end

function shell.resolveProgram( _sCommand )
    if type( _sCommand ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sCommand ) .. ")", 2 )
    end
    -- Substitute aliases firsts
    if tAliases[ _sCommand ] ~= nil then
        _sCommand = tAliases[ _sCommand ]
    end

    -- If the path is a global path, use it directly
    local sStartChar = string.sub( _sCommand, 1, 1 )
    if sStartChar == "/" or sStartChar == "\\" then
        local sPath = fs.combine( "", _sCommand )
        if fs.exists( sPath ) and not fs.isDir( sPath ) then
            return sPath
        else
            local sPathLua = pathWithExtension( sPath, "lua" )
            if fs.exists( sPathLua ) and not fs.isDir( sPathLua ) then
                return sPathLua
            end
        end
        return nil
    end

    -- Otherwise, look on the path variable
    for sPath in string.gmatch(sPath, "[^:]+") do
        sPath = fs.combine( shell.resolve( sPath ), _sCommand )
        if fs.exists( sPath ) and not fs.isDir( sPath ) then
            return sPath
        else
            local sPathLua = pathWithExtension( sPath, "lua" )
            if fs.exists( sPathLua ) and not fs.isDir( sPathLua ) then
                return sPathLua
            end
        end
    end

    -- Not found
    return nil
end

function shell.programs( _bIncludeHidden )
    local tItems = {}

    -- Add programs from the path
    for sPath in string.gmatch(sPath, "[^:]+") do
        sPath = shell.resolve( sPath )
        if fs.isDir( sPath ) then
            local tList = fs.list( sPath )
            for n=1,#tList do
                local sFile = tList[n]
                if not fs.isDir( fs.combine( sPath, sFile ) ) and
                        (_bIncludeHidden or string.sub( sFile, 1, 1 ) ~= ".") then
                    if #sFile > 4 and sFile:sub(-4) == ".lua" then
                        sFile = sFile:sub(1,-5)
                    end
                    tItems[ sFile ] = true
                end
            end
        end
    end

    -- Sort and return
    local tItemList = {}
    for sItem, b in pairs( tItems ) do
        table.insert( tItemList, sItem )
    end
    table.sort( tItemList )
    return tItemList
end

local function completeProgram( sLine )
    if #sLine > 0 and string.sub( sLine, 1, 1 ) == "/" then
        -- Add programs from the root
        return fs.complete( sLine, "", true, false )

    else
        local tResults = {}
        local tSeen = {}

        -- Add aliases
        for sAlias, sCommand in pairs( tAliases ) do
            if #sAlias > #sLine and string.sub( sAlias, 1, #sLine ) == sLine then
                local sResult = string.sub( sAlias, #sLine + 1 )
                if not tSeen[ sResult ] then
                    table.insert( tResults, sResult )
                    tSeen[ sResult ] = true
                end
            end
        end

        -- Add programs from the path
        local tPrograms = shell.programs()
        for n=1,#tPrograms do
            local sProgram = tPrograms[n]
            if #sProgram > #sLine and string.sub( sProgram, 1, #sLine ) == sLine then
                local sResult = string.sub( sProgram, #sLine + 1 )
                if not tSeen[ sResult ] then
                    table.insert( tResults, sResult )
                    tSeen[ sResult ] = true
                end
            end
        end

        -- Sort and return
        table.sort( tResults )
        return tResults
    end
end

local function completeProgramArgument( sProgram, nArgument, sPart, tPreviousParts )
    local tInfo = tCompletionInfo[ sProgram ]
    if tInfo then
        return tInfo.fnComplete( shell, nArgument, sPart, tPreviousParts )
    end
    return nil
end

function shell.complete( sLine )
    if type( sLine ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( sLine ) .. ")", 2 )
    end
    if #sLine > 0 then
        local tWords = tokenise( sLine )
        local nIndex = #tWords
        if string.sub( sLine, #sLine, #sLine ) == " " then
            nIndex = nIndex + 1
        end
        if nIndex == 1 then
            local sBit = tWords[1] or ""
            local sPath = shell.resolveProgram( sBit )
            if tCompletionInfo[ sPath ] then
                return { " " }
            else
                local tResults = completeProgram( sBit )
                for n=1,#tResults do
                    local sResult = tResults[n]
                    local sPath = shell.resolveProgram( sBit .. sResult )
                    if tCompletionInfo[ sPath ] then
                        tResults[n] = sResult .. " "
                    end
                end
                return tResults
            end

        elseif nIndex > 1 then
            local sPath = shell.resolveProgram( tWords[1] )
            local sPart = tWords[nIndex] or ""
            local tPreviousParts = tWords
            tPreviousParts[nIndex] = nil
            return completeProgramArgument( sPath , nIndex - 1, sPart, tPreviousParts )

        end
    end
    return nil
end

function shell.completeProgram( sProgram )
    if type( sProgram ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( sProgram ) .. ")", 2 )
    end
    return completeProgram( sProgram )
end

function shell.setCompletionFunction( sProgram, fnComplete )
    if type( sProgram ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( sProgram ) .. ")", 2 )
    end
    if type( fnComplete ) ~= "function" then
        error( "bad argument #2 (expected function, got " .. type( fnComplete ) .. ")", 2 )
    end
    tCompletionInfo[ sProgram ] = {
        fnComplete = fnComplete
    }
end

function shell.getCompletionInfo()
    return tCompletionInfo
end

function shell.getRunningProgram()
    if #tProgramStack > 0 then
        return tProgramStack[#tProgramStack]
    end
    return nil
end

function shell.setAlias( _sCommand, _sProgram )
    if type( _sCommand ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sCommand ) .. ")", 2 )
    end
    if type( _sProgram ) ~= "string" then
        error( "bad argument #2 (expected string, got " .. type( _sProgram ) .. ")", 2 )
    end
    tAliases[ _sCommand ] = _sProgram
end

function shell.clearAlias( _sCommand )
    if type( _sCommand ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sCommand ) .. ")", 2 )
    end
    tAliases[ _sCommand ] = nil
end

function shell.aliases()
    -- Copy aliases
    local tCopy = {}
    for sAlias, sCommand in pairs( tAliases ) do
        tCopy[sAlias] = sCommand
    end
    return tCopy
end

if multishell then
    function shell.openTab( ... )
        local tWords = tokenise( ... )
        local sCommand = tWords[1]
        if sCommand then
            local sPath = shell.resolveProgram( sCommand )
            if sPath == "rom/programs/shell.lua" then
                return multishell.launch( createShellEnv( "rom/programs" ), sPath, table.unpack( tWords, 2 ) )
            elseif sPath ~= nil then
                return multishell.launch( createShellEnv( "rom/programs" ), "rom/programs/shell.lua", sCommand, table.unpack( tWords, 2 ) )
            else
                printError( "No such program" )
            end
        end
    end

    function shell.switchTab( nID )
        if type( nID ) ~= "number" then
            error( "bad argument #1 (expected number, got " .. type( nID ) .. ")", 2 )
        end
        multishell.setFocus( nID )
    end
end

-- DEFINE ALIASES, ARGS, BIN PATHS

-- Setup paths
local sPath = ".:/rom/programs"
if term.isColor() then
    sPath = sPath..":/rom/programs/advanced"
end
if turtle then
    sPath = sPath..":/rom/programs/turtle"
else
    sPath = sPath..":/rom/programs/rednet:/rom/programs/fun"
    if term.isColor() then
        sPath = sPath..":/rom/programs/fun/advanced"
    end
end
if pocket then
    sPath = sPath..":/rom/programs/pocket"
end
if commands then
    sPath = sPath..":/rom/programs/command"
end
if http then
    sPath = sPath..":/rom/programs/http"
end
sPath = sPath..":/.sPhone/sdk"
shell.setPath( sPath )
help.setPath( "/rom/help" )

-- Setup aliases
shell.setAlias( "ls", "list" )
shell.setAlias( "dir", "list" )
shell.setAlias( "cp", "copy" )
shell.setAlias( "mv", "move" )
shell.setAlias( "rm", "delete" )
shell.setAlias( "clr", "clear" )
shell.setAlias( "rs", "redstone" )
shell.setAlias( "sh", "shell" )
if term.isColor() then
    shell.setAlias( "background", "bg" )
    shell.setAlias( "foreground", "fg" )
end

-- Setup completion functions
local function completeMultipleChoice( sText, tOptions, bAddSpaces )
    local tResults = {}
    for n=1,#tOptions do
        local sOption = tOptions[n]
        if #sOption + (bAddSpaces and 1 or 0) > #sText and string.sub( sOption, 1, #sText ) == sText then
            local sResult = string.sub( sOption, #sText + 1 )
            if bAddSpaces then
                table.insert( tResults, sResult .. " " )
            else
                table.insert( tResults, sResult )
            end
        end
    end
    return tResults
end
local function completePeripheralName( sText, bAddSpaces )
    return completeMultipleChoice( sText, peripheral.getNames(), bAddSpaces )
end
local tRedstoneSides = redstone.getSides()
local function completeSide( sText, bAddSpaces )
    return completeMultipleChoice( sText, tRedstoneSides, bAddSpaces )
end
local function completeFile( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return fs.complete( sText, shell.dir(), true, false )
    end
end
local function completeDir( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return fs.complete( sText, shell.dir(), false, true )
    end
end
local function completeEither( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return fs.complete( sText, shell.dir(), true, true )
    end
end
local function completeEitherEither( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        local tResults = fs.complete( sText, shell.dir(), true, true )
        for n=1,#tResults do
            local sResult = tResults[n]
            if string.sub( sResult, #sResult, #sResult ) ~= "/" then
                tResults[n] = sResult .. " "
            end
        end
        return tResults
    elseif nIndex == 2 then
        return fs.complete( sText, shell.dir(), true, true )
    end
end
local function completeProgram( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return shell.completeProgram( sText )
    end
end
local function completeHelp( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return help.completeTopic( sText )
    end
end
local function completeAlias( shell, nIndex, sText, tPreviousText )
    if nIndex == 2 then
        return shell.completeProgram( sText )
    end
end
local function completePeripheral( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completePeripheralName( sText )
    end
end
local tGPSOptions = { "host", "host ", "locate" }
local function completeGPS( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tGPSOptions )
    end
end
local tLabelOptions = { "get", "get ", "set ", "clear", "clear " }
local function completeLabel( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tLabelOptions )
    elseif nIndex == 2 then
        return completePeripheralName( sText )
    end
end
local function completeMonitor( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completePeripheralName( sText, true )
    elseif nIndex == 2 then
        return shell.completeProgram( sText )
    end
end
local tRedstoneOptions = { "probe", "set ", "pulse " }
local function completeRedstone( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tRedstoneOptions )
    elseif nIndex == 2 then
        return completeSide( sText )
    end
end
local tDJOptions = { "play", "play ", "stop " }
local function completeDJ( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tDJOptions )
    elseif nIndex == 2 then
        return completePeripheralName( sText )
    end
end
local tPastebinOptions = { "put ", "get ", "run " }
local function completePastebin( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tPastebinOptions )
    elseif nIndex == 2 then
        if tPreviousText[2] == "put" then
            return fs.complete( sText, shell.dir(), true, false )
        end
    end
end
local tChatOptions = { "host ", "join " }
local function completeChat( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tChatOptions )
    end
end
local function completeSet( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, settings.getNames(), true )
    end
end
local tCommands
if commands then
    tCommands = commands.list()
end
local function completeExec( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 and commands then
        return completeMultipleChoice( sText, tCommands, true )
    end
end
shell.setCompletionFunction( "rom/programs/alias.lua", completeAlias )
shell.setCompletionFunction( "rom/programs/cd.lua", completeDir )
shell.setCompletionFunction( "rom/programs/copy.lua", completeEitherEither )
shell.setCompletionFunction( "rom/programs/delete.lua", completeEither )
shell.setCompletionFunction( "rom/programs/drive.lua", completeDir )
shell.setCompletionFunction( "rom/programs/edit.lua", completeFile )
shell.setCompletionFunction( "rom/programs/eject.lua", completePeripheral )
shell.setCompletionFunction( "rom/programs/gps.lua", completeGPS )
shell.setCompletionFunction( "rom/programs/help.lua", completeHelp )
shell.setCompletionFunction( "rom/programs/id.lua", completePeripheral )
shell.setCompletionFunction( "rom/programs/label.lua", completeLabel )
shell.setCompletionFunction( "rom/programs/list.lua", completeDir )
shell.setCompletionFunction( "rom/programs/mkdir.lua", completeFile )
shell.setCompletionFunction( "rom/programs/monitor.lua", completeMonitor )
shell.setCompletionFunction( "rom/programs/move.lua", completeEitherEither )
shell.setCompletionFunction( "rom/programs/redstone.lua", completeRedstone )
shell.setCompletionFunction( "rom/programs/rename.lua", completeEitherEither )
shell.setCompletionFunction( "rom/programs/shell.lua", completeProgram )
shell.setCompletionFunction( "rom/programs/type.lua", completeEither )
shell.setCompletionFunction( "rom/programs/set.lua", completeSet )
shell.setCompletionFunction( "rom/programs/advanced/bg.lua", completeProgram )
shell.setCompletionFunction( "rom/programs/advanced/fg.lua", completeProgram )
shell.setCompletionFunction( "rom/programs/fun/dj.lua", completeDJ )
shell.setCompletionFunction( "rom/programs/fun/advanced/paint.lua", completeFile )
shell.setCompletionFunction( "rom/programs/http/pastebin.lua", completePastebin )
shell.setCompletionFunction( "rom/programs/rednet/chat.lua", completeChat )
shell.setCompletionFunction( "rom/programs/command/exec.lua", completeExec )