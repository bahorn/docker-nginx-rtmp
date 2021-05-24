-- Scripts if an RTMP stream is meant to still be active.
-- on_update handler.

ngx.req.read_body()

-- setup redis connection
local redis = require "resty.redis"
local red = redis:new()
red:set_timeouts(1000, 1000, 1000)
local ok, err = red:connect("redis", 6379)

if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("failed to connect: ", err)
    return ngx.exit(ngx.status)
end

-- read the arguments in
local args, err = ngx.req.get_post_args()
if not args then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("failed to get post args: ", err)
    return ngx.exit(ngx.status)
end

-- query the key
local res, err = red:get(args["name"])
if not res or res == ngx.null then
    ngx.status = ngx.HTTP_FORBIDDEN
    ngx.say("app isn't authorized.")
    return ngx.exit(ngx.status)
end

-- and success
ngx.status = ngx.HTTP_OK
ngx.exit(ngx.status)
