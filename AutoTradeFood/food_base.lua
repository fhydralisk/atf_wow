---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hydra.
--- DateTime: 2020-01-10 22:42
---

local addonName, L = ...

local tclass_food = {
    ["战士"]={0, 6},
    ["法师"]={4, 0},
    ["猎人"]={4, 2},
    ["圣骑士"]={4, 2},
    ["潜行者"]={0, 6},
    ["牧师"]={4, 2},
    ["德鲁伊"]={3, 3},
    ["术士"]={3, 3}
}


function L.F.get_food_name_level()
  local food

  if ATFClientSettings.bread_55 then
    food = {name="魔法肉桂面包", level=55}
  else
    food = L.items.food
  end

  return {
    water=L.items.water,
    food=food,
  }
end


function L.F.get_feed_count(tclass, npc_name)
    local w, f
    if PlayerDefinedScale[npc_name] then
        w = PlayerDefinedScale[npc_name]["water"]
        f = PlayerDefinedScale[npc_name]["food"]
    else
        w = tclass_food[tclass][1]
        f = tclass_food[tclass][2]
    end
    return w, f
end


function L.F.can_feed_target(tlevel, tclass, npc_name)
    local info = L.F.get_food_name_level()
    local w, b = L.F.get_feed_count(tclass, npc_name)
    if w > 0 and info.water.level > tlevel then
        return false
    end
    if b > 0 and info.food.level > tlevel then
        return false
    end
    return true
end


local hans_num_map = {
  {"一", "少"},
  {"二", "两"},
  {"三"},
  {"四"},
  {"五", "多"},
  {"六"},
  {"七"},
  {"八"},
  {"九"},
  [0] = {"无", "不"},
}


local function wf_preprocess(msg)
  for num, hans in ipairs(hans_num_map) do
    for _, han in ipairs(hans) do
      msg = string.gsub(msg, han, num)
    end
  end
  return " "..msg.." "
end


local function wf_parser1(msg)
  local water_pattern = "[^%d]*(%d)[^%d]*水"
  local food_pattern = "[^%d]*(%d)[^%d]*面包"
  local matched = 0
  local w_s = string.match(msg, water_pattern)
  if not(w_s == nil) then matched = matched + 1 else w_s = 0 end
  local f_s = string.match(msg, food_pattern)
  if not(f_s == nil) then matched = matched + 1 else f_s = 0 end
  return tonumber(w_s), tonumber(f_s), matched
end


local function wf_parser2(msg)
  local water_pattern = "水[^%d]*(%d)[^%d]*"
  local food_pattern = "面包[^%d]*(%d)[^%d]"
  local matched = 0
  local w_s = string.match(msg, water_pattern)
  if not (w_s == nil) then matched = matched + 1 else w_s = 0 end
  local f_s = string.match(msg, food_pattern)
  if not (f_s == nil) then matched = matched + 1 else f_s = 0 end
  return tonumber(w_s), tonumber(f_s), matched
end


local function do_set_scale(water, food, author)
  PlayerDefinedScale[author] = {
    ["water"] = water,
    ["food"] = food
  }
  if L.F.get_busy_state() then
    L.F.whisper_or_say(
            string.format("【用餐高峰、数量减半！】配比成功，您在交易{player}时，非高峰时将获得%d组水，%d组面包（如果库存充足）。", water, food),
            author
    )
  else
    L.F.whisper_or_say(
            string.format("配比成功，您在交易{player}时，将获得%d组水，%d组面包（如果库存充足）。" ..
                    "如果和预期的不同，请按如下例子进行定制：“4组水，2组面包”。", water, food),
            author
    )
  end

end


function L.F.may_set_scale(msg, author)
  msg = wf_preprocess(msg)
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
        L.F.whisper_or_say("如需【25-54】小号食物，请M{player}【"
                ..L.cmds.low_level_cmd.."】进行预约。查看预约流程，请M{player}【"
                ..L.cmds.low_level_help_cmd.."】", author)
      else
        L.F.whisper_or_say("定制面包和水的数量，请确保水和面包加和不要大于6哦，不然怎么交易给您？", author)
      end
    else
      do_set_scale(water, food, author)
    end
    return true
  end

  return false
end


function L.F.check_food_trade_target_items(trade)
  local npc_name = trade.npc_name
  local items = trade.items.target.items
  local cnt = trade.items.target.count
  local food_info = L.F.get_food_name_level()
  if cnt == 0 then
    return true
  else
    if items[L.items.stone_name] then
      L.F.whisper_or_say(
              npc_name.."，请首先M{player}需要去的城市名称，例如“达纳苏斯”，再交易{player}【传送门符文】！"..
                      "如果您已经M过{player}，可能已经过期，请重试，谢谢！", npc_name
      )
    elseif items[food_info.water.name] or items[food_info.food.name] then
      L.F.whisper_or_say(
              npc_name.."，如希望为{player}补货，请M{player}【"..L.cmds.refill_cmd.."】。如果您觉得水或面包多余，请在交易{player}之前M{player}配比情况，例如“{player}要3组水，1组面包”，然后再进行交易。",
              npc_name
      )

    elseif items["Gold"] then
      L.F.whisper_or_say(npc_name.."，餐饮完全免费，请勿交易{player}任何金币，谢谢您的鼓励！", npc_name)
    else
      L.F.whisper_or_say(npc_name.."，背包有限，请勿交易{player}任何物品，感谢支持！", npc_name)
    end
    return false
  end
end
