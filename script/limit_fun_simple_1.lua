-- 针对固定窗口的访问频率，而动态的非滑动窗口。
-- 即：如果规定一分钟内访问10次，记为超限。
-- 在本实例中前一分钟的最后一秒访问9次，下一分钟的第1秒又访问9次，不计为超限。
local visitNum = redis.call('incr', KEYS[1])

if visitNum == 1 then 
    redis.call('expire', KEYS[1], ARGV[1])
end

if visitNum > tonumber(ARGV[2]) then
    return 0
end

return 1