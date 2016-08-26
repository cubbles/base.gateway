local jwt = require "resty.jwt"
local cjson = require "cjson"

-- common error handler
function respondWith500 (errorId)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR;
    ngx.header["X-CUBBLES-StatusReason"] = "Internal Error (".. errorId ..")"
    ngx.say(ngx.status, " | reason: Internal Error (".. errorId ..")");
    ngx.exit(ngx.status);
end

-- allow the token to be passed as argument or cookie named 'access_token'
local access_token = ngx.var.cookie_access_token
if not access_token then
    access_token = ngx.var.arg_access_token
end
-- verify the token
local auth_obj
function verifyAccessToken()
    auth_obj = jwt:verify(ngx.var.auth_secret, access_token, 0)
    if not auth_obj["verified"] then
        ngx.status = ngx.HTTP_UNAUTHORIZED;
        ngx.header["X-CUBBLES-StatusReason"] = auth_obj.reason
        ngx.say(ngx.status, " | reason: ", auth_obj.reason);
        ngx.exit(ngx.status);
    end
end

-- check permissions for the requested store
function checkPermissions()
    -- ngx.log(ngx.WARN, "ngx.var.uri: "..ngx.var.uri)
    -- ngx.log(ngx.WARN, "ngx.var.uri1: "..string.match(ngx.var.uri, "/webpackage%-store%-([^/]*)"))
    local requestedStore = string.match(ngx.var.uri, "/webpackage%-store%-([^/]*)")
    local permissions = auth_obj.payload.permissions
    if not permissions[requestedStore] or not permissions[requestedStore].upload then
        local reason = "No upload permissions for the requested store '"..requestedStore.."'";
        ngx.status = ngx.HTTP_UNAUTHORIZED;
        ngx.header["X-CUBBLES-StatusReason"] = reason;
        ngx.say(ngx.status, " | reason: ", reason);
        ngx.exit(ngx.status);
    end
end

-- do token verification and permission check via proctected calls (pcalls)
if not pcall(verifyAccessToken) then
    respondWith500("VERIFYACCESSTOKEN")
end
if not pcall(checkPermissions) then
    respondWith500("CHECKPERMISSIONS")
else
    -- finally extract information from the token and pass them to nginx variables
    -- references
    -- * http://docs.couchdb.org/en/1.6.1/api/server/authn.html#proxy-authentication
    ngx.var.user = auth_obj.payload.user;
    ngx.var.roles = auth_obj.payload.roles;
end
