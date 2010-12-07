-- Monitoring probe for Tokyo Tyrant

_log(_thid .. " loading the monitoring probe")
require "json"
if not _log then
   function _log(s,l) print(s) end
end
if not _thid then
   _thid = ""
end

local function _repr(res, noquote)
   local success = table.remove(res, 1)
   if success then
      if #res == 1 then
         if noquote and type(res[1]) == "string" then return res[1] end
         return json.encode(res[1])
      else
         return json.encode(res)
      end
   else
      return table.concat(res,"\n")
   end
end

local function _teval(line)
   local res = { loadstring("return ".. line) }
   if not res[1] then -- syntax
      res = { loadstring(line) }
   end
   if res[1] then
      return { xpcall(res[1],debug.traceback) }
   else
      return res
   end
end

function teval(key, val)
   return _thid .. " " .. _repr(_teval(key))
end

function repl(port, prompt)
   require "socket"
   if not prompt or prompt=="" then prompt = "_thid .. '> '" end
   local server = assert(socket.bind("127.0.0.1", tonumber(port) or 1999))
   while 1 do
      local client = server:accept()
      client:settimeout(10)
      client:send(_repr(_teval(prompt), true))
      while true do
         local line, err = client:receive()
         if line then
            _log(_thid .. "rcvd:" .. line)
            client:send(_repr(_teval(line)) .. "\n")
            client:send(_repr(_teval(prompt), true))
         else
            if err ~= "timeout" then
               _log(_thid .. " recv: " .. json.encode(err))
               break
            end 
         end
      end
      client:close()
      break
   end
   server:close()
   return _thid .. " repl finished!"
end

