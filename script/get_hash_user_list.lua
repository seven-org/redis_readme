-- 获取用户列表
-- KEYS为uid数组
local users = {}
for i,uid in ipairs(KEYS) do
    local user = redis.call('hgetall', uid)
    if user ~= nil then
        table.insert(users, i, user)
    end
end
return users