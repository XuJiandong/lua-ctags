#!/usr/bin/env lua

-- {{[1] [2]}, {[1], [2]}, ...}
local function removeNested(loc)
    local function cover(a, b)
        return a[1] <= b[1] and a[2] >= b[2]
    end
    table.sort(loc, function(a, b) return a[1] < b[1] end)
    for i = 1, #loc-1 do
        if not loc[i] then break end
        if loc[i][1] == 0 and loc[i][2] == 0 then 
            loc[i][3] = true -- marked as removed
        else
            for j = i+1, #loc do
                if cover(loc[i], loc[j]) then
                    loc[j][3] = true -- marked as removed
                end
                if loc[j][1] > loc[i][2] then
                    break
                end
            end
        end
    end
    local result = {}
    for _, v in ipairs(loc) do
        if not v[3] then
            table.insert(result, v)
        end
    end
    return result
end


--
-- parse output from luac 
-- like following:
--
-- function <../test/simple.lua:3,4> (1 instruction, 4 bytes at 0x9244e50)
-- 0 params, 2 slots, 0 upvalues, 0 locals, 0 constants, 0 functions
--   1   [4] RETURN      0 1
local function parseLuac(...)
    local cmd  = [[luac -l -p %s]]
    local argv = {...}
    local argc = select('#', ...)

    local luacCmd = string.format(cmd, table.concat(argv, " "))
    local output  = io.popen(luacCmd)

    if not output then
        return print("can't execute luac command!")
    end

    local result = {}
    for line in output:lines() do
        -- match line like following and capture the starting line number(3)
        -- function <simple.lua:3,4> (1 instruction, 4 bytes at 0x8b97e40)
        local fileName, beginLine, endLine = string.match(line, [=[function <([^:]+):(%d+),(%d+)]=])
        if fileName and beginLine then
            if not result[fileName] then result[fileName] = {} end
            table.insert(result[fileName], {tonumber(beginLine), tonumber(endLine)})
        end
    end
    output:close()
    return result
end

-- input: only filename -> line numbers of function definition
-- generate tags like following:
-- AF_LOCAL	anet.h	39;"	d
-- note: not space, it's tab in string
local function generate(input)
    -- parse function like following, it's possible that they are spreaded 
    -- on mutilple lines.
    -- function qsort(x,l,u,f)
    local function parseFunction(line, ...)
        local l = line .. " " .. table.concat({...})
        -- don't accept anonymous function
        local format = "function%s+([%w%.:]+)%s*%(.*%)"
        local funcName = string.match(l, format)
        return funcName
    end
    local result = {}
    for fileName, lineSet in pairs(input) do
        table.sort(lineSet, function(a, b) return a[1] < b[1] end)
        local targetIndex = 1
        local lineNum = 0
        for line in io.lines(fileName) do
            if targetIndex > #lineSet then break end
            lineNum = lineNum + 1
            if lineNum == lineSet[targetIndex][1] then
                local funcName = parseFunction(line)
                if funcName then
                    table.insert(result, string.format("%s\t%s\t%d;\"\td",funcName, fileName, lineNum))
                end
                targetIndex = targetIndex + 1
            end
        end
    end
    return result
end

local function test()
    function dump(r)
        for k, v in pairs(r) do
            print(k, "->", table.concat(v, ","))
        end
    end
    local f, r
    ----------------
    --test removeNested
    local loc = {{1,2}, {3,10}, {4,5}, {6,7}, {7,10}, {11, 12}}
    r = removeNested(loc)
    assert(r[1][1] == 1 and r[1][2] == 2)
    assert(r[2][1] == 3 and r[2][2] == 10)
    assert(r[3][1] == 11 and r[3][2] == 12)

    -----------------
    f = "../test/simple.lua"
    r = parseLuac(f)
    assert(r[f][1][1] == 3)
    ------------------
    f = "../test/more_functions.lua"
    r = parseLuac(f)
    assert(r[f][1][1] == 3 and r[f][2][1] == 6 and r[f][3][1] == 9 and r[f][4][1] == 12)
    r2 = generate(r)
    for i, l in ipairs(r2) do
        assert(string.match(l, f))
    end
    ---------------------
    f = "../test/very-long-path/very-long-path/very-long-path/very_long_path.lua"
    r = parseLuac(f)
    assert(r[f][1][1] == 3)
    print("It works!")
end

local function printUsage()
    print("lua lua_ctags.lua <file1> <file2> ...")
    print("note: accept *.lua. To check it works or not:")
    print("lua lua_ctags.lua test")
end

local function main(...)
    local argv = {...}
    local argc = select('#', ...)
    if argv[1] == "test" then
        return test()
    end
    if argc < 1 or not argv[1] then
        return printUsage()
    end
    local loc = parseLuac(...)
    if not loc then
        return printUsage()
    end
    local newLoc = {}
    for file, lines in pairs(loc) do
        newLoc[file] = removeNested(lines)
    end
    local result = generate(newLoc)
    for _, v in ipairs(result) do
        print(v)
    end
end

main(...)
