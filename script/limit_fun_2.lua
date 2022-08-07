local busIdentify   = tostring(KEYS[1])
local ip            = tostring(KEYS[2])
local expireSeconds = tonumber(ARGV[1])
local limitTimes    = tonumber(ARGV[2])
-- 传入额外参数，请求时间戳
local timestamp     = tonumber(ARGV[3])
local lastTimestamp
local identify  = busIdentify .. "_" .. ip
local times     = redis.call("LLEN", identify)
if times < limitTimes then
    redis.call("RPUSH", identify, timestamp)
    return 1
end
lastTimestamp = redis.call("LRANGE", identify, 0, 0)
lastTimestamp = tonumber(lastTimestamp[1])
if lastTimestamp + expireSeconds >= timestamp then
    return 0
end
redis.call("LPOP", identify)
redis.call("RPUSH", identify, timestamp)
return 1