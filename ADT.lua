--[[ Usage:
    ADT = AbilityDurationTimer(FRAME[, callback]); <- callback is called shortly before timer ends and ADT gets destroyed

    ADT:Reschedule(delay)         -> this we need public
    ADT:Release()                 -> make private (maybe?)
    ADT:VisibilityTo(val, delay)  -> make private (maybe?)
    ADT:MoveTo(left, delay)       -> make private (maybe?)
    ADT:Relocate(delay)           -> make private (maybe?)
    ADT:StartTimer(callback)      -> this we need public
    ADT:UpdateTimerBind(callback) -> make private (maybe?)
    ADT:UpdateDuration()          -> make private (maybe?)
    ADT:GetID()
    ADT:SetPos(val)               -> make private (maybe?)
    ADT:GetPos()
    ADT:SetAbilityID(val)
    ADT:GetAbilityID()
    ADT:SetAbilityName(val)
    ADT:GetAbilityName()
    ADT:SetIconID(val)
    ADT:GetIconID()
    ADT:SetAlignment(val)
    ADT:GetAlignment()
    ADT:SetDuration(val)
    ADT:GetDuration()
    ADT:GetDurationMs()
    ADT:GetRemainingMs()
--]]

require "lib/lib_Callback2";

-- local
local PRIVATE = {};

PRIVATE.max_visible        = 0;
PRIVATE.alignment          = 0;
PRIVATE.font_name          = "";
PRIVATE.font_size          = 0;
PRIVATE.font_color         = "";
PRIVATE.font_color_outline = "";
PRIVATE.active             = 0;
PRIVATE.unique             = 1;
PRIVATE.is_ordering        = false;
PRIVATE.ADTS               = {};

function PRIVATE.GetUniqueId()
    -- PRIVATE.SystemMsg("PRIVATE:GetUniqueId()");
    PRIVATE.unique = PRIVATE.unique + 1;

    return PRIVATE.unique;
end

function PRIVATE.GetMaxPos()
    -- PRIVATE.SystemMsg("PRIVATE:GetMaxPos()");

    local max = 0;

    for i,_ in pairs(PRIVATE.ADTS) do
        if PRIVATE.ADTS[i]:GetPos() > max then
            max = PRIVATE.ADTS[i]:GetPos();
        end
    end

    return max;
end

function PRIVATE.OrderTimers()
    -- PRIVATE.SystemMsg("PRIVATE:OrderTimers()");

    if PRIVATE.is_ordering then
        Callback2.FireAndForget(PRIVATE.OrderTimers, nil, 0.1);

        return;
    end

    PRIVATE.is_ordering = true;

    for i,_ in pairs(PRIVATE.ADTS) do
        for ii,__ in pairs(PRIVATE.ADTS) do
            local check_id        = PRIVATE.ADTS[i]:GetID() ~= PRIVATE.ADTS[ii]:GetID();
            local check_remaining = PRIVATE.ADTS[i]:GetRemainingMs() < PRIVATE.ADTS[ii]:GetRemainingMs();
            local check_pos       = PRIVATE.ADTS[i]:GetPos() > PRIVATE.ADTS[ii]:GetPos();

            if check_id and check_remaining and check_pos then
                local pos_one = PRIVATE.ADTS[i]:GetPos();
                local pos_two = PRIVATE.ADTS[ii]:GetPos();

                PRIVATE.ADTS[i]:SetPos(pos_two);
                PRIVATE.ADTS[ii]:SetPos(pos_one);
            end
        end
    end

    for i,_ in pairs(PRIVATE.ADTS) do
        PRIVATE.ADTS[i]:Relocate(0.1);
    end

    PRIVATE.is_ordering = false;

    return PRIVATE;
end

function PRIVATE.OrderTimersLoop()
    PRIVATE.OrderTimers();

    Callback2.FireAndForget(PRIVATE.OrderTimersLoop, {}, 1);
end

function PRIVATE.SystemMsg(message)
    Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text = "[ADT] "..tostring(message)});
end

-- global
AbilityDurationTimer = {};
AbilityDurationTimer.__index = AbilityDurationTimer

setmetatable(AbilityDurationTimer, {__call = function(CLS, ...) return CLS.New(...) end});

function AbilityDurationTimer.New(FRAME)
    -- =========================================================================
    -- = private properties
    -- =========================================================================

    local ADT          = setmetatable({}, AbilityDurationTimer); -- instance
    local id           = PRIVATE.GetUniqueId();
    local pos          = PRIVATE.GetMaxPos() + 1;
    local start_time   = tonumber(System.GetClientTime());
    local ability_id   = 0;
    local ability_name = "";
    local icon_id      = 0;
    local alignment    = 0;
    local duration     = 0;
    local duration_ms  = 0;
    local remaining_ms = 0;

    local BP  = Component.CreateWidget("BP_IconTimer", FRAME); -- from blueprint in xml
    local GRP = BP:GetChild("timer_grp");

    local ICON            = GRP:GetChild("icon");
    local ARC             = GRP:GetChild("arc");
    local TIMER_OUTLINE_1 = GRP:GetChild("text_timer_outline_1");
    local TIMER_OUTLINE_2 = GRP:GetChild("text_timer_outline_2");
    local TIMER_OUTLINE_3 = GRP:GetChild("text_timer_outline_3");
    local TIMER_OUTLINE_4 = GRP:GetChild("text_timer_outline_4");
    local TIMER           = GRP:GetChild("text_timer");

    local UPDATE_TIMER = Callback2.Create();

    -- =========================================================================
    -- = init stuff
    -- =========================================================================

    GRP:ParamTo("alpha", 0, 0);

    -- PRIVATE.SystemMsg(type(ADT));

    -- =========================================================================
    -- = public properties
    -- =========================================================================

    -- public properties go in the instance table
    -- ADT.property_name = value;

    -- =========================================================================
    -- = public methods
    -- =========================================================================

    function ADT:Reschedule(delay)
        -- PRIVATE.SystemMsg("ADT:Reschedule()");
        TIMER:StartTimer(delay, true);
        TIMER_OUTLINE_1:StartTimer(delay, true);
        TIMER_OUTLINE_2:StartTimer(delay, true);
        TIMER_OUTLINE_3:StartTimer(delay, true);
        TIMER_OUTLINE_4:StartTimer(delay, true);

        UPDATE_TIMER:Reschedule(delay);

        return self;
    end

    function ADT:Release()
        -- PRIVATE.SystemMsg("ADT:Release()");
        -- UPDATE_TIMER:Release();
        self:Reschedule(0);

        return self;
    end

    function ADT:VisibilityTo(val, delay)
        -- PRIVATE.SystemMsg("ADT:VisibilityTo()");

        if "Group" ~= type(GRP) then
            return self;
        end

        if nil ~= delay then
            delay = 0;
        end

        -- PRIVATE.SystemMsg("val: "..tostring(val));
        -- PRIVATE.SystemMsg("delay: "..tostring(delay));

        GRP:ParamTo("alpha", val, delay);

        return self;
    end

    function ADT:MoveTo(left, delay)
        -- PRIVATE.SystemMsg("ADT:MoveTo()");
        -- PRIVATE.SystemMsg("left: "..tostring(left));
        -- PRIVATE.SystemMsg("delay: "..tostring(delay));

        if "Group" ~= type(GRP) then
            return self;
        end

        if nil ~= delay then
            delay = 0;
        end

        GRP:MoveTo("left:"..tostring(left).."; top:0; height:64; width:64;", delay);

        return self;
    end

    function ADT:Relocate(delay)
        -- PRIVATE.SystemMsg("ADT:Relocate()");
        -- PRIVATE.SystemMsg("delay: "..tostring(delay));

        if nil ~= delay then
            delay = 0.1;
        end

        -- move to pos related dimensions
        self:MoveTo((0 + PRIVATE.alignment * (pos - 1)), delay);

        -- hide
        if self:GetPos() > PRIVATE.max_visible then
            self:VisibilityTo(0, 0.1);
        end

        return self;
    end

    function ADT:StartTimer(callback)
        -- PRIVATE.SystemMsg("ADT:StartTimer()");

        local font = PRIVATE.font_name.."_"..tostring(PRIVATE.font_size);

        if PRIVATE.max_visible >= PRIVATE.active then
            self:VisibilityTo(1, 0);
        end

        self:MoveTo((0 + PRIVATE.alignment * (pos - 1) + PRIVATE.alignment), 0); -- start opposite to slide in
        self:MoveTo((0 + PRIVATE.alignment * (pos - 1)), 0.1); -- slide in

        -- Font
        TIMER:SetFont(font);
        TIMER_OUTLINE_1:SetFont(font);
        TIMER_OUTLINE_2:SetFont(font);
        TIMER_OUTLINE_3:SetFont(font);
        TIMER_OUTLINE_4:SetFont(font);

        -- Font color
        TIMER:SetTextColor("#"..PRIVATE.font_color);
        TIMER_OUTLINE_1:SetTextColor("#"..PRIVATE.font_color_outline);
        TIMER_OUTLINE_2:SetTextColor("#"..PRIVATE.font_color_outline);
        TIMER_OUTLINE_3:SetTextColor("#"..PRIVATE.font_color_outline);
        TIMER_OUTLINE_4:SetTextColor("#"..PRIVATE.font_color_outline);

        if "Activate: Rocket Wings" == ability_name then
            GRP:GetChild("rocketeers_wings"):ParamTo("alpha", 1, 0);
        else
            ICON:SetIcon(icon_id);
        end

        -- start timer
        TIMER:StartTimer(duration, true);
        TIMER_OUTLINE_1:StartTimer(duration, true);
        TIMER_OUTLINE_2:StartTimer(duration, true);
        TIMER_OUTLINE_3:StartTimer(duration, true);
        TIMER_OUTLINE_4:StartTimer(duration, true);

        self:UpdateDuration();

        UPDATE_TIMER:Bind(
            function()
                self:UpdateTimerBind(callback);
            end
        );
        UPDATE_TIMER:Schedule(duration);

        PRIVATE.OrderTimers();
    end

    function ADT:UpdateTimerBind(callback)
        -- PRIVATE.SystemMsg("ADT:UpdateTimerBind()");

        if nil == PRIVATE.ADTS[self:GetID()] then
            -- PRIVATE.SystemMsg("Timer already gone.");

            return;
        end

        Component.RemoveWidget(BP);

        if "function" == type(callback) then
            callback(self);
        end

        local _id  = id;
        local _pos = pos;

        for i,_ in pairs(PRIVATE.ADTS) do
            if PRIVATE.ADTS[i]:GetID() == _id then
                PRIVATE.ADTS[i] = nil;
                PRIVATE.active  = PRIVATE.active - 1;
            elseif PRIVATE.ADTS[i]:GetPos() > _pos then
                PRIVATE.ADTS[i]:SetPos(PRIVATE.ADTS[i]:GetPos() - 1):Relocate(0.1);
            end
        end

        if 0 > PRIVATE.active then
            PRIVATE.active = 0;
        end

        PRIVATE.OrderTimers();

        return self;
    end

    function ADT:UpdateDuration()
        -- PRIVATE.SystemMsg("ADT:UpdateDuration()");

        if "Arc" ~= type(ARC) then
            do return end
        end

        local duration  = tonumber(System.GetClientTime()) - start_time;
        local remaining = duration_ms - duration;
        local angle     = -180 + (duration / duration_ms) * 360;

        remaining_ms = remaining;

        if 5000 >= remaining then
            ARC:SetParam("tint", "#FF0000", 0.1);
        end

        if 180 <= angle then
            ARC:SetParam("end-angle", 180);
        else
            ARC:SetParam("end-angle", angle);

            Callback2.FireAndForget(self.UpdateDuration, self, 0.1);
        end
    end

    -- =========================================================================
    -- = getter and setter
    -- =========================================================================

    function ADT:GetID()
        return id;
    end

    function ADT:SetPos(val)
        pos = tonumber(val);

        return self;
    end

    function ADT:GetPos()
        return pos;
    end

    function ADT:SetAbilityID(val)
        -- ability_id = tonumber(val);
        ability_id = val;

        return self;
    end

    function ADT:GetAbilityID()
        return ability_id;
    end

    function ADT:SetAbilityName(val)
        ability_name = tostring(val);

        return self;
    end

    function ADT:GetAbilityName()
        return ability_name;
    end

    function ADT:SetIconID(val)
        icon_id = tonumber(val);

        -- PRIVATE.SystemMsg("Icon ID: "..tostring(icon_id));

        return self;
    end

    function ADT:GetIconID()
        return icon_id;
    end

    function ADT:SetDuration(val)
        duration     = tonumber(val);
        duration_ms  = tonumber(val) * 1000;
        remaining_ms = tonumber(val) * 1000;

        return self;
    end

    function ADT:GetDuration()
        return duration;
    end

    function ADT:GetDurationMs()
        return duration_ms;
    end

    function ADT:GetRemainingMs()
        return remaining_ms;
    end

    -- =========================================================================
    -- = finish creation
    -- =========================================================================

    PRIVATE.ADTS[id] = ADT;

    PRIVATE.active = PRIVATE.active + 1;

    return ADT;
end

-- global
ADTStatic = {};

function ADTStatic.Init()
    Callback2.FireAndForget(PRIVATE.OrderTimersLoop, {}, 1);
end

function ADTStatic.SetMaxVisible(val)
    PRIVATE.max_visible = tonumber(val);

    log("PRIVATE.max_visible: "..tostring(PRIVATE.max_visible));

    return AbilityDurationTimer;
end

function ADTStatic.SetAlignment(val)
    PRIVATE.alignment = tonumber(val);

    log("PRIVATE.alignment: "..tostring(PRIVATE.alignment));

    return AbilityDurationTimer;
end

function ADTStatic.SetFontName(val)
    PRIVATE.font_name = tostring(val);

    log("PRIVATE.font_name: "..PRIVATE.font_name);

    return AbilityDurationTimer;
end

function ADTStatic.SetFontSize(val)
    PRIVATE.font_size = tonumber(val);

    log("PRIVATE.font_size: "..tostring(PRIVATE.font_size));

    return AbilityDurationTimer;
end

function ADTStatic.SetFontColor(val)
    PRIVATE.font_color = tostring(val);

    log("PRIVATE.font_color: "..PRIVATE.font_color);

    return AbilityDurationTimer;
end

function ADTStatic.SetFontColorOutline(val)
    PRIVATE.font_color_outline = tostring(val);

    log("PRIVATE.: "..PRIVATE.font_color_outline);

    return AbilityDurationTimer;
end

function ADTStatic.GetActive()
    return PRIVATE.active;
end

function ADTStatic.KillAll()
    for i,_ in pairs(PRIVATE.ADTS) do
        PRIVATE.ADTS[i]:Release();

        PRIVATE.ADTS[i] = nil;
    end
end

-- =============================================================================
-- = patch type function [http://stackoverflow.com/a/19349078/1549628]
-- =============================================================================

local original_type = type;

type = function (obj)
    local otype = original_type(obj);

    if otype == "table" and getmetatable(obj) == AbilityDurationTimer then
        return "AbilityDurationTimer";
    end

    return otype;
end
