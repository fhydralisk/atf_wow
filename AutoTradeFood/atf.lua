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

local AtfFrame = L.F.create_macro_button("ATFButton", "/atf")
local AtfReportFrame = L.F.create_macro_button("ATFRButton", "/atfr")


local function bind_drink()
  if check_buff("喝水", 3) or check_buff("唤醒", 0.5) then
    SetBinding(interact_key, "")
  else
    local wakeup_cd = GetSpellCooldown("唤醒", "BOOKTYPE_SPELL")
    if wakeup_cd > 0 or UnitPower("player") > UnitPowerMax("player") * 0.5 then
      SetBindingItem(interact_key, "魔法晶水")
    else
      SetBindingSpell(interact_key, "唤醒")
    end
  end
end


local function bind_buff()
  if UnitPower("player") < 2000 then
    SetBindingItem(interact_key, "魔法晶水")
  elseif not(UnitName("target") == UnitName("player")) then
    SetBinding(interact_key, "TARGETSELF")
  elseif not check_buff("魔甲术", 300) then
    SetBindingSpell(interact_key, "魔甲术")
  elseif not (check_buff("奥术智慧", 300) or check_buff("奥术光辉", 300))then
    SetBindingSpell(interact_key, "奥术智慧")
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
  end
end


local function drive_state()
  if L.state == 1 then  -- working -> resting or buffing
    if UnitPower("player") < min_mana then
      L.state = 2
    elseif not ((check_buff("奥术智慧", 10) or check_buff("奥术光辉", 10)) and check_buff("魔甲术", 10)) then
      L.state = 4
    end
  elseif L.state == 2 then  -- resting -> working
    if UnitPower("player") == UnitPowerMax("player") then
      L.state = 1
    end
  elseif L.state == 3 then  -- gating -> working
    local cd_gate = GetSpellCooldown(L.gate.gating_context["spell"])
    if cd_gate > 0 then
      L.gate.gating_context['cooldown_ts'] = cd_gate + 60
      L.state = 1
    end
  elseif L.state == 4 then -- buffing -> working
    if (check_buff("奥术智慧", 100) or check_buff("奥术光辉", 100)) and check_buff("魔甲术", 100) then
      L.state = 1
    end
  end
end


function SlashCmdList.ATFCmd(msg)
  drive_state()
  L.F.drive_gate()
  auto_bind()
  L.F.drive_busy_state()
  if L.atfr_run == true or msg == "force" then
    if TradeFrame:IsShown() then
      local npc_name = UnitName("NPC")
      if L.gate.gating_contexts[npc_name] then
        L.F.trade_stone(npc_name)
      else
        L.F.trade_food()
      end
    end
  end
end


function SlashCmdList.ATF_REPORT(msg)
  if L.atfr_run == true or msg == "force" then
    L.F.send_ad()
  end
end


local function do_delete_groups(item_name, groups)
  local x = 0
  for b = 0, 4 do
    for l = 0, 32 do
      local itemLink = GetContainerItemLink(b, l)
      if itemLink and itemLink:find(item_name) and x < groups then
        x = x + 1
        L.F.delete_item_at(b, l)
      end
    end
  end
end


local function delete_groups()
  local water = GetItemCount(L.items.water_name)
  local food = GetItemCount(L.items.food_name)
  if water * 0.5 > food then
    local water_to_delete = math.modf((water * 0.5 - food) / 20)
    do_delete_groups(L.items.water_name, water_to_delete)
  elseif food > water * 0.9 then
    local food_to_delete = math.modf((food - water * 0.9) / 20)
    do_delete_groups(L.items.food_name, food_to_delete)
  end
end


local function del_fragment()
  for b = 0, 4 do
    for l = 1, 32 do
      local _, itemCount, _, _, _, _, link = GetContainerItemInfo(b, l)
      if link and (link:find(L.items.water_name) or link:find(L.items.food_name)) then
        if itemCount < 20 then
          L.F.delete_item_at(b, l)
        end
      end
    end
  end
end


local function do_real_cleanup()
  del_fragment()
  delete_groups()
end


local function do_clean_all()
  for b = 0, 4 do
    for l = 1, 32 do
      local _, _, _, _, _, _, link = GetContainerItemInfo(b, l)
      if link and (link:find(L.items.water_name) or link:find(L.items.food_name)) then
          L.F.delete_item_at(b, l)
      end
    end
  end
end


function SlashCmdList.ATF_CLEAN(msg)
  local free_slots = L.F.get_free_slots()
  if free_slots == 0 or msg == "force" then
    do_real_cleanup()
  elseif msg == "clean all" then
    do_clean_all()
  end
end


function SlashCmdList.ATF_SWITCH(msg)
  if msg == "on" then
    L.atfr_run = true
    SetBindingClick(atf_key, "ATFButton")
    SetBindingClick(atfr_key, "ATFRButton")
  elseif msg == "off" then
    if L.atfr_run then
      SendChatMessage("自动模式已关闭，人工介入")
    end
    L.atfr_run = false
  elseif msg == "maintain" then
    L.atfr_run = "maintain"
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
