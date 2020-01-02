local addonName, addon = ...

local frame = CreateFrame("FRAME", "ATFFrame")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("TRADE_ACCEPT_UPDATE")
frame:RegisterEvent("PARTY_INVITE_REQUEST")


local water_name = "魔法晶水"
local food_name = "魔法甜面包"
local retrieve_position = "pos"
local scale_cmd = "查看比例"
local help_cmd = "帮助"
local invite_cmd = "水水水"
local gate_help_cmd = "传送门"
local last_trade_player = ""
local last_trade_player_count = 0
local atfr_run = false
local min_mana = 780
local state = 1
-- states: 1 making, 2 watering? 3 gating, 4 buff
local interact_key = "CTRL-I"
local atf_key = "CTRL-Y"
local atfr_key = "ALT-CTRL-Y"
local gating_context = {["spell"]="", ["requester"]="", ["cooldown_ts"]=0, ["city"]="", ["invited"]=false}
local gating_contexts = {}
local gate_request_timeout = 90
local ad_msg = {
  "【米豪公益】需要55级水、45级面包，请直接交易“米豪”货仓！免费提供！",
  "【米豪公益】需要打开去主城的捷径，请与我私聊“传送门”！，牢记程序，免一切手续费！",
  "【米豪公益】如果亲觉得米豪公益好用，请奔走相告，米豪力争24小时为各位提供免费食水传送服务！",
  "【米豪公益】TIPs: 如遇高峰时期，请各位勤拿少取，需要多少水，多少面包，可以私聊我进行定制！例如“我要1水2面包”。路过的各位，请给点BUFF给我加速，例如激活、精神、王者、智慧",
  "【米豪公益】TIPs: 米豪开门只收【传送门符文】不收金币！！！详情M我【传送门】",
  "【米豪公益】TIPs: 如果米豪开始奥暴，并非米豪在划水，而是米豪食水充足无比！欢迎各种交易！完全免费！",
  "【米豪公益】TIPs: 如果您和米豪不在一个位面，请M我唯一有效咒语【"..invite_cmd.."】进组！",
  "【米豪公益】TIPs: 米豪平时无人值守，需要食物的请直接交易！需要传送请M我【传送门】，并认真按照开门程序操作，简单便捷！",
  "【米豪公益】米豪每天会升级维护，维护期间不能提供服务，敬请谅解！有关米豪的使用帮助，请M我【"..help_cmd.."】！",
}


local tclass_food = {
  ["战士"]={0, 6},
  ["法师"]={2, 2},
  ["猎人"]={4, 2},
  ["圣骑士"]={4, 2},
  ["潜行者"]={0, 6},
  ["牧师"]={4, 2},
  ["德鲁伊"]={3, 3},
  ["术士"]={3, 3}
}

local tclass_level = {
  ["战士"]=45,
  ["法师"]=55,
  ["猎人"]=50,
  ["圣骑士"]=55,
  ["潜行者"]=45,
  ["牧师"]=55,
  ["德鲁伊"]=55,
  ["术士"]=55
}

local trade_count_words = {
  [2]="听说胃口好的人身体都好！",
  [3]="继续努力……我的背包很大很大！",
  [4]="您真的确定不会浪费这些。。魔法嘛？",
  [5]="感觉身体被掏空，给跪给跪。。。"
}

SLASH_ATFCmd1 = "/atf"
SLASH_ATF_REPORT1 = "/atfr"
SLASH_ATF_CLEAN1= "/atfc"
SLASH_ATF_SWITCH1 = "/atfs"
SLASH_ATF_DEBUG1 = "/atfd"
SLASH_ATG_WHITELIST1 = "/atgwl"

local function create_macro_button(button_name, macro_text)
  local cframe = CreateFrame("Button", button_name, UIParent, "SecureActionButtonTemplate");
--  cframe:RegisterForClicks("AnyUp");
  cframe:SetAttribute("type", "macro");
  cframe:SetAttribute("macrotext", macro_text);
  return cframe
end

local AtfFrame = create_macro_button("ATFButton", "/atf")
local AtfReportFrame = create_macro_button("ATFRButton", "/atfr")

local function get_water_count(identity)
  if identity then
    return GetItemCount(water_name)
  else
    return math.modf(GetItemCount(water_name)/20)
  end
end

local function get_bread_count(identity)
  if identity then
    return GetItemCount(food_name)
  else
    return math.modf(GetItemCount(food_name)/20)
  end
end

local function get_free_slots()
  local free_slots = 0
  for b = 0, 4 do
    free_slots = free_slots + GetContainerNumFreeSlots(b)
  end
  return free_slots
end
local function delete_item_at(b, s)
  PickupContainerItem(b, s)
  DeleteCursorItem()
end

local function search_str_contains(s, tbl)
  for _, ss in pairs(tbl) do
    if s and string.lower(s):find(ss) then
      return true
    end
  end
  return false
end

local function my_position()
  local mapID = C_Map.GetBestMapForUnit("player")
  local tempTable = C_Map.GetPlayerMapPosition(mapID, "player")
  local x, y = tempTable.x, tempTable.y
  return string.format("(%.1f,%.1f)", x * 100, y * 100)
end

local function say_pos(to_player)
  SendChatMessage(
    "我目前位于坐标"..my_position()..", 如不便查看，可M我“"..invite_cmd.."”进组", "WHISPER", "Common", to_player
  )
end

local function say_help(to_player)
  SendChatMessage(
    "我会自动根据您的职业分配食物与水的比例。", "WHISPER", "Common", to_player
  )
  SendChatMessage(
    "请勿交易金币和物品，否则可能无法正常交易。如有有建议或希望捐赠，请使用魔兽邮箱，谢谢支持！", "WHISPER", "Common", to_player
  )
  SendChatMessage(
    "小号暂不提供食物！开门服务试运行！如果不小心黑了您的石头，请给我发邮件", "WHISPER", "Common", to_player
  )
  SendChatMessage(
    "=========我目前支持如下命令：", "WHISPER", "Common", to_player
  )
  SendChatMessage(
    string.format("1.【%s】打印本命令列表", help_cmd), "WHISPER", "Common", to_player
  )
  SendChatMessage(
    string.format("2.【%s】获取我的坐标", retrieve_position), "WHISPER", "Common", to_player
  )
  SendChatMessage(
    string.format("3.【%s】向您发起组队邀请，以便发送位置、跨位面", invite_cmd), "WHISPER", "Common", to_player
  )
  SendChatMessage(
    string.format("4.【%s】查看不同职业水和面包比例", scale_cmd), "WHISPER", "Common", to_player
  )
  SendChatMessage(
    "5.【自定义分配】为您定制水和面包比例，例如您可说“4水2面包”",
    "WHISPER", "Common", to_player
  )
  SendChatMessage(
    string.format("6.【%s】查看开门步骤", gate_help_cmd), "WHISPER", "Common", to_player
  )

end

local function say_gate_help(to_player)
  SendChatMessage("4步便捷开门！请花1分钟仔细阅读，简单高效无需求人开门即可达成！", "WHISPER", "Common", to_player)
  SendChatMessage("1. 在材料NPC处购买传【送门符文】1枚，也可以AH购买，我原价放了许多。", "WHISPER", "Common", to_player)
--  SendChatMessage("**！！！请注意！！！，原价是20银！！！认准我的名字【米豪】或【米豪的维修师】**", "WHISPER", "Common", to_player)
  SendChatMessage("2. 【先】M我主城的名字，“暴风城”、“铁炉堡”或“达纳苏斯”", "WHISPER", "Common", to_player)
  SendChatMessage("3. 【然后】将石头主动交易给我：【传送门符文】【1枚】", "WHISPER", "Common", to_player)
  SendChatMessage("4. 【交易成功后】，我将【自动】向您发起组队邀请，并在短时间内释放传送门法术，请确保您已退组哈", "WHISPER", "Common", to_player)
  SendChatMessage("请您使用传送门后自行离队，祝您旅途愉快！", "WHISPER", "Common", to_player)
end

local function say_scale(to_player)
  SendChatMessage("食水分配比例如下：", "WHISPER", "Common", to_player)
  for tclass, sc in pairs(tclass_food) do
    SendChatMessage(string.format("%s: 水%d 面包%d", tclass, sc[1], sc[2]), "WHISPER", "Common", to_player)
  end
end

local function wf_parser1(msg)
  local water_pattern = "(%d+)[^%d]*水"
  local food_pattern = "(%d+)[^%d]*面包"
  local matched = 0
  local w_s = string.match(msg, water_pattern)
  if not(w_s == nil) then matched = matched + 1 else w_s = 0 end
  local f_s = string.match(msg, food_pattern)
  if not(f_s == nil) then matched = matched + 1 else f_s = 0 end
  return tonumber(w_s), tonumber(f_s), matched
end

local function wf_parser2(msg)
  local water_pattern = "水[^%d]*(%d+)"
  local food_pattern = "面包[^%d]*(%d+)"
  local matched = 0
  local w_s = string.match(msg, water_pattern)
  if not (w_s == nil) then matched = matched + 1 else w_s = 0 end
  local f_s = string.match(msg, food_pattern)
  if not (f_s == nil) then matched = matched + 1 else f_s = 0 end
  return tonumber(w_s), tonumber(f_s), matched
end

local function do_set_scale(water, food, author)
  print("enter")
  PlayerDefinedScale[author] = {
    ["water"] = water,
    ["food"] = food
  }
  print("ok")
  SendChatMessage(
    string.format("配比成功，您在交易我时，将获得%d组水，%d组面包（如果库存充足）。"..
        "如果和预期的不同，请按如下例子进行定制：“4组水，2组面包”。", water, food),
    "WHISPER", "Common", author
  )
end

local function may_set_scale(msg, author)
  local ws1, fs1, matched1 = wf_parser1(msg)
  local ws2, fs2, matched2 = wf_parser2(msg)
  local water, food
  if matched1 > matched2 then
    water = ws1
    food = fs1
  else
    water = ws2
    food = fs2
  end

  if water + food > 0 then
    if water + food > 6 then
      if water == 45 or water == 35 then
        SendChatMessage("暂时无法提供小号食品，请您求助其他法师，抱歉", "WHISPER", "Common", author)
      elseif water == 20 then
        -- 自动交易提醒，不予回复
        return true
      else
        SendChatMessage("定制面包和水的数量，请确保水和面包加和不要大于6哦，不然我怎么交易给您？", "WHISPER", "Common", author)
      end
    else
      do_set_scale(water, food, author)
    end
    return true
  end

  return false
end

local function parse_and_set_city(msg)
  local spell, city
  if msg:find("暴风城") then
    spell = "传送门：暴风城"
    city = "暴风城"
  elseif msg:find("达纳苏斯") then
    spell = "传送门：达纳苏斯"
    city = "达纳苏斯"
  elseif msg:find("铁炉堡") then
    spell = "传送门：铁炉堡"
    city = "铁炉堡"
  else
    print("这里不应该到达")
    return nil, nil
  end
  return spell, city
end

local function invalidate_requests(winner, city)
  for player, _ in pairs(gating_contexts) do
    SendChatMessage(winner..
            "抢先一步交易了我【传送门符文】，您的请求已取消。我将为其施放通往"..city.."的传送门，若果顺路，请M我【水水水】进组",
            "WHISPER", "Common", player
    )
  end
  gating_contexts = {}
end

local function transit_to_gate_state(player)
  gating_contexts[player] = nil
  invalidate_requests(player, gating_context["city"])
  state = 3
  gating_context["cooldown_ts"] = GetTime() + 60
  gating_context["invited"] = false
  InviteUnit(player)
end

local function gate_request(player, msg)
  if GetTime() < gating_context["cooldown_ts"] then
    local cooldown_last = math.modf( gating_context["cooldown_ts"] - GetTime())
    SendChatMessage("传送门法术正在冷却，请"..cooldown_last.."秒后重新请求", "WHISPER", "Common", player)
    return
  end
  local spell, city = parse_and_set_city(msg)
  print(spell, city)
  if not spell then
    return
  end
  if GetNumGroupMembers() >= 5 then
    LeaveParty()
  end
  if GateWhiteList[player] then
    if GetItemCount("传送门符文") > 0 then
      gating_context["spell"] = spell
      gating_context["city"] = city
      gating_context["requester"] = player
      transit_to_gate_state(player)
      SendChatMessage("贵宾驾到，马上起航！", "WHISPER", "Common", player)
      return
    else
      SendChatMessage("贵宾您好，我已无油，请交易我施法材料【传送门符文】【1枚】来为我补充油料", "WHISPER", "Common", player)
    end
  end

  gating_contexts[player] = {
    ["request_ts"]=GetTime(),
    ["city"]=city,
    ["spell"]=spell,
  }
  SendChatMessage(
    city.."传送门指定成功，请于"..gate_request_timeout..
        "秒内交易我【1】枚【传送门符文】。请于施法材料商或AH原价从我手中购买该材料。请注意，原价为20Y，如果没有这个价格的，请寻找材料NPC！",
    "WHISPER", "Common", player
  )
end

local function eventHandler(self, event, msg, author, ...)
  if event == "CHAT_MSG_WHISPER" then
    author = string.match(author, "([^-]+)")
    if atfr_run == true then
      if string.lower(msg) == help_cmd or msg == "1" or string.lower(msg) == "help" then
        say_help(author)
      elseif string.lower(msg) == retrieve_position or msg == "2" then
        say_pos(author)
      elseif msg == invite_cmd then
        InviteUnit(author)
      elseif msg == "3" then
        SendChatMessage("请M我【水水水】进组，而不是M我3，zu，组，谢谢", "WHISPER", "Common", author)
      elseif msg == scale_cmd or msg == "4" then
        say_scale(author)
      elseif may_set_scale(msg, author) then
        -- do nothing
      elseif msg == "5" then
        SendChatMessage(
          "请这样M我来设置比例： 【2组水，3组面包】，或者【法师，可不可以来水3组，面包2组？】或者，【2水】，等等，然后交易我。",
          "WHISPER", "Common", author)
      elseif search_str_contains(msg, {"暴风城", "铁炉堡", "达纳苏斯"}) then
        gate_request(author, msg)
      elseif search_str_contains(msg, {"门", "们", "暴风", "铁", "精灵", gate_help_cmd}) or msg == "6" then
        say_gate_help(author)
      elseif search_str_contains(msg, {"脚本", "外挂", "机器", "自动", "宏"}) then
        SendChatMessage("是的，我是纯公益机器人，请亲手下留情，爱你哦！", "WHISPER", "Common", author)
      elseif search_str_contains(msg, {"谢", "蟹", "xie", "3q"}) then
        SendChatMessage("小事不言谢，欢迎随时回来薅羊毛！", "WHISPER", "Common", author)
      else
        if not(author == UnitName("player")) then
          SendChatMessage(
            "【【【【渴了？饿了？经济舱？找米豪！请直接交易我！坐标"..my_position().."，需要帮助，请M我“"..help_cmd.."”】】】",
            "WHISPER", "Common", author
          )
        end
      end
    elseif atfr_run == "maintain" then
      SendChatMessage("米豪正在停机维护，暂时无法为您提供服务……", "WHISPER", "Common", author)
    end
  elseif event == "ADDON_LOADED" and msg == "AutoTradeFood" then
    if PlayerDefinedScale == nil then
      PlayerDefinedScale = {}
    end
    if GateWhiteList == nil then
      GateWhiteList = {}
    end
  elseif event == "PARTY_INVITE_REQUEST" then
    if atfr_run then
      DeclineGroup()
      StaticPopup_Hide("PARTY_INVITE")
      SendChatMessage("请勿邀请我进组，您可以M我【"..invite_cmd.."】进组，谢谢！", "WHISPER", "Common", msg)
    end
  end
end

frame:SetScript("OnEvent", eventHandler)

local function feed(itemname, icount)
  local x = 0
  for b = 0, 4 do
    for s =1, 32 do
      local _, itemCount, _, _, _, _, link = GetContainerItemInfo(b, s)
      if link and link:find(itemname) and itemCount==20 and x < icount then
        UseContainerItem(b, s)
        x = x + 1
      end
    end
  end
end

local function set_last_trade_player(pname)
  if last_trade_player == pname then
    last_trade_player_count = last_trade_player_count + 1
  else
    last_trade_player_count = 0
    last_trade_player = pname
  end
  return last_trade_player_count
end

local function do_trade_feed(tclass, npc_name)
  local w, f
  if PlayerDefinedScale[npc_name] then
    w = PlayerDefinedScale[npc_name]["water"]
    f = PlayerDefinedScale[npc_name]["food"]
  else
    w = tclass_food[tclass][1]
    f = tclass_food[tclass][2]
  end
  feed(water_name, w)
  feed(food_name, f)
end

local function pre_check_startup(npc_name)
  if get_water_count() >= 4 and get_bread_count() >= 4 then
    return true
  else
    local water = get_water_count()
    local bread = get_bread_count()
    SendChatMessage("库存不足，请稍等一小会儿...当前存货：【大水】"..water.."组，【面包】"..bread.."组", "WHISPER", "Common", npc_name)
    return false
  end
end

local function pre_check_role(tlevel, tclass, npc_name)
  if tlevel < tclass_level[tclass] then
    SendChatMessage("暂时无法对小号提供餐饮服务，敬请期待", "WHISPER", "Common", npc_name)
    return false
  end
  return true
end

local function check_and_do_feed()
  local tclass = UnitClass("NPC")
  local tlevel = UnitLevel("NPC")
  local npc_name = UnitName("NPC")

  if pre_check_startup(npc_name) and pre_check_role(tlevel, tclass, npc_name) then
    do_trade_feed(tclass, npc_name)
  else
    CloseTrade()
  end
end

local function maybe_say_some()
  local pname = UnitName("NPC")
  local pclass = UnitClass("NPC")
  if search_str_contains(pclass, {"牧师", "圣骑士", "德鲁伊"}) then
    SendChatMessage(pname..",".."智慧祝福、王者祝福、爪子、精神可以提高我的制作效率，如果您方便，就强化我一下，谢谢！", "say", "Common")
  elseif pclass == "法师" then
    SendChatMessage("法爷需自强，不当伸手党，嘿嘿嘿...", "say", "Common")
  end
  local words = trade_count_words[set_last_trade_player(pname)]
  if words then
    SendChatMessage(pname..","..words, "say", "Common")
  end
end

local function post_check_oppside_trade(npc_name, allow_trade)
  local accepted_item
  for t_index = 1, 6 do
    local name, _, cnt = GetTradeTargetItemInfo(t_index)
    if name and not(allow_trade and name==allow_trade["item"] and cnt==allow_trade["cnt"]) then
      if allow_trade then
        SendChatMessage(npc_name.."，背包有限，请勿交易我任何物品，感谢支持！"
                ..allow_trade["item"].."仅需交易"..allow_trade["cnt"].."个", "say", "Common")
      else
        SendChatMessage(npc_name.."，背包有限，请勿交易我任何物品，感谢支持！", "say", "Common")
      end
      return false
    end
    if name then
      accepted_item = name
    end
  end

  if GetTargetTradeMoney() > 0 then
    SendChatMessage(npc_name.."，餐饮完全免费，请勿交易我任何金币，谢谢您的鼓励！", "say", "Common")
    return false
  end
  return accepted_item or true
end

local function do_accept_trade(dont_say)
  if TradeHighlightRecipient:IsShown() then
    AcceptTrade()
    if not dont_say then maybe_say_some() end
    return true
  end
  return false
end

local function check_and_accept_trade()
  local npc_name = UnitName("NPC")
  if post_check_oppside_trade(npc_name) then
    do_accept_trade()
  else
    CloseTrade()
  end
end

local function check_buff(buff_name, remain)
  local i = 1;
  if remain == nil then
    remain = 0
  end
  while true do
    local buff, _, _,   _, dur, ts = UnitBuff("player", i);
    if buff == nil then
      return false
    elseif buff == buff_name then
      local remaining = ts - GetTime()
      return remaining > remain
    end
    i = i + 1;
  end;
end

local function bind_make_food_or_water()
  if check_buff("喝水", 0) then
    SetBinding(interact_key, "JUMP")
  elseif get_free_slots() == 0 then
    SetBindingSpell(interact_key, "魔爆术")
  else
    local w = get_water_count(1)
    local b = get_bread_count(1)
    if w * 0.8 > b then
      SetBindingSpell(interact_key, "造食术")
    else
      SetBindingSpell(interact_key, "造水术")
    end
  end
end


local function bind_drink()
  if check_buff("喝水", 3) or check_buff("唤醒", 0.5) then
    SetBinding(interact_key, "")
  else
    local weakup_cooldown = GetSpellCooldown("唤醒", "BOOKTYPE_SPELL")
    if weakup_cooldown > 0 then
      SetBindingItem(interact_key, "魔法晶水")
    else
      SetBindingSpell(interact_key, "唤醒")
    end
  end
end

local function drive_gate()
  for player, gc in pairs(gating_contexts) do
    if GetTime() - gc["request_ts"] > gate_request_timeout then
      SendChatMessage("传送门未能成功开启，未收到符文石", "WHISPER", "Common", player)
      gating_contexts[player] = nil
    end
  end
  if GetTime() < gating_context["cooldown_ts"] and gating_context['invited'] == false then
    if UnitInParty(gating_context[gating_context["requester"]]) then
      gating_context["invited"] = true
    else
      InviteUnit(gating_context["requester"])
    end
  end
end

local function bind_gate()
  if UnitPower("player") < min_mana then
    SetBindingItem(interact_key, "魔法晶水")
  else
    SetBindingSpell(interact_key, gating_context["spell"])
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
  if state == 1 then
    bind_make_food_or_water()
  elseif state == 2 then
    bind_drink()
  elseif state == 3 then
    bind_gate()
  elseif state == 4 then
    bind_buff()
  end
end

local function trade_food()
  if TradeFrame.acceptState == 0 then
      local ils = GetTradePlayerItemLink(1)
      if ils == nil then
        check_and_do_feed()
      else
        check_and_accept_trade()
      end
    end
end

local function trade_stone(npc_name)
  local ils = GetTradePlayerItemLink(1)
  local post_check = post_check_oppside_trade(npc_name, {["item"]="传送门符文", ["cnt"]=1})
  if ils == nil then
    feed(food_name, 1)
  elseif post_check == "传送门符文" then
    if do_accept_trade(true) then
      local city = gating_contexts[npc_name]["city"]
      local spell = gating_contexts[npc_name]["spell"]
      SendChatMessage(
              "符文石交易成功，请接受组队邀请。稍等几秒将为您开门...若未邀请成功，请M我水水水进组", "WHISPER", "Common", npc_name)
      SendChatMessage(npc_name.."，"..city.."传送程序已载入，请坐稳扶好！想搭便车的朋友，M我【水水水】进组")
      gating_context["spell"] = spell
      gating_context["city"] = city
      gating_context["requester"] = npc_name
      transit_to_gate_state(npc_name)
    end
  elseif post_check == true then
    -- do nothing
  else
    CloseTrade()
  end
end

local function drive_state()
  if state == 1 then
    if UnitPower("player") < min_mana then
      state = 2
    elseif not ((check_buff("奥术智慧", 10) or check_buff("奥术光辉", 10)) and check_buff("魔甲术", 10)) then
      state = 4
    end
  elseif state == 2 then
    if UnitPower("player") == UnitPowerMax("player") then
      state = 1
    end
  elseif state == 3 then
    local cd_gate = GetSpellCooldown(gating_context["spell"])
    if cd_gate > 0 then
      gating_context['cooldown_ts'] = cd_gate + 60
      state = 1
    end
  elseif state == 4 then
    if (check_buff("奥术智慧", 100) or check_buff("奥术光辉", 100)) and check_buff("魔甲术", 100) then
      state = 2
    end
  end
end

function SlashCmdList.ATFCmd(msg)
  drive_state()
  drive_gate()
  auto_bind()
  if TradeFrame:IsShown() then
    local npc_name = UnitName("NPC")
    if gating_contexts[npc_name] then
      trade_stone(npc_name)
    else
      trade_food()
    end
  end
end

function SlashCmdList.ATF_REPORT(msg)
  local water = get_water_count()
  local bread = get_bread_count()
  SendChatMessage(date("%X").."存货：【大水】"..water.."组，【面包】"..bread.."组","say","Common")
  SendChatMessage(date("%X")..ad_msg[math.random(1, #ad_msg)], "say", "Common")
end

local function do_delete_groups(item_name, groups)
  local x = 0
  for b = 0, 4 do
    for l = 0, 32 do
      local itemLink = GetContainerItemLink(b, l)
      if itemLink and itemLink:find(item_name) and x < groups then
        x = x + 1
        delete_item_at(b, l)
      end
    end
  end
end

local function delete_groups()
  local water = GetItemCount(water_name)
  local food = GetItemCount(food_name)
  if water * 0.5 > food then
    local water_to_delete = math.modf((water * 0.5 - food) / 20)
    do_delete_groups(water_name, water_to_delete)
  elseif food > water * 0.9 then
    local food_to_delete = math.modf((food - water * 0.9) / 20)
    do_delete_groups(food_name, food_to_delete)
  end
end

local function del_fragment()
  for b = 0, 4 do
    for l = 1, 32 do
      local _, itemCount, _, _, _, _, link = GetContainerItemInfo(b, l)
      if link and (link:find(water_name) or link:find(food_name)) then
        if itemCount < 20 then
          delete_item_at(b, l)
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
      if link and (link:find(water_name) or link:find(food_name)) then
          delete_item_at(b, l)
      end
    end
  end
end

function SlashCmdList.ATF_CLEAN(msg)
  local free_slots = get_free_slots()
  if free_slots == 0 or msg == "force" then
    do_real_cleanup()
  elseif msg == "clean all" then
    do_clean_all()
  end
end

function SlashCmdList.ATF_SWITCH(msg)
  if msg == "on" then
    atfr_run = true
    SetBindingClick(atf_key, "ATFButton")
    SetBindingClick(atfr_key, "ATFRButton")
  elseif msg == "off" then
    SendChatMessage("自动模式已关闭，人工介入")
    atfr_run = false
  elseif msg == "maintain" then
    atfr_run = "maintain"
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
    print(state)
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
