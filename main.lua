-- Task Handler
local task = {}
local tasks = {}
local taskRunning = false
function task.kill(pid)
  local task = tasks[pid]
  if not task then
    error("Invalid task PID", 2)
  else
    coroutine.resume(task.coroutine, "terminate")
  end
  tasks[pid] = nil
end
function task.add(func, label, errorHandle, env)
  local env = env or _G
  func = setfenv(func, env)
  local pid = #tasks + 1
  tasks[#tasks + 1] = {
    ["coroutine"] = coroutine.create(func),
    ["handle"] = errorHandle or nil,
    ["label"] = label or "Unnamed",
    ["env"] = env or nil,
    ["lastfilter"] = "*"
  }
  return #tasks
end
function task.run()
  os.queueEvent("_")
  if #tasks < 1 then
    error("Not enough tasks!", 2)
end
  while true do
    local event = {coroutine.yield()}
    local coroutines = {}
    local pid = 1
    for i,v in pairs(tasks) do
      if v.coroutine and coroutine.status(v.coroutine) then
        coroutines[#coroutines + 1] = v
        coroutines[#coroutines].pid = pid
        pid = pid + 1
      end
    end
    if #coroutines < 1 then
      error("Out of tasks!", 2)
    end
    function handle(data, v)
      if data[1] == false and v.handle then
        handle(table.unpack(data))
        task.kill(v.pid)
      elseif data[1] == false then
        task.kill(v.pid)
      else
        if not data[2] then
          tasks[v.pid].lastfilter = "*"
        else
          tasks[v.pid].lastfilter = data[2]
        end
      end
    end
    for i,v in pairs(coroutines) do
      local data
      if v.lastfilter == "*" then
        local data = {coroutine.resume(v.coroutine, table.unpack(event))}
        handle(data, v)
      elseif v.lastfilter == event[1] then
        local data = {coroutine.resume(v.coroutine, table.unpack(event))}
        handle(data, v)
      end
    end
  end
end

_G.task = {
  ["add"] = task.add,
  ["kill"] = task.kill,
  ["list"] = function()
    return tasks
  end
}
