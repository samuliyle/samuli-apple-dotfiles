-- This script allows for quick navigation between applications. It
-- remembers which window was last focused so that you can switch
-- quickly back to that specific window.

local lastFocusedWindowByApp = {}

-- To determine the bundle IDs, run "codesign -dr - /Applications/FOO.app" or
-- osascript -e 'id of app "Finder"'
local mappings = {
    { { "cmd" }, "1", "com.brave.Browser" },
    { { "cmd" }, "2", "com.googlecode.iterm2" },
    { { "cmd" }, "3", "com.microsoft.VSCode" },
    { { "cmd" }, "4", "md.obsidian" },
    { { "cmd" }, "5", "net.ankiweb.dtop" },
    { { "cmd" }, "6", "io.mpv" },
    { { "cmd" }, "7", "com.apple.finder" }
}

for _, mapping in ipairs(mappings) do
    local mods = mapping[1]
    local key = mapping[2]
    local bundleId = mapping[3]

    print(string.format("Mapping %s+%s → %s", hs.inspect(mods), key, bundleId))

    hs.hotkey.bind(mods, key, function()
        activateApp(bundleId)
    end)
end

function activateApp(bundleId)
    -- (this only finds RUNNING applications)
    -- The second param is to only search for exact matches:
    -- https://www.hammerspoon.org/docs/hs.application.html#find
    local app = hs.application.find(bundleId, true)

    -- If the app isn't running, launch it.
    if app == nil then
        hs.application.launchOrFocusByBundleID(bundleId)
        return
    end

    -- If the app was already running but we weren't tracking a window,
    -- then focus the first window.
    lastFocusedWindow = lastFocusedWindowByApp[app:bundleID()]
    if lastFocusedWindow == nil then
        hs.application.launchOrFocusByBundleID(bundleId)
        return
    end

    -- Try to focus the last-focused window again. Due to race conditions,
    -- this can fail, so we retry in those situations.
    for i = 1, 3, 1
    do
        if i == 1 or app:focusedWindow():title() ~= lastFocusedWindow:title() then
            lastFocusedWindow:focus()
            lastFocusedWindow:raise()
        else
            return
        end
    end
end

-- Block ⌘H. It just annoys me.
hs.hotkey.bind({ "cmd" }, "H", function()
    hs.alert.show("Hammerspoon blocked ⌘H 🔥")
end)

function winFocused(w)
    if w == nil then return end

    local bundleID = w:application():bundleID()

    lastFocusedWindowByApp[bundleID] = w
end

-- There's a known issue where windowFocused just stops working:
-- https://github.com/Hammerspoon/hammerspoon/issues/3038
-- From what I've seen, this happens exactly 5 seconds into running
-- Hammerspoon, and it's fixed by just switching between applications
-- once or twice.
local subscriptions = {
    [hs.window.filter.windowFocused] = winFocused
}

windowFilter = hs.window.filter.new(nil, "my-log")
windowFilter:subscribe(subscriptions)
