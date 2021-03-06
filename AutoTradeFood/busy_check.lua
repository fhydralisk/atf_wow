---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hydra.
--- DateTime: 2020-01-05 14:36
---
local addonName, L = ...

local busy_state_context = {
  ["samples"] = {
    {["sample_ts"]=0, ["water"]=0, ["bread"]=0}
  },
  ["is_busy"] = false,
}

local threshold_busy_low = 12
local threshold_busy_high = 20
local sample_interval = 45
local sample_size = 5


local function get_last_sample()
    return busy_state_context.samples[#busy_state_context.samples]
end


local function sample_busy()
    if get_last_sample() == nil or GetTime() - get_last_sample().sample_ts >= sample_interval then
        table.insert(busy_state_context.samples, {
            ["sample_ts"] = GetTime(),
            ["water"] = L.F.get_water_count(),
            ["bread"] = L.F.get_bread_count(),
        })
    end
end


local function cleanup_sample()
    while #busy_state_context.samples > sample_size or (
        busy_state_context.samples[1]
        and
        GetTime() - busy_state_context.samples[1].sample_ts > (sample_interval + 3) * sample_size
    ) do
        table.remove(busy_state_context.samples, 1)
    end
end


function L.F.drive_busy_state()
    sample_busy()
    cleanup_sample()
    if #busy_state_context.samples >= sample_size - 1 then
        if busy_state_context.is_busy then
            for _, value in ipairs(busy_state_context.samples) do
                if value.water + value.bread < threshold_busy_high then
                    return
                end
            end
            -- all water+bread >= threshold_busy_high
            print("Exit busy state")
            busy_state_context.is_busy = false
            table.insert(BusyHistory, {["busy"]=false, ["time"]=date("%x %X")})
        else
            for _, value in ipairs(busy_state_context.samples) do
                if value.water + value.bread > threshold_busy_low then
                    return
                end
            end
            -- all water+bread <= threshold_busy_low
            print("Enter busy state")
            busy_state_context.is_busy = true
            table.insert(BusyHistory, {["busy"]=true, ["time"]=date("%x %X")})
        end
    end
end


function L.F.get_busy_state()
    return busy_state_context.is_busy
end


function L.F.set_busy(state)
    busy_state_context.is_busy = state
    busy_state_context.samples = {}
end


function L.F.say_busy(to_player)
  if L.F.get_busy_state() then
    L.F.whisper_or_say("【当前正处于用餐高峰！】", to_player)
  else
    L.F.whisper_or_say("【当前处于非用餐高峰。】", to_player)
  end
  L.F.whisper_or_say("米豪将在库存持续紧张的情况下自动切换为用餐高峰模式，将在库存不紧张时切换为非用餐高峰模式。", to_player)
  L.F.whisper_or_say("用餐高峰模式下，米豪将自动进行如下限制：", to_player)
  L.F.whisper_or_say("1. 每次交易时，供应餐饮数量减半。", to_player)
  L.F.whisper_or_say("2. 在多个角色同时交易时，将阻止某一玩家连续（成功的）交易。", to_player)
  L.F.whisper_or_say("3. 阻止60级法师进行交易。", to_player)
  L.F.whisper_or_say("谢谢您的理解与支持，如有任何建议，请邮件与{player}联系哈！", to_player)
end
