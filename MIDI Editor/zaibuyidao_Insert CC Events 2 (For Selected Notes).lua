--[[
 * ReaScript Name: Insert CC Events 2 (For Selected Notes)
 * Instructions: Open a MIDI take in MIDI Editor. Select Notes. Run.
 * Version: 1.7
 * Author: zaibuyidao
 * Author URI: https://www.soundengine.cn/user/%E5%86%8D%E8%A3%9C%E4%B8%80%E5%88%80
 * Repository: GitHub > zaibuyidao > ReaScripts
 * Repository URI: https://github.com/zaibuyidao/ReaScripts
 * REAPER: 6.0
 * Donation: http://www.paypal.me/zaibuyidao
--]]

--[[
 * Changelog:
 * v1.7 (2019-1-5)
  # Adjust the name
 * v1.5 (2019-1-5)
  # Bug fix offset
 * v1.225 (2019-1-1)
  # Bug fix endppqpos offset
 * v1.0 (2019-12-12)
  + Initial release
--]]

selected = false
muted = false
chan = 0 -- Channel 1

function Main()
  local take=reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  if take == nil then return end
  item = reaper.GetMediaItemTake_Item(take)
  retval, notes, ccs, sysex = reaper.MIDI_CountEvts(take)
  local retval, userInputsCSV = reaper.GetUserInputs("Insert CC Events 2", 5, "CC Number,First Value,Second Value,First Offset,Second Offset", "64,127,0,110,-10")
  if not retval then return reaper.SN_FocusMIDIEditor() end
  local msg2, msg3, msg4, first_offset, second_offset = userInputsCSV:match("(.*),(.*),(.*),(.*),(.*)")
  msg2, msg3, msg4, first_offset, second_offset = tonumber(msg2), tonumber(msg3), tonumber(msg4), tonumber(first_offset), tonumber(second_offset)

  for i = 0,  notes-1 do
    retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if selected == true then
      reaper.MIDI_InsertCC(take, selected, muted, startppqpos + first_offset, 0xB0, 0, msg2, msg3)
      reaper.MIDI_InsertCC(take, selected, muted, endppqpos + second_offset, 0xB0, 0, msg2, msg4)
      reaper.UpdateItemInProject(item)
    end
    i=i+1
  end
  reaper.UpdateArrange()
end

script_title = "Insert CC Events 2"
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(script_title, -1)
reaper.SN_FocusMIDIEditor()
