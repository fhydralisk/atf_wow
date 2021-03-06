---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hydra.
--- DateTime: 2020-01-05 13:44
---

local addonName, L = ...

local check_buff = L.F.check_buff
local interact_key = L.hotkeys.interact_key
local dancing_counter = 0
local is_dancing = false
local dancing_time = 0

local mw_button = L.F.create_macro_button("MWButton", "")

local tclass_food = {
  ["战士"]={0, 6},
  ["法师"]={2, 0},
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
  ["猎人"]=55,
  ["圣骑士"]=55,
  ["潜行者"]=45,
  ["牧师"]=55,
  ["德鲁伊"]=55,
  ["术士"]=55
}

SLASH_ATF_IDLE1 = "/atfidle"


local trade_count_words = {
  [2]="听说胃口好的人身体都好！",
  [3]="继续努力……我的背包很大很大！",
  [4]="您真的确定不会浪费这些。。魔法嘛？",
  [5]="感觉身体被掏空，给跪给跪。。。",
  [6]="呃……你会收到……我的律师函的",
  [7]="监狱的生活给我上了一堂很重要的课，如果算上要把肥皂捏紧的话那就是两堂，是的！生存第一！",
}

L.food = {}
L.food.tclass_food = tclass_food
L.food.tclass_level = tclass_level

local last_trade_player = ""
local last_fail_player_is_trade_player = true
local last_trade_player_count = 0
local last_trade_success_ts = 0

local items_usable = {}


local function set_last_trade_player(pname)
  last_fail_player_is_trade_player = true
  last_trade_success_ts = GetTime()
  if last_trade_player == pname then
    last_trade_player_count = last_trade_player_count + 1
  else
    last_trade_player_count = 0
    last_trade_player = pname
  end
  return last_trade_player_count
end


function L.F.register_item_to_use(name, condition)
  ---
  --- item: a dict of item information
  ---      key: name, value: (string) item name;
  ---      key: condition, value: (function) condition of item to use;
  ---

  if name and condition then
    items_usable[name]=condition
  end
end


L.F.register_item_to_use("博学坠饰", function()
  return UnitPower("player") >= 3000
end)


L.F.register_item_to_use("思维加速宝石", function()
  return UnitPower("player") >= 5000
end)


L.F.register_item_to_use("洞察法袍", function()
  return true
end)


L.F.register_item_to_use("大法师之袍", function()
  return true
end)


local function use_enforce_item()
  for t = 1, 18 do
    local itemLink = GetInventoryItemLink("player", t)
    for name, condition in pairs(items_usable) do
      if itemLink and itemLink:find(name) then
        local cd = GetInventoryItemCooldown("player", t)
        if cd == 0 and condition() then
          return "/use "..name.."\n"
        end
      end
    end

  end
  return ""
end


local function should_restrict(class, level, name)
  return class == "法师" and level == 60 and L.admin_names[name] == nil
end

function L.F.bind_make_food_or_water()
  if L.F.target_level_to_acquire() then
    L.F.bind_acquire_target_level()
  elseif check_buff("喝水", 0) then
    dancing_counter = 0
    SetBinding(interact_key, "JUMP")
  elseif L.F.should_cook_low_level_food() then
    dancing_counter = 0
    L.F.bind_low_level_cook()
  else
    SetBindingClick(interact_key, "MWButton")
    if L.F.get_free_slots() == 0 then
      if ATFClientSettings.idle_dance then
        mw_button:SetAttribute("macrotext", "/atfidle")
      else
        mw_button:SetAttribute("macrotext", "/cast 魔爆术")
      end
    else
      dancing_counter = 0
      local w = L.F.get_water_count(1)
      local b = L.F.get_bread_count(1)
      local may_use_item = use_enforce_item()
      if w * 0.8 > b then
        mw_button:SetAttribute("macrotext", may_use_item .."/cast 造食术")
      else
        mw_button:SetAttribute("macrotext", may_use_item .."/cast 造水术")
      end
    end
  end
end


function SlashCmdList.ATF_IDLE()
  if dancing_counter >= 4 and is_dancing == false then
    is_dancing = true
    DoEmote("dance", "player")
    dancing_time = GetTime()
  elseif dancing_counter < 4 then
    print(dancing_counter, is_dancing)

    is_dancing = false
    dancing_counter = dancing_counter + 1
    print(dancing_counter, is_dancing)
  end
end


local function check_stock(npc_name)
  if L.F.get_water_count() >= 4 and L.F.get_bread_count() >= 4 then
    return true
  else
    if npc_name == last_trade_player then
      last_fail_player_is_trade_player = true
    else
      last_fail_player_is_trade_player = false
    end
    return false
  end
end


local function check_level(tlevel, tclass, npc_name)
  if L.debug.enabled and L.debug.white_list[npc_name] then
    return true
  end
  return L.F.can_feed_target(tlevel, tclass, npc_name)
end


local function should_give_food(trade)
  local tclass = trade.npc_class
  local tlevel = trade.npc_level
  local npc_name = trade.npc_name
  local guild = GetGuildInfo("npc")
  local guild_player = GetGuildInfo("player")
  if ATFClientSettings.is_internal and not(guild == guild_player) then
    local myname = UnitName("player")
    L.F.whisper_or_say(myname.."为供货员，仅用于为楼下供货以及为【"..guild_player.."】工会内部成员提供食物，烦请您移步楼下交易前台。", npc_name)
    return true, true
  end

  if should_restrict(trade.npc_class, trade.npc_level, trade.npc_name) and L.F.get_water_count() < 25 then
    L.F.whisper_or_say("60级法师仅能在米豪货存充足时取水。如希望为我补充货存，请M我【"..L.cmds.refill_cmd.."】。", npc_name)
    return true, true
  end

  if L.F.get_busy_state() then
    if npc_name == last_trade_player and not(last_fail_player_is_trade_player) and GetTime() - last_trade_success_ts < 120 then
      L.F.whisper_or_say("当前为用餐高峰时间，请勿连续取用食物，给其他朋友些机会哦，谢谢支持！", npc_name)
      return true, true
    end
  end
  if not check_stock() then
    local water = L.F.get_water_count()
    local bread = L.F.get_bread_count()
    L.F.whisper_or_say(
            "库存不足，请稍等一小会儿...当前存货：【大水】"..water.."组，【面包】"..bread.."组", npc_name
    )
    return true, true
  elseif check_level(tlevel, tclass, npc_name) then
    return true, false
  end
  return false, false
end


local function feed_foods(trade)
  local w, f = L.F.get_feed_count(trade.npc_class, trade.npc_name)
  local scale = 1
  if L.F.get_busy_state() then
    scale = 0.5
  end
  if should_restrict(trade.npc_class, trade.npc_level, trade.npc_name) then
    scale = scale * 0.5
  end
  w = math.ceil(w * scale)
  f = math.ceil(f * scale)
  local info = L.F.get_food_name_level()
  L.F.feed(info.water.name, w, 20)
  L.F.feed(info.food.name, f, 20)
end


local function statistics_food(trade)
  local name = trade.npc_name
  local class = trade.npc_class
  local key_trade_ind = "trade.food.ind."..date("%x").."."..name
  local key_trade_class = "trade.food.class."..date("%x").."."..class
  local key_trade_all = "trade.food.all."..date("%x")
  local key_trade_count = "trade.food.count."..date("%x")
  L.F.merge_statistics_plus_table(key_trade_ind, trade.items.player.items)
  L.F.merge_statistics_plus_table(key_trade_class, trade.items.player.items)
  L.F.merge_statistics_plus_table(key_trade_all, trade.items.player.items)
  L.F.merge_statistics_plus_int(key_trade_count, 1)
end


local buff_asked = {}


local function ask_buff(name, class)
  if not(buff_asked[name] and GetTime() - buff_asked[name] < 240) then
    if class == "牧师" then
      L.F.whisper_or_say(name.."，精神可以提高我的制作效率，如果您有该技能，麻烦给一手哦！", name)
    elseif class == "德鲁伊" then
      L.F.whisper_or_say(name.."，激活、爪子可以提高我的制作效率，如果您有该技能，麻烦给一手哦！", name)
    elseif class == "圣骑士" then
      L.F.whisper_or_say(name.."，王者、智慧可以提高我的制作效率，如果您有该技能，麻烦给一手哦！", name)
    else
      return
    end
    buff_asked[name] = GetTime()
  end
end


local function trade_completed(trade)
  local class = trade.npc_class
  local level = trade.npc_level
  local name = trade.npc_name

  set_last_trade_player(name)

  ask_buff(name, class)
  if should_restrict(class, level, name) then
    L.F.whisper_or_say("法爷需自强，不当伸手党，嘿嘿嘿...", name)
  end
  local words = trade_count_words[last_trade_player_count]
  if words then
    L.F.whisper_or_say(name.."，"..words, name)
  end

  statistics_food(trade)
end


L.trade_hooks.trade_food = {
  ["should_hook"] = should_give_food,
  ["feed_items"] = feed_foods,
  ["on_trade_complete"] = trade_completed,
  ["on_trade_cancel"] = nil,
  ["on_trade_error"] = nil,
  ["should_accept"] = L.F.check_food_trade_target_items,
  ["check_target_item"] = nil,
}
