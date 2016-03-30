-- ===============================
-- Ability Duration Timer
-- by: Rumpel, Vollmond
-- ===============================
-- 
-- ===============================

require "lib/lib_Callback2"
require "lib/lib_InterfaceOptions"

-- ===============================
--  Variables
-- ===============================

local DEV_MODE      = false;
local UI            = {};
local RUMPEL        = {};
local SETTINGS      = {};
local ABILITY_INFOS = {};

UI.FRAME         = Component.GetFrame("adt_frame");
-- UI.GRP           = {};
-- UI.GRP.MAIN      = UI.FRAME:GetChild("timer");
-- UI.GRP.LABEL     = UI.GRP.MAIN:GetChild("label");
-- UI.GRP.TEXTTIMER = UI.GRP.MAIN:GetChild("texttimer");

RUMPEL.ui_timers_count = 1;
RUMPEL.UI_TIMERS       = {};

SETTINGS.DEFAULT = {
    debug          = false,
    system_message = true,
    -- objects
    FONT = {
        name = "Demi",
        size = 18,
        -- objects
        COLOR = {
            label     = "FFFFFF",
            texttimer = "FF8800"
        }
    },
    TIMERS = {
        -- objects
        GUARDIAN = {
            -- objects
            HEAVY_ARMOR = {
                name    = "Heavy Armor",
                enabled = true
            },
            THUNDERDOME = {
                name    = "Thunderdome",
                enabled = true
            }
        },
        MEDIC = {
            -- objects
            ADRENALINE_RUSH = {
                name    = "Adrenaline Rush",
                enabled = true
            }
        },
        RECON = {
            -- objects
            TELEPORT_BEACON = {
                name    = "Teleport Beacon",
                enabled = true
            }
        },
        BERZERKER = {
            -- objects
            OVERCHARGE = {
                name    = "Overcharge",
                enabled = true
            }
        },
        ENGINEER = {}
    }
};
SETTINGS.USER = {
    debug          = false,
    system_message = true,
    -- objects
    FONT = {
        name  = "Demi",
        size  = 18,
        -- objects
        COLOR = {
            label     = "FFFFFF",
            texttimer = "FF8800"
        }
    },
    TIMERS = {
        -- objects
        GUARDIAN = {
            -- objects
            HEAVY_ARMOR = {
                enabled = true
            },
            THUNDERDOME = {
                enabled = true
            }
        },
        MEDIC = {
            -- objects
            ADRENALINE_RUSH = {
                enabled = true
            }
        },
        RECON = {
            -- objects
            TELEPORT_BEACON = {
                enabled = true
            }
        },
        BERZERKER = {
            -- objects
            OVERCHARGE = {
                enabled = true
            }
        },
        ENGINEER = {}
    }
};

ABILITY_INFOS[3782]  = {icon_id = 202130}; -- Heavy Armor
ABILITY_INFOS[1726]  = {icon_id = 222527}; -- Thunderdome
ABILITY_INFOS[15206] = {icon_id = 492574}; -- Adrenaline Rush
ABILITY_INFOS[12305] = {icon_id = 202115}; -- Teleport Beacon
ABILITY_INFOS[3639]  = {icon_id = 222507}; -- Overcharge

-- ===============================
--  Options
-- ===============================

function BuildOptions()
    InterfaceOptions.AddMovableFrame({frame=UI.FRAME, label="Ability Duration Timer", scalable=true});

    InterfaceOptions.StartGroup({label="Ability Duration Timer: Main Settings"});
        InterfaceOptions.AddCheckBox({id="DEBUG_ENABLED", label="Debug", default=SETTINGS.DEFAULT.debug});
        InterfaceOptions.AddCheckBox({id="SYSMSG_ENABLED", label="Chat output (Starting duration timer ...)", default=SETTINGS.DEFAULT.system_message});
        InterfaceOptions.AddChoiceMenu({id="FONT", label="Font", default=SETTINGS.DEFAULT.FONT.name});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Demi", label="Eurostile Medium"});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Bold", label="Eurostile Bold"});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuMedium", label="Ubuntu Medium"});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuBold", label="Ubuntu Bold"});
        InterfaceOptions.AddSlider({id="FONTSIZE", label="Fontsize", min=8, max=20, inc=1, suffix="px", default=SETTINGS.DEFAULT.FONT.size});
        InterfaceOptions.AddColorPicker({id="TIMERCOLOR", label="Ability duration color", default={tint=SETTINGS.DEFAULT.FONT.COLOR.texttimer}});
    InterfaceOptions.StopGroup();

    -- Dreadnaught
    InterfaceOptions.StartGroup({label="Dreadnaught"});
        InterfaceOptions.AddCheckBox({id="HEAVY_ARMOR_ENABLED", label=SETTINGS.DEFAULT.TIMERS.GUARDIAN.HEAVY_ARMOR.name.." enabled", default=SETTINGS.DEFAULT.TIMERS.GUARDIAN.HEAVY_ARMOR.enabled});
        InterfaceOptions.AddCheckBox({id="THUNDERDOME_ENABLED", label=SETTINGS.DEFAULT.TIMERS.GUARDIAN.THUNDERDOME.name.." enabled", default=SETTINGS.DEFAULT.TIMERS.GUARDIAN.THUNDERDOME.enabled});
    InterfaceOptions.StopGroup();

    -- Biotech
    InterfaceOptions.StartGroup({label="Biotech"});
        InterfaceOptions.AddCheckBox({id="ADRENALINE_RUSH_ENABLED", label=SETTINGS.DEFAULT.TIMERS.MEDIC.ADRENALINE_RUSH.name.." enabled", default=SETTINGS.DEFAULT.TIMERS.MEDIC.ADRENALINE_RUSH.enabled});
    InterfaceOptions.StopGroup();

    -- Recon
    InterfaceOptions.StartGroup({label="Recon"});
        InterfaceOptions.AddCheckBox({id="TELEPORT_BEACON_ENABLED", label=SETTINGS.DEFAULT.TIMERS.RECON.TELEPORT_BEACON.name.." enabled", default=SETTINGS.DEFAULT.TIMERS.RECON.TELEPORT_BEACON.enabled});
    InterfaceOptions.StopGroup();

    -- Assault
    InterfaceOptions.StartGroup({label="Assault"});
        InterfaceOptions.AddCheckBox({id="OVERCHARGE_ENABLED", label=SETTINGS.DEFAULT.TIMERS.BERZERKER.OVERCHARGE.name.." enabled", default=SETTINGS.DEFAULT.TIMERS.BERZERKER.OVERCHARGE.enabled});
    InterfaceOptions.StopGroup();

    -- Engineer
    -- InterfaceOptions.StartGroup({label="Engineer"});
    --     InterfaceOptions.AddCheckBox({id="_ENABLED", label="", default=SETTINGS.DEFAULT.TIMERS});
    -- InterfaceOptions.StopGroup();
end

-- ===============================
--  Events
-- ===============================

function OnComponentLoad()
    BuildOptions();

    InterfaceOptions.SetCallbackFunc(OnOptionChanged, "Ability Duration Timer");

    RUMPEL.UpdateText();
end

function OnOptionChanged(id, value)
    if "DEBUG_ENABLED" == id then
        SETTINGS.USER.debug = value;
    elseif "SYSMSG_ENABLED" == id then
        SETTINGS.USER.system_message = value;
    elseif "FONT" == id then
        SETTINGS.USER.FONT.name = value;
    elseif "FONTSIZE" == id then
        SETTINGS.USER.FONT.size = value;
    elseif "TEXTCOLOR" == id then
        SETTINGS.USER.FONT.COLOR.label = value.tint;
    elseif "TIMERCOLOR" == id then
        SETTINGS.USER.FONT.COLOR.texttimer = value.tint;
    elseif "HEAVY_ARMOR_ENABLED" == id then
        SETTINGS.USER.TIMERS.GUARDIAN.HEAVY_ARMOR.enabled = value;
    elseif "THUNDERDOME_ENABLED" == id then
        SETTINGS.USER.TIMERS.GUARDIAN.THUNDERDOME.enabled = value;
    elseif "ADRENALINE_RUSH_ENABLED" == id then
        SETTINGS.USER.TIMERS.MEDIC.ADRENALINE_RUSH.enabled = value;
    elseif "TELEPORT_BEACON_ENABLED" == id then
        SETTINGS.USER.TIMERS.RECON.TELEPORT_BEACON.enabled = value;
    elseif "OVERCHARGE_ENABLED" == id then
        SETTINGS.USER.TIMERS.BERZERKER.OVERCHARGE.enabled = value;
    end

    RUMPEL.UpdateText();
end

function OnAbilityInEffect(args)
    local archetype = Player.GetCurrentArchtype();

    RUMPEL.ConsoleLog("==[ADT.RUMPEL.ConsoleLog(OnAbilityInEffect)]===============");
    RUMPEL.ConsoleLog(archetype);
    RUMPEL.ConsoleLog(args);
end

function OnAbilityUsed(args)
    local archetype = Player.GetCurrentArchtype();

    RUMPEL.ConsoleLog("==[ADT.RUMPEL.ConsoleLog(OnAbilityUsed)]===================");
    RUMPEL.ConsoleLog(archetype);
    RUMPEL.ConsoleLog(args);

    -- local player_all_stats = Player.GetAllStats();

    -- RUMPEL.ConsoleLog(player_all_stats);

    -- local abilities = Player.GetAbilities();

    -- RUMPEL.ConsoleLog(abilities);

    -- local attribute = Player.GetAttribute();

    -- RUMPEL.ConsoleLog(attribute);

    if -1 ~= args.index then
        local ability_id    = args.id;
        -- local ability_state = Player.GetAbilityState(ability_id);
        local ability_info  = Player.GetAbilityInfo(ability_id);

        -- RUMPEL.ConsoleLog(ability_state);
        RUMPEL.ConsoleLog(ability_info);

        if true == DEV_MODE then
            RUMPEL.CreateIcon(ability_info.iconId, 20);
        end
    end
end

function OnAbilityState(args)
    local archetype = Player.GetCurrentArchtype();
    local fill_ui   = false;

    RUMPEL.ConsoleLog("==[ADT.RUMPEL.ConsoleLog(OnAbilityState)]==================");
    RUMPEL.ConsoleLog(archetype);
    RUMPEL.ConsoleLog(args);

    if -1 ~= args.index then
        local ability_name = args.state;

        if "Adrenaline" == ability_name then
            ability_name = SETTINGS.DEFAULT.TIMERS.MEDIC.ADRENALINE_RUSH.name;
        end

        RUMPEL.ConsoleLog("Ability '"..ability_name.."' fired Event 'ON_ABILITY_STATE'!");

        if "guardian" == archetype then
            if
                ability_name == SETTINGS.DEFAULT.TIMERS.GUARDIAN.HEAVY_ARMOR.name
                and
                true == SETTINGS.USER.TIMERS.GUARDIAN.HEAVY_ARMOR.enabled
            then
                fill_ui = true;
            elseif
                ability_name == SETTINGS.DEFAULT.TIMERS.GUARDIAN.THUNDERDOME.name
                and
                true == SETTINGS.USER.TIMERS.GUARDIAN.THUNDERDOME.enabled
            then
                fill_ui = true;
            end
        elseif "medic" == archetype then
            if
                ability_name == SETTINGS.DEFAULT.TIMERS.MEDIC.ADRENALINE_RUSH.name
                and
                true == SETTINGS.USER.TIMERS.MEDIC.ADRENALINE_RUSH.enabled
            then
                fill_ui = true;
            end
        elseif "recon" == archetype then
            if
                ability_name == SETTINGS.DEFAULT.TIMERS.RECON.TELEPORT_BEACON.name
                and
                true == SETTINGS.USER.TIMERS.RECON.TELEPORT_BEACON.enabled
            then
                fill_ui = true;
            end
        elseif "berzerker" == archetype then
            if
                ability_name == SETTINGS.DEFAULT.TIMERS.BERZERKER.OVERCHARGE.name
                and
                true == SETTINGS.USER.TIMERS.BERZERKER.OVERCHARGE.enabled
            then
                fill_ui = true;
            end
        end

        if true == fill_ui then
            local ability_id    = args.id;
            -- local ability_state = Player.GetAbilityState(ability_id);
            -- local ability_info  = Player.GetAbilityInfo(ability_id);

            RUMPEL.ConsoleLog("Ability ID: "..tostring(ability_id));
            -- RUMPEL.ConsoleLog("Player.GetAbilityState()");
            -- RUMPEL.ConsoleLog(ability_state);
            -- RUMPEL.ConsoleLog("Player.GetAbilityInfo()");
            -- RUMPEL.ConsoleLog(ability_info);

            RUMPEL.CreateIcon(ABILITY_INFOS[tonumber(ability_id)].icon_id, args.state_dur_total, ability_name);
        end
    end
end

-- ===============================
--  Functions
-- ===============================

function RUMPEL.CreateIcon(icon_id, duration, ability_name)
    -- widgets from blueprint in xml
    local GRP     = Component.CreateWidget("BP_IconTimer", UI.FRAME);
    local CONTENT = Component.CreateWidget("BP_IconTimer_Content", GRP);

    RUMPEL.UI_TIMERS[RUMPEL.ui_timers_count] = {
        id      = RUMPEL.ui_timers_count,
        GRP     = GRP,
        CONTENT = CONTENT
    };

    RUMPEL.DurTimerMsg(ability_name);
    RUMPEL.SetTimer(RUMPEL.ui_timers_count, icon_id, duration);

    if 100 <= RUMPEL.ui_timers_count then
        RUMPEL.ui_timers_count = 1;
    else
        RUMPEL.ui_timers_count = RUMPEL.ui_timers_count + 1;
    end
end

function RUMPEL.SetTimer(timer_id, icon_id, duration)
    local UI_TIMER = RUMPEL.UI_TIMERS[timer_id];
    local TIMER    = UI_TIMER.CONTENT:GetChild("texttimer");
    local ICON     = UI_TIMER.CONTENT:GetChild("icon");
    local font     = SETTINGS.USER.FONT.name.."_"..tostring(SETTINGS.USER.FONT.size);

    -- Font
    TIMER:SetFont(font);

    -- Font color
    TIMER:SetTextColor("#"..SETTINGS.USER.FONT.COLOR.texttimer);

    ICON:SetIcon(icon_id);

    TIMER:StartTimer(duration, true);
    TIMER:ParamTo("alpha", 1, 0.1);

    local UPDATE_TIMER = Callback2.Create();

    UPDATE_TIMER:Bind(
        function()
            TIMER:ParamTo("alpha", 0, 0.1);
            Component.RemoveWidget(UI_TIMER.GRP);
            RUMPEL.UI_TIMERS[timer_id] = nil;
        end
    );
    UPDATE_TIMER:Schedule(tonumber(duration));
end

function RUMPEL.ConsoleLog(message)
    if true == SETTINGS.USER.debug then
        message = "[DEBUG] "..tostring(message);

        log(message);

        RUMPEL.SystemMsg(message);
    end
end

function RUMPEL.SystemMsg(message)
    Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text = "[ADT] "..tostring(message)});
end

function RUMPEL.DurTimerMsg(ability_name)
    if true == SETTINGS.USER.system_message then
        RUMPEL.SystemMsg("Starting duration timer for '"..ability_name.."'.");
    end
end
