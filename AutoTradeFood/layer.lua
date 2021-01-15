local addonName, L = ...

L.last_layer_detect_ts = 0
L.layer_detected = false
local dl_button = L.F.create_macro_button("DLButton", "")


local function parse_guid_layer(guid)
  return string.match(guid, ".-\-.-\-.-\-.-\-(.-)\-.+")
end


SLASH_ATF_GetLayer1 = "/atflayer"


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


function SlashCmdList.ATF_GetLayer()
  if UnitName("target") == ATFClientSettings.npc_nearby then
    local guid = UnitGUID("target")
    local layer_id = parse_guid_layer(guid)
    L.layer_id = layer_id
    L.nwb_layer = GetNWBLayer(layer_id)
  end
  L.last_layer_detect_ts = GetTime()
  L.layer_detected = true
end


function L.F.bind_detect_layer()
  dl_button:SetAttribute("macrotext", string.format(
            "/targetexact %s\n/atflayer\n/targetlasttarget", ATFClientSettings.npc_nearby
  ))
  SetBindingClick(L.hotkeys.interact_key, "DLButton")
end
