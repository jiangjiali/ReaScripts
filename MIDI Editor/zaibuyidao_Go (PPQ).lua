--[[
 * ReaScript Name: Go (PPQ)
 * Instructions: Open a MIDI take in MIDI Editor. Select Notes. Run.
 * Version: 1.0
 * Author: zaibuyidao
 * Author URI: https://www.soundengine.cn/user/%E5%86%8D%E8%A3%9C%E4%B8%80%E5%88%80
 * Repository: GitHub > zaibuyidao > ReaScripts
 * Repository URI: https://github.com/zaibuyidao/ReaScripts
 * REAPER: 6.0
 * Donation: http://www.paypal.me/zaibuyidao
 * provides: [main=midi_editor,midi_eventlisteditor] .
--]]

--[[
 * Changelog:
 * v1.0 (2020-1-30)
  + Initial release
--]]

-- Ensure accurate time format
-- REAPER Preferences -> MIDI -> Ticks per quarter note for new MIDI Items: 480
-- MIDI Editor -> Options -> Time format for ruler, transoprt, event properties -> Measures.Beats.MIDI_ticks

function Main()
  local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  local cur_pos = reaper.GetCursorPositionEx()
  local qn = reaper.TimeMap2_timeToQN(0, cur_pos)
  local ppqpos = reaper.MIDI_GetPPQPosFromProjQN(take, qn)
  local _, measures, _, _, _ = reaper.TimeMap2_timeToBeats(0, cur_pos)
  local start_meas = reaper.MIDI_GetPPQPos_StartOfMeasure(take, ppqpos)
  local start_beat = (ppqpos - start_meas) / 480
  local num_01, num_02 = math.modf(start_beat)
  num_01 = num_01 + 1
  num_02 = num_02 * 0.480
  num_add = string.format("%.3f", num_01 + num_02)
  measures = measures + 1
  local cur_range = tostring(measures)..','..tostring(num_add)
  local OK, get_input = reaper.GetUserInputs("Go", 2, "Measure,Beat", cur_range)
  if not OK then return reaper.SN_FocusMIDIEditor() end
  measure, beat = get_input:match("(.*),(.*)")
  if not measure:match('[%d%.]+') or not beat:match('[%d%.]+') then return reaper.SN_FocusMIDIEditor() end
  measure, beat = tonumber(measure), tonumber(beat)
  num_03, num_04 = math.modf(beat)
  num_04 = num_04 / 0.480
  local x = measure - 1
  local z = (num_03 - 1) + num_04
  reaper.SetEditCurPos(reaper.TimeMap2_beatsToTime(0, z, x), true, true)
end

script_title = "Go (PPQ)"
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(script_title, -1)
reaper.SN_FocusMIDIEditor()