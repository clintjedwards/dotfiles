-- Used by `mpv-sampler watch`. The playlist is the saved watch order, started
-- at the saved position, so playlist-pos is the index into that order. This
-- writes down which index to start from next time:
--   - the file that's playing, so quitting halfway resumes it
--   - the one after it, once a file plays to the end
-- Skipping ahead with > or Enter counts too, since the next file loading
-- saves its own index.

local position_file = mp.get_opt("watch-position")
local current = nil

local function save(index)
    local f = io.open(position_file, "w")
    if f then
        f:write(index, "\n")
        f:close()
    end
end

mp.register_event("file-loaded", function()
    current = mp.get_property_number("playlist-pos")
    save(current)
    mp.osd_message(string.format("%d of %d", current + 1, mp.get_property_number("playlist-count")), 3)
end)

mp.register_event("end-file", function(event)
    if event.reason == "eof" and current then
        save(current + 1)
    end
end)
