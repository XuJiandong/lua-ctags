local function parse(...)
    local cmd = [[luac -l -p %s]]
    local argv = {...}
    local argc = select('#', ...)

    local luacCmd = string.format(cmd, table.concat(argv, " "))
    local output = io.popen(luacCmd)

    if not output then
        return print("can't execute luac command!")
    end

    local result = {}
    for line in output:lines() do
        -- match line like following and capture the starting line number(3)
        -- function <simple.lua:3,4> (1 instruction, 4 bytes at 0x8b97e40)
        local fileName, startingLine = string.match(line, [=[function <([^:]+):(%d+),%d+]=])
        if fileName and startingLine then
            if not result[fileName] then result[fileName] = {} end
            table.insert(result[fileName], tonumber(startingLine))
        end
    end
    output:close()
    return result
end

-- parse function like following, it's possible that they are spreaded 
-- on mutilple lines.
-- function qsort(x,l,u,f)
local function parseFunction(line, ...)
    local l = line .. " " .. table.concat({...})
    local format = "function%s+([%w%.:]+)%s*%(.*%)"
    local funcName = string.match(l, format)
end

-- generate tags like following:
-- qsort	sort.lua	/^function qsort(x,l,u,f)$/;"	f
local function generate(result)
    for fileName, lineSet in pairs(result) do
        for _, lineNumber in ipairs(lineSet) do
        end
    end
end


if TEST then
    function dump(r)
        for k, v in pairs(r) do
            print(k, "->", table.concat(v, ","))
        end
    end
    print("TEST enabled")
    local r = parse("../test/simple.lua")
    assert(r["../test/simple.lua"][1] == 3)
    r = parse("../test/more_functions.lua")
    dump(r)
end

