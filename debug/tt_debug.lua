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
         res = res[1]
      end
      success, res = pcall(function() return json.encode(res) end)
      return res
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
   if not prompt or prompt=="" then prompt = "'th_' .. _thid .. '> '" end
   local server = assert(socket.bind("127.0.0.1", tonumber(port) or 1999))
   while true do
      local client = server:accept()
      client:settimeout(10)
      client:send(_repr(_teval(prompt), true))
      while true do
         local line, err = client:receive()
         if line then
            _log("th_" .. _thid .. " rcvd:" .. line)
            client:send(_repr(_teval(line)) .. "\n")
            client:send(_repr(_teval(prompt), true))
         else
            if err ~= "timeout" then
               _log("th_" .._thid .. " recv: " .. json.encode(err))
               break
            end 
         end
      end
      client:close()
      break -- serving just one connection for now
   end
   server:close()
   return "th_" .._thid .. " repl finished!"
end

function ext_list(inc) -- lists the available ext functions
   ret = {}
   exc = {["tostring"]=1, ["gcinfo"]=1, ["getfenv"]=1, ["pairs"]=1,
          ["assert"]=1, ["tonumber"]=1, ["load"]=1, ["module"]=1,
          ["loadstring"]=1, ["xpcall"]=1, ["require"]=1,
          ["setmetatable"]=1, ["next"]=1, ["ipairs"]=1, ["rawequal"]=1,
          ["newproxy"]=1, ["rawset"]=1, ["print"]=1, ["unpack"]=1,
          ["pcall"]=1, ["type"]=1, ["collectgarbage"]=1, ["dofile"]=1,
          ["select"]=1, ["getmetatable"]=1, ["rawget"]=1, ["setfenv"]=1,
          ["error"]=1, ["loadfile"]=1}

   for k,v in pairs(getfenv()) do
      if k:sub(1,1) ~= "_" and type(v) == "function"
         and (inc and inc=="all" or not exc[k]) then
         table.insert(ret, k)
      end
   end
   return table.concat(ret, " ")
end
