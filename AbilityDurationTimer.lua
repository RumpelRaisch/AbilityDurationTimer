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

RUMPEL.DEV = {
    ui_timers_count = 1,
    UI_TIMERS = {}
};

SETTINGS.DEFAULTS = {
    debug                     = false,
    system_message            = true,
    show_icon_instead_of_text = true,
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
    debug                     = false,
    system_message            = true,
    show_icon_instead_of_text = true,
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
        InterfaceOptions.AddCheckBox({id="DEBUG_ENABLED", label="Debug", default=SETTINGS.DEFAULTS.debug});
        InterfaceOptions.AddCheckBox({id="SYSMSG_ENABLED", label="Chat output (Starting duration timer ...)", default=SETTINGS.DEFAULTS.system_message});
        -- InterfaceOptions.AddCheckBox({id="SHOW_ICON_ENEBLED", label="Show icon instead of ability name", default=SETTINGS.DEFAULTS.show_icon_instead_of_text});
        InterfaceOptions.AddChoiceMenu({id="FONT", label="Font", default=SETTINGS.DEFAULTS.FONT.name});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Demi", label="Eurostile Medium"});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Bold", label="Eurostile Bold"});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuMedium", label="Ubuntu Medium"});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuBold", label="Ubuntu Bold"});
        InterfaceOptions.AddSlider({id="FONTSIZE", label="Fontsize", min=8, max=20, inc=1, suffix="px", default=SETTINGS.DEFAULTS.FONT.size});
        -- InterfaceOptions.AddColorPicker({id="TEXTCOLOR", label="Ability name color", default={tint=SETTINGS.DEFAULTS.FONT.COLOR.label}});
        InterfaceOptions.AddColorPicker({id="TIMERCOLOR", label="Ability duration color", default={tint=SETTINGS.DEFAULTS.FONT.COLOR.texttimer}});
    InterfaceOptions.StopGroup();

    -- Dreadnaught
    InterfaceOptions.StartGroup({label="Dreadnaught"});
        InterfaceOptions.AddCheckBox({id="HEAVY_ARMOR_ENABLED", label=SETTINGS.DEFAULTS.TIMERS.GUARDIAN.HEAVY_ARMOR.name.." enabled", default=SETTINGS.DEFAULTS.TIMERS.GUARDIAN.HEAVY_ARMOR.enabled});
    --     InterfaceOptions.AddTextInput({id="HEAVY_ARMOR_TEXT", label=SETTINGS.DEFAULTS.TIMERS.GUARDIAN.HEAVY_ARMOR.name.." text", default=SETTINGS.DEFAULTS.TIMERS.GUARDIAN.HEAVY_ARMOR.name, maxlen=100});
        InterfaceOptions.AddCheckBox({id="THUNDERDOME_ENABLED", label=SETTINGS.DEFAULTS.TIMERS.GUARDIAN.THUNDERDOME.name.." enabled", default=SETTINGS.DEFAULTS.TIMERS.GUARDIAN.THUNDERDOME.enabled});
    --     InterfaceOptions.AddTextInput({id="THUNDERDOME_TEXT", label=SETTINGS.DEFAULTS.TIMERS.GUARDIAN.THUNDERDOME.name.." text", default=SETTINGS.DEFAULTS.TIMERS.GUARDIAN.THUNDERDOME.name, maxlen=100});
    InterfaceOptions.StopGroup();

    -- Biotech
    InterfaceOptions.StartGroup({label="Biotech"});
        InterfaceOptions.AddCheckBox({id="ADRENALINE_RUSH_ENABLED", label=SETTINGS.DEFAULTS.TIMERS.MEDIC.ADRENALINE_RUSH.name.." enabled", default=SETTINGS.DEFAULTS.TIMERS.MEDIC.ADRENALINE_RUSH.enabled});
    --     InterfaceOptions.AddTextInput({id="ADRENALINE_RUSH_TEXT", label=SETTINGS.DEFAULTS.TIMERS.MEDIC.ADRENALINE_RUSH.name.." text", default=SETTINGS.DEFAULTS.TIMERS.MEDIC.ADRENALINE_RUSH.name, maxlen=100});
    InterfaceOptions.StopGroup();

    -- Recon
    InterfaceOptions.StartGroup({label="Recon"});
        InterfaceOptions.AddCheckBox({id="TELEPORT_BEACON_ENABLED", label=SETTINGS.DEFAULTS.TIMERS.RECON.TELEPORT_BEACON.name.." enabled", default=SETTINGS.DEFAULTS.TIMERS.RECON.TELEPORT_BEACON.enabled});
    --     InterfaceOptions.AddTextInput({id="TELEPORT_BEACON_TEXT", label=SETTINGS.DEFAULTS.TIMERS.RECON.TELEPORT_BEACON.name.." text", default=SETTINGS.DEFAULTS.TIMERS.RECON.TELEPORT_BEACON.name, maxlen=100});
    InterfaceOptions.StopGroup();

    -- Assault
    InterfaceOptions.StartGroup({label="Assault"});
        InterfaceOptions.AddCheckBox({id="OVERCHARGE_ENABLED", label=SETTINGS.DEFAULTS.TIMERS.BERZERKER.OVERCHARGE.name.." enabled", default=SETTINGS.DEFAULTS.TIMERS.BERZERKER.OVERCHARGE.enabled});
    --     InterfaceOptions.AddTextInput({id="OVERCHARGE_TEXT", label=SETTINGS.DEFAULTS.TIMERS.BERZERKER.OVERCHARGE.name.." text", default=SETTINGS.DEFAULTS.TIMERS.BERZERKER.OVERCHARGE.name, maxlen=100});
    InterfaceOptions.StopGroup();

    -- Engineer
    -- InterfaceOptions.StartGroup({label="Engineer"});
    --     InterfaceOptions.AddCheckBox({id="_ENABLED", label="", default=SETTINGS.DEFAULTS.TIMERS});
    --     InterfaceOptions.AddTextInput({id="_TEXT", label="", default=SETTINGS.DEFAULTS.TIMERS, maxlen=100});
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
    elseif "SHOW_ICON_ENEBLED" == id then
        SETTINGS.USER.show_icon_instead_of_text = value;
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
    elseif "HEAVY_ARMOR_TEXT" == id then
        SETTINGS.USER.TIMERS.GUARDIAN.HEAVY_ARMOR.name = value;
    elseif "THUNDERDOME_ENABLED" == id then
        SETTINGS.USER.TIMERS.GUARDIAN.THUNDERDOME.enabled = value;
    elseif "THUNDERDOME_TEXT" == id then
        SETTINGS.USER.TIMERS.GUARDIAN.THUNDERDOME.name = value;
    elseif "ADRENALINE_RUSH_ENABLED" == id then
        SETTINGS.USER.TIMERS.MEDIC.ADRENALINE_RUSH.enabled = value;
    elseif "ADRENALINE_RUSH_TEXT" == id then
        SETTINGS.USER.TIMERS.MEDIC.ADRENALINE_RUSH.name = value;
    elseif "TELEPORT_BEACON_ENABLED" == id then
        SETTINGS.USER.TIMERS.RECON.TELEPORT_BEACON.enabled = value;
    elseif "TELEPORT_BEACON_TEXT" == id then
        SETTINGS.USER.TIMERS.RECON.TELEPORT_BEACON.name = value;
    elseif "OVERCHARGE_ENABLED" == id then
        SETTINGS.USER.TIMERS.BERZERKER.OVERCHARGE.enabled = value;
    elseif "OVERCHARGE_TEXT" == id then
        SETTINGS.USER.TIMERS.BERZERKER.OVERCHARGE.name = value;
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
            RUMPEL.DEV.CreateIcon(ability_info.iconId, 20);
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
            ability_name = SETTINGS.USER.TIMERS.MEDIC.ADRENALINE_RUSH.name;
        end

        RUMPEL.ConsoleLog("Ability '"..ability_name.."' fired Event 'ON_ABILITY_STATE'!");

        if "guardian" == archetype then
            if
                ability_name == SETTINGS.USER.TIMERS.GUARDIAN.HEAVY_ARMOR.name
                and
                true == SETTINGS.USER.TIMERS.GUARDIAN.HEAVY_ARMOR.enabled
            then
                fill_ui = true;
            elseif
                ability_name == SETTINGS.USER.TIMERS.GUARDIAN.THUNDERDOME.name
                and
                true == SETTINGS.USER.TIMERS.GUARDIAN.THUNDERDOME.enabled
            then
                fill_ui = true;
            end
        elseif "medic" == archetype then
            if
                ability_name == SETTINGS.USER.TIMERS.MEDIC.ADRENALINE_RUSH.name
                and
                true == SETTINGS.USER.TIMERS.MEDIC.ADRENALINE_RUSH.enabled
            then
                fill_ui = true;
            end
        elseif "recon" == archetype then
            if
                ability_name == SETTINGS.USER.TIMERS.RECON.TELEPORT_BEACON.name
                and
                true == SETTINGS.USER.TIMERS.RECON.TELEPORT_BEACON.enabled
            then
                fill_ui = true;
            end
        elseif "berzerker" == archetype then
            if
                ability_name == SETTINGS.USER.TIMERS.BERZERKER.OVERCHARGE.name
                and
                true == SETTINGS.USER.TIMERS.BERZERKER.OVERCHARGE.enabled
            then
                fill_ui = true;
            end
        end

        if true == fill_ui then
            if true == SETTINGS.USER.show_icon_instead_of_text then
                local ability_id    = args.id;
                -- local ability_state = Player.GetAbilityState(ability_id);
                -- local ability_info  = Player.GetAbilityInfo(ability_id);

                RUMPEL.ConsoleLog("Ability ID: "..tostring(ability_id));
                -- RUMPEL.ConsoleLog("Player.GetAbilityState()");
                -- RUMPEL.ConsoleLog(ability_state);
                -- RUMPEL.ConsoleLog("Player.GetAbilityInfo()");
                -- RUMPEL.ConsoleLog(ability_info);

                RUMPEL.DEV.CreateIcon(ABILITY_INFOS[tonumber(ability_id)].icon_id, args.state_dur_total, ability_name);
            else
                RUMPEL.FillUiFrame(ability_name, args.state_dur_total);
            end
        end
    end
end

-- ===============================
--  Functions
-- ===============================

function RUMPEL.DEV.CreateIcon(icon_id, duration, ability_name)
    -- widgets from blueprint in xml
    local GRP     = Component.CreateWidget("BP_IconTimer", UI.FRAME);
    local CONTENT = Component.CreateWidget("BP_IconTimer_Content", GRP);

    RUMPEL.DEV.UI_TIMERS[RUMPEL.DEV.ui_timers_count] = {
        GRP     = GRP,
        CONTENT = CONTENT
    };

    RUMPEL.DurTimerMsg(ability_name);
    RUMPEL.DEV.SetTimer(RUMPEL.DEV.ui_timers_count, icon_id, duration);

    if 100 <= RUMPEL.DEV.ui_timers_count then
        RUMPEL.DEV.ui_timers_count = 1;
    else
        RUMPEL.DEV.ui_timers_count = RUMPEL.DEV.ui_timers_count + 1;
    end
end

function RUMPEL.DEV.SetTimer(timer_id, icon_id, duration)
    local UI_TIMER = RUMPEL.DEV.UI_TIMERS[timer_id];
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
        end
    );
    UPDATE_TIMER:Schedule(tonumber(duration));
end

function RUMPEL.UpdateText()
    local font = SETTINGS.USER.FONT.name.."_"..tostring(SETTINGS.USER.FONT.size);

    -- Font
    UI.GRP.LABEL:SetFont(font);
    UI.GRP.TEXTTIMER:SetFont(font);

    -- Font color
    UI.GRP.LABEL:SetTextColor("#"..SETTINGS.USER.FONT.COLOR.label);
    UI.GRP.TEXTTIMER:SetTextColor("#"..SETTINGS.USER.FONT.COLOR.texttimer);
end

function RUMPEL.FillUiFrame(ability_name, duration)
    RUMPEL.DurTimerMsg(ability_name);

    UI.GRP.LABEL:SetText(ability_name);
    UI.GRP.LABEL:ParamTo("alpha", 1, 0.1);

    RUMPEL.SetTimer(duration);
end

function RUMPEL.SetTimer(duration)
    UI.GRP.TEXTTIMER:StartTimer(duration, true);
    UI.GRP.TEXTTIMER:ParamTo("alpha", 1, 0.1);

    local updateTimer = Callback2.Create();

    updateTimer:Bind(
        function()
            UI.GRP.TEXTTIMER:ParamTo("alpha", 0, 0.1);
            UI.GRP.LABEL:ParamTo("alpha", 0, 0.1);
        end
    );
    updateTimer:Schedule(tonumber(duration));
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
