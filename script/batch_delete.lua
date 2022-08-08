-- 批量删除 match 的 key
-- 定义游标cur初始值为0
local cur = 0
-- 定义删除个数初始值
local count=0
-- 循环调用
repeat
    -- 调用游标
    local result = redis.call("scan",cur,"match",KEYS[1])
    -- 将下个游标点转化为number
    cur = tonumber(result[1])
    local arr = result[2]
    -- 循环当前游标获取到的值，进行删除
    if(arr~=nil and #arr>0) then
        for i,k in pairs(arr) do
            local key = tostring(k)
            -- 或者使用redis.call("unlink",key)
            redis.call("del",key)
            count = count +1
        end
    end
-- 当游标点为0时，退出循环
until(cur<=0)
-- 返回执行的结果
return "del pattern is : "..KEYS[1]..", count is:"..count
