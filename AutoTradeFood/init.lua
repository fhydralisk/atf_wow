---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hydra.
--- DateTime: 2020-01-05 13:11
---

local addonName, L = ...

L.addonName = addonName
L.F = {}
L.trade_hooks = {}

L.cmds = {}
L.cmds.stat = "stat"
L.cmds.kick_offline = "kick offline"
L.cmds.retrieve_position = "pos"
L.cmds.scale_cmd = "查看比例"
L.cmds.help_cmd = "帮助"
L.cmds.invite_cmd = "水水水"
L.cmds.gate_help_cmd = "传送门"
L.cmds.busy_cmd = "高峰"
L.cmds.refill_cmd = "补货"
L.cmds.refill_help_cmd = "如何补货"
L.cmds.low_level_cmd = "宝宝餐"
L.cmds.low_level_help_cmd = "小号"
L.cmds.say_ack = "致谢"
L.cmds.statistics = "数据"
L.cmds.reset_instance_help = "重置帮助"
L.cmds.reset_instance_cmd = "重置"
L.cmds.boom_predict = "爆本"
L.cmds.boom_record = "手动重置"

L.items = {}
L.items.water_name = "魔法晶水"
L.items.food_name = "魔法甜面包"
L.items.stone_name = "传送门符文"
L.items.food = {name="魔法甜面包", level=45}
L.items.water = {name="魔法晶水", level=55}
L.items.stone_name_incorrect = "传送符文"
L.items.pet_name = "恶心的软泥怪"

L.buffs = {}
L.buffs.armor = "魔甲术"
L.buffs.intel = "奥术智慧"
L.buffs.wakeup = "唤醒"
L.buffs.drinking = "喝水"
L.buffs.pet_debuff_name = "软泥怪的恶心光环"
L.buffs.activate = "激活"

L.state = 1
-- states: 1 making, 2 watering? 3 gating, 4 buff

L.hotkeys = {}
L.hotkeys.interact_key = "CTRL-I"
L.hotkeys.atf_key = "CTRL-Y"
L.hotkeys.atfr_key = "ALT-CTRL-Y"

L.min_mana = 780
L.atfr_run = false

L.trade_timeout = 14

L.gate_request_timeout = 90

L.refill_timeout = 120

L.low_level_wait_timeout = 60

L.watch_dog_threshold = 15

L.block_detect_duration = 55

L.debug = {}
L.debug.white_list = {
    ["米豪的维修师"] = true
}
L.debug.enabled = false

L.admin_names = {
    ["卑微的米豪"] = true,
    ["米豪的备胎"] = true,
    ["米豪的维修师"] = true,
    ["米豪"] = true,
    ["云缠绕星光丶"] = true,
}

L.agent_timeout = 7200
L.reset_instance_timeout = 40

--小号模式
--L.items.water_name = "魔法纯净水"
--L.items.food_name = "魔法黑面包"
--L.buffs.armor = "霜甲术"
--L.min_mana = 300


local frame = CreateFrame("FRAME", "InitFrame")
frame:RegisterEvent("ADDON_LOADED")

local function eventHandler(self, event, msg)
    if event == "ADDON_LOADED" and msg == "AutoTradeFood" then
        if PlayerDefinedScale == nil then
            PlayerDefinedScale = {}
        end
        if GateWhiteList == nil then
            GateWhiteList = {}
        end
        if BusyHistory == nil then
            BusyHistory = {}
        end
        if ATFStatistics == nil then
            ATFStatistics = {}
        end
        if InstanceResetBackends == nil then
            InstanceResetBackends = {}
        end
        if ATFResetBlockList == nil then
            ATFResetBlockList = {}
        end
        if ForwardIgnoreSource == nil then
            ForwardIgnoreSource = {}
        end
        if ATFClientSettings == nil then
            ATFClientSettings = {
                client_types={frontend=true, backend=false, inviter=false, enlarger=false}, -- "backend", "inviter", "enlarger"
                adv=false,
                inviter=nil,
                silent=true,
                is_internal=false,
                invite_words=nil,
                should_enlarge=false,
                bread_55=nil,
                raid_message=nil,
                raid_message_interval=15,
            }
        end
        if ATFAdminList == nil then
            ATFAdminList = {}
        end
        if ATFInviterVip == nil then
            ATFInviterVip = {}
        end
        if ATFBlockList == nil then
            ATFBlockList = {}
        end
    end
end

frame:SetScript("OnEvent", eventHandler)
C_ChatInfo.RegisterAddonMessagePrefix("ATF")
