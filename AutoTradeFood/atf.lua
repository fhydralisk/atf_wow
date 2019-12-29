local addonName, addon = ...

local frame = CreateFrame("FRAME", "ATFFrame")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("ADDON_LOADED")


local water_name = "魔法晶水"
local food_name = "魔法甜面包"
local retrieve_position = "pos"
local scale_cmd = "查看比例"
local help_cmd = "help"
local invite_cmd = "水水水"
local last_trade_player = ""
local last_trade_player_count = 0
local atfr_run = false


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
    "小号暂不提供食物，暂不提供开门服务！", "WHISPER", "Common", to_player
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
  local w_s = string.match(msg, water_pattern) or 0
  local f_s = string.match(msg, food_pattern) or 0
  return tonumber(w_s), tonumber(f_s)
end

local function wf_parser2(msg)
  local water_pattern = "水[^%d]*(%d+)"
  local food_pattern = "面包[^%d]*(%d+)"
  local w_s = string.match(msg, water_pattern) or 0
  local f_s = string.match(msg, food_pattern) or 0
  return tonumber(w_s), tonumber(f_s)
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
  local ws1, fs1 = wf_parser1(msg)
  local ws2, fs2 = wf_parser2(msg)
  local water, food
  if ws1 + fs1 > ws2 + fs2 then
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

local function eventHandler(self, event, msg, author, ...)
  if event == "CHAT_MSG_WHISPER" then
    author = string.match(author, "([^-]+)")
    if atfr_run then
      if string.lower(msg) == help_cmd then
        say_help(author)
      elseif string.lower(msg) == retrieve_position then
        say_pos(author)
      elseif msg == invite_cmd then
        InviteUnit(author)
      elseif msg == scale_cmd then
        say_scale(author)
      elseif may_set_scale(msg, author) then
        -- do nothing
      elseif search_str_contains(msg, {"门", "们", "暴风", "铁", "精灵"}) then
        SendChatMessage("魔法补给透支吾身，无力掌控其他奥术力量，请向其他奥术掌控者寻求帮助", "WHISPER", "Common", author)
      elseif search_str_contains(msg, {"脚本", "外挂", "机器", "自动"}) then
        SendChatMessage("是的，我是纯公益机器人，请亲手下留情，爱你哦！", "WHISPER", "Common", author)
      elseif search_str_contains(msg, {"谢", "蟹", "xie", "3q"}) then
        SendChatMessage("小事不言谢，欢迎随时回来薅羊毛！", "WHISPER", "Common", author)
      else
        if not(author == UnitName("player")) then
          SendChatMessage(
            "【【【【渴了饿了找米豪！请直接交易我！坐标"..my_position().."，需要帮助，请M我help】】】",
            "WHISPER", "Common", author
          )
        end
      end
    end
  elseif event == "ADDON_LOADED" and msg == "AutoTradeFood" then
    print(PlayerDefinedScale)
    if PlayerDefinedScale == nil then
      PlayerDefinedScale = {}
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
  if tclass == "法师" then
    SendChatMessage("法师交易我都是有思想的", "say", "Common")
  end
  feed(water_name, w)
  feed(food_name, f)
end

local function pre_check_startup(npc_name)
  if get_water_count() >= 4 and get_bread_count() >= 4 then
    return true
  else
    SendChatMessage(npc_name.."，我正在热身，兜兜里也很空荡，请稍等一小会儿...", "say", "Common")
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
  local words = trade_count_words[set_last_trade_player(pname)]
  if words then
    SendChatMessage(pname..","..words, "say", "Common")
  end
end

local function post_check_oppside_trade(npc_name)
  for t_index = 1, 6 do
    if GetTradeTargetItemLink(t_index) then
      SendChatMessage(npc_name.."，背包有限，请勿交易我任何物品，感谢支持", "say", "Common")
      return false
    end
  end

  if GetTargetTradeMoney() > 0 then
    SendChatMessage(npc_name.."，餐饮完全免费，请勿交易我任何金币，谢谢您的鼓励！", "say", "Common")
    return false
  end
  return true
end

local function check_and_accept_trade()
  local npc_name = UnitName("NPC")
  if post_check_oppside_trade(npc_name) then
    AcceptTrade()
    maybe_say_some()
  else
    CloseTrade()
  end
end

local function auto_bind_make()
  local w = get_water_count(1)
  local b = get_bread_count(1)
  if w * 0.8 > b then
    SetBindingSpell("CTRL-I", "造食术")
  else
    SetBindingSpell("CTRL-I", "造水术")
  end
end

function SlashCmdList.ATFCmd(msg)
  auto_bind_make()
  if TradeFrame:IsShown() then
    if TradeFrame.acceptState == 0 then
      local ils = GetTradePlayerItemLink(1)
      if ils == nil then
        check_and_do_feed()
      else
        check_and_accept_trade()
      end
    end 
  end
end

function SlashCmdList.ATF_REPORT(msg)
  local water = get_water_count()
  local bread = get_bread_count()
  SendChatMessage("存货：【大水】"..water.."组，【面包】"..bread.."组","say","Common")
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
  local free_slots = 0
  for b = 0, 4 do
    free_slots = free_slots + GetContainerNumFreeSlots(b)
  end
  if free_slots == 0 or msg == "force" then
    do_real_cleanup()
  elseif msg == "clean all" then
    do_clean_all()
  end
end

function SlashCmdList.ATF_SWITCH(msg)
  if msg == "on" then
    atfr_run = true
  else
    SendChatMessage("自动模式已关闭，人工介入")
    atfr_run = false
  end
end

function SlashCmdList.ATF_DEBUG(msg)
  if string.match(msg, "bind ([^%s]*) ([^%s]*)") then
    local bind, spell = string.match(msg, "bind ([^%s]*) ([^%s]*)")
    print(bind)
    print(spell)
    SetBinding(bind, "SPELL "..spell)
  end
end
