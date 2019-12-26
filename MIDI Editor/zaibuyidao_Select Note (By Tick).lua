--[[
 * ReaScript Name: Select Note (By Tick)
 * Instructions: Open a MIDI take in MIDI Editor. Select Notes. Run.
 * Version: 1.0
 * Author: zaibuyidao
 * Author URI: https://www.soundengine.cn/user/%E5%86%8D%E8%A3%9C%E4%B8%80%E5%88%80
 * Repository: GitHub > zaibuyidao > ReaScripts
 * Repository URI: https://github.com/zaibuyidao/ReaScripts
 * Reference: https://forum.cockos.com/showthread.php?t=225108
 * REAPER: 6.0
 * Donation: http://www.paypal.me/zaibuyidao
--]]

--[[
 * Changelog:
 * v1.0 (2019-12-27)
  + Initial release
--]]

function Main()
  local take=reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  retval, notes, ccs, sysex = reaper.MIDI_CountEvts(take)
  userOK, dialog_ret_vals = reaper.GetUserInputs("Select Note", 2, "Min Tick,Max Tick", "0,240")
  if not userOK then return reaper.SN_FocusMIDIEditor() end
  min_val, max_val = dialog_ret_vals:match("(.*),(.*)")
  min_val, max_val = tonumber(min_val), tonumber(max_val)
  if min_val > 1919 or max_val > 1919 or min_val < 0 or max_val < 0 then return reaper.MB("Please enter a value from 0 through 1919", "Error", 0), reaper.SN_FocusMIDIEditor() end

  for i = 0,  notes-1 do
    retval, sel, muted, ppq_start, ppq_end, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    newstart = reaper.MIDI_GetProjQNFromPPQPos(take, ppq_start)
    if sel == true then
      if newstart >= math.floor(newstart) + min_val/480 and newstart <= math.floor(newstart) + max_val/480 then -- 定义Tick范围
        reaper.MIDI_SetNote(take, i, true, muted, ppq_start, ppq_end, chan, pitch, vel, true)
      else
        reaper.MIDI_SetNote(take, i, false, muted, ppq_start, ppq_end, chan, pitch, vel, true)
      end
    end
    i=i+1
  end
  reaper.UpdateArrange()
end

script_title = "Select Note"
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(script_title, -1)
reaper.SN_FocusMIDIEditor()