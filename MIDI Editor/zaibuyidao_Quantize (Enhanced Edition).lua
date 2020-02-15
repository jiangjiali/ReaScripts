--[[
 * ReaScript Name: Quantize (Enhanced Edition)
 * Instructions: Open a MIDI take in MIDI Editor. Select Notes And CC Events. Run.
 * Version: 1.1
 * Author: zaibuyidao
 * Author URI: https://www.soundengine.cn/user/%E5%86%8D%E8%A3%9C%E4%B8%80%E5%88%80
 * Repository: GitHub > zaibuyidao > ReaScripts
 * Repository URI: https://github.com/zaibuyidao/ReaScripts
 * REAPER: 6.0
--]]

--[[
 * Changelog:
 * v1.1 (2020-2-15)
  + When executing the script, delete overlapped notes is switched, and delete overlapped notes is enabled by default
 * v1.0 (2020-2-1)
  + Initial release
--]]

function Msg(param) reaper.ShowConsoleMsg(tostring(param) .. "\n") end
local title = "Quantize (Enhanced Edition)"
local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
local tick = reaper.SNM_GetIntConfigVar("MidiTicksPerBeat", 480)
local cur_grid, swing = reaper.MIDI_GetGrid(take)
local _, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
local OK, userInputsCSV = reaper.GetUserInputs('Quantize', 2, 'Enter A Tick,0=Start+Dur 1=Start 2=Durations', '120,0')
if not OK then return reaper.SN_FocusMIDIEditor() end
local grid, toggle = userInputsCSV:match("(.*),(.*)")
if not grid:match('[%d%.]+') or not toggle:match('[%d%.]+') then return reaper.SN_FocusMIDIEditor() end
reaper.SetExtState("Quantize", "ToggleValue", toggle, true)
local has_state = reaper.HasExtState("Quantize", "ToggleValue")
if has_state == true then
    state = reaper.GetExtState("Quantize", "ToggleValue")
end

grid = grid / tick

function StartTimes()
    for i = 1, notecnt do
        local _, selected, _, startppqpos, endppqpos, _, _, _ = reaper.MIDI_GetNote(take, i - 1)
        if selected then
            local start_note_qn = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)
            local end_note_qn = reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos)
            local beats_01, _, _, start_cdenom = reaper.TimeMap2_timeToBeats(0, start_note_qn)
            local beats_02, _, _, end_cdenom = reaper.TimeMap2_timeToBeats(0, end_note_qn)
            local out_pos, out_ppq, out_beatpos
            if swing == 0 then
                if (end_cdenom - start_cdenom) < (grid / 2) and (beats_02 % grid) > (grid / 2) then
                    out_beatpos = start_cdenom - (beats_01 % grid)
                elseif (beats_01 % grid) < (grid / 2) then
                    out_beatpos = start_cdenom - (beats_01 % grid)
                else
                    out_beatpos = start_cdenom - (beats_01 % grid) + grid
                end
                out_pos = reaper.TimeMap2_beatsToTime(0, out_beatpos)
                out_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, out_pos)
            end
            reaper.MIDI_SetNote(take, i - 1, true, nil, out_ppq, nil, nil, nil, nil, false)
        end
    end
end

function NoteDurations()
    for i = 1, notecnt do
        local _, selected, _, startppqpos, endppqpos, _, _, _ = reaper.MIDI_GetNote(take, i - 1)
        if selected then
            local start_note_qn = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)
            local end_note_qn = reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos)
            local beats_01, _, _, start_cdenom = reaper.TimeMap2_timeToBeats(0, start_note_qn)
            local beats_02, _, _, end_cdenom = reaper.TimeMap2_timeToBeats(0, end_note_qn)
            local out_pos, out_ppq, out_beatpos
            if swing == 0 then
                if (end_cdenom - start_cdenom) < (grid / 2) and (beats_01 % grid) < (grid / 2) then
                    out_beatpos = end_cdenom - (beats_02 % grid) + grid
                elseif (beats_02 % grid) < (grid / 2) then
                    out_beatpos = end_cdenom - (beats_02 % grid)
                else
                    out_beatpos = end_cdenom - (beats_02 % grid) + grid
                end
                out_pos = reaper.TimeMap2_beatsToTime(0, out_beatpos)
                out_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, out_pos)
            end
            reaper.MIDI_SetNote(take, i - 1, true, nil, nil, out_ppq, nil, nil, nil, false)
        end
    end
end

function CCEvents()
    for i = 1, ccevtcnt do
        local _, selected, _, ppqpos, _, _, _, _ = reaper.MIDI_GetCC(take, i - 1)
        if selected then
            local start_qn = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)
            local beats_01, _, _, start_cdenom = reaper.TimeMap2_timeToBeats(0, start_qn)
            local out_pos, out_ppq, out_beatpos
            if swing == 0 then
                if (beats_01 % grid) < (grid / 2) then
                    out_beatpos = start_cdenom - (beats_01 % grid)
                else
                    out_beatpos = start_cdenom - (beats_01 % grid) + grid
                end
                out_pos = reaper.TimeMap2_beatsToTime(0, out_beatpos)
                out_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, out_pos)
            end
            reaper.MIDI_SetCC(take, i - 1, true, nil, out_ppq, nil, nil, nil, nil, false)
        end
    end
end

function TextSysEvents()
    for i = 1, textsyxevtcnt do
        local _, selected, _, ppqpos, _, _ = reaper.MIDI_GetTextSysexEvt(take, i - 1)
        if selected then
            local start_qn = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)
            local beats_01, _, _, start_cdenom = reaper.TimeMap2_timeToBeats(0, start_qn)
            local out_pos, out_ppq, out_beatpos
            if swing == 0 then
                if (beats_01 % grid) < (grid / 2) then
                    out_beatpos = start_cdenom - (beats_01 % grid)
                else
                    out_beatpos = start_cdenom - (beats_01 % grid) + grid
                end
                out_pos = reaper.TimeMap2_beatsToTime(0, out_beatpos)
                out_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, out_pos)
            end
            reaper.MIDI_SetTextSysexEvt(take, i - 1, true, nil, out_ppq, nil, nil, false) 
        end
    end
end

function Main()
    reaper.Undo_BeginBlock()
    reaper.MIDI_DisableSort(take)
    if reaper.GetToggleCommandStateEx(32060, 40681) == 1 then
        reaper.MIDIEditor_LastFocused_OnCommand(40681,0) -- Options: Correct overlapping notes while editing
    end
    if state == "2" then
        NoteDurations()
    elseif state == "1" then
        StartTimes()
        CCEvents()
        TextSysEvents()
    else
        StartTimes()
        NoteDurations()
        CCEvents()
        TextSysEvents()
    end
    reaper.MIDIEditor_LastFocused_OnCommand(40681,0) -- Options: Correct overlapping notes while editing
    reaper.MIDI_Sort(take)
    reaper.Undo_EndBlock(title, -1)
end

function CheckForNewVersion(new_version)
    local app_version = reaper.GetAppVersion()
    app_version = tonumber(app_version:match('[%d%.]+'))
    if new_version > app_version then
      reaper.MB('Update REAPER to newer version '..'('..new_version..' or newer)', '', 0)
      return
     else
      return true
    end
end

local CFNV = CheckForNewVersion(6.03)
if CFNV then Main() end
reaper.UpdateArrange()
reaper.SN_FocusMIDIEditor()
reaper.defer(Main)