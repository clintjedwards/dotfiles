-- Plays random fixed-length clips from a list of files. Started by the
-- mpv-sampler script, which passes in the list(s) to read with --script-opts.
-- Each list line is "path|duration in seconds".
--
--   f, F   new shuffled playlist with one clip from every file in the library
--   r      new random start point for the current file
--   c      clear the playlist
--   ENTER / RIGHT   next clip
--   LEFT            previous clip
--   UP / DOWN       seek 60s forward / back within the clip

local sample_duration = 200
local default_image_duration = 30
local image_exts = { jpg = true, jpeg = true, png = true, webp = true, gif = true, bmp = true }

local library_path = mp.get_opt("sampler-library")
local mix_path = mp.get_opt("sampler-mix")

-- path -> duration for whatever list was loaded last, so reroll knows how long
-- the source file really is (the playing EDL only knows the clip length).
local durations = {}

math.randomseed(os.time())

local function read_list(path)
    local f = path and io.open(path, "r")
    if not f then
        mp.osd_message("Sampler: can't read " .. tostring(path) .. ". Run 'mpv-sampler update'.", 5)
        return {}
    end
    local items = {}
    durations = {}
    for line in f:lines() do
        -- Split on the last pipe, in case a filename has one in it.
        local p, d = line:match("^(.*)|([^|]*)$")
        local duration = tonumber(d)
        if p and duration then
            table.insert(items, { path = p, duration = duration })
            durations[p] = duration
        end
    end
    f:close()
    return items
end

local function is_image(path)
    local ext = path:lower():match("%.([^%./]+)$")
    return ext ~= nil and image_exts[ext] == true
end

-- An EDL entry plays just one slice of a file. The %len% prefix lets the path
-- contain commas. The clip length is capped at what's actually left in the
-- file, because an EDL entry that claims more than the source has freezes at
-- the end instead of moving on to the next clip.
local function clip_uri(path, duration)
    local start, length = 0, sample_duration
    if is_image(path) then
        length = duration or default_image_duration
    else
        duration = duration or 0
        if duration > sample_duration then
            start = math.floor(math.random() * (duration - sample_duration))
        elseif duration > 0 then
            length = math.floor(duration)
        end
    end
    return string.format("edl://%%%d%%%s,%d,%d", #path, path, start, length)
end

-- Undo clip_uri; returns the source file path of a playlist entry.
local function source_path(uri)
    local len, rest = uri:match("^edl://%%(%d+)%%(.*)$")
    if len then
        return rest:sub(1, tonumber(len))
    end
    return uri
end

local function load_samples(items)
    if #items == 0 then
        return
    end

    -- Fisher-Yates shuffle.
    for i = #items, 2, -1 do
        local j = math.random(i)
        items[i], items[j] = items[j], items[i]
    end

    -- The first clip replaces the whole playlist. playlist-clear would keep
    -- whatever is playing right now, leaving a stray clip at the front.
    for i, item in ipairs(items) do
        mp.commandv("loadfile", clip_uri(item.path, item.duration), i == 1 and "replace" or "append")
    end
    mp.set_property_bool("pause", false)
    mp.osd_message("Sampler: loaded " .. #items .. " clips", 3)
end

local function reroll_current()
    local uri = mp.get_property("path")
    local pos = mp.get_property_number("playlist-pos")
    if not uri or not pos or pos < 0 then
        return
    end

    local path = source_path(uri)
    local duration = durations[path] or 0
    if is_image(path) or duration <= sample_duration then
        mp.osd_message("Too short to reroll (" .. math.floor(duration) .. "s)")
        return
    end

    -- Put the new clip in the current slot, play it, then drop the old one,
    -- which has been pushed down to pos + 1.
    mp.commandv("loadfile", clip_uri(path, duration), "insert-at", pos)
    mp.commandv("playlist-play-index", pos)
    mp.commandv("playlist-remove", pos + 1)
    mp.osd_message("Rerolled", 1)
end

-- Each entry is a fixed-length EDL clip, so a plain "seek 60" can ask for a
-- point past the end of the clip and hang instead of reaching EOF. Move to
-- the next or previous clip instead when the seek would leave this one.
local function bounded_seek(amount)
    local pos = mp.get_property_number("time-pos", 0)
    local dur = mp.get_property_number("duration", sample_duration)
    local target = pos + amount

    if target >= dur - 0.5 then
        mp.command("playlist-next")
    elseif target < 0 then
        mp.command("playlist-prev")
    else
        mp.commandv("seek", amount, "relative")
    end
end

local function feed_all()
    load_samples(read_list(library_path))
end

mp.add_key_binding("f", "sampler-feed", feed_all)
mp.add_key_binding("F", "sampler-feed-all", feed_all)
mp.add_key_binding("r", "sampler-reroll", reroll_current)
mp.add_key_binding("c", "sampler-clear", function() mp.command("playlist-clear") end)
mp.add_key_binding("SPACE", "sampler-pause", function() mp.command("cycle pause") end)
mp.add_key_binding("ENTER", "sampler-next", function() mp.command("playlist-next") end)
mp.add_key_binding("RIGHT", "sampler-next-key", function() mp.command("playlist-next") end)
mp.add_key_binding("LEFT", "sampler-prev-key", function() mp.command("playlist-prev") end)
mp.add_key_binding("UP", "sampler-seek-fwd", function() bounded_seek(60) end)
mp.add_key_binding("DOWN", "sampler-seek-back", function() bounded_seek(-60) end)

-- Start playing right away: the mix if one was given, otherwise the library.
if mix_path and mix_path ~= "" then
    load_samples(read_list(mix_path))
else
    feed_all()
end
