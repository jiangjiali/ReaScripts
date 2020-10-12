--[[
 * ReaScript Name: Insert Sysex
 * Version: 1.0
 * Author: zaibuyidao
 * Author URI: https://www.soundengine.cn/user/%E5%86%8D%E8%A3%9C%E4%B8%80%E5%88%80
 * Repository: GitHub > zaibuyidao > ReaScripts
 * Repository URI: https://github.com/zaibuyidao/ReaScripts
 * REAPER: 6.0
 * provides: [main=midi_editor,midi_eventlisteditor] .
--]]

--[[
 * Changelog:
 * v1.0 (2020-10-13)
  + Initial release
--]]

function Msg(param) reaper.ShowConsoleMsg(tostring(param) .. "\n") end
local window, _, _ = reaper.BR_GetMouseCursorContext()
local _, inline_editor, _, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
local sysex_byte = reaper.GetExtState("InsertSysex", "SysexByte")
if (sysex_byte == "") then sysex_byte = "41 10 42 12 00 00 7F 01 00" end
user_ok, sysex_byte = reaper.GetUserInputs('Insert Sysex', 1, 'F0 ......... F7,extrawidth=250', sysex_byte)

reaper.SetExtState("InsertSysex", "SysexByte", sysex_byte, false)

sysex_byte = sysex_byte:gsub("%s+", "") -- 去除所有空格

reaper.Undo_BeginBlock()
if window == "midi_editor" then
  if not inline_editor then
      if not user_ok then return reaper.SN_FocusMIDIEditor() end
      take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  else
      take = reaper.BR_GetMouseCursorContext_Take()
  end

  local ppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetCursorPositionEx(0)) -- 獲取光標位置
  local bytestr = ''
  for char_pair in sysex_byte:gmatch('..') do
      bytestr = bytestr .. string.char(tonumber(char_pair, 16))
  end

  reaper.MIDI_InsertTextSysexEvt(take, true, false, ppqpos, -1, bytestr)

  if not inline_editor then reaper.SN_FocusMIDIEditor() end
else
  if not user_ok then return end
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items == 0 then return end
  for i = 1, count_sel_items do
      item = reaper.GetSelectedMediaItem(0, count_sel_items - i)
      take = reaper.GetTake(item, 0)

      local ppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetCursorPositionEx(0)) -- 獲取光標位置
      local bytestr = ''
      for char_pair in sysex_byte:gmatch('..') do
          bytestr = bytestr .. string.char(tonumber(char_pair, 16))
      end

      reaper.MIDI_InsertTextSysexEvt(take, true, false, ppqpos, -1, bytestr)
  end
end
reaper.Undo_EndBlock("Insert Sysex", 0)
reaper.UpdateArrange()
