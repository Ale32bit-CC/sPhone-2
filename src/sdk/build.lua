local args = {...}
if #args < 2 then
    print("sPhone SPK builder v2")
    print("Usage: build <directory> <output>")
    return
end

print("sPhone SPK builder v2")

local input = args[1]
local output = args[2]

-- functions readFile and explore took from Compress by Creator

local function readFile(path)
    local file = fs.open(path,"r")
    local variable = file.readAll()
    file.close()
    return variable
end

local function explore(dir)
    local buffer = {}
    local sBuffer = fs.list(dir)
    for i,v in pairs(sBuffer) do
        if fs.isDir(dir.."/"..v) then
            if v ~= ".git" then
                buffer[v] = explore(dir.."/"..v)
            end
        else
            if v ~= "spk.cfg" then
                buffer[v] = readFile(dir.."/"..v)
            end
        end
    end
    return buffer
end

print("Packing files...")

local files = explore(input)

print("Checking config...")

local file = fs.open(input.."/spk.cfg","r")
local config = textutils.unserialise(file.readAll())
file.close()

if not config then
    error("Invalid config",0)
end

if not config.id then
    error("Invalid ID",2)
end

config.name = config.name or config.id
config.author = config.author or "Unknown"
config.version = config.version or "1.0"
config.type = config.type or "generic"
config.builder = "sPhone SPK Builder"
config.builderVersion = "2.0"

print("Config data:")

for k,v in pairs(config) do
    print(k..":"..v)
end

local out = {}
out["config"] = config
out["files"] = files

local f = fs.open(output..".spk","w")
f.write(textutils.serialise(out))
f.close()
print("Output: "..output..".spk")