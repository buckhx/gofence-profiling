-- Adapted from: https://github.com/timotta/wrk-scripts/blob/master/multiplepaths.lua

-- Initialize the pseudo random number generator
-- Resource: http://lua-users.org/wiki/MathLibraryTutorial
math.randomseed(os.time())
math.random(); math.random(); math.random()

-- Shuffle array
-- Returns a randomly shuffled array
function shuffle(bodies)
  local j, k
  local n = #bodies

  for i = 1, n do
    j, k = math.random(n), math.random(n)
    bodies[j], bodies[k] = bodies[k], bodies[j]
  end

  return bodies
end

-- Load URL bodies from the file
function load_bodies(file)
  lines = {}

  -- Check if the file exists
  -- Resource: http://stackoverflow.com/a/4991602/325852
  local f=io.open(file,"r")
  if f~=nil then 
    io.close(f)
  else
    -- Return the empty array
    return lines
  end

  -- If the file exists loop through all its lines 
  -- and add them into the lines array
  for line in io.lines(file) do
    if not (line == '') then
      lines[#lines + 1] = line
    end
  end

  return shuffle(lines)
end

-- Load bodies from WRK_BODIES envvar
path = os.getenv("WRK_BODIES")
bodies = load_bodies(path)

-- Check if at least one path was found in the file
if #bodies <= 0 then
  print("multibodies: No bodies found. WRK_BODIES envvar needs to be set to path")
  os.exit()
end

print("Let " .. #bodies .. " bodies hit the floor")

-- Initialize the bodies array iterator
counter = 0

request = function()
  -- Get the next bodies array element
  body = bodies[counter]
  -- 
  counter = counter + 1

  -- Reset Counter
  if counter > #bodies then
    counter = 0
  end

  -- Return the request object with the current URL path
  return wrk.format("POST", wrk.path, wrk.headers, body)
end

--[[
-- Print Bad Requests
function response(status, headers, body) 
  if status ~= 200 then
    print("== Bad Request ==")
    print(status)
    print("= Headers =")
    for key,value in pairs(headers) do print(key,value) end
    print("= Body =")
    print(body)
    os.exit()
  end
end
]]--
