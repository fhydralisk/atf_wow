local addonName, L = ...

L.last_layer_detect_ts = 0
L.layer_detected = false
L.unit_layer_map = {}

local dl_button = L.F.create_macro_button("DLButton", "")
local la_frame = CreateFrame("FRAME")
la_frame:RegisterEvent("CHAT_MSG_ADDON")

local function parse_guid_layer(guid)
  return string.match(guid, ".-\-.-\-.-\-.-\-(.-)\-.+")
end


SLASH_ATF_GetLayer1 = "/atflayer"


function L.F.layer_detect_interval()
  return ATFClientSettings.layer_detect_interval or 300
end


local function NWBPairsByKeys(t, f)
	local a = {};
	for n in pairs(t) do
		table.insert(a, n);
	end
	table.sort(a, f);
	local i = 0;
	local iter = function()
		i = i + 1;
		if (a[i] == nil) then
			return nil;
		else
			return a[i], t[a[i]];
		end
	end
	return iter;
end


local function NWBGetLayerNum(zoneID, layers)
	local count = 0;
	local found;
	for k, v in NWBPairsByKeys(layers) do
		count = count + 1;
    if (k == zoneID) then
      found = true;
      break;
    else
      for l, _ in pairs(v.layerMap) do
        if (l == zoneID) then
          found = true;
          break;
        end
      end
      if (found) then
        break;
      end
    end
  end
	if (found) then
		return count;
	else
		return 0;
	end
end


local function GetNWBLayer(layer_id)
  if NWBdatabase == nil then
    return nil
  else
    local success, layer = pcall(function(l)
      return NWBGetLayerNum(tonumber(l), NWBdatabase.global[L.realm][L.faction].layers)
    end, layer_id)
    if success then
      if layer == 0 then
        return nil
      else
        return layer
      end
    end
  end
end


local function unit_layer(unit)
  if L.unit_layer_map[unit] and L.unit_layer_map[unit].expire > GetTime() then
    return L.unit_layer_map[unit].layer
  end
end


local function send_layer_info(player, target, ack)
  local expire = math.max(0, math.floor(L.F.layer_detect_interval() - GetTime() + L.last_layer_detect_ts))
  if expire > 0 then
    if ack == nil then
      if unit_layer(target) then
        ack = 0
      else
        ack = 1
      end
    end

    C_ChatInfo.SendAddonMessage(
        "ATF",
        "unit_layer:"..player..","..L.nwb_layer..","..expire..","..ack,
        "whisper",
        target
    )
  end
end


function SlashCmdList.ATF_GetLayer()
  L.last_layer_detect_ts = GetTime()
  local npc_nearby = {}
  for _, npc in ipairs(ATFClientSettings.npc_nearby) do
    npc_nearby[npc] = true
  end
  if npc_nearby[UnitName("target")] then
    local guid = UnitGUID("target")
    local layer_id = parse_guid_layer(guid)
    local player = UnitName("player")
    L.layer_id = layer_id
    L.nwb_layer = GetNWBLayer(layer_id)
    L.unit_layer_map[player] = {
      layer=L.nwb_layer,
      expire=GetTime()+L.F.layer_detect_interval()
    }
    if L.nwb_layer then
      for _, target in ipairs(ATFClientSettings.layer_units) do
        if not(target == player) then
          send_layer_info(player, target)
        end
      end
    end
  end
  L.layer_detected = true
end


function L.F.bind_detect_layer()
  local macrotext = ""
  for _, npc in ipairs(ATFClientSettings.npc_nearby) do
    macrotext = macrotext..string.format("/targetexact %s\n/atflayer\n/targetlasttarget\n", npc)
  end
  dl_button:SetAttribute("macrotext", macrotext)
  SetBindingClick(L.hotkeys.interact_key, "DLButton")
end


local function say_layer(to_player)
  L.F.whisper_or_say("工具人位面情况：", to_player)
  local player = UnitName("player")
  for k, v in pairs(L.unit_layer_map) do
    if k == player then
      k = ">>>本工具人<<<"..k
    end
    if v.expire > GetTime() then
      L.F.whisper_or_say("【位面"..v.layer.."】 - "..k, to_player)
    end
  end
  L.F.whisper_or_say("希望快速切换位面，请密我：【位面1】 或 【位面2】", to_player)
end


local function want_layer(requester, layer)
  for k, v in pairs(L.unit_layer_map) do
    if v.layer == layer and v.expire > GetTime() then
      if k == UnitName("player") then
        L.F.invite_player(requester)
      else
        L.F.whisper_or_say("正在尝试请工具人【"..k.."】邀请您。", requester)
        C_ChatInfo.SendAddonMessage("ATF", "invite_by_layer:"..requester, "whisper", k)
      end
      return true
    end
  end
  L.F.whisper_or_say("目前没有工具人位于位面"..layer.."，十分抱歉。", requester)
end


function L.F.layer_request(msg, author)
  local layer_wanted = string.match(msg, L.cmds.layer.."(%d+)")
  if layer_wanted then
    want_layer(author, tonumber(layer_wanted))
  else
    say_layer(author)
  end
end


local function eventHandler(self, event, arg1, arg2, arg3, arg4)
  if event == "CHAT_MSG_ADDON" and arg1 == "ATF" then
    local message, author = arg2, arg4
    author = string.match(author, "([^-]+)")
    local cmd, msg = string.match(message, "(.-):(.+)")
    if cmd and msg then
      if cmd == "unit_layer" then
        local unit, layer, expire, ack = string.match(msg, "(.-),(.-),(.-),(.+)")
        L.unit_layer_map[unit] = {
          layer=tonumber(layer),
          expire=GetTime()+tonumber(expire)
        }
        if ack == "1" then
          send_layer_info(UnitName("player"), author, 0)
        end
      elseif cmd == "invite_by_layer" then
        L.F.invite_player(msg)
      end
    end
  end
end


la_frame:SetScript("OnEvent", eventHandler)
