-- Settings
-- Display numbers follow hs.screen.allScreens(); UUID strings also work.
-- Desktop numbers count regular Spaces only, excluding fullscreen apps.
-- Three connected displays use docked mode; fewer use the laptop display.
local modes = {
    docked = {
        browser = {display = 1, desktop = 1}, chat = {desktop = 2},
        code = {display = 1, desktop = 3}, calendar = {display = 2, desktop = 1},
        muse = {display = 3}, twitch = {display = 2}, terminal = {},
    },
    laptop = {
        browser = {desktop = 1}, chat = {desktop = 2},
        code = {desktop = 5}, calendar = {desktop = 4}, muse = {desktop = 3}, twitch = {}, terminal = {},
    },
}
local REMINDERS_MIN_WIDTH = 260
local POLL_INTERVAL = 0.1
local LAUNCH_TIMEOUT = 15
local MOVE_TIMEOUT = 10
local FIREFOX_PATH = "/Applications/Firefox.app/Contents/MacOS/firefox"
-- Compatibility helper for background Space transfers on macOS Tahoe.
local loadBridge = package.loadlib(hs.configdir .. "/layout_spaces_bridge.so", "luaopen_layout_spaces_bridge")
local spaceBridge = loadBridge and loadBridge()

-- Layouts
-- Rectangles use screen fractions: x, y, width, height.
-- Bundle IDs select native apps without matching browser window titles.
-- No display means the current display. The latest layout takes focus after placement.
-- Firefox URLs are used for new layout windows; reused windows keep their tabs.
local layouts = {
    browser = {key = "H", windows = {
        {name = "Firefox", bundleID = "org.mozilla.firefox", rect = {x = 0.25, y = 0, w = 0.5, h = 1}, urls = {
            "https://mail.google.com/mail/u/2/",
            "https://mail.google.com/mail/u/0/#inbox",
            "https://news.ycombinator.com/",
        }},
    }},
    chat = {key = "J", windows = {
        {name = "Slack", bundleID = "com.tinyspeck.slackmacgap", rect = {x = 0, y = 0, w = 0.5, h = 1}},
        {name = "Messages", bundleID = "com.apple.MobileSMS", rect = {x = 0.5, y = 0.5, w = 0.5, h = 0.5}},
        {name = "WhatsApp", bundleID = "net.whatsapp.WhatsApp", rect = {x = 0.5, y = 0, w = 0.5, h = 0.5}},
        {name = "Telegram", bundleID = "ru.keepcoder.Telegram", rect = {x = 0.5, y = 0, w = 0.5, h = 0.5}},
        {name = "Signal", bundleID = "org.whispersystems.signal-desktop", rect = {x = 0.5, y = 0, w = 0.5, h = 0.5}},
    }},
    code = {key = "K", windows = {
        {name = "Zed", bundleID = "dev.zed.Zed", rect = {x = 0, y = 0, w = 2/3, h = 1}},
        {name = "ChatGPT", bundleID = "com.openai.codex", rect = {x = 1/3, y = 0, w = 2/3, h = 1}},
    }},
    calendar = {key = "L", windows = {
        {name = "Calendar", bundleID = "com.apple.iCal", rect = {x = 0, y = 0, w = 1, h = 1}},
        {name = "Reminders", bundleID = "com.apple.reminders", minWidth = REMINDERS_MIN_WIDTH},
    }},
    muse = {key = ";", windows = {
        {name = "Muse", bundleID = "com.meta.endo", laptopRect = {x = 0, y = 0, w = 0.5, h = 1}, rect = {x = 0, y = 0, w = 1, h = 0.5}},
        {name = "Claude", bundleID = "com.anthropic.claudefordesktop", laptopRect = {x = 0.5, y = 0, w = 0.5, h = 1}, rect = {x = 0, y = 0.5, w = 1, h = 0.5}},
    }},
    twitch = {key = "'", windows = {
        {name = "Firefox", bundleID = "org.mozilla.firefox", fullscreen = true, urls = {"https://www.twitch.tv/"}},
    }},
    terminal = {key = "N", windows = {
        {name = "Ghostty", bundleID = "com.mitchellh.ghostty", fullscreen = true, newWindow = true},
    }},
}

-- Screen and window lookup
local function getScreen(display)
    if not display then return hs.screen.mainScreen() end
    if type(display) == "number" then return hs.screen.allScreens()[display] end
    return hs.screen.find(display)
end

local function getDesktopSpace(screen, desktop)
    local spaces, err = hs.spaces.spacesForScreen(screen)
    if not spaces then return nil, err end
    local count = 0
    for _, space in ipairs(spaces) do
        if hs.spaces.spaceType(space) == "user" then
            count = count + 1
            if count == desktop then return space end
        end
    end
    return nil, nil, count
end

-- Use installed application paths, never a browser tab title or an app-name search.
local appPaths = {
    ["org.mozilla.firefox"] = "/Applications/Firefox.app",
    ["com.tinyspeck.slackmacgap"] = "/Applications/Slack.app",
    ["com.apple.MobileSMS"] = "/System/Applications/Messages.app",
    ["net.whatsapp.WhatsApp"] = "/Applications/WhatsApp.app",
    ["ru.keepcoder.Telegram"] = "/Applications/Telegram.app",
    ["org.whispersystems.signal-desktop"] = "/Applications/Signal.app",
    ["com.meta.endo"] = "/Applications/Muse.app",
    ["com.anthropic.claudefordesktop"] = "/Applications/Claude.app",
    ["com.apple.iCal"] = "/System/Applications/Calendar.app",
    ["com.apple.reminders"] = "/System/Applications/Reminders.app",
    ["dev.zed.Zed"] = "/Applications/Zed.app",
    ["com.openai.codex"] = "/Applications/ChatGPT.app",
    ["com.mitchellh.ghostty"] = "/Applications/Ghostty.app",
}

local function runningApp(item)
    for _, app in ipairs(hs.application.applicationsForBundleID(item.bundleID)) do
        if app:path() == appPaths[item.bundleID] then return app end
    end
end

-- Muse starts Chrome for its browser integration; preserve any existing Chrome session.
local function closeChromeAfterMuseLaunch(item)
    if item.chromeTimer then return end
    local deadline = hs.timer.secondsSinceEpoch() + LAUNCH_TIMEOUT
    item.chromeTimer = hs.timer.doEvery(POLL_INTERVAL, function()
        if item.launchError or hs.timer.secondsSinceEpoch() >= deadline then
            item.chromeTimer:stop()
            item.chromeTimer = nil
            return
        end
        if not runningApp(item) then return end
        local chrome = hs.application.applicationsForBundleID("com.google.Chrome")[1]
        if chrome then
            chrome:kill() -- Request a normal quit, never force termination.
            item.chromeTimer:stop()
            item.chromeTimer = nil
        end
    end)
end

local function launchApp(item)
    item.launchError = nil
    if runningApp(item) then return true end
    if item.launchTask then return true end
    local closeChrome = item.bundleID == "com.meta.endo" and #hs.application.applicationsForBundleID("com.google.Chrome") == 0
    local path = appPaths[item.bundleID]
    print("Layouts: launching " .. path)
    item.launchTask = hs.task.new("/usr/bin/open", function(code)
        item.launchTask = nil
        if code ~= 0 then item.launchError = "Could not open application (exit " .. tostring(code) .. ")." end
    end, function() return true end, {"-g", "-a", path})
    if item.launchTask and item.launchTask:start() then
        if closeChrome then closeChromeAfterMuseLaunch(item) end
        return true
    end
    item.launchTask = nil
    return false
end

local function appWindows(item)
    local windows, known, app = {}, {}, runningApp(item)
    if not app then return windows, known end
    local candidates = app:allWindows()
    if app:mainWindow() then table.insert(candidates, 1, app:mainWindow()) end
    for _, win in ipairs(candidates) do
        local id = win:id()
        if type(id) == "number" and id > 0 and win:isStandard() and not known[id] then
            known[id] = true
            if #(hs.spaces.windowSpaces(win) or {}) > 0 then table.insert(windows, win) end
        end
    end
    return windows, known
end

-- Include windows on inactive desktops when identifying a newly created window.
local function existingWindowIDs()
    local ids = {}
    for _, spaces in pairs(hs.spaces.allSpaces() or {}) do
        for _, space in ipairs(spaces) do
            for _, id in ipairs(hs.spaces.windowsForSpace(space) or {}) do ids[id] = true end
        end
    end
    return ids
end

local firefoxRequestOwner
local function ensureWindow(item)
    if item.launchError then return nil, item.launchError end
    local windows, known = appWindows(item)
    if item.newWindow then
        for _, win in ipairs(windows) do
            if not item.previousWindows[win:id()] then return win end
        end
        return nil
    end
    if not item.urls then return windows[1] end
    local cacheKey = "layout.firefox." .. (item.fullscreen and "twitch" or "browser")
    local saved = hs.settings.get(cacheKey)
    for _, win in ipairs(windows) do
        if win:id() == item.windowID or (saved and win:id() == saved.id and win:application():pid() == saved.pid) then return win end
    end
    if item.windowID and known[item.windowID] then return nil end
    if saved and known[saved.id] and runningApp(item):pid() == saved.pid then return nil end
    -- Reuse a matching window after a reload, preserving its existing tabs.
    if not item.request then
        for _, win in ipairs(windows) do
            local title = (win:title() or ""):lower()
            local matches = item.fullscreen and title:find("twitch", 1, true) or (not item.fullscreen and (title:find("gmail", 1, true) or title:find("hacker news", 1, true)))
            if matches then
                item.windowID = win:id()
                hs.settings.set(cacheKey, {id = win:id(), pid = win:application():pid()})
                return win
            end
        end
    end
    local now = hs.timer.secondsSinceEpoch()
    local pending = firefoxRequestOwner
    local owner = pending and pending.item or item
    local request = pending and pending.request or item.request
    if request then
        if request.error then
            firefoxRequestOwner = nil
            if owner == item then return nil, request.error end
        else
            -- Finish a cancelled layout's pending request before starting another Firefox window.
            local found
            for _, win in ipairs(windows) do
                if not request.before[win:id()] then
                    owner.windowID, owner.request, firefoxRequestOwner = win:id(), nil, nil
                    local ownerKey = "layout.firefox." .. (owner.fullscreen and "twitch" or "browser")
                    hs.settings.set(ownerKey, {id = win:id(), pid = win:application():pid()})
                    if owner == item then return win end
                    found = true
                    break
                end
            end
            if not found then
                if now >= request.deadline then
                    request.error = "Firefox did not provide a movable window."
                    firefoxRequestOwner = nil
                    return nil, request.error
                end
                return nil
            end
        end
    end
    request = {before = existingWindowIDs(), deadline = now + LAUNCH_TIMEOUT}
    for _, win in ipairs(windows) do request.before[win:id()] = true end
    item.request = request
    firefoxRequestOwner = {item = item, request = request}
    local args = #item.urls == 1 and {"--new-window", item.urls[1]} or item.urls
    local path = FIREFOX_PATH
    if not runningApp(item) then
        path = "/usr/bin/open"
        local browserArgs = args
        args = {"-g", "-a", appPaths[item.bundleID], "--args"}
        for _, argument in ipairs(browserArgs) do table.insert(args, argument) end
    end
    -- Firefox may activate itself when creating a new window; reusing one avoids this.
    print("Layouts: opening Firefox layout window")
    request.task = hs.task.new(path, function(code)
        if code ~= 0 then request.error = "Firefox launch failed: " .. tostring(code) end
    end, function() return true end, args)
    if not request.task or not request.task:start() then request.error = "Could not launch Firefox." end
    return nil, request.error
end

-- Shared waits keep the layout steps readable without blocking Hammerspoon.
local function waitFor(check, timeout, message)
    local deadline = hs.timer.secondsSinceEpoch() + timeout
    repeat
        local value, err = check()
        if err then error(err, 0) end
        if value then return value end
        if hs.timer.secondsSinceEpoch() >= deadline then error(message, 0) end
        coroutine.yield()
    until false
end

local function onScreen(win, screen)
    return win:screen() and win:screen():getUUID() == screen:getUUID()
end

local function onSpace(win, space)
    for _, id in ipairs(hs.spaces.windowSpaces(win) or {}) do
        if id == space then return true end
    end
    return false
end

local function regularSpace(win)
    for _, id in ipairs(hs.spaces.windowSpaces(win) or {}) do
        if hs.spaces.spaceType(id) == "user" then return id end
    end
end

local function moveToDisplay(win, screen)
    if not onScreen(win, screen) then
        -- Center first so minimum-size windows cannot straddle the display edge.
        win:centerOnScreen(screen, true, 0)
        waitFor(function() return onScreen(win, screen) and regularSpace(win) end, MOVE_TIMEOUT, "Window did not reach the display.")
    end
end

local function moveToDesktop(win, space)
    if space and not onSpace(win, space) then
        waitFor(function() return regularSpace(win) end, MOVE_TIMEOUT, "Window is not ready to change desktops.")
        local ok, err
        if spaceBridge and spaceBridge.available() then
            ok, err = spaceBridge.move(win:id(), space)
        else
            ok, err = hs.spaces.moveWindowToSpace(win, space)
        end
        if not ok then error(err or "Could not move window to desktop.", 0) end
        -- Check the actual destination: macOS may report success without moving it.
        waitFor(function() return onSpace(win, space) end, MOVE_TIMEOUT, "macOS did not move the window to the requested desktop.")
    end
end

local function fitWindow(win, item, screen, mode)
    if not item.minWidth then
        win:move(mode == "laptop" and item.laptopRect or item.rect, screen, true, 0)
        return
    end
    -- Reminders enforces its own minimum width. Anchor its actual right edge.
    local area = screen:frame()
    local resizedAt = hs.timer.secondsSinceEpoch()
    local retried, stableAt, width = false, nil, nil
    win:setSize({w = math.min(item.minWidth, area.w), h = area.h})
    waitFor(function()
        local now, frame = hs.timer.secondsSinceEpoch(), win:frame()
        if not retried and now - resizedAt >= 0.3 then
            win:setSize({w = math.min(item.minWidth, area.w), h = area.h})
            retried, resizedAt, stableAt = true, now, nil
        end
        if math.abs(frame.x + frame.w - area.x - area.w) >= 2 or math.abs(frame.y - area.y) >= 2 then
            win:setTopLeft({x = area.x + area.w - frame.w, y = area.y})
            stableAt = nil
        end
        if width ~= frame.w then stableAt = nil end
        width, stableAt = frame.w, stableAt or now
        return now - resizedAt >= 0.7 and now - stableAt >= 0.2 and math.abs(frame.h - area.h) < 2
    end, MOVE_TIMEOUT, "Reminders did not finish resizing.")
end

-- Step 1: start missing apps in the background. Running apps are never reopened.
local function spawnApps(layout)
    local errors = {}
    for _, item in ipairs(layout.windows) do
        local now = hs.timer.secondsSinceEpoch()
        if item.request and (item.request.error or now >= item.request.deadline) then item.request = nil end
        local app = runningApp(item)
        if item.newWindow then
            local _, known = appWindows(item)
            item.previousWindows = existingWindowIDs()
            for id in pairs(known) do item.previousWindows[id] = true end
        end
        if item.newWindow and app then
            app:activate()
            if not app:selectMenuItem({"File", "New Window"}) then errors[item.name] = "Could not create a new window." end
        -- Firefox starts with its URLs in ensureWindow, avoiding a separate startup window.
        elseif not item.urls and not launchApp(item) then
            errors[item.name] = "Could not open application."
        end
    end
    return errors
end

-- Step 2: place windows before switching to the finished layout.
local function placeWindow(win, item, destination, mode)
    win:unminimize()
    win:application():unhide()
    local screen, space = destination.screen, destination.space
    if win:isFullScreen() and not (item.fullscreen and onScreen(win, screen)) then
        -- Native fullscreen transitions can switch Spaces independently of this script.
        win:setFullScreen(false)
        waitFor(function() return not win:isFullScreen() and regularSpace(win) end, MOVE_TIMEOUT, "Window did not leave fullscreen.")
    end
    if not win:isFullScreen() then
        local source = (hs.spaces.windowSpaces(win) or {})[1]
        if source and hs.spaces.spaceType(source) == "fullscreen" then error("Leave Split View first.", 0) end
        moveToDisplay(win, screen)
        if not item.fullscreen then fitWindow(win, item, screen, mode) end
        moveToDesktop(win, space)
        if item.fullscreen then win:setFullScreen(true) end
    end
    if item.fullscreen then
        waitFor(function()
            for _, id in ipairs(hs.spaces.windowSpaces(win) or {}) do
                if win:isFullScreen() and hs.spaces.spaceType(id) == "fullscreen" and onScreen(win, screen) then return true end
            end
        end, MOVE_TIMEOUT, "Window did not finish entering fullscreen.")
    end
    return win
end

local function placeWindows(layout, destination, mode, errors)
    local tasks, issues, windows = {}, {}, {}
    for index, item in ipairs(layout.windows) do
        tasks[index] = coroutine.create(function()
            if errors[item.name] then error(errors[item.name], 0) end
            local win = waitFor(function() return ensureWindow(item) end, LAUNCH_TIMEOUT, "No application window became available.")
            return placeWindow(win, item, destination, mode)
        end)
    end
    -- Ready windows move immediately while other apps are still opening.
    local remaining = #tasks
    while remaining > 0 do
        for index, item in ipairs(layout.windows) do
            local task = tasks[index]
            if task then
                local ok, result = coroutine.resume(task)
                if not ok or coroutine.status(task) == "dead" then
                    if ok then windows[index] = result else table.insert(issues, item.name .. ": " .. tostring(result)) end
                    tasks[index], remaining = nil, remaining - 1
                end
            end
        end
        if remaining > 0 then coroutine.yield() end
    end
    return issues, windows
end

local pendingSpaceSwitch
local function focusLayout(layout, destination, windows)
    local primary
    for index in ipairs(layout.windows) do
        if windows[index] then primary = windows[index]; break end
    end
    if not primary then return end
    -- A cancelled layout may already have asked macOS to switch Spaces.
    if pendingSpaceSwitch then
        local pending = pendingSpaceSwitch
        waitFor(function()
            return hs.spaces.activeSpaceOnScreen(pending.screen) == pending.space or hs.timer.secondsSinceEpoch() >= pending.deadline
        end, MOVE_TIMEOUT, "The previous desktop switch did not settle.")
        pendingSpaceSwitch = nil
    end
    local space = destination.space or (hs.spaces.windowSpaces(primary) or {})[1]
    if not space then error("The layout window has no desktop to focus.", 0) end
    if hs.spaces.activeSpaceOnScreen(destination.screen) ~= space then
        local ok, err = hs.spaces.gotoSpace(space)
        if not ok then error(err or "Could not switch to the layout desktop.", 0) end
        pendingSpaceSwitch = {screen = destination.screen, space = space, deadline = hs.timer.secondsSinceEpoch() + MOVE_TIMEOUT}
        waitFor(function() return hs.spaces.activeSpaceOnScreen(destination.screen) == space end, MOVE_TIMEOUT, "The layout desktop did not become active.")
        pendingSpaceSwitch = nil
    end
    primary:focus()
    waitFor(function()
        local focused = hs.window.focusedWindow()
        return focused and focused:id() == primary:id()
    end, MOVE_TIMEOUT, "The layout window did not take focus.")
    -- Keep secondary windows, including the narrow Reminders overlay, visible.
    for index in ipairs(layout.windows) do
        local win = windows[index]
        if win and win:id() ~= primary:id() then win:raise() end
    end
end

local selectedMode = "automatic"
local function currentMode()
    if selectedMode ~= "automatic" then return selectedMode end
    return #hs.screen.allScreens() >= 3 and "docked" or "laptop"
end

local function destinationFor(layout, mode)
    local target = modes[mode][layout.name]
    local screen = getScreen(target.display)
    if mode == "laptop" then screen = hs.screen.find("Built-in") or hs.screen.find("Color LCD") or hs.screen.allScreens()[1] end
    if not screen then error("Configured display is not connected.", 0) end
    local space
    if not target.desktop and not layout.windows[1].fullscreen then
        space = hs.spaces.activeSpaceOnScreen(screen)
        if hs.spaces.spaceType(space) ~= "user" then space = getDesktopSpace(screen, 1) end
    end
    return {screen = screen, desktop = target.desktop, space = space}
end

local function prepareDesktop(destination)
    if not destination.desktop then return end
    local screen, number = destination.screen, destination.desktop
    local space, err, count = getDesktopSpace(screen, number)
    if err then error(err, 0) end
    while not space do
        local ok, createErr = hs.spaces.addSpaceToScreen(screen)
        if not ok then error(createErr or "Could not create desktop.", 0) end
        local previous = count
        waitFor(function()
            space, err, count = getDesktopSpace(screen, number)
            return space or (count and count > previous), err
        end, MOVE_TIMEOUT, "New desktop did not appear.")
    end
    destination.space = space
end

local layoutTimer
local function openLayout(layout)
    -- Cancel the previous layout, including any pending final focus.
    if layoutTimer then layoutTimer:stop(); layoutTimer = nil end
    if not hs.accessibilityState(false) then hs.alert.show("Enable Hammerspoon in System Settings > Privacy & Security > Accessibility."); return end
    local mode = currentMode()
    print("Layouts: " .. layout.name .. " [" .. mode .. "]")
    -- Capture the target once, before starting asynchronous work.
    local ok, destination = pcall(destinationFor, layout, mode)
    if not ok then hs.alert.show(destination); return end
    local task = coroutine.create(function()
        local errors = spawnApps(layout)
        prepareDesktop(destination)
        local issues, windows = placeWindows(layout, destination, mode, errors)
        if #issues > 0 then hs.alert.show(table.concat(issues, "\n")) end
        focusLayout(layout, destination, windows)
    end)
    layoutTimer = hs.timer.doEvery(POLL_INTERVAL, function()
        local resumed, err = coroutine.resume(task)
        if not resumed or coroutine.status(task) == "dead" then
            layoutTimer:stop()
            layoutTimer = nil
            if not resumed then hs.alert.show(tostring(err)) end
        end
    end)
end

-- Shortcuts: browser H, chat J, Zed/ChatGPT K, Calendar/Reminders L, Muse/Claude ;, Twitch ', Ghostty N.
for name, layout in pairs(layouts) do
    layout.name = name
    if layout.key then hs.hotkey.bind({"ctrl", "alt", "cmd"}, layout.key, function() openLayout(layout) end) end
end

-- Keep the menu object alive for the lifetime of this configuration.
layoutMenu = hs.menubar.new()
if layoutMenu then
    layoutMenu:setTitle("Layouts")
    layoutMenu:setMenu(function()
        local modeName = currentMode() == "docked" and "Docked" or "Laptop"
        local menu = {{title = "Current mode: " .. modeName, disabled = true}}
        for _, choice in ipairs({"Automatic", "Docked", "Laptop"}) do
            local value = choice:lower()
            table.insert(menu, {title = choice, checked = selectedMode == value, fn = function() selectedMode = value end})
        end
        table.insert(menu, {title = "-"})
        for _, item in ipairs({
            {"browser", "Firefox mail + news"},
            {"chat", "Chat apps"},
            {"code", "Zed + ChatGPT"},
            {"calendar", "Calendar + Reminders"},
            {"muse", "Muse + Claude"},
            {"twitch", "Twitch fullscreen"},
            {"terminal", "New Ghostty fullscreen"},
        }) do
            local layout = layouts[item[1]]
            table.insert(menu, {title = item[2] .. "  (⌃⌥⌘" .. layout.key .. ")", fn = function() openLayout(layout) end})
        end
        return menu
    end)
end

-- Optional startup layout; leave commented to keep reloads quiet.
-- openLayout(layouts.chat)
