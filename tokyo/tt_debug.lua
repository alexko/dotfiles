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

local function _teval(line, client)
   local print0 = print
   print = function(...)
                    if not client then return end
                    local res = {}      
                    for i, v in ipairs(arg) do
                       table.insert(res, tostring(v))
                    end
                    client:send(table.concat(res,"\t") .. "\n")
                 end 
   local res = { loadstring("return ".. line) }
   if not res[1] then -- syntax
      res = { loadstring(line) }
   end
   if res[1] then
      res = { xpcall(res[1],debug.traceback) }
      print = print0
   end  
   return res
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
            local res = _teval(line, client)
            if #res>1 then client:send(_repr(res) .. "\n") end
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
   local ret = {}
   local exc = {["tostring"]=1, ["gcinfo"]=1, ["getfenv"]=1, ["pairs"]=1,
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

function help(fn)
   help_dict = help_dict or {
      [_eval] = [[_eval(chunk)
Evaluate a Lua chunk in each native thread.
'chunk' specifies the Lua chunk string.
If successful, the return value is true, else, it is false.]],
      [_log] = [[_log(message, level)
Print a message into the server log.
'message' specifies the message string.
'level' specifies the log level; 0 for debug, 1 for information, 2 for error, 3 for system. It can be omitted and the default value is 1.]],
      [_put] = [[_put(key, value)
Store a record.
'key' specifies the key.
'value' specifies the value.
If successful, the return value is true, else, it is false.]],
      [_putkeep] = [[_putkeep(key, value)
Store a new record.
'key' specifies the key.
'value' specifies the value.
If successful, the return value is true, else, it is false.]],
      [_putcat] = [[_putcat(key, value)
Concatenate a value at the end of the existing record.
'key' specifies the key.
'value' specifies the value.
If successful, the return value is true, else, it is false.]],
      [_out] = [[_out(key)
Remove a record.
'key' specifies the key.
If successful, the return value is true, else, it is false.]],
      [_get] = [[_get(key)
Retrieve a record.
'key' specifies the key.
If successful, the return value is the value of the corresponding record. 'nil' is returned if no record corresponds.]],
      [_vsiz] = [[_vsiz(key)
Get the size of the value of a record.
'key' specifies the key.
If successful, the return value is the size of the value of the corresponding record, else, it is -1.]],
      [_iterinit] = [[_iterinit()
Initialize the iterator.
If successful, the return value is true, else, it is false.]],
      [_iternext] = [[_iternext()
Get the next key of the iterator.
If successful, the return value is the next key, else, it is 'nil'. 'nil' is returned when no record is to be get out of the iterator.]],
      [_fwmkeys] = [[_fwmkeys(prefix, max)
Get forward matching keys.
The return value an array of the keys of the corresponding records. This function does never fail. It returns an empty array even if no record corresponds.]],
      [_addint] = [[_addint(key, value)
Add an integer to a record.
'key' specifies the key.
'value' specifies the value.
If successful, the return value is the summation value, else, it is 'nil'.]],
      [_adddouble] = [[_adddouble(key, value)
Add a real number to a record.
'key' specifies the key.
'value' specifies the value.
If successful, the return value is the summation value, else, it is 'nil'.]],
      [_vanish] = [[_vanish()
Remove all records.
If successful, the return value is true, else, it is false.]],
      [_rnum] = [[_rnum()
Get the number of records.
The return value is the number of records.]],
      [_size] = [[_size()
Get the size of the database file.
The return value is the size of the database file.]],
      [_misc] = [[_misc(name, args, ...)
Call a versatile function for miscellaneous operations.
'name' specifies the name of the function. If it begins with "$", the update log is omitted.
'args' specifies an array of arguments.
If successful, the return value is an array of the result. 'nil' is returned on failure.]],
      [_foreach] = [[_foreach(func)
Process each record atomically.
'func' the iterator function called for each record. It receives two parameters of the key and the value, and returns true to continue iteration or false to stop iteration.
If successful, the return value is true, else, it is false.]],
      [_mapreduce] = [[_mapreduce(mapper, reducer, keys)
Perform operations based on MapReduce.
'mapper' specifies the mapper function. It is called for each target record and receives the key, the value, and the function to emit the mapped records. The emitter function receives a key and a value. The mapper function should return true normally or false on failure.
'reducer' specifies the reducer function. It is called for each record generated by sorting emitted records by keys, and receives the key and an array of values. The reducer function should return true normally or false on failure.
'keys' specifies the keys of target records. If it is not defined, every record in the database is processed.
If successful, the return value is true, else, it is false.]],
      [_stashput] = [[_stashput(key, value)
Store a record into the stash.
'key' specifies the key.
'value' specifies the value.
The return value is always true.]],
      [_stashout] = [[_stashout(key)
Remove a record from the stash.
'key' specifies the key.
If successful, the return value is true, else, it is false.]],
      [_stashget] = [[_stashget(key)
Retrieve a record in the stash.
'key' specifies the key.
If successful, the return value is the value of the corresponding record. 'nil' is returned if no record corresponds.]],
      [_stashvanish] = [[_stashvanish()
Remove all records of the stash.]],
      [_stashforeach] = [[_stashforeach(func)
Process each record atomically of the stash.
'func' the iterator function called for each record. It receives two parameters of the key and the value, and returns true to continue iteration or false to stop iteration.
If successful, the return value is true, else, it is false.]],
      [_lock] = [[_lock(key)
Lock an arbitrary key.
'key' specifies the key. The locked key should be unlocked in the same operation.
If successful, the return value is true, else, it is false.]],
      [_unlock] = [[_unlock(key)
Unock an arbitrary key.
'key' specifies the key.
If successful, the return value is true, else, it is false.]],
      [_pack] = [[_pack(format, ary, ...)
Serialize an array of numbers into a string.
'format' specifies the format string. It should be composed of conversion characters; 'c' for int8_t, 'C' for uint8_t, 's' for int16_t, 'S' for uint16_t, 'i' for int32_t, 'I' for uint32_t, 'l' for int64_t, 'L' for uint64_t, 'f' for float, 'd' for double, 'n' for uint16_t in network byte order, 'N' for uint32_t in network byte order, 'M' for uint64_t in network byte order, and 'w' for BER encoding. They can be trailed by a numeric expression standing for the iteration count or by '*' for the rest all iteration.
'ary' specifies the array of numbers.
The return value is the serialized string.]],
      [_unpack] = [[_unpack(format, str)
Deserialize a binary string into an array of numbers.
'format' specifies the format string. It should be composed of conversion characters as with '_pack'.
'str' specifies the binary string.
The return value is the deserialized array.]],
      [_split] = [[_split(str, delims)
Split a string into substrings.
'str' specifies the string.
'delims' specifies a string including separator characters. If it is not defined, the zero code is specified.
The return value is an array of substrings.]],
      [_codec] = [[_codec(mode, str)
Encode or decode a string.
'mode' specifies the encoding method; 'url' for URL encoding, '~url' for URL decoding, 'base' for Base64 encoding, '~base' for Base64 decoding, 'hex' for hexadecimal encoding, '~hex' for hexadecimal decoding, 'pack' for PackBits encoding, '~pack' for PackBits decoding, 'tcbs' for TCBS encoding, '~tcbs' for TCBS decoding, 'deflate' for Deflate encoding, '~deflate' for Deflate decoding, 'gzip' for GZIP encoding, '~gzip' for GZIP decoding, 'bzip' for BZIP2 encoding, '~bzip' for BZIP2 decoding, 'xml' for XML escaping, '~xml' for XML unescaping.
'str' specifies the string.
The return value is the encoded or decoded string.]],
      [_hash] = [[_hash(mode, str)
Get the hash value of a string.
'mode' specifies the hash method; 'md5' for MD5 in hexadecimal format, 'md5raw' for MD5 in raw format, 'crc32' for CRC32 checksum number.
'str' specifies the string.
The return value is the hash value.]],
      [_bit] = [[_bit(mode, num, aux)
Perform bit operation of an integer.
'mode' specifies the operator; 'and' for bitwise-and operation, 'or' for bitwise-or operation, 'xor' for bitwise-xor operation, 'not' for bitwise-not operation, 'left' for left shift operation, 'right' for right shift operation.
'num' specifies the integer, which is treated as a 32-bit unsigned integer.
'aux' specifies the auxiliary operand for some operators.
The return value is the result value.]],
      [_strstr] = [[_strstr(str, pattern, alt)
Perform substring matching or replacement without evaluating any meta character.
'str' specifies the source string.
'pattern' specifies the matching pattern.
'alt' specifies the alternative string corresponding for the pattern. If it is not defined, matching check is performed.
If the alternative string is specified, the converted string is returned. If the alternative string is not specified, the index of the substring matching the given pattern or 0 is returned.]],
      [_regex] = [[_regex(str, pattern, alt)
Perform pattern matching or replacement with regular expressions.
'str' specifies the source string.
'pattern' specifies the pattern of regular expressions.
'alt' specifies the alternative string corresponding for the pattern. If it is not defined, matching check is performed.
If the alternative string is specified, the converted string is returned. If the alternative string is not specified, the boolean value of whether the source string matches the pattern is returned.]],
      [_ucs] = [[_ucs(data)
Convert a UTF-8 string into a UCS-2 array or its inverse.
'data' specifies the target data. If it is a string, convert it into a UCS-array. If it is an array, convert it into a UTF-8 string.
The return value is the result data.]],
      [_dist] = [[_dist(astr, bstr, isutf)
Calculate the edit distance of two UTF-8 strings.
'astr' specifies a string.
'bstr' specifies the other string.
'isutf' specifies whether to calculate cost by Unicode character. If it is not defined, false is specified and calculate cost by ASCII character.
The return value is the edit distance which is known as the Levenshtein distance.]],
      [_isect] = [[_isect(ary, ...)
Calculate the intersection set of arrays.
'ary' specifies the arrays. Arbitrary number of arrays can be specified as the parameter list.
The return value is the array of the intersection set.]],
      [_union] = [[_union(ary, ...)
Calculate the union set of arrays.
'ary' specifies the arrays. Arbitrary number of arrays can be specified as the parameter list.
The return value is the array of the union set.]],
      [_time] = [[_time()
Get the time of day in seconds.
The return value is the time of day in seconds. The accuracy is in microseconds.]],
      [_sleep] = [[_sleep(sec)
Suspend execution for the specified interval.
'sec' specifies the interval in seconds.
If successful, the return value is true, else, it is false.]],
      [_stat] = [[_stat(path)
Get the status of a file.
'path' specifies the path of the file.
If successful, the return value is a table containing status, else, it is 'nil'. There are keys of status name; 'dev', 'ino', 'mode', 'nlink', 'uid', 'gid', 'rdev', 'size', 'blksize', 'blocks', 'atime', 'mtime', 'ctime', which have same meanings of the POSIX 'stat' call. Additionally, '_regular' for whether the file is a regular file, '_directory' for whether the file is a directory, '_readable' for whether the file is readable by the process, '_writable' for whether the file is writable by the process, '_executable' for whether the file is executable by the process, '_realpath' for the real path of the file, are supported.]],
      [_glob] = [[_glob(pattern)
Find pathnames matching a pattern.
'pattern' specifies the matching pattern. '?' and '*' are meta characters.
The return value is an array of matched paths. If no path is matched, an empty array is returned.]],
      [_remove] = [[_remove(path)
Remove a file or a directory and its sub ones recursively.
'path' specifies the path of the link.
If successful, it is true, else, it is false.]],
      [_mkdir] = [[_mkdir(path)
Create a directory.
'path' specifies the path of the directory.
If successful, it is true, else, it is false.]]
   }
   if fn then
      return help_dict[fn]
   else
      local ret = {}
      for k,v in pairs(getfenv()) do
         if type(v) == "function" and help_dict[v] then
            table.insert(ret, k)
         end
      end
      table.sort(ret)
      return table.concat(ret, " ")
   end
end  
