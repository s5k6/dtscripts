--[[ Some helper functions I use from more than one script.

    Author: Stefan Klinger (www.stefan-klinger.de)
    License: GNU General Public License Version 3
]]



local h = {}


--[[ Append all following arguments to the table given as first
    argument. ]]

h.append = function(t, ...)
    for _, v in pairs({...}) do
        table.insert(t, v)
    end
end



--[[ Lua provides no interface to `execve`.  So we must go through
    `os.execute`, which takes one shell command as string, and thus
    requires special care when quoting arguments (xkcd.com/327).

    From a list (Lua: table) of arguments as one would pass them to
    execve(2), create a command string to be passed to the shell via
    `os.execute`, assuming that `'` is strong quoting as in
    bash(1). ]]

h.mkCmdString = function(argv)
    local words = {}
    for _, a in pairs(argv) do
        h.append(words, "'" .. a:gsub("'", "'\\''") .. "'")
    end
    return table.concat(words, ' ')
end



--[[ Try `h.runCmd{'echo', "'", '"', ";", '\nla"l\'a'}` ]]

h.runCmd = function(argv)
    -- FIXME: better use a builtin function when available
    local cmd = h.mkCmdString(argv)
    if not os.execute(cmd) then
        print("Failed to run command: " .. cmd)
        return false
    end
    return true
end



-- create the path passed as argument

h.mkDir = function(path)
    -- FIXME: better use builtin function if available
    return h.runCmd{'mkdir', '-p', path}
end



-- copy file `src` to directory `dst`

h.copyToDir = function(dst, src)
    -- FIXME: better use builtin function if available
    return h.runCmd{ 'cp', '-t', dst, src }
end



return h
