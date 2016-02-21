local na = #ARGV
local v = {}
local nv = 10
local level = redis.LOG_NOTICE

local table_exists = function(t) 
    if (1 == redis.call('sismember', '_T_N_', t)) then
        return true
    end
    return false
end

local to_int = function(n)
    local i = tonumber(n)
    if i then
        return math.floor(i)
    end
    return nil
end

local find_pk = function(t)
    local pkd = string.format('_T_[%s]_C_PK_', t)
    local cd = redis.call('get', pkd)
    if (nil == cd) then
        return nil
    end
    local d = string.format('_T_[%s]_C_[%s]_', t, cd)
    local v = redis.call('hmget', d, 'PRIMARY_KEY', 'TYPE')
    if (nil == v) then
        return nil
    end
    return {n=cd, pk=v[1], t=v[2]}
end

if (2 > na) then
    return {-1, "should provides arguments [table cursor]"}
end

local t = ARGV[1]
if (not table_exists(t)) then
    return {-00942, string.format('table does not exist', t)}
end

local i = to_int(ARGV[2])
if (not i) then
    return {-01001, string.format('invalid cursor [%s]', ARGV[2])}
end

local pk = find_pk(t)
if (nil == pk) then
    redis.log(level, string.format('no primary keys in table %s', t))
    return {-02270, 'primary key does not exist'}
end

local pkd = string.format('_T_[%s]:[%s]_', t, pk['n'])
local pks = nil
if ('STRING' == pk['t']) then
    pks = redis.call('zrangebylex', pkd, '-', '+', 'limit', i, nv)
else
    pks = redis.call('zrange', pkd, i, nv)
end

v[#v+1] = {i, nv}
for j=1,#pks  do
    local r = string.format('_T_[%s]:[%s]:<%s>_', t, pk['n'], pks[j])
    v[#v+1] = redis.call('hgetall', r)
end

return v
