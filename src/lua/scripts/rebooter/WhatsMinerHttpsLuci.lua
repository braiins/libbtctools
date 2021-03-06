--[[
MIT License

Copyright (c) 2021 Braiins Systems s.r.o.
Copyright (c) 2021 BTC.COM.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

WhatsMinerHttpsLuci = oo.class({}, ExecutorBase)

function WhatsMinerHttpsLuci:__init(parent, context)
    local miner = context:miner()
    local ip = miner:ip()
    miner:setOpt("settings_pasword_key", "WhatsMiner")

    context:setRequestHost("tls://"..ip)
    context:setRequestPort("443")

    local obj = ExecutorBase.__init(self, parent, context)
    obj:setStep("getSession")
    return obj
end

function WhatsMinerHttpsLuci:getSession()
    self:makeLuciSessionReq()
    self:setStep("parseSession", "login...")
end

function WhatsMinerHttpsLuci:parseSession(httpResponse, stat)
    local response = self:parseLuciSessionReq(httpResponse, stat)
    if (not response) then
        self:setStep("getNoPswdSession")
    else
        self:setStep("getToken")
    end
end

function WhatsMinerHttpsLuci:getNoPswdSession()
    self:makeLuciSessionReq(true)
    self:setStep("parseNoPswdSession", "login without pwd...")
end

function WhatsMinerHttpsLuci:parseNoPswdSession(httpResponse, stat)
    local response = self:parseLuciSessionReq(httpResponse, stat)
    if (not response) then
        return
    end
    self:setStep("getToken")
end

function WhatsMinerHttpsLuci:getToken()
    self:makeLuciTokenReq()
    self:setStep("parseToken", "get token...")
end

function WhatsMinerHttpsLuci:parseToken(httpResponse, stat)
    local token = self:parseLuciTokenReq(httpResponse, stat)
    if (not token) then
        return
    end
    self:setStep("callReboot", "rebooting...")
end

function WhatsMinerHttpsLuci:callReboot()
    local context = self.context
    local miner = context:miner()

    local request = {
        method = "POST",
        path = "/cgi-bin/luci/admin/system/reboot/call",
        headers = {
            ["content-type"] = "application/x-www-form-urlencoded"
        },
        body = "token=" .. miner:opt("_luci_token")
    }

    self:makeSessionedHttpReq(request)
    self:setStep("parseReboot")
end

function WhatsMinerHttpsLuci:parseReboot(httpResponse, stat)
    local context = self.context
    local miner = context:miner()
    local response = self:parseHttpResponse(httpResponse, stat, false)

    if (response and response.statCode ~= "200") then
        utils.debugInfo("WhatsMinerHttpsLuci:parseReboot", "statCode ~= 200")
        self:setStep("end", "perform reboot failed")
        return
    end

    miner:setOpt("check-reboot-finish-times", "0")
    self:setStep("waitFinish")
    self:disableRetry()
end

function WhatsMinerHttpsLuci:waitFinish()
    local context = self.context
    context:setRequestDelayTimeout(5)
    context:setRequestSessionTimeout(5)

    local request = {
        method = "GET",
        path = "/"
    }

    self:makeBasicHttpReq(request)
    self:setStep("doWaitFinish", "wait finish...")
end

function WhatsMinerHttpsLuci:doWaitFinish(httpResponse, stat)
    local context = self.context
    local miner = context:miner()

    if (stat == "success") then
        self:setStep("end", "rebooted")
        return
    end

    local times = tonumber(miner:opt("check-reboot-finish-times"))
    if (times > 30) then
        self:setStep("end", "timeout, may succeeded")
        return
    end

    miner:setOpt("check-reboot-finish-times", tostring(times + 1))
    self:setStep("waitFinish", "not finish")
end
