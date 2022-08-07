--[[
    传入参数：
    业务标识
    ip
    限制时间
    限制时间内的访问次数
]]--
local busIdentify   = tostring(KEYS[1]) -- 业务标识
local ip            = tostring(KEYS[2]) -- ip
local expireSeconds = tonumber(ARGV[1]) -- 限制时间 单位(秒)
local limitTimes    = tonumber(ARGV[2]) -- 限制时间内的访问次数
local identify  = busIdentify .. "_" .. ip
local times     = redis.call("GET", identify)
--[[
    获取已经记录的时间
    获取到继续判断是否超过限制
    超过限制返回0
    否则加1，返回1
]]--
if times ~= false then
    times = tonumber(times)
    if times >= limitTimes then
        return 0
    else
        redis.call("INCR", identify)
        return 1
    end
end
-- 不存在的话，设置为1并设置过期时间
local flag = redis.call("SETEX", identify, expireSeconds, 1)
return 1