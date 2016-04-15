--[[ Usage:
    ADT = AbilityDurationTimer.New(FRAME[, callback]); <- callback is called shortly before timer ends and ADT gets destroyed

    ADT:Reschedule(delay)         -> this we need public
    ADT:Release()                 -> make private
    ADT:VisibilityTo(val, delay)  -> make private
    ADT:MoveTo(left, delay)       -> make private
    ADT:Relocate(delay)           -> make private
    ADT:StartTimer(callback)      -> this we need public
    ADT:UpdateTimerBind(callback) -> make private
    ADT:UpdateDuration()          -> make private
    ADT:SetPos(val)               -> make private
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

PRIVATE.GetUniqueId = function ()
    -- PRIVATE.SystemMsg("PRIVATE:GetUniqueId()");
    PRIVATE.unique = PRIVATE.unique + 1;

    return PRIVATE.unique;
end

PRIVATE.GetMaxPos = function ()
    -- PRIVATE.SystemMsg("PRIVATE:GetMaxPos()");

    local max = 0;

    for i,_ in pairs(PRIVATE.ADTS) do
        if PRIVATE.ADTS[i]:GetPos() > max then
            max = PRIVATE.ADTS[i]:GetPos();
        end
    end

    return max;
end

PRIVATE.OrderTimers = function ()
    -- PRIVATE.SystemMsg("PRIVATE:OrderTimers()");

    if PRIVATE.is_ordering then
        Callback2.FireAndForget(PRIVATE.OrderTimers, nil, 0.1);

        return;
    end

    PRIVATE.is_ordering = true;

    for i,_ in pairs(PRIVATE.ADTS) do
        for ii,__ in pairs(PRIVATE.ADTS) do
            local check_id        = PRIVATE.ADTS[i].id ~= PRIVATE.ADTS[ii].id;
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

PRIVATE.SystemMsg = function (message)
    Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text = "[ADT] "..tostring(message)});
end

-- global
AbilityDurationTimer = {};

AbilityDurationTimer.New = function (FRAME)
    -- =========================================================================
    -- = private properties
    -- =========================================================================


    local ADT          = {};
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
    local GRP:ParamTo("alpha", 0, 0);

    local ICON            = GRP:GetChild("icon");
    local ARC             = GRP:GetChild("arc");
    local TIMER_OUTLINE_1 = GRP:GetChild("text_timer_outline_1");
    local TIMER_OUTLINE_2 = GRP:GetChild("text_timer_outline_2");
    local TIMER_OUTLINE_3 = GRP:GetChild("text_timer_outline_3");
    local TIMER_OUTLINE_4 = GRP:GetChild("text_timer_outline_4");
    local TIMER           = GRP:GetChild("text_timer");

    local UPDATE_TIMER = Callback2.Create();

    -- =========================================================================
    -- = public methods
    -- =========================================================================

    -- ADT:Reschedule = function (delay) -- not supported in FireFall
    ADT.Reschedule = function (self, delay)
        -- PRIVATE.SystemMsg("ADT:Reschedule()");
        UPDATE_TIMER:Reschedule(delay);

        return self;
    end

    ADT.Release = function (self)
        -- PRIVATE.SystemMsg("ADT:Release()");
        -- UPDATE_TIMER:Release();
        UPDATE_TIMER:Reschedule(0);

        return self;
    end

    ADT.VisibilityTo = function (self, val, delay)
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

    ADT.MoveTo = function (self, left, delay)
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

    ADT.Relocate = function (self, delay)
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

    ADT.StartTimer = function (self, callback)
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

    ADT.UpdateTimerBind = function (self, callback)
        -- PRIVATE.SystemMsg("ADT:UpdateTimerBind()");

        Component.RemoveWidget(BP);

        if "function" == type(callback) then
            callback(self);
        end

        local _id  = id;
        local _pos = pos;

        for i,_ in pairs(PRIVATE.ADTS) do
            if PRIVATE.ADTS[i]:GetId() == _id then
                PRIVATE.ADTS[i]       = nil;
                PRIVATE.PROPERTIES[i] = nil;
                PRIVATE.active        = PRIVATE.active - 1;
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

    ADT.UpdateDuration = function (self)
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

    ADT.SetPos = function (self, val)
        pos = tonumber(val);

        return self;
    end

    ADT.GetPos = function (self)
        return pos;
    end

    ADT.SetAbilityID = function (self, val)
        ability_id = tonumber(val);

        return self;
    end

    ADT.GetAbilityID = function (self)
        return ability_id;
    end

    ADT.SetAbilityName = function (self, val)
        ability_name = tostring(val);

        return self;
    end

    ADT.GetAbilityName = function (self)
        return ability_name;
    end

    ADT.SetIconID = function (self, val)
        icon_id = tonumber(val);

        -- PRIVATE.SystemMsg("Icon ID: "..tostring(icon_id));

        return self;
    end

    ADT.GetIconID = function (self)
        return icon_id;
    end

    ADT.SetDuration = function (self, val)
        duration     = tonumber(val);
        duration_ms  = tonumber(val) * 1000;
        remaining_ms = tonumber(val) * 1000;

        return self;
    end

    ADT.GetDuration = function (self)
        return duration;
    end

    ADT.GetDurationMs = function (self)
        return duration_ms;
    end

    ADT.GetRemainingMs = function (self)
        return remaining_ms;
    end

    -- =========================================================================
    -- = finish creation
    -- =========================================================================

    PRIVATE.ADTS[ADT.id] = ADT;

    PRIVATE.active = PRIVATE.active + 1;

    return ADT;
end

AbilityDurationTimer.SetMaxVisible = function (val)
    PRIVATE.max_visible = tonumber(val);

    log("PRIVATE.max_visible: "..tostring(PRIVATE.max_visible));

    return AbilityDurationTimer;
end

AbilityDurationTimer.SetAlignment = function (val)
    PRIVATE.alignment = tonumber(val);

    log("PRIVATE.alignment: "..tostring(PRIVATE.alignment));

    return AbilityDurationTimer;
end

AbilityDurationTimer.SetFontName = function (val)
    PRIVATE.font_name = tostring(val);

    log("PRIVATE.font_name: "..PRIVATE.font_name);

    return AbilityDurationTimer;
end

AbilityDurationTimer.SetFontSize = function (val)
    PRIVATE.font_size = tonumber(val);

    log("PRIVATE.font_size: "..tostring(PRIVATE.font_size));

    return AbilityDurationTimer;
end

AbilityDurationTimer.SetFontColor = function (val)
    PRIVATE.font_color = tostring(val);

    log("PRIVATE.font_color: "..PRIVATE.font_color);

    return AbilityDurationTimer;
end

AbilityDurationTimer.SetFontColorOutline = function (val)
    PRIVATE.font_color_outline = tostring(val);

    log("PRIVATE.: "..PRIVATE.font_color_outline);

    return AbilityDurationTimer;
end

AbilityDurationTimer.GetActive = function ()
    return PRIVATE.active;
end

AbilityDurationTimer.KillAll = function ()
    for i,_ in pairs(PRIVATE.ADTS) do
        PRIVATE.ADTS[i]:Release();

        PRIVATE.ADTS[i] = nil;
    end
end
