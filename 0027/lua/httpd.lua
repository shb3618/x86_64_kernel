local resps = {ngx.get_req()}
--yaos.show_dump(resps);
local ctx = ngx.ctx
local getn = table.getn
local cut = function (s,p,i)
    return string.sub(s,p,i,"cut");
end

--local split = require("split");
local split = function(s, p)
    return {yaos.split(s,p)}
end
local find = function(s,p,index) 
--    yaos.say("httpd:s:"..type(s).."#p"..type(p).."\n"); 
    return string.find(s,p,index,"httpd");
end
local lower = string.lower
local inserttable = table.insert
--yaos.show_dump(ctx);
if not ctx.status then
    ctx.status = 0
    ctx.req = {headers = {},body_arr = {}, content_len = 0, body_len = 0, method = "GET"}
end
local req = ctx.req
if getn(resps)<1 then
    yaos.say("empty ngx.get_req\n");
    return 1
end
--yaos.show_dump(ctx);
--yaos.show_dump(split(resps[1] or "test\r\ntest2","\r\n"));
local function parse_line(linestr)
    --yaos.say("linestr:"..linestr.."#"..#linestr.."#status:"..ctx.status);
    if linestr =="" then
        if ctx.status == 1 then
            ctx.status = 2
        end
    elseif ctx.status == 1 then
        local pos = find(linestr,": ")

        if pos then
            local headername = lower(cut(linestr,1,pos-1))
            req.headers[headername] = cut(linestr,pos+2)
            if headername == "content-length" then
                 req.content_len = req.headers[headername] - 0
            end
        else
           yaos.say("can't found : in "..linestr);
        end
    elseif ctx.status == 2 then
       inserttable(req.body_arr, linestr);
       req.body_len = req.body_len + #linestr;
       if req.body_len >= req.content_len then
           ctx.status = 3
       end
    end

end
for _,resp in ipairs(resps) do

    if ctx.status == 0 then
        local arr = split(resp, "\r\n");
        local firstline = arr[1] or "";
        local firstarr = split(firstline,"%s")
        req.method = firstarr[1]
        if firstarr[2] then

            local querypos = find(firstarr[2],'?');
            if querypos then
                req.uri = cut(firstarr[2], 1, querypos - 1);
                req.query_string = cut(firstarr[2], querypos+1)
            else
                req.uri = firstarr[2]
            end
        end
        req.ver = firstarr[3]
        ctx.status = 1
        local idx = 2
        while idx <= getn(arr) do
           local linestr = arr[idx]
           parse_line(linestr) 
           idx = idx +1
        end
    elseif ctx.status == 1 then
        local arr = split(resp, "\r\n");
        local idx = 1
        while idx <= getn(arr) do
           local linestr = arr[idx]
           parse_line(linestr)
           idx = idx +1
        end
    elseif ctx.status == 2 then
        parse_line(resp)
    
    end
end
if ctx.status == 2 and req.content_len == 0 then
    ctx.status = 3
end
if ctx.status == 3 then
    --yaos.show_dump(ctx);
    local route = {test="web_test",json="web_json"}
    --yaos.say("req.uri:"..(req.uri or ""));
    yaos.do_file(route[cut(req.uri,2)] or "web_index");
    ngx.flush()
--    yaos.show_dump(ctx);
else
    --yaos.say("ctx.status:"..ctx.status.."#"..req.body_len.."\n")
end
return ctx.status
