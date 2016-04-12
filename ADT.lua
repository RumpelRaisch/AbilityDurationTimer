--[[ Usage:
    ADT = AbilityDurationTimer.New(FRAME[, callback]); <- callback is called shortly before timer ends and ADT gets destroyed

    ADT:Reschedule(delay)         -- make private
    ADT:Release()                 -- make private
    ADT:VisibilityTo(val, delay)  -- make private
    ADT:MoveTo(left, delay)       -- make private
    ADT:Relocate(delay)           -- make private
    ADT:StartTimer(callback)      -- this we need public
    ADT:UpdateTimerBind(callback) -- make private
    ADT:UpdateDuration()          -- make private
    ADT:SetPos(val)               -- make private
    ADT:GetPos()
    ADT:SetAbilityID(val)
    ADT:GetAbilityID()
    ADT:SetAbilityName(val)
    ADT:GetAbilityName()
    ADT:SetNameCheck(val)         -- do we need this here?
    ADT:GetNameCheck()            -- do we need this here?
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
PRIVATE.PROPERTIES         = {};

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
    -- = public properties (meh ... we need this one)
    -- =========================================================================

    local ADT_NEW = {id = PRIVATE.GetUniqueId()};

    -- =========================================================================
    -- = private properties
    -- =========================================================================

    PRIVATE.PROPERTIES[ADT_NEW.id]              = {};
    PRIVATE.PROPERTIES[ADT_NEW.id].pos          = PRIVATE.GetMaxPos() + 1;
    PRIVATE.PROPERTIES[ADT_NEW.id].start_time   = tonumber(System.GetClientTime());
    PRIVATE.PROPERTIES[ADT_NEW.id].ability_id   = 0;
    PRIVATE.PROPERTIES[ADT_NEW.id].ability_name = "";
    PRIVATE.PROPERTIES[ADT_NEW.id].name_check   = "";
    PRIVATE.PROPERTIES[ADT_NEW.id].icon_id      = 0;
    PRIVATE.PROPERTIES[ADT_NEW.id].alignment    = 0;
    PRIVATE.PROPERTIES[ADT_NEW.id].duration     = 0;
    PRIVATE.PROPERTIES[ADT_NEW.id].duration_ms  = 0;
    PRIVATE.PROPERTIES[ADT_NEW.id].remaining_ms = 0;

    PRIVATE.PROPERTIES[ADT_NEW.id].BP  = Component.CreateWidget("BP_IconTimer", FRAME); -- from blueprint in xml
    PRIVATE.PROPERTIES[ADT_NEW.id].GRP = PRIVATE.PROPERTIES[ADT_NEW.id].BP:GetChild("timer_grp");
    PRIVATE.PROPERTIES[ADT_NEW.id].GRP:ParamTo("alpha", 0, 0);

    PRIVATE.PROPERTIES[ADT_NEW.id].ICON            = PRIVATE.PROPERTIES[ADT_NEW.id].GRP:GetChild("icon");
    PRIVATE.PROPERTIES[ADT_NEW.id].ARC             = PRIVATE.PROPERTIES[ADT_NEW.id].GRP:GetChild("arc");
    PRIVATE.PROPERTIES[ADT_NEW.id].TIMER_OUTLINE_1 = PRIVATE.PROPERTIES[ADT_NEW.id].GRP:GetChild("text_timer_outline_1");
    PRIVATE.PROPERTIES[ADT_NEW.id].TIMER_OUTLINE_2 = PRIVATE.PROPERTIES[ADT_NEW.id].GRP:GetChild("text_timer_outline_2");
    PRIVATE.PROPERTIES[ADT_NEW.id].TIMER_OUTLINE_3 = PRIVATE.PROPERTIES[ADT_NEW.id].GRP:GetChild("text_timer_outline_3");
    PRIVATE.PROPERTIES[ADT_NEW.id].TIMER_OUTLINE_4 = PRIVATE.PROPERTIES[ADT_NEW.id].GRP:GetChild("text_timer_outline_4");
    PRIVATE.PROPERTIES[ADT_NEW.id].TIMER           = PRIVATE.PROPERTIES[ADT_NEW.id].GRP:GetChild("text_timer");

    PRIVATE.PROPERTIES[ADT_NEW.id].UPDATE_TIMER = Callback2.Create();

    -- =========================================================================
    -- = public methods
    -- =========================================================================

    -- ADT_NEW:Reschedule = function (delay) -- not supported in FireFall
    ADT_NEW.Reschedule = function (self, delay)
        -- PRIVATE.SystemMsg("ADT:Reschedule()");
        PRIVATE.PROPERTIES[self.id].UPDATE_TIMER:Reschedule(delay);

        return self;
    end

    ADT_NEW.Release = function (self)
        -- PRIVATE.SystemMsg("ADT:Release()");
        -- PRIVATE.PROPERTIES[self.id].UPDATE_TIMER:Release();
        PRIVATE.PROPERTIES[self.id].UPDATE_TIMER:Reschedule(0);

        return self;
    end

    ADT_NEW.VisibilityTo = function (self, val, delay)
        -- PRIVATE.SystemMsg("ADT:VisibilityTo()");

        if "Group" ~= type(PRIVATE.PROPERTIES[self.id].GRP) then
            return self;
        end

        if nil ~= delay then
            delay = 0;
        end

        -- PRIVATE.SystemMsg("val: "..tostring(val));
        -- PRIVATE.SystemMsg("delay: "..tostring(delay));

        PRIVATE.PROPERTIES[self.id].GRP:ParamTo("alpha", val, delay);

        return self;
    end

    ADT_NEW.MoveTo = function (self, left, delay)
        -- PRIVATE.SystemMsg("ADT:MoveTo()");
        -- PRIVATE.SystemMsg("left: "..tostring(left));
        -- PRIVATE.SystemMsg("delay: "..tostring(delay));

        if "Group" ~= type(PRIVATE.PROPERTIES[self.id].GRP) then
            return self;
        end

        if nil ~= delay then
            delay = 0;
        end

        PRIVATE.PROPERTIES[self.id].GRP:MoveTo("left:"..tostring(left).."; top:0; height:64; width:64;", delay);

        return self;
    end

    ADT_NEW.Relocate = function (self, delay)
        -- PRIVATE.SystemMsg("ADT:Relocate()");
        -- PRIVATE.SystemMsg("delay: "..tostring(delay));

        if nil ~= delay then
            delay = 0.1;
        end

        -- move to pos related dimensions
        self:MoveTo((0 + PRIVATE.alignment * (PRIVATE.PROPERTIES[self.id].pos - 1)), delay);

        -- hide
        if self:GetPos() > PRIVATE.max_visible then
            self:VisibilityTo(0, 0.1);
        end

        return self;
    end

    ADT_NEW.StartTimer = function (self, callback)
        -- PRIVATE.SystemMsg("ADT:StartTimer()");

        local font = PRIVATE.font_name.."_"..tostring(PRIVATE.font_size);

        if PRIVATE.max_visible >= PRIVATE.active then
            self:VisibilityTo(1, 0);
        end

        self:MoveTo((0 + PRIVATE.alignment * (PRIVATE.PROPERTIES[self.id].pos - 1) + PRIVATE.alignment), 0); -- start opposite to slide in
        self:MoveTo((0 + PRIVATE.alignment * (PRIVATE.PROPERTIES[self.id].pos - 1)), 0.1); -- slide in

        -- Font
        PRIVATE.PROPERTIES[self.id].TIMER:SetFont(font);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_1:SetFont(font);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_2:SetFont(font);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_3:SetFont(font);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_4:SetFont(font);

        -- Font color
        PRIVATE.PROPERTIES[self.id].TIMER:SetTextColor("#"..PRIVATE.font_color);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_1:SetTextColor("#"..PRIVATE.font_color_outline);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_2:SetTextColor("#"..PRIVATE.font_color_outline);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_3:SetTextColor("#"..PRIVATE.font_color_outline);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_4:SetTextColor("#"..PRIVATE.font_color_outline);

        if "Activate: Rocket Wings" == PRIVATE.PROPERTIES[self.id].ability_name then
            PRIVATE.PROPERTIES[self.id].GRP:GetChild("rocketeers_wings"):ParamTo("alpha", 1, 0);
        else
            PRIVATE.PROPERTIES[self.id].ICON:SetIcon(PRIVATE.PROPERTIES[self.id].icon_id);
        end

        -- start timer
        PRIVATE.PROPERTIES[self.id].TIMER:StartTimer(PRIVATE.PROPERTIES[self.id].duration, true);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_1:StartTimer(PRIVATE.PROPERTIES[self.id].duration, true);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_2:StartTimer(PRIVATE.PROPERTIES[self.id].duration, true);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_3:StartTimer(PRIVATE.PROPERTIES[self.id].duration, true);
        PRIVATE.PROPERTIES[self.id].TIMER_OUTLINE_4:StartTimer(PRIVATE.PROPERTIES[self.id].duration, true);

        self:UpdateDuration();

        PRIVATE.PROPERTIES[self.id].UPDATE_TIMER:Bind(
            function()
                self:UpdateTimerBind(callback);
            end
        );
        PRIVATE.PROPERTIES[self.id].UPDATE_TIMER:Schedule(PRIVATE.PROPERTIES[self.id].duration);

        PRIVATE.OrderTimers();
    end

    ADT_NEW.UpdateTimerBind = function (self, callback)
        -- PRIVATE.SystemMsg("ADT:UpdateTimerBind()");

        Component.RemoveWidget(PRIVATE.PROPERTIES[self.id].BP);

        if "function" == type(callback) then
            callback(self);
        end

        local id  = self.id;
        local pos = PRIVATE.PROPERTIES[self.id].pos;

        for i,_ in pairs(PRIVATE.ADTS) do
            if PRIVATE.ADTS[i].id == id then
                PRIVATE.ADTS[i]       = nil;
                PRIVATE.PROPERTIES[i] = nil;
                PRIVATE.active        = PRIVATE.active - 1;
            elseif PRIVATE.ADTS[i]:GetPos() > pos then
                PRIVATE.ADTS[i]:SetPos(PRIVATE.ADTS[i]:GetPos() - 1):Relocate(0.1);
            end
        end

        if 0 > PRIVATE.active then
            PRIVATE.active = 0;
        end

        PRIVATE.OrderTimers();

        return self;
    end

    ADT_NEW.UpdateDuration = function (self)
        -- PRIVATE.SystemMsg("ADT:UpdateDuration()");

        if nil == PRIVATE.PROPERTIES[self.id] or "Arc" ~= type(PRIVATE.PROPERTIES[self.id].ARC) then
            do return end
        end

        local duration  = tonumber(System.GetClientTime()) - PRIVATE.PROPERTIES[self.id].start_time;
        local remaining = PRIVATE.PROPERTIES[self.id].duration_ms - duration;
        local angle     = -180 + (duration / PRIVATE.PROPERTIES[self.id].duration_ms) * 360;

        PRIVATE.PROPERTIES[self.id].remaining_ms = remaining;

        if 5000 >= remaining then
            PRIVATE.PROPERTIES[self.id].ARC:SetParam("tint", "#FF0000", 0.1);
        end

        if 180 <= angle then
            PRIVATE.PROPERTIES[self.id].ARC:SetParam("end-angle", 180);
        else
            PRIVATE.PROPERTIES[self.id].ARC:SetParam("end-angle", angle);

            Callback2.FireAndForget(self.UpdateDuration, self, 0.1);
        end
    end

    -- =========================================================================
    -- = getter and setter
    -- =========================================================================

    ADT_NEW.SetPos = function (self, val)
        PRIVATE.PROPERTIES[self.id].pos = tonumber(val);

        return self;
    end

    ADT_NEW.GetPos = function (self)
        return PRIVATE.PROPERTIES[self.id].pos;
    end

    ADT_NEW.SetAbilityID = function (self, val)
        PRIVATE.PROPERTIES[self.id].ability_id = tonumber(val);

        return self;
    end

    ADT_NEW.GetAbilityID = function (self)
        return PRIVATE.PROPERTIES[self.id].ability_id;
    end

    ADT_NEW.SetAbilityName = function (self, val)
        PRIVATE.PROPERTIES[self.id].ability_name = tostring(val);

        return self;
    end

    ADT_NEW.GetAbilityName = function (self)
        return PRIVATE.PROPERTIES[self.id].ability_name;
    end

    ADT_NEW.SetNameCheck = function (self, val)
        PRIVATE.PROPERTIES[self.id].name_check = tostring(val);

        return self;
    end

    ADT_NEW.GetNameCheck = function (self)
        return PRIVATE.PROPERTIES[self.id].name_check;
    end

    ADT_NEW.SetIconID = function (self, val)
        PRIVATE.PROPERTIES[self.id].icon_id = tonumber(val);

        -- PRIVATE.SystemMsg("Icon ID: "..tostring(PRIVATE.PROPERTIES[self.id].icon_id));

        return self;
    end

    ADT_NEW.GetIconID = function (self)
        return PRIVATE.PROPERTIES[self.id].icon_id;
    end

    ADT_NEW.SetDuration = function (self, val)
        PRIVATE.PROPERTIES[self.id].duration     = tonumber(val);
        PRIVATE.PROPERTIES[self.id].duration_ms  = tonumber(val) * 1000;
        PRIVATE.PROPERTIES[self.id].remaining_ms = tonumber(val) * 1000;

        return self;
    end

    ADT_NEW.GetDuration = function (self)
        return PRIVATE.PROPERTIES[self.id].duration;
    end

    ADT_NEW.GetDurationMs = function (self)
        return PRIVATE.PROPERTIES[self.id].duration_ms;
    end

    ADT_NEW.GetRemainingMs = function (self)
        return PRIVATE.PROPERTIES[self.id].remaining_ms;
    end

    -- =========================================================================
    -- = finish creation
    -- =========================================================================

    PRIVATE.ADTS[ADT_NEW.id] = ADT_NEW;

    PRIVATE.active = PRIVATE.active + 1;

    return ADT_NEW;
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
