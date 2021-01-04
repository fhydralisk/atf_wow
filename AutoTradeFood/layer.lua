local addonName, L = ...


local function parse_guid_layer(guid)

end


SLASH_ATF_GetLayer1 = "/atflayer"


function SlashCmdList.ATF_GetLayer(msg)
  if UnitName("target") == ATFClientSettings.npc_nearby then
    local guid = UnitGUID("target")
    local layer_id = parse_guid_layer(guid)
    L.layer_id = layer_id
  end
end
