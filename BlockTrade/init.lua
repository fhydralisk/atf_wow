local addonName, L = ...

local frame = CreateFrame("FRAME", "BTInitFrame")
frame:RegisterEvent("ADDON_LOADED")

local origInitiateTrade

local function bcInitiateTrade(target, ...)
  L.p_name = UnitName(target)
  L.p_time = GetTime()
  origInitiateTrade(target, ...)
end


local function eventHandler(self, event, msg)
    if event == "ADDON_LOADED" and msg == "BlockTrade" then
      if BlockTradeWhiteList == nil then
          BlockTradeWhiteList = {}
      end
      if BlockTradeConfig == nil then
        BlockTradeConfig = {
          level=1,
          msg="本人不与乞丐交易，抱歉。",
          on=true,
        }
      end
      local s
      if BlockTradeConfig.on then
        s = "开启"
      else
        s = "关闭"
      end
      origInitiateTrade = InitiateTrade
      InitiateTrade = bcInitiateTrade
      print("BlockTrade插件已载入，当前处于"..s.."，查看帮助，请输入/bth")
    end
end

frame:SetScript("OnEvent", eventHandler)
