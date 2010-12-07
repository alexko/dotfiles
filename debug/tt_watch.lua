#!/usr/bin/env lua
-- a simple script to monitor lua threads of Tokyo Tyrant

if arg and arg[0] and #arg[0] > 0 then

   local function esc(x) return "\27[" .. x end
        
   local function tt_watch(args)
      local fp = io.popen(table.concat(args, " ", 1))
      if fp then
         x = fp:read("*all")
         thread = x:match("(%d+)")
         if not thread then return end
         local line = 1+tonumber(thread)
         if line then
            io.write( esc(line .. ";1H") .. x)
         end
         socket.sleep(0.2)
      end
      fp:close()
   end

   func = arg[1] or "'return gcinfo()'"
   port = arg[2] or "2000"
   args = { "tcrmgr", "ext", "-port", port, "localhost", "teval", func, "2>/dev/null" }
   io.write(esc("2J") .. esc("0;1H") .. "= " .. func)
   while true do tt_watch(args) end
end
