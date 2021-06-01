--[[
 * ReaScript Name: Rename Region
 * Version: 1.1
 * Author: zaibuyidao
 * Author URI: https://www.soundengine.cn/user/%E5%86%8D%E8%A3%9C%E4%B8%80%E5%88%80
 * Repository: GitHub > zaibuyidao > ReaScripts
 * Repository URI: https://github.com/zaibuyidao/ReaScripts
 * REAPER: 6.0
 * Donation: http://www.paypal.me/zaibuyidao
--]]

--[[
 * Changelog:
 * v1.0 (2021-5-30)
  + Initial release
--]]

function Msg(param) 
  reaper.ShowConsoleMsg(tostring(param) .. "\n") 
end

function max(a,b)
  if a>b then
    return a
  end
  return b
end

function create_region(reg_start, reg_end, name)
  if name == nil then return end
  local index = reaper.AddProjectMarker2(0, true, reg_start, reg_end, name, -1, 0)
end

function rename_region(name)
  if name == nil then return end
  reaper.SetProjectMarker3(0, markrgnindexnumber, isrgn, pos, rgnend, name, color)
end

item_count = reaper.CountSelectedMediaItems(0)
if item_count == 0 then return end

local items = {}

for i = 1, reaper.CountSelectedMediaItems(0) do
  local item = reaper.GetSelectedMediaItem(0, i-1)
  if item ~= nil then
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end = item_pos + item_len
    table.insert( items,{ left=item_pos,right=item_end } )
  end
end

if #items <= 0 then return end

table.sort(items,function(a,b)
  return a.left < b.left
end)

local regions = {}
local left_t = {}

local cur = {
  left = items[1].left,
  right = items[1].right
}

for i,item in ipairs(items) do
  if cur.right - item.left > 0 then -- 判定區域是否為相交
    cur.right = max(item.right,cur.right)
  else
    table.insert(regions, cur)
    cur = {
      left = item.left,
      right = item.right
    }
  end
end

table.insert(regions, cur)

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

for i, region in ipairs(regions) do
  markeridx, regionidx = reaper.GetLastMarkerAndCurRegion(0, region.left)
  retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, regionidx)
  local tail = reaper.GetExtState("RenameRegion", "Tail")
  if (tail == "") then tail = "0" end

  if pos == region.left then
    input_ret, retvals_csv = reaper.GetUserInputs("Rename Region", 2, "Region name 區域名稱:,Tail 尾巴:,extrawidth=200", name .. ',' .. tail)
    if not input_ret or not tonumber(tail) then return end
    name, tail = retvals_csv:match("(.*),(.*)")

    reaper.SetExtState("RenameRegion", "Tail", tail, false)

    if name == '-1' then break end
    if input_ret then
      if isrgn then
        reaper.SetProjectMarker3(0, markrgnindexnumber, isrgn, pos, rgnend+tail, name, color)
      end
    end
  end
end

reaper.Undo_EndBlock("Rename Region", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
