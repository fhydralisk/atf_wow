---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hydra.
--- DateTime: 2020-01-05 13:27
---

local addonName, L = ...

local ad_msg = {
  "【米豪公益】吃喝、传送门、重置、位面：M{player}【"..L.cmds.help_cmd.."】获取帮助。",
  --"【米豪公益】米豪自开工以来300余次升级，只为大家能够体会一丝温馨，如有意见，请高抬贵手邮件控诉，勿采取其他极端方式，谢谢您！",
--  "【米豪公益】需要打开去主城的捷径，请与{player}私聊“传送门”！，牢记程序，免一切手续费！",
--  --"【米豪公益】米豪4大功能：免费餐饮，0手续费传送门，跨位面，副本重置。详情M{player}【"..L.cmds.help_cmd.."】",
--  "【米豪公益】如果亲觉得米豪公益好用，请奔走相告，米豪力争24小时为各位提供免费食水传送服务！",
--  "【米豪公益】TIPs: 米豪开门只收【传送门符文】不收金币！！！详情M{player}【传送门】",
----  "【米豪公益】TIPs: 如果米豪开始奥暴，并非米豪在划水，而是米豪食水充足无比！欢迎各种交易！完全免费！",
--  "【米豪公益】TIPs: 如果您和米豪不在一个位面，请M{player}唯一有效咒语【"..L.cmds.invite_cmd.."】进组！",
--  "【米豪公益】TIPs: 米豪平时无人值守，需要食物的请直接交易！需要传送请M{player}【传送门】，并认真按照开门程序操作，简单便捷！",
----  "【米豪公益】米豪每天会升级维护，维护期间不能提供服务，敬请谅解！有关米豪的使用帮助，请M{player}【"..L.cmds.help_cmd.."】！",
--  "【米豪公益】米豪现在可以为【25-54】的小号供餐，详情请M{player}【"..L.cmds.low_level_help_cmd.."】",
--  "【米豪公益】TIPs: 如果米豪变绿了，说明现在正处于用餐高峰，请M{player}【"..L.cmds.busy_cmd.."】查看高峰期规则！",
--  "【米豪公益】TIPs: 如需单刷重置FB工具人服务，请M{player}【"..L.cmds.reset_instance_help.."】查看使用方法！",
--  "【米豪公益】TIPs: 6组大水相当于约1分钟时间，当其他法师免费赠与您时间时，希望您能心存感激，保持礼貌哦！",
--  "【米豪公益】无论是在魔兽世界，还是现实生活，请各位一定勤洗手，保持个人清洁，远离疾病！",
--  "【米豪公益】特殊时期，请各位友人减少外出，外出请带一次性口罩，切忌水洗口罩哦，否则过滤功能会失效！",
--  "【米豪公益】米豪祝愿湖北省早日攻克难关！武汉加油！湖北加油！中国加油！",
}

local ad_msg_busy = {
    "【米豪公益：用餐高峰】M{player}【"..L.cmds.help_cmd.."】获取帮助。",
    --"【米豪公益】米豪自开工以来300余次升级，只为大家能够体会一丝温馨，如有意见，请高抬贵手邮件控诉，勿采取其他极端方式，谢谢您！",
    --"【米豪公益：用餐高峰】由于米豪被相关利益集团举报，重置功能暂停使用。该账号尚能提供位面与传送门等服务。",

  --"【米豪公益：用餐高峰】需要55级水、45级面包，请直接交易“米豪”货仓！免费提供！",
  --"【米豪公益：用餐高峰】需要打开去主城的捷径，请与{player}私聊“传送门”！，牢记程序，免一切手续费！",
  --"【米豪公益：用餐高峰】TIPs：用餐高峰期间，米豪每次交易供应减半，阻止相同角色连续交易，阻止60级FS交易，敬请谅解！",
  --"【米豪公益：用餐高峰】TIPs：米豪在喝水期间，货存不会增长，如果库存不足，请不要在米豪喝水期间重复交易哦！",
  --"【米豪公益：用餐高峰】TIPs：用餐高峰期间，请各位亲保持有序，不要争抢，谢谢大家支持与配合！",
  --"【米豪公益：用餐高峰】TIPs：米豪在面包与水均高于4组的情况下才允许交易，请亲关注库存！",
  --"【米豪公益：用餐高峰】TIPs：【激活】法术会【大幅提升】米豪制作效率，如果米豪正在制作中，请德爷们赏个激活吧！！",
  --"【米豪公益：用餐高峰】TIPs：用餐高峰期，米豪支持志同道合朋友们的补货！请M米豪【补货】查看详情，谢谢！",
  --"【米豪公益：用餐高峰】TIPs: 如果米豪变绿了，说明现在正处于用餐高峰，请M{player}【"..L.cmds.busy_cmd.."】查看高峰期规则！",
}

function L.F.say_help(to_player)
  L.F.whisper_or_say(
    "需要吃喝，直接交易。勿交易金币和物品。如有有建议或希望捐赠，请使用魔兽邮箱，谢谢支持！", to_player
  )
  L.F.whisper_or_say(
    "========={player}目前支持如下命令：", to_player
  )
  L.F.whisper_or_say(
    string.format("1.【%s】打印本命令列表", L.cmds.help_cmd), to_player
  )
  L.F.whisper_or_say(
    string.format("2.【%s】查看重置副本方法", L.cmds.reset_instance_help), to_player
  )
  L.F.whisper_or_say(
    string.format("3.【%s】向您发起组队邀请，以便发送位置、跨位面", L.cmds.invite_cmd), to_player
  )
  L.F.whisper_or_say(
    string.format("4.【%s】查看高峰期补货方式", L.cmds.refill_help_cmd), to_player
  )
  L.F.whisper_or_say(
    "5.【自定义分配】为您定制水和面包比例，例如您可说“4水2面包”", to_player
  )
  L.F.whisper_or_say(
    string.format("6.【%s】查看开门步骤", L.cmds.gate_help_cmd), to_player
  )
  L.F.whisper_or_say(
    string.format("7.【%s】查看获取小号食物方法", L.cmds.low_level_help_cmd), to_player
  )
  L.F.whisper_or_say("其他命令：【"..L.cmds.say_ack.."】，【"
          ..L.cmds.scale_cmd.."】，【"
          ..L.cmds.retrieve_position.."】,【"
          ..L.cmds.statistics.."】，【"
          ..L.cmds.busy_cmd.."】，【"
          ..L.cmds.layer.."】", to_player)
end


local is_odd = false

function L.F.send_ad()
  if ATFClientSettings.adv then
    is_odd = not is_odd
    if is_odd then
      local water = L.F.get_water_count()
      local bread = L.F.get_bread_count()
      L.F.whisper_or_say(date("%X").."存货：【大水】"..water.."组，【面包】"..bread.."组。【免费】【直接交易】")
    else
      local admsgs;
      if L.F.get_busy_state() then
        admsgs = ad_msg_busy
      else
        admsgs = ad_msg
      end
      L.F.whisper_or_say(date("%X")..admsgs[math.random(1, #admsgs)])
    end
  end
end


function L.F.say_acknowledgements(to_player)
  L.F.whisper_or_say("感谢下列玩家对米豪一直以来的支持！", to_player)
  L.F.whisper_or_say("云缠绕星光丶、阿信的小可爱", to_player)
  L.F.whisper_or_say("留白丶、梦魇丶", to_player)
  L.F.whisper_or_say("大头菜咖喱酱", to_player)
  L.F.whisper_or_say("嘟嘟歪嘟嘟", to_player)
  L.F.whisper_or_say("且洛", to_player)
  L.F.whisper_or_say("蛋蛋放中间", to_player)
  L.F.whisper_or_say("皇额娘", to_player)
  L.F.whisper_or_say("路过一只小软", to_player)
end


function L.F.say_statistics(day)
  if day == nil then
    day = 0
  end
  local words = {}
  local ts = math.modf(time()) - day * 24 * 60 * 60
  local date_to_stat = date("%x", ts)
  table.insert(words, "米豪"..date_to_stat.."数据：")

  local gate_count = L.F.query_statistics_int("trade.gate.count."..date_to_stat)
  table.insert(words, "总计开门：【"..gate_count.."】次")

  local food_info = L.F.get_food_name_level()

  local water_count = L.F.query_statistics_int("trade.food.all."..date_to_stat.."."..food_info.water.name)
  local food_count = L.F.query_statistics_int("trade.food.all."..date_to_stat.."."..food_info.food.name)
  table.insert(words, "总计送水：【"..
          math.modf(water_count / 20).."】组，送面包：【"..
          math.modf(food_count / 20).."】组")

  table.insert(words, "职业需求排序：")
  local trade_by_class = L.F.query_statistics("trade.food.class."..date_to_stat)
  local class_count = {}
  for class, items in pairs(trade_by_class) do
    table.insert(class_count, {class=class, count= L.F.nil_fallback_zero(items[food_info.food.name]) +  L.F.nil_fallback_zero(items[food_info.water.name])})
  end
  table.sort(class_count, function(a, b) return a.count > b.count end)
  for i, class in ipairs(class_count) do
    table.insert(words, ""..i..". "..class.class.." 交易成功：【"..math.modf(class.count / 20).."】组")
  end

  table.insert(words, "吃货排行：")
  local trade_by_ind = L.F.query_statistics("trade.food.ind."..date_to_stat)
  local trade_count = {}
  for name, items in pairs(trade_by_ind) do
    table.insert(trade_count, {name=name, count=L.F.nil_fallback_zero(items[food_info.food.name]) + L.F.nil_fallback_zero(items[food_info.water.name])})
  end
  table.sort(trade_count, function(a, b) return a.count > b.count end)
  for i, ind in ipairs(trade_count) do
    table.insert(words, ""..i..". "..ind.name.." 取走【"..math.modf(ind.count / 20).."】组")
    if i >= 3 then break end
  end

  table.insert(words, "补货排行：")
  local refill_by_ind = L.F.query_statistics("trade.refill.ind."..date_to_stat)
  local refill_count = {}
  for name, items in pairs(refill_by_ind) do
    table.insert(refill_count, {name=name, food_count= L.F.nil_fallback_zero(items[food_info.food.name]), water_count= L.F.nil_fallback_zero(items[food_info.water.name])})
  end
  table.sort(refill_count, function(a, b) return a.water_count > b.water_count end)
  for i, ind in ipairs(refill_count) do
    table.insert(words, ""..i..". "..ind.name.." 补充大水：【"..math.modf(ind.water_count / 20)..
            "】组，面包【"..math.modf(ind.food_count / 20).."】组")
    if i >= 3 then break end
  end
  return words
end


function L.F.say_statistics_backend(day)
  if day == nil then
    day = 0
  end
  local words = {}
  local ts = math.modf(time()) - day * 24 * 60 * 60
  local date_to_stat = date("%x", ts)
  table.insert(words, "米豪"..date_to_stat.."数据：")

  local gate_count = L.F.query_statistics_int("reset.count."..date_to_stat)
  table.insert(words, "总计重置：【"..gate_count.."】次")

  table.insert(words, "职业排行：")
  local reset_by_class = L.F.query_statistics("reset.class."..date_to_stat)
  local class_count = {}
  for class, cnt in pairs(reset_by_class) do
    table.insert(class_count, {class=class, count=cnt})
  end
  table.sort(class_count, function(a, b) return a.count > b.count end)
  for i, class in ipairs(class_count) do
    table.insert(words, ""..i..". "..class.class.." 重置：【"..class.count.."】次")
  end

  table.insert(words, "副本排行：")
  local reset_by_instance = L.F.query_statistics("reset.instance."..date_to_stat)
  local instance_count = {}
  for instance, cnt in pairs(reset_by_instance) do
    table.insert(instance_count, {instance=instance, count=cnt})
  end
  table.sort(instance_count, function(a, b) return a.count > b.count end)
  for i, instance in ipairs(instance_count) do
    table.insert(words, ""..i..". ".. instance.instance.." 重置：【".. instance.count.."】次")
  end

  table.insert(words, "肝帝排行：")
  local reset_by_ind = L.F.query_statistics("reset.ind."..date_to_stat)
  local ind_count = {}
  for ind, cnt in pairs(reset_by_ind) do
    table.insert(ind_count, {name=ind, count=cnt})
  end
  table.sort(ind_count, function(a, b) return a.count > b.count end)
  for i, ind in ipairs(ind_count) do
    table.insert(words, ""..i..". ".. ind.name.." 重置：【".. ind.count.."】次")
    if i >= 3 then break end
  end
  return words
end


function L.F.may_say_statistics(msg, author)
  if string.match(msg, "/g") == "/g" then
    msg = string.gsub(msg, "/g", "")
    author = "/g"
  end
  local pattern = L.cmds.statistics.."%-(%d+)"
  local day = string.match(msg, pattern)
  if day or msg == L.cmds.statistics then
    local words
    if L.F.is_frontend() then
      words = L.F.say_statistics(day)
    elseif L.F.is_backend() then
      words = L.F.say_statistics_backend(day)
    end
    for _, w in ipairs(words) do
      L.F.whisper_or_say(w, author)
    end
    return true
  end
  return false
end
