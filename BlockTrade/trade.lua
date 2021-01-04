local addonName, L = ...


SLASH_BTWL1 = "/btw"
SLASH_BT_HELP1 = "/bth"
SLASH_BTSW1 = "/bts"


local trade_log_frame = CreateFrame("FRAME", "BTTradeFrame")
trade_log_frame:RegisterEvent("TRADE_SHOW");

local bag_shown
local handle = false
local last_shown = 0
local hooked = false


local Bag_OnShow = function(self)
  if handle or GetTime() - last_shown < 0.5 then
    last_shown = GetTime()
    handle = false
    if bag_shown == 0 then
      CloseAllBags()
    end
  end
end

local Bag_OnHide = function(self)
  if handle or GetTime() - last_shown < 0.5 then
    last_shown = GetTime()
    handle = false
    if bag_shown == 1 then
      OpenAllBags()
    end
  end
end

local function hook_frame()
  if CombuctorFrame1 then
    CombuctorFrame1:HookScript("OnShow", Bag_OnShow)
    CombuctorFrame1:HookScript("OnHide", Bag_OnHide)
  end
  if BagnonInventoryFrame1 then
    BagnonInventoryFrame1:HookScript("OnShow", Bag_OnShow)
    BagnonInventoryFrame1:HookScript("OnHide", Bag_OnHide)
  end
end

local function interface_bag_shown()
  return (CombuctorFrame1 and CombuctorFrame1:IsShown()) or (BagnonInventoryFrame1 and BagnonInventoryFrame1:IsShown())
end

local function trade_on_event(self, event, arg1, arg2)

  if event == "TRADE_SHOW" and BlockTradeConfig.on then
    local trader = UnitName("NPC")
    local level = UnitLevel("NPC")
    if not hooked then
      ContainerFrame1:HookScript("OnShow", Bag_OnShow)
      ContainerFrame1:HookScript("OnHide", Bag_OnHide)
      hook_frame()
      hooked = true
    end
    if ContainerFrame1:IsShown() or interface_bag_shown() then
      bag_shown = 1
    else
      bag_shown = 0
    end
    if BlockTradeWhiteList[trader] == nil and not (UnitInParty(trader) or UnitInRaid(trader)) then
      if level <= BlockTradeConfig.level then
        if L.p_name == trader and GetTime() - L.p_time < 10 then
          print("[BlockTrade]与小号"..trader.."的交易由您最近主动发起，允许本次交易。")
        else
          handle = true
          CloseTrade()
          if BlockTradeConfig.msg then
            SendChatMessage(BlockTradeConfig.msg, "whisper", nil, trader)
            SendChatMessage("BlockTrade插件: 已自动阻止与>>"..trader.."<<的交易并问候其父母。", "emote")
          end
        end
      end
    end
  end

end

--CombuctorFrame1:HookScript("OnShow", CombuctorFrame1_OnShow)


trade_log_frame:SetScript("OnEvent", trade_on_event);

function SlashCmdList.BTSW(msg)
  BlockTradeConfig.on = not BlockTradeConfig.on
  if BlockTradeConfig.on then
    print("BlockTrade已开启")
  else
    print("BlockTrade已关闭")
  end
end


function SlashCmdList.BTWL(msg)
  BlockTradeWhiteList[msg] = true
  print("已添加"..msg.."至白名单")
end


function SlashCmdList.BT_HELP(msg)
  print("添加白名单：/btw 玩家名字")
  print("设置等级：/run BlockTradeConfig.level=2")
  print("设置回复：/run BlockTradeConfig.msg=\"sb\"")
  print("屏蔽器开关：/bts")
end
