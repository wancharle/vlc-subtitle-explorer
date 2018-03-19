--[[  Functions required by VLC  ]]--

local g_subtitles = {
    path = nil,
    loaded = false,
    currents = {}, -- indexes of current subtitles

    prev_time = nil, -- start time of previous subtitle
    begin_time = nil, -- start time of current subtitle
    end_time = nil, -- end time of current subtitle
    next_time = nil, -- next subtitle start time
    atual = 2,
    subtitles = {} -- contains all the subtitles
}

local sia_settings =
{
    charset = "iso-8859-1",          -- works for english and french subtitles (try also "Windows-1252")
    dict_dir = "/Users/wancharle/dicts",            -- where Stardict dictionaries are located
    wordnet_dir = "/Users/wancharle/dicts/wordnet", -- where WordNet files are located
    chosen_dict = "/Users/wancharle/dicts/Babylon_English_Portuguese", -- Stardict dictionary used by default (there should be 3 files with this name but different extensions)
    words_file_path = nil, -- if 'nil' then "Desktop/sia_words.txt" will be used
    always_show_subtitles = false,
    osd_position = "top",
    help_duration = 6, -- sec; change to nil to disable osd help
    log_enable = true, -- Logs can be viewed in the console (Ctrl-M)
    definition_separator = "<br />", -- separator used if multiple definitions are selected for saving

    key_prev_subt = 121, -- y
    key_next_subt = 117, -- u
    key_again = 8, -- backspace
    key_save = 105, -- i
}


function filter_html(str)
    local res = str or ""
    res = string.gsub(res, "&apos;", "'")
    res = string.gsub(res, "<.->", "")
    return res
end

function trim(str)
    if not str then return "" end
    return str:match("^%s*(.*%S)") or ""
end


function to_sec(h,m,s,ms)
    return tonumber(h)*3600 + tonumber(m)*60 + tonumber(s) + tonumber(ms)/1000
end


function read_file(path, binary)
    if is_nil_or_empty(path) then
        log("Can't open file: Path is empty")
        return nil
    end

    local f, msg = io.open(path, "r" .. (binary and "b" or ""))

    if not f then
        log("Can't open file '"..path.."': ".. (msg or "unknown error"))
        return nil
    end

    local res = f:read("*all")

    f:close()

    return res
end


function is_nil_or_empty(str)
    return not str or str == ""
end


function get_input_item()
    return vlc.input.item()
end



function descriptor()
    return {
        title = "Subtitle Explorer",
        version = "0.0.1";
        author = "wancharle",
        url = 'http://wancharle.com.br',
        shortdesc = "Navigate freely through the subtitle list and then sync your movie.",
        description = [[<html>
        How to use: Pause the video as you slide the caption. Browse through the list of Subtitles until you find the correct subtitle for the moment you stopped the video. Click the Sync button to synchronize. Wait a few seconds for the VLC to sync the caption.(I think this wait is a vlc bug: sometimes it takes a delay to start the video equal to or higher than the delay that you sync.)
</html>]],
        capabilities = {"menu"}
    }
end

function log(msg, ...)
        vlc.msg.dbg("[WANCHARLE] " .. tostring(msg), unpack(arg))
end


-- extension activated
function key_pressed_handler(var, old, new, data)
    --log("var: "..tostring(var).."; old: "..tostring(old).."; new: "..tostring(new).."; data: "..tostring(data))
    --key_prev_subt = 121, -- y
    --key_next_subt = 117, -- u
        loc("presionado")
end
function uri_to_path(uri, is_unix_platform)
    if is_nil_or_empty(uri) then return "" end
    local path
    if not is_unix_platform then
        if uri:match("file://[^/]") then -- path to windows share
            path = uri:gsub("file://", "\\\\")
        else
            path = uri:gsub("file:///", "")
        end
        return path:gsub("/", "\\")
    else
        return uri:gsub("file://", "")
    end
end


function get_subtitles_path()
    local item = get_input_item()
    if not item then return "" end

    local path_to_video = uri_to_path(vlc.strings.decode_uri(item:uri()), true)
    log(path_to_video)

    return path_to_video:gsub("[^.]*$", "") .. "srt"
end

function chaves(tab)
local keyset={}
local n=0

for k,v in pairs(tab) do
      n=n+1
        keyset[n]=k
        log(k)
        log(v[1])
        end

end

local atraso_id = nil
local caixa_id = nil
local msg_id = nil

function prox()
    g_subtitles.atual = g_subtitles.atual+1
    vlc.osd.message(g_subtitles:getText(),msg_id, "center", 2000000)
    vlc.osd.message(g_subtitles:getTime(),caixa_id, "left", 2000000)
end

function prev()
    if g_subtitles.atual > 0 then
    g_subtitles.atual = g_subtitles.atual-1
    vlc.osd.message(g_subtitles:getText(),msg_id, "center", 2000000)
    vlc.osd.message(g_subtitles:getTime(),caixa_id, "left", 2000000)
    end 

end
function sinc()
    log("ok")
    local input = vlc.object.input()
    local time = vlc.var.get(input, "time")
    local diff =  time - g_subtitles:getTime() 
    vlc.osd.message(diff,atraso_id, "right", 10000000)
    vlc.osd.message(g_subtitles:getText(),msg_id, "center", 2000000)
    vlc.osd.message(g_subtitles:getTime(),caixa_id, "left", 2000000)
    
    vlc.var.set(input, "spu-delay",diff) 
end

function activate()
   log("Activate")
local d = vlc.dialog( "Subtitle Explorer" )
    w2 = d:add_button(" << ",prev,1,1,1,1)
    w = d:add_button(" >> ",prox,2,1,1,1)
    w3 = d:add_button("synchronize",sinc,3,1,1,1)
    d:show()

    msg_id =  vlc.osd.channel_register()
    caixa_id =  vlc.osd.channel_register()
    atraso_id =  vlc.osd.channel_register()
    if vlc.object.input() then
        local loaded, msg = g_subtitles:load(get_subtitles_path())
        if not loaded then
            log(msg)
            return
        end
    end


   --vlc.var.add_callback(vlc.object.libvlc(), "key-pressed", key_pressed_handler, 0)
end

-- extension deactivated
function deactivate()
    log("Deactivate")

end

-- input changed (playback stopped, file changed)
function input_changed()

    log("adicionado filme")

end

-- main dialog window closed
function close()
    log("Close")
end
-- main dialog window closed
function close()
    log("Close")
end

-- menu items 
function menu()
    return {"Settings"}
end

-- a menu element is selected
function trigger_menu(id)
        log("Menu2 clicked")
end

function g_subtitles:load(spath)
    self.loaded = false

    if is_nil_or_empty(spath) then return false, "cant load subtitles: path is nil" end

    if spath == self.path then
        self.loaded = true
        return false, "cant load subtitles: already loaded"
    end

    self.path = spath

    local data = read_file(self.path)
    if not data then return false end
 
    data = data:gsub("\r\n", "\n") -- fixes issues with Linux
    local srt_pattern = "(%d%d):(%d%d):(%d%d),(%d%d%d) %-%-> (%d%d):(%d%d):(%d%d),(%d%d%d).-\n(.-)\n\n"
    for h1, m1, s1, ms1, h2, m2, s2, ms2, text in string.gmatch(data, srt_pattern) do
        if not is_nil_or_empty(text) then
            if sia_settings.charset then
                text = vlc.strings.from_charset(sia_settings.charset, text)
            end
            table.insert(self.subtitles, {to_sec(h1, m1, s1, ms1), to_sec(h2, m2, s2, ms2), text})
        end
    end

    if #self.subtitles==0 then return false, "cant load subtitles: could not parse" end

    self.loaded = true

    log("loaded subtitles: " .. self.path)

    return true
end

function g_subtitles:getText()
    local sub = self.subtitles[self.atual]
    return sub[3]
end

function g_subtitles:getTime()
    local sub = self.subtitles[self.atual]
    return sub[1]
end

-- works only if there is current subtitle!
function g_subtitles:get_previous()
    return filter_html(self.currents[1] and
        self.subtitles[self.currents[1]-1] and
        self.subtitles[self.currents[1]-1][3])
end

-- works only if there is current subtitle!
function g_subtitles:get_next()
    return filter_html(self.currents[#self.currents] and
        self.subtitles[self.currents[#self.currents]+1] and
        self.subtitles[self.currents[#self.currents]+1][3])
end

function g_subtitles:get_current()
    if #self.currents == 0 then return nil end

    local subtitle = ""
    for i = 1, #self.currents do
        subtitle = subtitle .. self.subtitles[self.currents[i]][3] .. "\n"
    end

    subtitle = subtitle:sub(1,-2) -- remove trailing \n
    subtitle = filter_html(subtitle)

    return subtitle 
end

-- returns false if time is withing current subtitle
function g_subtitles:move(time)
    if self.begin_time and self.end_time and self.begin_time <= time and time <= self.end_time then
        --log("same title")
        return false, self:get_current(), self.end_time-time
    end
    
    self:_fill_currents(time)

    --g_subtitles:log(time)

    return true, self:get_current(), self.end_time and self.end_time-time or 0
end

function g_subtitles:log(cur_time)
        log("________________________________________________")
        log("prev\tbegin\tcurr\tend\tnext")
        log(tostring(self.prev_time or "----").."\t"..tostring(self.begin_time or "----").."\t"..
                tostring(cur_time or "----").."\t"..tostring(self.end_time or "----")..
                "\t"..tostring(self.next_time or "----"))
        log("nesting: " .. #self.currents)
        log("titre:" .. (g_subtitles:get_current() or "nil"))
        log("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
end

-- private
function g_subtitles:_fill_currents(time)
    self.currents = {} -- there might be several current overlapping subtitles
    self.prev_time = nil
    self.begin_time = nil
    self.end_time = nil
    self.next_time = nil

    local last_checked = 0
    for i = 1, #self.subtitles do
        last_checked = i
        if self.subtitles[i][1] <= time and time <= self.subtitles[i][2] then
            self.prev_time = self.subtitles[i-1] and self.subtitles[i-1][1]
            self.begin_time = self.subtitles[i][1]
            self.end_time = math.min(self.subtitles[i+1] and self.subtitles[i+1][1] or 9999999, self.subtitles[i][2])
            table.insert(self.currents, i)
        end
        if self.subtitles[i][1] > time then
            self.next_time = self.subtitles[i][1]
            break
        end
    end

    -- if there are no current subtitles
    if #self.currents == 0 then
        self.prev_time = self.subtitles[last_checked-1] and self.subtitles[last_checked-1][1]
        self.begin_time = self.subtitles[last_checked-1] and self.subtitles[last_checked-1][2] or 0
        if last_checked < #self.subtitles then
            self.end_time = self.subtitles[last_checked] and self.subtitles[last_checked][1]
        else
            self.end_time = nil -- no end time after the last subtitle
        end
        self.next_time = self.end_time
    end
end


