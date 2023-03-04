-- @description Switch Media Explorer Shortcut
-- @version 1.0.1
-- @author zaibuyidao
-- @changelog Initial release
-- @links
--   webpage https://www.soundengine.cn/user/%E5%86%8D%E8%A3%9C%E4%B8%80%E5%88%80
--   repo https://github.com/zaibuyidao/ReaScripts
-- @donate http://www.paypal.me/zaibuyidao
-- @about Requires JS_ReaScriptAPI & SWS Extension

function print(...)
  local args = {...}
  local str = ""
  for i = 1, #args do
    str = str .. tostring(args[i]) .. "\t"
  end
  reaper.ShowConsoleMsg(str .. "\n")
end

if not reaper.BR_GetCurrentTheme then
  local retval = reaper.ShowMessageBox("This script requires the SWS Extension.\n該脚本需要 SWS 擴展。\n\nDo you want to download it now? \n你想現在就下載它嗎？", "Warning 警告", 1)
  if retval == 1 then
    if not OS then local OS = reaper.GetOS() end
    if OS=="OSX32" or OS=="OSX64" then
      os.execute("open " .. "http://www.sws-extension.org/download/pre-release/")
    else
      os.execute("start " .. "http://www.sws-extension.org/download/pre-release/")
    end
  end
  return
end

if not reaper.APIExists("JS_Localize") then
  reaper.MB("Please right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'.\n請右鍵單擊並安裝 'js_ReaScriptAPI: API functions for ReaScripts'。\n\nThen restart REAPER and run the script again, thank you!\n然後重新啟動 REAPER 並再次運行腳本，謝謝！\n", "You must install JS_ReaScriptAPI 你必須安裝JS_ReaScriptAPI", 0)
  local ok, err = reaper.ReaPack_AddSetRepository("ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1)
  if ok then
    reaper.ReaPack_BrowsePackages("js_ReaScriptAPI")
  else
    reaper.MB(err, "錯誤", 0)
  end
  return reaper.defer(function() end)
end

function getSystemLanguage()
  local locale = tonumber(string.match(os.setlocale(), "(%d+)$"))
  local os = reaper.GetOS()
  local lang

  if os == "Win32" or os == "Win64" then -- Windows
    if locale == 936 then -- Simplified Chinese
      lang = "简体中文"
    elseif locale == 950 then -- Traditional Chinese
      lang = "繁體中文"
    else -- English
      lang = "English"
    end
  elseif os == "OSX32" or os == "OSX64" then -- macOS
    local handle = io.popen("/usr/bin/defaults read -g AppleLocale")
    local result = handle:read("*a")
    handle:close()
    lang = result:gsub("_", "-"):match("[a-z]+%-[A-Z]+")
    if lang == "zh-CN" then -- 简体中文
      lang = "简体中文"
    elseif lang == "zh-TW" then -- 繁体中文
      lang = "繁體中文"
    else -- English
      lang = "English"
    end
  elseif os == "Linux" then -- Linux
    local handle = io.popen("echo $LANG")
    local result = handle:read("*a")
    handle:close()
    lang = result:gsub("%\n", ""):match("[a-z]+%-[A-Z]+")
    if lang == "zh_CN" then -- 简体中文
      lang = "简体中文"
    elseif lang == "zh_TW" then -- 繁體中文
      lang = "繁體中文"
    else -- English
      lang = "English"
    end
  end

  return lang
end

function normalize_path(path)
  local os_name = reaper.GetOS()
  local separator = "/"
  if os_name == "Win32" or os_name == "Win64" then
    separator = "\\"
  end
  return string.gsub(path, "[/\\]", separator)-- .. separator
end

function replace_invalid_chars(path)
  local new_path = string.gsub(path, "[\\/:*?\"<>|%s]+", "_")
  new_path = string.gsub(new_path, "_([%.%s])", "%1") -- 移除下划线后面的点号或空格
  new_path = string.gsub(new_path, "^%s+|_+$", "") -- 移除开头和结尾的空格和下划线
  return new_path
end

-- https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-char
local function PostText(hwnd, str)
  for char in string.gmatch(str, ".") do
    local ret = reaper.JS_WindowMessage_Post(hwnd, "WM_CHAR", string.byte(char),0,0,0)
    if not ret then break end
  end
end

function escape_if_needed(str)
  -- 检测字符串中是否包含需要转义的字符
  if string.match(str, "[\\]") then
    -- 如果包含，则进行转义
    str = string.gsub(str, "\\", "\\\\")
  end
  return str
end

function create_explorer_path(get_path)
  local language = getSystemLanguage()
  local new_path = ""
  local chortcut = ""

  if language == "简体中文" then
    str = "切换快捷方式 - "
    uok, uinput = reaper.GetUserInputs("创建一个切换快捷方式的动作", 2, "脚本路径:,脚本別名:,extrawidth=200", get_path .. new_path .. "," .. str .. chortcut)
  elseif language == "繁体中文" then
    str = "切換快捷方式 - "
    uok, uinput = reaper.GetUserInputs("創建一個切換快捷方式的動作", 2, "脚本路徑:,脚本別名:,extrawidth=200", get_path .. new_path .. "," .. str .. chortcut)
  else
    str = "Switch shortcut - "
    uok, uinput = reaper.GetUserInputs("Create an action to switch shortcut", 2, "Script path:,Script alias:,extrawidth=200", get_path .. new_path .. "," .. str .. chortcut)
  end

  if not uok or uinput == "" then return end

  get_path, chortcut = string.match(uinput, "(.*),(.*)")
  if chortcut == "" then return end
  if not get_path then return end

  get_path = normalize_path(get_path .. new_path)
  -- 创建新文件夹
  reaper.RecursiveCreateDirectory(get_path, 0)

  local pattern = str:gsub("%-", "%%-") .. "%s-"
  local origin_shortcut = string.gsub(chortcut, pattern, "") -- 或 local origin_shortcut = string.gsub(chortcut, str, "") --"Switch Explorer Path%s-[-]%s*", "")
  if origin_shortcut == "" then return end
  local file_path = get_path .. "" .. str .. replace_invalid_chars(origin_shortcut) .. ".lua"
  local file, err = io.open(file_path , "w+")
  
  if not file then
    local err_msg
    if language == "简体中文" then
      err_msg = "不能创建文件:\n" .. file_path .. "\n\n错误: " .. tostring(err)
      reaper.ShowMessageBox(err_msg, "见鬼了: ", 0)
    elseif language == "繁体中文" then
      err_msg = "不能創建文件:\n" .. file_path .. "\n\n錯誤: " .. tostring(err)
      reaper.ShowMessageBox(err_msg, "見鬼了: ", 0)
    else
      err_msg = "Couldn't create file:\n" .. file_path .. "\n\nError: " .. tostring(err)
      reaper.ShowMessageBox(err_msg, "Whoops", 0)
    end
    return
  end

  file:write([[
function PostKey(hwnd, vk_code) -- https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
  reaper.JS_WindowMessage_Post(hwnd, "WM_KEYDOWN", vk_code, 0,0,0)
  reaper.JS_WindowMessage_Post(hwnd, "WM_KEYUP", vk_code, 0,0,0)
end

function PostText(hwnd, str) -- https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-char
  for char in string.gmatch(str, ".") do
    ret = reaper.JS_WindowMessage_Post(hwnd, "WM_CHAR", string.byte(char),0,0,0)
    if not ret then break end
  end
end

function SetExplorerPath(hwnd, folder)
  local cbo = reaper.JS_Window_FindChildByID(hwnd, 0x3EA)
  local edit = reaper.JS_Window_FindChildByID(cbo, 0x3E9)
  if edit then
    reaper.JS_Window_SetTitle(edit, "")
    PostText(edit, folder)
    PostKey(edit, 0xD) -- post Return key
  end
end

function set_reaper_explorer_path(f)
  SetExplorerPath(reaper.JS_Window_Find("Media Explorer", true), f)
end

set_reaper_explorer_path("]] .. escape_if_needed(origin_shortcut) .. [[")
]])
  if language == "简体中文" then
    reaper.ShowMessageBox("成功创建文件:\n" .. (string.len(file_path) > 64 and ( "..." .. string.sub(file_path, -56) ) or file_path), "非常好!", 0)
  elseif language == "繁体中文" then
    reaper.ShowMessageBox("成功創建文件:\n" .. (string.len(file_path) > 64 and ( "..." .. string.sub(file_path, -56) ) or file_path), "非常好!", 0)
  else
    reaper.ShowMessageBox("Successfully created file:\n" .. (string.len(file_path) > 64 and ( "..." .. string.sub(file_path, -56) ) or file_path), "Yes!", 0)
  end

  io.close(file)

  -- 0, Main
  -- 100, Main (alt recording)
  -- 32060, MIDI Editor
  -- 32061, MIDI Event List Editor
  -- 32062, MIDI Inline Editor
  -- 32063, Media Explorer
  reaper.AddRemoveReaScript(true, 32063, file_path, true)
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local script_path = debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]]
create_explorer_path(script_path)

reaper.Undo_EndBlock('Switch Media Explorer Shortcut', -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()