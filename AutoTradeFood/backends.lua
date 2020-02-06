---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hydra.
--- DateTime: 2020-01-30 00:56
---

local addonName, L = ...


local frame = CreateFrame("FRAME")
frame:RegisterEvent("CHAT_MSG_ADDON")


local last_pind_ts = 0
local backends_available = {}
local ping_interval = 10
local max_latency = 5


local function should_ping()
    return GetTime() - last_pind_ts > ping_interval
end


function L.F.ping_backends()
    if should_ping() then
        last_pind_ts = GetTime()
        for backend, _ in pairs(InstanceResetBackends) do
            print("pinging ".. backend)
            local t = math.modf(time()/1000)
            C_ChatInfo.SendAddonMessage("ATF", "ping:"..t, "WHISPER", backend)
        end
    end
    for backend, ts in pairs(backends_available) do
        if GetTime() - ts > ping_interval * 1.5 then
            backends_available[backend] = nil
        end
    end
end


function L.F.get_backends()
    return backends_available
end


function L.F.is_in_backends(player)
    if backends_available[player] then
        return true
    else
        return false
    end
end


function L.F.choice_random_backend()
    local backends = {}
    for backend, _ in pairs(backends_available) do
        table.insert(backends, backend)
    end

    if #backends > 0 then
        return backends[math.random(1, #backends)]
    else
        return nil
    end
end


local function eventHandler(self, event, arg1, arg2, arg3, arg4)
    if event == "CHAT_MSG_ADDON" and arg1 == "ATF" then
        local message, author = arg2, arg4
        author = string.match(author, "([^-]+)")
        local cmd, ts = string.match(message, "(.-):(.+)")
        if cmd and ts then
            ts = tonumber(ts)
            if time()/1000 - ts > max_latency then
                return
            end
            if L.F.is_frontend() then
                if cmd == "pong" and InstanceResetBackends[author] then
                    print("received pong from "..author)
                    backends_available[author] = GetTime()
                end
            else
                if cmd == "ping" then
                    local t = math.modf(time()/1000)
                    C_ChatInfo.SendAddonMessage("ATF", "pong:"..t, "WHISPER", author)
                end
            end
        end
    end
end


-- default hook for backends
local function should_hook(trade)
    L.F.whisper("您想从我这个弱小可爱又无助的"..UnitLevel("player").."级"..UnitClass("player").."这里得到什么？一丝安慰嘛~~", trade.npc_name)
    return true, true
end


local function should_accept(trade)
    return false
end


L.trade_hooks.backend_default = {
  ["should_hook"] = should_hook,
  ["feed_items"] = nil,
  ["on_trade_complete"] = nil,
  ["on_trade_cancel"] = nil,
  ["on_trade_error"] = nil,
  ["should_accept"] = should_accept,
  ["check_target_item"] = nil,
}

frame:SetScript("OnEvent", eventHandler)
