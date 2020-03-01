---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hydra.
--- DateTime: 2020-01-17 23:01
---

local addonName, L = ...

local frame = CreateFrame("FRAME", "ATFFrame")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("ADDON_LOADED")


local timeout = L.reset_instance_timeout


local reseter_context = {
    player=nil,
    class=nil,
    request_ts=nil,
    invite_ts=nil,
    reset=nil,
    frontend=nil,
    instance=nil,
    queue_length=nil,
}

local last_ctx = {}

local just_started = true

local block_intention_list = {}
local block_duration_to_block = 120
local block_duration_try_block = 0
local block_duration_repeat_request = 3600


local function can_reset(player)
    return UnitInParty(player) and not UnitIsConnected(player) and reseter_context.invite_ts and GetTime() - reseter_context.invite_ts > 2
end


local function dequeue_reseter()
    if #InstanceResetQueue > 0 then
        local queued = InstanceResetQueue[1]
        table.remove(InstanceResetQueue, 1)
        return queued
    end
end


local function notify_queued_player()
    for i, q in ipairs(InstanceResetQueue) do
        L.F.whisper("重置队列已更新，您的当前位置："..i, q.player)
    end
end


local function get_block_duration(player)
    if ATFResetBlockList[player] then
        local deadline = ATFResetBlockList[player].deadline
        if deadline == 0 then
            return 0
        elseif deadline > GetTime() then
            return deadline - GetTime()
        else
            ATFResetBlockList[player] = nil
        end
    end
end


local function block_player(player, duration)
    if duration == 0 then
        ATFResetBlockList[player] = { deadline=0 }
    else
        ATFResetBlockList[player] = { deadline=GetTime() + duration }
    end
end


local function block_intention(player, duration)
    if not block_intention_list[date("%x")] then
        block_intention_list[date("%x")] = {}
    end
    if not block_intention_list[date("%x")][player] then
        block_intention_list[date("%x")][player] = 0
    end

    block_intention_list[date("%x")][player] = block_intention_list[date("%x")][player] + duration
    local block_reset_duration = block_intention_list[date("%x")][player]
    if block_reset_duration >= block_duration_to_block then
        block_player(player, block_duration_try_block)
        block_intention_list[date("%x")][player] = nil
    end
    return math.max(math.modf(block_duration_to_block - block_reset_duration), 0)
end


local function detect_block_intention()
    if reseter_context.request_ts then
        local block_reset_duration = GetTime() - reseter_context.request_ts
        if block_reset_duration >= 20 then
            local block_remain = block_intention(reseter_context.player, block_reset_duration)
            L.F.whisper("【敬告】不当的使用重置功能，导致阻塞重置队列的玩家，将被禁止使用该功能。", reseter_context.player)
            if block_remain > 0 then
                L.F.whisper("本次重置您阻塞了重置队列"..math.modf(block_reset_duration).."秒，若再次累计阻塞"..block_remain.."秒，您将被禁止使用该功能。", reseter_context.player)
                L.F.whisper("为防止被禁用，烦请您快速接受组队邀请，并迅速通过/camp宏或返回人物选择按键下线，谢谢合作。", reseter_context.player)
            else
                L.F.whisper("由于您多次阻塞重置队列，累计阻塞时长达到警戒值，您已被限制/禁止使用该功能。", reseter_context.player)
            end
        end
    end
end


function L.F.drive_reset_instance()
    if just_started then
        just_started = false
        if #InstanceResetQueue > 0 then
            print("queue is not empty")
            for _, q in ipairs(InstanceResetQueue) do
                SendChatMessage("十分抱歉，重置工具人刚刚被服务器踢下线，所有重置请求已取消，请您重新请求。", "WHISPER", nil, q.player)
            end
        end
        InstanceResetQueue = {}
        if UnitInParty("player") then
            local player = UnitName("party1")
            if UnitIsGroupLeader("player") then
                if UnitIsConnected("party1") then
                    L.F.whisper("由于工具人刚刚从掉线中恢复，本次重置失败，请您再次尝试下线，或离队后重新请求，十分抱歉！", player)
                    reseter_context = {
                        player=player,
                        request_ts=GetTime(),
                        invite_ts=GetTime(),
                        class=UnitClass("party1"),
                        frontend=nil,
                    }
                else
                    ResetInstances()
                    LeaveParty()
                end
            else
                L.F.whisper("由于工具人刚刚从掉线中恢复，本次重置失败，请您重新请求，十分抱歉！", player)
                LeaveParty()
            end
            return
        end
    end

    local player = reseter_context.player
    if player then
        if GetTime() - reseter_context.request_ts > timeout then
            L.F.whisper("未能重置，您未在规定时间内下线。", player)
            LeaveParty()
            detect_block_intention()
            reseter_context = {}
        elseif reseter_context.reset then
            reseter_context = {}
            UninviteUnit(player)
        elseif can_reset(player) then
            print("reseting")
            ResetInstances()
            print("reseted")
            reseter_context.reset = true
            if reseter_context.frontend then
                SendChatMessage("米豪已帮【"..player.."】重置副本。请M "..reseter_context.frontend.." 【"..L.cmds.reset_instance_help.."】查看使用方法。", "say")
            else
                SendChatMessage("米豪已帮【"..player.."】重置副本。请M我【"..L.cmds.reset_instance_help.."】查看使用方法。", "say")
            end
        end
    else
        local queued = dequeue_reseter()
        if queued then
            player = queued.player
            last_ctx = reseter_context
            reseter_context.player = player
            reseter_context.request_ts = GetTime()
            reseter_context.frontend = queued.frontend
            LeaveParty()
            InviteUnit(player)
            L.F.whisper("请接受组队邀请，然后立即下线。请求有效期"..timeout.."秒。", player)
            notify_queued_player()
        end
    end
end


local function enqueue_player(player, frontend)
    for i, q_player in ipairs(InstanceResetQueue) do
        if q_player.player == player then
            q_player.request_count = q_player.request_count + 1
            if q_player.request_count > 10 then
                L.F.whisper("由于您过于频繁的请求，您已被暂停使用该服务。您已被移出队列。", player)
                table.remove(InstanceResetQueue, i)
                block_player(player, block_duration_repeat_request)
                return
            else
                L.F.whisper("您已在队列中，队列位置："..i.."。请勿重复请求，刷屏可能会被暂停使用该功能，谢谢！", player)
                return
            end
        end
    end
    table.insert(InstanceResetQueue, { player=player, request_ts=GetTime(), request_count=1, frontend=frontend})
    return #InstanceResetQueue
end


function L.F.reset_instance_request_frontend(player)
    local backend = L.F.choice_random_backend()

    if backend then
        C_ChatInfo.SendAddonMessage("ATF", "reset:"..player, "WHISPER", backend)
        L.F.whisper("重置请求已转发至重置后端【"..backend.."】，请等待其回应。", player)
    else
        L.F.whisper("重置服务离线，待重置后端账号上线后可用。", player)
    end
end


function L.F.reset_instance_request(player, frontend)
    if not (L.F.watch_dog_ok()) then
        L.F.whisper(
                "米豪的驱动程序出现故障，重置副本功能暂时失效，请等待米豪的维修师进行修复。十分抱歉！", player)
        return
    end
    assert(not L.F.is_frontend())

    local block_duration = get_block_duration(player)

    if block_duration then
        if block_duration > 0 then
            L.F.whisper("由于刷屏或其他原因，您已被暂停该服务【"..math.ceil(block_duration / 60).."】分钟。请解禁后避免刷屏操作，谢谢合作！", player)
        else
            L.F.whisper("由于您的不当使用，该服务已向您永久关闭，请邮件联系我咨询解禁事宜，抱歉！", player)
        end
        return
    end

    if UnitInParty(player) then
        if reseter_context.player == player then
            L.F.whisper("【重置流程变更】当前版本只需在【未进组】的情况下M我一次请求即可。无需再次请求。", player)
        else
            L.F.whisper("【重置流程变更】为避免高峰期重置冲突，重置流程发生变化，您务必在【未进组】的前提下想我发起请求。本次请求失败。", player)
        end
        return
    elseif reseter_context.player == player then
        L.F.whisper("请接受组队邀请，然后立即下线。", player)
        return
    end

    local queue_pos = enqueue_player(player, frontend)
    if queue_pos > 1 or (queue_pos == 1 and reseter_context.player) then
        L.F.whisper("目前正在为其他玩家重置，已为您排队。请勿重复请求，刷屏可能会被暂停服务，谢谢支持！", player)
        L.F.whisper("队列位置："..queue_pos, player)
    end
end


function L.F.say_reset_instance_help(to_player)
    L.F.whisper("重置副本功能可以帮您迅速传送至副本门口，并对副本内怪物进行重置。请按如下步骤操作", to_player)
    L.F.whisper("1. 请确保您不在队伍中，且副本内没有其他玩家，然后M我【"..L.cmds.reset_instance_cmd.."】", to_player)
    L.F.whisper("2. 如果请求成功，我的【重置工具人】会向您发起组队邀请。请您进入队伍后在"..timeout.."秒内下线。", to_player)
    L.F.whisper("3. 一旦您下线，我会立即重置副本。", to_player)
    L.F.whisper("4. 如果您未爆本，下次上线您将会出现在副本门口，且副本内怪物已重置。", to_player)
    L.F.whisper("注：如果下次上线您发现在炉石点，说明：您已爆本或服务器总副本数量达到上限。", to_player)
end


function L.F.bind_reseter_backend()
    SetBinding(L.hotkeys.interact_key, "JUMP")
end


local function statistics_reset_instance(reset_ctx)
    local name = reset_ctx.player
    local class = reset_ctx.class
    local instance = reset_ctx.instance
    local key_instance_ind = "reset.ind."..date("%x").."."..name
    local key_instance_class = "reset.class."..date("%x").."."..class
    local key_instance_instance = "reset.instance."..date("%x").."."..instance
    local key_instance_count = "reset.count."..date("%x")
    L.F.merge_statistics_plus_int(key_instance_ind, 1)
    L.F.merge_statistics_plus_int(key_instance_class, 1)
    L.F.merge_statistics_plus_int(key_instance_instance, 1)
    L.F.merge_statistics_plus_int(key_instance_count, 1)
end


local function may_record_success(message)
    local pattern = string.format(INSTANCE_RESET_SUCCESS, "(.+)")
    local instance = string.match(message, pattern)
    if instance then
        last_ctx.instance = instance
        last_ctx.queue_length = #InstanceResetQueue
        statistics_reset_instance(last_ctx)
        return true
    end
end


local function eventHandler(self, event, arg1, arg2, arg3, arg4)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if ATFResetBlockList == nil then
            ATFResetBlockList = {}
        end
        if InstanceResetQueue == nil then
            InstanceResetQueue = {}
        end
        return
    end
    if not(L.atfr_run) then
        return
    end

    if event == 'CHAT_MSG_SYSTEM' then
        local message = arg1
        if reseter_context.player then
            if string.format(ERR_DECLINE_GROUP_S, reseter_context.player) == message
                    or string.format(ERR_ALREADY_IN_GROUP_S, reseter_context.player) == message then
                L.F.whisper("您拒绝了组队邀请，重置请求已取消。", reseter_context.player)
                detect_block_intention()
                reseter_context = {}
            elseif string.format(ERR_JOINED_GROUP_S, reseter_context.player) == message
                    or string.format(ERR_RAID_MEMBER_ADDED_S, reseter_context.player) == message then
                L.F.whisper("请抓紧时间下线，我将在您下线后立即重置副本。", reseter_context.player)
                reseter_context.invite_ts = GetTime()
                reseter_context.class = UnitClass(reseter_context.player)
            elseif string.format(ERR_LEFT_GROUP_S, reseter_context.player) == message
                    or string.format(ERR_RAID_MEMBER_REMOVED_S, reseter_context.player) == message
                    or ERR_GROUP_DISBANDED == message then
                L.F.whisper("您离开了队伍，重置请求已取消。", reseter_context.player)
                detect_block_intention()
                reseter_context = {}
            elseif string.format(ERR_BAD_PLAYER_NAME_S, reseter_context.player) == message then
                reseter_context = {}
            elseif may_record_success(message) then
                -- do nothing
            end
        end
    elseif event == "CHAT_MSG_ADDON" and arg1 == "ATF" then
        local message, author = arg2, arg4
        author = string.match(author, "([^-]+)")
        if L.F.is_frontend() then
            -- frontend do not respond to commands.
        else
            local cmd, target = string.match(message, "(.-):(.+)")
            if cmd and target then
                if cmd == "reset" then
                    author = string.match(author, "([^-]+)") or author
                    L.F.reset_instance_request(target, author)
                end
            end
        end
    end
end

frame:SetScript("OnEvent", eventHandler)
