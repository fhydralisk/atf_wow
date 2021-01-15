local addonName, L = ...

local min_mana = L.min_mana
local interact_key = L.hotkeys.interact_key
local atf_key = L.hotkeys.atf_key
local atfr_key = L.hotkeys.atfr_key

local check_buff = L.F.check_buff

SLASH_ATFCmd1 = "/atf"
SLASH_ATF_REPORT1 = "/atfr"
SLASH_ATF_CLEAN1= "/atfc"
SLASH_ATF_SWITCH1 = "/atfs"
SLASH_ATF_DEBUG1 = "/atfd"
SLASH_ATG_WHITELIST1 = "/atgwl"
SLASH_ATF_FWD1 = "/atff"
SLASH_ATF_FWD_IGNORE1 = "/atffignore"
SLASH_RESET_BACKEND1 = "/atrb"
SLASH_REPORT_STATISTICS1 = "/atrs"


local AtfFrame = L.F.create_macro_button("ATFButton", "/atf")
local AtfReportFrame = L.F.create_macro_button("ATFRButton", "/atfr")

local pet_last_used = 0


local function maybe_use_pet_when_busy()
  if GetTime() - pet_last_used > 2 then
    if GetItemCount(L.items.pet_name) > 0 then
      if L.F.get_busy_state() and not(L.F.check_buff(L.buffs.pet_debuff_name, nil, true)) then
        SetBindingItem(interact_key, L.items.pet_name)
        pet_last_used = GetTime()
        return true
      elseif not(L.F.get_busy_state()) and L.F.check_buff(L.buffs.pet_debuff_name, nil, true) then
        SetBindingItem(interact_key, L.items.pet_name)
        pet_last_used = GetTime()
        return true
      end
    end
  end
  return false
end


local function bind_drink()
  if maybe_use_pet_when_busy() then
    return
  end
  if check_buff(L.buffs.drinking, 3) or check_buff(L.buffs.wakeup, 0.5) then
    SetBinding(interact_key, "")
  else
    local wakeup_cd = GetSpellCooldown(L.buffs.wakeup, "BOOKTYPE_SPELL")
    local food_info = L.F.get_food_name_level()
    if wakeup_cd > 0 or UnitPower("player") > UnitPowerMax("player") * 0.5 then
      SetBindingItem(interact_key, food_info.water.name)
    else
      SetBindingSpell(interact_key, L.buffs.wakeup)
    end
  end
end


local function bind_buff()
  if UnitPower("player") < UnitPowerMax("player") / 3 then
    SetBindingItem(interact_key, L.F.get_food_name_level().water.name)
  elseif not(UnitName("target") == UnitName("player")) then
    SetBinding(interact_key, "TARGETSELF")
  elseif not check_buff(L.buffs.armor, 300) then
    SetBindingSpell(interact_key, L.buffs.armor)
  elseif not (check_buff(L.buffs.intel, 300) or check_buff("奥术光辉", 300))then
    SetBindingSpell(interact_key, L.buffs.intel)
  end
end


local function auto_bind()
  if L.state == 1 then
    L.F.bind_make_food_or_water()
  elseif L.state == 2 then
    bind_drink()
  elseif L.state == 3 then
    L.F.bind_gate()
  elseif L.state == 4 then
    bind_buff()
  elseif L.state == 5 then
    L.F.bind_detect_layer()
  end
end


local function auto_bind_backend()
  if L.F.bind_set_enlarge_target() then
    return
  end
  L.F.bind_reseter_backend()
end


local function should_detect_layer()
  if ATFClientSettings.npc_nearby then
    local interval = ATFClientSettings.layer_detect_interval or 600
    if GetTime() - L.last_layer_detect_ts > interval then
      return true
    end
  end
end


local function drive_state()
  if L.next_state then
    -- using next_state to bypass the concurrent issue.
    L.state = L.next_state
    L.next_state = nil
  end
  if L.state == 1 then  -- working -> resting or buffing or layer detecting
    if UnitPower("player") < min_mana then
      L.state = 2
      DoEmote("drink", "none")
    elseif not ((check_buff(L.buffs.intel, 10) or check_buff("奥术光辉", 10)) and check_buff(L.buffs.armor, 10)) then
      L.state = 4
    elseif should_detect_layer() then
      L.layer_detected = false
      L.state = 5
    end
  elseif L.state == 2 then  -- resting -> working
    local scale = 0.95
    if L.F.check_buff(L.buffs.activate, 1) then
      scale = 0.65
    end
    if UnitPower("player") >= UnitPowerMax("player") * scale then
      L.state = 1
      DoEmote("work", "none")
    end
  elseif L.state == 3 then  -- gating -> working
    local cd_gate, cd_duration = GetSpellCooldown(L.gate.gating_context["spell"])
    if cd_gate > 0 and cd_duration > 10 then
      L.gate.gating_context['cooldown_ts'] = cd_gate + cd_duration
      L.state = 1
    end
  elseif L.state == 4 then -- buffing -> working
    if (check_buff(L.buffs.intel, 100) or check_buff("奥术光辉", 100)) and check_buff(L.buffs.armor, 100) then
      L.state = 1
    end
  elseif L.state == 5 then -- detecting layer -> working
    if L.layer_detected then
      L.state = 1
    end
  end
end


local revive_rw_last = 0
local revive_rw_interval = 15

local function may_revive()
  if UnitIsDeadOrGhost("player") then
    AcceptResurrect()
    if GetTime() - revive_rw_last > revive_rw_interval then
      revive_rw_last = GetTime()
      local chat_type = "party"
      if UnitInRaid("player") then
        chat_type = "raid_warning"
      elseif not UnitInParty("player") then
        return
      end
      SendChatMessage("工具人已阵亡，如您有复活技能或工具，烦请在我的尸体位置安全复活我，感谢！", chat_type)
    end
  end
end


local last_raid_warn = 0

local function may_send_raid_warn()
  if GetTime() - last_raid_warn > (ATFClientSettings.raid_message_interval or 10) then
    last_raid_warn = GetTime()
    if  ATFClientSettings.raid_message then
      SendChatMessage(ATFClientSettings.raid_message, "raid_warning")
    end
    if L.nwb_layer then
      SendChatMessage("我目前位于位面【"..L.nwb_layer.."】", "raid_warning")
    end
  end
end


function SlashCmdList.ATFCmd(msg)
  L.F.watch_dog_hit()
  if L.F.is_frontend() then
    drive_state()
    L.F.drive_gate()
    auto_bind()
    L.F.drive_busy_state()
    L.F.check_low_level_food()
    L.F.ping_backends()
    L.F.drive_enlarge_baggage_frontend()
    L.F.may_cleanup_baggage()
    L.F.may_cleanup_group()
    may_send_raid_warn()
    pcall(L.F.record_player_enter)
    if ATFClientSettings.inviter and not(UnitIsGroupLeader(ATFClientSettings.inviter)) and UnitInParty("player") then
      LeaveParty()
    end
  end

  if L.F.is_backend() then
    auto_bind_backend()
    L.F.drive_reset_instance()
  end

  if L.F.is_inviter() then
    L.F.auto_bind_inviter()
    L.F.drive_inviter()
    L.F.may_cleanup_group()
  end

  if L.F.is_enlarger() then
    L.F.drive_enlarge_baggage_backend()
  end

  L.F.accept_accepted_trade()
  L.F.dequeue_say_messages()
  may_revive()
end


function SlashCmdList.ATF_REPORT(msg)
  if (L.atfr_run == true or msg == "force") and L.F.is_frontend() then
    L.F.send_ad()
  end
end


function SlashCmdList.ATF_CLEAN(msg)
  local free_slots = L.F.get_free_slots()
  if free_slots == 0 or msg == "force" then
    L.F.do_real_cleanup()
  elseif msg == "clean all" then
    L.F.do_clean_all()
  end
end


function SlashCmdList.ATF_SWITCH(msg)
  if msg == "on" then
    L.atfr_run = true
    SetBindingClick(atf_key, "ATFButton")
    SetBindingClick(atfr_key, "ATFRButton")
    L.F.start_handler()
    L.F.start_trade_hook()
    CloseTrade()
  elseif msg == "off" then
    if L.atfr_run then
      SendChatMessage("自动模式已关闭，人工介入")
    end
    L.atfr_run = false
  elseif msg == "maintain" then
    L.atfr_run = "maintain"
  elseif msg == "noparty" then
    print("no party mode on")
    L.no_party = true
  elseif msg == "party" then
    print("no party mode off")
    L.no_party = nil
  elseif msg == "adv" then
    print("say adv")
    ATFATFClientSettings.adv = true
  elseif msg == "noadv" then
    print("disable say adv")
    ATFClientSettings.adv = false
  end
end


function SlashCmdList.ATF_DEBUG(msg)
  if string.match(msg, "bind ([^%s]*) ([^%s]*)") then
    local bind, spell = string.match(msg, "bind ([^%s]*) ([^%s]*)")
    print(bind)
    print(spell)
    SetBinding(bind, "SPELL "..spell)
  end
  if msg == "showstate" then
    print(L.state)
  end
  if msg == "showframe" then
    print(AtfFrame)
    print(AtfReportFrame)
  end
  if msg == "forcebusy" then
    L.F.set_busy(true)
  end
  if msg == "forceunbusy" then
    L.F.set_busy(false)
  end
  if msg == "enabledebug" then
    print("Enter debug mode")
    L.debug.enabled = true
  end
  if msg == "disabledebug" then
    print("Exit debug mode")
    L.debug.enabled = false
  end
  if msg == "targetpos" then
    print(L.F.unit_position("target"))
  end
  if msg == "radab" then
    local x1, y1 = L.F.unit_position("player")
    local x2, y2 = L.F.unit_position("target")
    local deg = (GetPlayerFacing() - math.atan2(x1-x2, y1-y2))/ math.pi * 180
    if deg > 180 then deg = deg - 360 end
    print(deg)
  end
  local statics_match = string.match(msg, "statics (.+)")
  if statics_match then
    print(L.F.query_statistics_int(statics_match))
  end
end


function SlashCmdList.ATG_WHITELIST(msg)
  if not(msg=="") then
    print("msg"..msg)
    GateWhiteList[msg] = true
  else
    local vip = UnitName("target")
    print("1"..vip)
    if vip then
      if GateWhiteList[vip] then
        GateWhiteList[vip] = nil
        print("移除"..vip)
      else
        GateWhiteList[vip] = true
        print("添加"..vip)
      end
    end
  end
end


function SlashCmdList.ATF_FWD(msg)
  L.F.start_handler()
  L.F.set_msg_fwd(msg)
  print("fwd to "..msg)
end


function SlashCmdList.ATF_FWD_IGNORE(msg)
  L.F.ignore_fwd_source(msg)
end

function SlashCmdList.RESET_BACKEND(msg)
  local cmd, player = string.match(msg, "(.-) (.+)")
  if cmd and player then
    if cmd == "add" then
      InstanceResetBackends[player] = true
      print("add backend "..player)
    elseif cmd == "remove" or cmd == "delete" or cmd == "del" then
      InstanceResetBackends[player] = nil
      print("delete backend"..player)
    end
  end
end


function SlashCmdList.REPORT_STATISTICS(msg)
  if msg and not(msg=="") then
    L.F.say_statistics(msg)
  else
    L.F.say_statistics()
  end
end
