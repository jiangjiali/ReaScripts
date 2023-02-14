-- @description Humanize Take Pitch
-- @version 1.0.1
-- @author zaibuyidao
-- @changelog Optimized code
-- @links
--   webpage https://www.soundengine.cn/user/%E5%86%8D%E8%A3%9C%E4%B8%80%E5%88%80
--   repo https://github.com/zaibuyidao/ReaScripts
-- @donate http://www.paypal.me/zaibuyidao
-- @about Not Requires SWS Extensions

function print(...)
  local params = {...}
  for i = 1, #params do
    if i ~= 1 then reaper.ShowConsoleMsg(" ") end
    reaper.ShowConsoleMsg(tostring(params[i]))
  end
  reaper.ShowConsoleMsg("\n")
end

function table.print(t)
  local print_r_cache = {}
  local function sub_print_r(t, indent)
    if (print_r_cache[tostring(t)]) then
      print(indent .. "*" .. tostring(t))
    else
      print_r_cache[tostring(t)] = true
      if (type(t) == "table") then
        for pos, val in pairs(t) do
          if (type(val) == "table") then
            print(indent .. "[" .. tostring(pos) .. "] => " .. tostring(t) .. " {")
            sub_print_r(val, indent .. string.rep(" ", string.len(tostring(pos)) + 8))
            print(indent .. string.rep(" ", string.len(tostring(pos)) + 6) .. "}")
          elseif (type(val) == "string") then
            print(indent .. "[" .. tostring(pos) .. '] => "' .. val .. '"')
          else
            print(indent .. "[" .. tostring(pos) .. "] => " .. tostring(val))
          end
        end
      else
        print(indent .. tostring(t))
      end
    end
  end
  if (type(t) == "table") then
    print(tostring(t) .. " {")
    sub_print_r(t, "  ")
    print("}")
  else
    sub_print_r(t, "  ")
  end
end

local count_sel_items = reaper.CountSelectedMediaItems(0)
if count_sel_items > 0 then

  local strength = reaper.GetExtState("HUMANIZE_TAKE_PITCH", "STRENGTH")
  if (strength == "") then strength = "3" end
  local toggle = reaper.GetExtState("HUMANIZE_TAKE_PITCH", "TOGGLE")
  if (toggle == "") then toggle = "n" end

  local locale = tonumber(string.match(os.setlocale(), "(%d+)$"))
  
  local function check_locale(locale)
    if locale == 936 then
      return true
    elseif locale == 950 then
      return true
    end
    return false
  end

  default = strength ..','.. toggle

  if reaper.GetOS():match("Win") then
    if check_locale(locale) == false then
      title = "Humanize Take Pitch"
      lable = "Strength:,Use semitone? (y/n)"
    else
      title = "片段音高人性化"
      lable = "强度:,是否使用半音 (y/n)"
    end
  else
    title = "Humanize Take Pitch"
    lable = "Strength:,Use semitone?? (y/n)"
  end

  local uok, uinput = reaper.GetUserInputs(title, 2, lable, default)
  if not uok then return end

  strength, toggle = uinput:match("(.*),(.*)")
  strength, toggle = tonumber(strength), tostring(toggle)
  if strength == 0 then return end

  reaper.SetExtState("HUMANIZE_TAKE_PITCH", "STRENGTH", strength, false)
  reaper.SetExtState("HUMANIZE_TAKE_PITCH", "TOGGLE", toggle, false)
  strength = math.abs(strength-1)

  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()
  for i = 0, count_sel_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    if take then
      local pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
      local input = (strength+1)*2

      if not reaper.TakeIsMIDI(take) then
        if toggle == "y" then
          rand = math.floor(math.random()*(input+1)-(input/2)) -- 隨機整數
          pitch = math.floor(0.5+pitch)
        else
          rand = math.random()*(input)-(input/2)
        end
        if rand > 12 then rand = 12
        elseif rand < -12 then
          rand = -12
        end
        reaper.SetMediaItemTakeInfo_Value(take, 'D_PITCH', pitch+rand)
      end
    end
    reaper.UpdateItemInProject(item)
  end
  reaper.Undo_EndBlock(title, -1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end