-- Shift+U, then y to confirm, uploads the file that's playing to weow, using
-- the same upload-to-weow script as thunar's right-click action. Linked into
-- ~/.config/mpv/scripts, so it works in every mpv window, sampler or not.

local utils = require("mp.utils")

-- mpv may have been started from a launcher that doesn't have ~/.bin on PATH.
local uploader = os.getenv("HOME") .. "/.bin/upload-to-weow"

-- How long the confirmation prompt waits for y before giving up.
local confirm_seconds = 10
local pending = nil

-- The sampler plays slices of files as "edl://%<length>%<path>,start,length";
-- pull the real path back out of those.
local function source_path(path)
    local len, rest = path:match("^edl://%%(%d+)%%(.*)$")
    if len then
        return rest:sub(1, tonumber(len))
    end
    return path
end

local function upload(path)
    mp.osd_message("Uploading to weow...", 30)
    -- Async, because a big file over the network can take a while and mpv
    -- should keep playing meanwhile. The script prints its result on stderr.
    mp.command_native_async({
        name = "subprocess",
        args = { uploader, path },
        capture_stderr = true,
        playback_only = false,
    }, function(_, result)
        local msg = result and result.stderr and result.stderr:gsub("%s+$", "") or ""
        if msg == "" then
            msg = "upload-to-weow failed to run"
        end
        mp.msg.info(msg)
        mp.osd_message("Upload to weow: " .. msg, 4)
    end)
end

-- Drops the temporary y/n keys and the timeout, if a prompt is open.
local function close_prompt()
    if pending then
        pending:kill()
        pending = nil
    end
    mp.remove_key_binding("upload-to-weow-yes")
    mp.remove_key_binding("upload-to-weow-no")
end

-- Asks before uploading, so a stray keypress can't send anything. The path is
-- captured now, so if the clip changes before you answer, the file named in
-- the prompt is still the one that gets uploaded.
local function prompt()
    close_prompt()

    local path = mp.get_property("path")
    if not path then
        return
    end
    path = utils.join_path(mp.get_property("working-directory"), source_path(path))

    local info = utils.file_info(path)
    if not info or not info.is_file then
        mp.osd_message("Upload to weow: not a local file", 3)
        return
    end

    local name = path:match("([^/]+)$")
    mp.osd_message(string.format("Upload %s to weow?\ny to upload, n to cancel (%ds)", name, confirm_seconds),
        confirm_seconds)

    -- Forced so y and n win over any other binding for as long as the prompt is up.
    mp.add_forced_key_binding("y", "upload-to-weow-yes", function()
        close_prompt()
        upload(path)
    end)
    mp.add_forced_key_binding("n", "upload-to-weow-no", function()
        close_prompt()
        mp.osd_message("Upload cancelled", 2)
    end)
    pending = mp.add_timeout(confirm_seconds, function()
        close_prompt()
        mp.osd_message("Upload cancelled", 2)
    end)
end

mp.add_key_binding("U", "upload-to-weow", prompt)
