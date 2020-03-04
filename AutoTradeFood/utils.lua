---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hydra.
--- DateTime: 2020-01-05 13:13
---

local addonName, L = ...

local watch_dog_ts = 0


local whisper_protect = {}


function L.F.split(inputstr, sep)
    if sep == nil then
        sep = "."
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end


function L.F.create_macro_button(button_name, macro_text)
  local cframe = CreateFrame("Button", button_name, UIParent, "SecureActionButtonTemplate");
--  cframe:RegisterForClicks("AnyUp");
  cframe:SetAttribute("type", "macro");
  cframe:SetAttribute("macrotext", macro_text);
  return cframe
end


function L.F.search_str_contains(s, tbl, position)
  for _, ss in pairs(tbl) do
    if s and string.lower(s):find(ss) then
      local l, u = string.find(string.lower(s), ss)
      local mid_ss = (l + u) / 2
      local mid_s = (1 + string.len(s)) / 2
      if position == "left" then
        return mid_ss <= mid_s
      elseif position == "right" then
        return mid_ss >= mid_s
      else
        return true
      end
    end
  end
  return false
end

function L.F.my_position()
  local mapID = C_Map.GetBestMapForUnit("player")
  local tempTable = C_Map.GetPlayerMapPosition(mapID, "player")
  local x, y = tempTable.x, tempTable.y
  return string.format("(%.1f,%.1f)", x * 100, y * 100)
end

function L.F.check_buff(buff_name, remain, is_debuff)
  local buff_func = UnitBuff
  if is_debuff then
    buff_func = UnitDebuff
  end
  local i = 1;
  if remain == nil then
    remain = 0
  end
  while true do
    local buff, _, _,   _, dur, ts = buff_func("player", i);
    if buff == nil then
      return false
    elseif buff == buff_name then
      local remaining
      if ts and ts > 0 then
        remaining = ts - GetTime()
      else
        remaining = 9999
      end
      return remaining > remain
    end
    i = i + 1;
  end;
end


function L.F.invite_player(player)
  if L.F.is_inviter() or ATFClientSettings.inviter == nil then
    InviteUnit(player)
  else
    if not UnitInParty(ATFClientSettings.inviter) then
      C_ChatInfo.SendAddonMessage("ATF", "invite:"..UnitName("player"), "WHISPER", ATFClientSettings.inviter)
    end
    C_ChatInfo.SendAddonMessage("ATF", "invite:"..player, "WHISPER", ATFClientSettings.inviter)
  end
  ConvertToRaid()
end


function L.F.nil_fallback_zero(value)
  if value == nil then
    return 0
  else
    return value
  end
end


function L.F.player_is_admin(player)
  if L.admin_names[player] then
    return true
  else
    return false
  end
end


function L.F.watch_dog_hit()
  watch_dog_ts = GetTime()
end


function L.F.watch_dog_ok()
  if GetTime() - watch_dog_ts < L.watch_dog_threshold then
    return true
  else
    return false
  end
end


local function may_whisper_to(to_player)
  local interval = 400
  local exceed = 40
  if whisper_protect[to_player] == nil or GetTime() - whisper_protect[to_player].sent > interval then
    whisper_protect[to_player] = {
      sent=GetTime(),
      num=0,
    }
  end
  whisper_protect[to_player].num = whisper_protect[to_player].num + 1
  return whisper_protect[to_player].num <= exceed
end


function L.F.whisper_or_say(message, to_player)
  if L.F.is_inviter() or ATFClientSettings.inviter == nil then
    if to_player then
      if may_whisper_to(to_player) then
        SendChatMessage(message, "WHISPER", nil, to_player)
      end
    else
      L.F.queue_message(message)
    end
  else
    if to_player then
      C_ChatInfo.SendAddonMessage("ATF", "/w:"..to_player..":"..message, "WHISPER", ATFClientSettings.inviter)
    else
      C_ChatInfo.SendAddonMessage("ATF", "/s:"..message)
    end
  end
end


function L.F.client_type()
  return ATFClientSettings.client_types
end


function L.F.is_frontend()
  return L.F.client_type().frontend
end


function L.F.is_backend()
  return L.F.client_type().backend
end


function L.F.is_inviter()
  return L.F.client_type().inviter
end


function L.F.is_inviter()
  return L.F.client_type().enlarger
end


function L.F.get_party_member_count()
  local members_count = GetNumGroupMembers()
  local prefix
  local online, offline = {}, {}

  if UnitInRaid("player") then
    prefix = "raid"
  elseif UnitInParty("player") then
    table.insert(online, "player")
    prefix = "party"
  else
    prefix = nil
  end

  if prefix then
    for i = 1, members_count do
      local unit = prefix..i
      if UnitIsConnected(unit) then
        table.insert(online, unit)
      else
        table.insert(offline, unit)
      end
    end
    return members_count, online, offline
  else
    return 1, {"player"}, {}
  end

end
