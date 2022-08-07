-- 一组商品秒杀 每个用户只能抢其中一种商品1个
local goodsSurplus
local flag
-- 判断用户是否已抢过
local buyMembersKey   = tostring(KEYS[1]) -- 已经购买过的用户的Set的名称
local memberUid       = tonumber(ARGV[1]) -- 用户id
local goodsSurplusKey = tostring(KEYS[2]) -- 商品key
local hasBuy = redis.call("sIsMember", buyMembersKey, memberUid)
-- 已经抢购过，返回0
if hasBuy ~= 0 then
    return 0
end
-- 准备抢购
goodsSurplus =  redis.call("GET", goodsSurplusKey)
if goodsSurplus == false then -- 商品key不存在 可能商品已经下架
    return 0
end
-- 库存判断
goodsSurplus = tonumber(goodsSurplus)
if goodsSurplus <= 0 then -- 商品已经没有库存
    return 0
end
flag = redis.call("SADD", buyMembersKey, memberUid)
flag = redis.call("DECR", goodsSurplusKey)
return 1
