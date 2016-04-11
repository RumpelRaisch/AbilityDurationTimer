require "lib/lib_Callback2";

-- global
AbilityDurationTimer = {};

AbilityDurationTimer.Create = function (FRAME)
    local ADT_NEW = {id = PRIVATE.GetUniqueId()};

    PRIVATE.PROPERTIES[ADT.id].start_time = tonumber(System.GetClientTime());

    PRIVATE.PROPERTIES[ADT.id].BP  = Component.CreateWidget("BP_IconTimer", FRAME); -- from blueprint in xml
    PRIVATE.PROPERTIES[ADT.id].GRP = PRIVATE.PROPERTIES[ADT.id].BP:GetChild("timer_grp");
    PRIVATE.PROPERTIES[ADT.id].GRP:ParamTo("alpha", 0, 0);

    PRIVATE.PROPERTIES[ADT.id].ICON            = PRIVATE.PROPERTIES[ADT.id].GRP:GetChild("icon");
    PRIVATE.PROPERTIES[ADT.id].ARC             = PRIVATE.PROPERTIES[ADT.id].GRP:GetChild("arc");
    PRIVATE.PROPERTIES[ADT.id].TIMER_OUTLINE_1 = PRIVATE.PROPERTIES[ADT.id].GRP:GetChild("text_timer_outline_1");
    PRIVATE.PROPERTIES[ADT.id].TIMER_OUTLINE_2 = PRIVATE.PROPERTIES[ADT.id].GRP:GetChild("text_timer_outline_2");
    PRIVATE.PROPERTIES[ADT.id].TIMER_OUTLINE_3 = PRIVATE.PROPERTIES[ADT.id].GRP:GetChild("text_timer_outline_3");
    PRIVATE.PROPERTIES[ADT.id].TIMER_OUTLINE_4 = PRIVATE.PROPERTIES[ADT.id].GRP:GetChild("text_timer_outline_4");
    PRIVATE.PROPERTIES[ADT.id].TIMER           = PRIVATE.PROPERTIES[ADT.id].GRP:GetChild("text_timer");

    PRIVATE.PROPERTIES[ADT.id].UPDATE_TIMER = Callback2.Create();

    ADT_NEW.Reschedule = function (ADT, delay)
        PRIVATE.PROPERTIES[ADT.id].UPDATE_TIMER:Reschedule(delay);

        return ADT;
    end

    ADT_NEW.Release = function (ADT)
        PRIVATE.PROPERTIES[ADT.id].UPDATE_TIMER:Release();

        return ADT;
    end

    ADT_NEW.MoveTo = function (ADT, dimensions, delay)
        PRIVATE.PROPERTIES[ADT.id].GRP:MoveTo(dimensions, delay);

        return ADT;
    end

    ADT_NEW.Relocate = function (ADT, delay)
        if nil ~= delay then
            delay = 0.1;
        end

        -- MoveTo ADT.pos related dimensions
        ADT:MoveTo("left:"..tostring(0 + PRIVATE.PROPERTIES[ADT.id].alignment * (PRIVATE.PROPERTIES[ADT.id].pos - 1)).."; top:0; height:64; width:64;", delay);

        -- hide
        if ADT:GetPos() > AbilityDurationTimer.GetMaxVisible() then
            PRIVATE.PROPERTIES[ADT.id].GRP:ParamTo("alpha", 0, 0.1);
        end

        return ADT;
    end

    ADT_NEW.SetPos = function (ADT, val)
        PRIVATE.PROPERTIES[ADT.id].pos = tonumber(val);

        return ADT;
    end

    ADT_NEW.GetPos = function (ADT)
        return PRIVATE.PROPERTIES[ADT.id].pos;
    end

    ADT_NEW.SetAbilityID = function (ADT, val)
        PRIVATE.PROPERTIES[ADT.id].ability_id = tonumber(val);

        return ADT;
    end

    ADT_NEW.GetAbilityID = function (ADT)
        return PRIVATE.PROPERTIES[ADT.id].ability_id;
    end

    ADT_NEW.SetAbilityName = function (ADT, val)
        PRIVATE.PROPERTIES[ADT.id].ability_name = tostring(val);

        return ADT;
    end

    ADT_NEW.GetAbilityName = function (ADT)
        return PRIVATE.PROPERTIES[ADT.id].ability_name;
    end

    ADT_NEW.SetNameCheck = function (ADT, val)
        PRIVATE.PROPERTIES[ADT.id].name_check = tostring(val);

        return ADT;
    end

    ADT_NEW.GetNameCheck = function (ADT)
        return PRIVATE.PROPERTIES[ADT.id].name_check;
    end

    ADT_NEW.SetIconID = function (ADT, val)
        PRIVATE.PROPERTIES[ADT.id].icon_id = tonumber(val);

        return ADT;
    end

    ADT_NEW.GetIconID = function (ADT)
        return PRIVATE.PROPERTIES[ADT.id].icon_id;
    end

    ADT_NEW.SetAlignment = function (ADT, val)
        PRIVATE.PROPERTIES[ADT.id].alignment = tonumber(val);

        return ADT;
    end

    ADT_NEW.GetAlignment = function (ADT)
        return PRIVATE.PROPERTIES[ADT.id].alignment;
    end

    ADT_NEW.SetDuration = function (ADT, val)
        PRIVATE.PROPERTIES[ADT.id].duration     = tonumber(val),
        PRIVATE.PROPERTIES[ADT.id].duration_ms  = tonumber(val) * 1000,
        PRIVATE.PROPERTIES[ADT.id].remaining_ms = tonumber(val) * 1000,

        return ADT;
    end

    ADT_NEW.GetDuration = function (ADT)
        return PRIVATE.PROPERTIES[ADT.id].duration;
    end

    ADT_NEW.GetDurationMs = function (ADT)
        return PRIVATE.PROPERTIES[ADT.id].duration_ms;
    end

    ADT_NEW.GetRemainingMs = function (ADT)
        return PRIVATE.PROPERTIES[ADT.id].remaining_ms;
    end

    PRIVATE.ADTS[ADT_NEW.id] = ADT_NEW;

    return ADT_NEW;
end

AbilityDurationTimer.SetMaxVisible = function (val)
    PRIVATE.max_visible = tonumber(val);

    return ADT;
end

AbilityDurationTimer.GetMaxVisible = function ()
    return PRIVATE.max_visible;
end

AbilityDurationTimer.KillAll = function ()
    for i,_ in pairs(PRIVATE.ADTS) do
        PRIVATE.ADTS[i]:Release();

        PRIVATE.ADTS[i] = nil;
    end
end

-- local
local PRIVATE = {};

PRIVATE.max_visible = 0;
PRIVATE.unique      = 1;
PRIVATE.ADTS        = {};
PRIVATE.PROPERTIES  = {};

PRIVATE.GetUniqueId = function ()
    PRIVATE.unique = PRIVATE.unique + 1;

    return PRIVATE.unique;
end
