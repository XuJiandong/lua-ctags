

local function localFunction(a, b, c)
end

function globalFunction(a, b, ...)
end

function T:memberFunction(...)
end

function T.memberFunction2(a, b, ...)
end

function outerFunction(...)
    local function innerFunction(...)
    end
    local f = function()
    end
end


