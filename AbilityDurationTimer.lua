-- =============================================================================
--  Ability Duration Timer
--  by: Rumpel
-- =============================================================================
--  Shows duration timer for abilities.
-- =============================================================================
--  Thanks to Vollmond for sharing his little addon "Simple Ability Timer" on
--  wich this addon is based on.
--   - http://forums.firefall.com/community/threads/7375721/#post-106885821
--
--  Thanks to NoReal and Reddeyfish for StatusIndicator addon wich was/is an
--  inspiration.
--
--  Also thanks to (for answering my questions in IRC):
--   - Arkii
--   - BurstBiscuit
--   - Hanachi
--   - Syna
--   - Xsear
--
--  Special thanks to my (main) testers:
--   - Fac3man
--   - Safada
-- =============================================================================

require "string";
require "lib/lib_Callback2";
require "lib/lib_InterfaceOptions";
require "lib/lib_Slash";
require "./ADT";

-- =============================================================================
--  Variables
-- =============================================================================

local UI                = {};
local RUMPEL            = {};
local SETTINGS          = {};
local ABILITY_INFOS     = {};
local ABILITY_ALIAS     = {};
local ABILITY_DURATIONS = {};
local ON_ABILITY_STATE  = {};
local slash_list        = "adt";

UI.ALIGNMENT = {};
UI.FRAME     = Component.GetFrame("adt_frame");

UI.ALIGNMENT["ltr"] = 68;
UI.ALIGNMENT["rtl"] = -68;

RUMPEL.KNOWN_ABILITIES                     = {};
RUMPEL.KNOWN_ABILITIES["ON_ABILITY_USED"]  = {};
RUMPEL.KNOWN_ABILITIES["ON_ABILITY_STATE"] = {};

RUMPEL.ABILITIES_RM_ON_REUSE                               = {};
-- RUMPEL.ABILITIES_RM_ON_REUSE["Bulwark"]                    = true; -- TODO: check this
RUMPEL.ABILITIES_RM_ON_REUSE["ort Beacon|Teleport Beacon"] = true;
RUMPEL.ABILITIES_RM_ON_REUSE["[TEST]"]                     = true;

SETTINGS = {
    debug            = false,
    system_message   = false,
    max_timers       = 12,
    timers_alignment = "ltr",
    -- objects
    TIMERS = {},
    FONT   = {
        name = "Demi",
        size = 16,
        -- objects
        COLOR = {
            text_timer         = "FF8800",
            text_timer_outline = "000000"
        }
    }
};

-- ABILITY_INFOS[3782]  = {icon_id = 202130}; -- Heavy Armor
-- ABILITY_INFOS[1726]  = {icon_id = 222527}; -- Thunderdome
-- ABILITY_INFOS[34066] = {icon_id = 202138}; -- Dreadfield
-- ABILITY_INFOS[41881] = {icon_id = 212177}; -- Absorption Bomb
-- ABILITY_INFOS[15206] = {icon_id = 492574}; -- Adrenaline Rush
-- ABILITY_INFOS[12305] = {icon_id = 202115}; -- Teleport Beacon
-- ABILITY_INFOS[3639]  = {icon_id = 222507}; -- Overcharge
-- ABILITY_INFOS[41880] = {icon_id = 222507}; -- Overclock [ON_ABILITY_USED]
-- ABILITY_INFOS[15229] = {icon_id = 222507}; -- Overclock [ON_ABILITY_STATE] (named Overcharge ...)
-- ABILITY_INFOS[35455] = {icon_id = 222475}; -- Bulwark
-- ABILITY_INFOS[41886] = {icon_id = 222491}; -- Fortify

ABILITY_ALIAS["Activate: Rocket Wings"] = "Rocketeer's Wings";
ABILITY_ALIAS["Adrenaline"]             = "Adrenaline Rush";
ABILITY_ALIAS["Cryo Bolt"]              = "Cryo Shot";

ABILITY_ALIAS["[ON_ABILITY_STATE]"]                    = {};
ABILITY_ALIAS["[ON_ABILITY_STATE]"]["Teleport Beacon"] = "ort Beacon"; -- TODO: check this
ABILITY_ALIAS["[ON_ABILITY_STATE]"]["ort Beacon"]      = "Teleport Beacon"; -- TODO: check this

ABILITY_ALIAS["[ON_ABILITY_USED]"] = {};

ABILITY_ALIAS["[PLAYER_STATS]"]                     = {};
ABILITY_ALIAS["[PLAYER_STATS]"]["Artillery Strike"] = "Accord Artillery Strike";
ABILITY_ALIAS["[PLAYER_STATS]"]["Cryo Bolt"]        = "Cryo Bomb Snare"; -- Cryo Shot
ABILITY_ALIAS["[PLAYER_STATS]"]["Fuel Air Bomb"]    = "Fuel Air Bomb Fire Patch";
ABILITY_ALIAS["[PLAYER_STATS]"]["Hellfire"]         = "Missile Barrage";

ABILITY_DURATIONS["Activate: Rocket Wings"] = 16;

ON_ABILITY_STATE["Adrenaline"]      = true;
ON_ABILITY_STATE["Heavy Armor"]     = true;
ON_ABILITY_STATE["Overcharge"]      = true;
ON_ABILITY_STATE["Teleport Beacon"] = true;
ON_ABILITY_STATE["Thunderdome"]     = true;
ON_ABILITY_STATE[15229]             = false; -- Overclock [ON_ABILITY_STATE] (named Overcharge ...)
ON_ABILITY_STATE[2843]              = false; -- Decoy [ON_ABILITY_STATE] (named Heavy Armor ...)
ON_ABILITY_STATE[15231]             = false; -- Absorption Bomb

-- Dreadnaught
SETTINGS.TIMERS["Absorption Bomb"] = true;
SETTINGS.TIMERS["Dreadfield"]      = true;
SETTINGS.TIMERS["Heavy Armor"]     = true;
SETTINGS.TIMERS["Thunderdome"]     = true;

-- Biotech
SETTINGS.TIMERS["Adrenaline"]     = true;
SETTINGS.TIMERS["Creeping Death"] = true;
SETTINGS.TIMERS["Heroism"]        = true;
SETTINGS.TIMERS["Necrosis"]       = true;
SETTINGS.TIMERS["Poison Ball"]    = true;
SETTINGS.TIMERS["Poison Trail"]   = true;

-- Recon
SETTINGS.TIMERS["Artillery Strike"] = true;
SETTINGS.TIMERS["Cryo Bolt"]        = true; -- Cryo Shot
SETTINGS.TIMERS["Decoy"]            = true;
SETTINGS.TIMERS["SIN Beacon"]       = true;
SETTINGS.TIMERS["Teleport Beacon"]  = true;

-- Assault
-- SETTINGS.TIMERS["Fuel Air Bomb"] = true; -- meh
-- SETTINGS.TIMERS["Fuel Cloud"]    = true; -- meh
SETTINGS.TIMERS["Hellfire"]      = true;
SETTINGS.TIMERS["Overcharge"]    = true;
SETTINGS.TIMERS["Thermal Wave"]  = true;

-- Engineer
SETTINGS.TIMERS["Bulwark"]   = true;
SETTINGS.TIMERS["Fortify"]   = true;
SETTINGS.TIMERS["Overclock"] = true;

-- Miscellaneous
SETTINGS.TIMERS["Activate: Rocket Wings"] = true;

-- =============================================================================
--  Options
-- =============================================================================

function BuildOptions()
    InterfaceOptions.AddMovableFrame({frame=UI.FRAME, label="Ability Duration Timer", scalable=true});

    InterfaceOptions.StartGroup({label="Ability Duration Timer: Main Settings"});
        InterfaceOptions.AddCheckBox({id="DEBUG_ENABLED", label="Debug enabled", default=(Component.GetSetting("DEBUG_ENABLED") or SETTINGS.debug)});
        InterfaceOptions.AddCheckBox({id="SYSMSG_ENABLED", label="Chat output (Starting duration timer ...) enabled", default=(Component.GetSetting("SYSMSG_ENABLED") or SETTINGS.system_message)});
        InterfaceOptions.AddSlider({id="MAX_TIMERS", label="max timers", min=1, max=50, inc=1, suffix="", default=(Component.GetSetting("MAX_TIMERS") or SETTINGS.max_timers)});
        InterfaceOptions.AddChoiceMenu({id="TIMERS_ALIGNMENT", label="Timer alignment", default=(Component.GetSetting("TIMERS_ALIGNMENT") or SETTINGS.timers_alignment)});
            InterfaceOptions.AddChoiceEntry({menuId="TIMERS_ALIGNMENT", val="ltr", label="left to right"});
            InterfaceOptions.AddChoiceEntry({menuId="TIMERS_ALIGNMENT", val="rtl", label="right to left"});
        InterfaceOptions.AddChoiceMenu({id="FONT", label="Font", default=(Component.GetSetting("FONT") or SETTINGS.FONT.name)});
            InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Demi", label="Eurostile Medium"});
            InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Narrow", label="Eurostile Narrow"});
            InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Wide", label="Eurostile Wide"});
            InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Bold", label="Eurostile Bold"});
            InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuRegular", label="Ubuntu Regular"});
            InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuMedium", label="Ubuntu Medium"});
            InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuBold", label="Ubuntu Bold"});
        InterfaceOptions.AddSlider({id="FONT_SIZE", label="Font size", min=1, max=20, inc=1, suffix="", default=(Component.GetSetting("FONT_SIZE") or SETTINGS.FONT.size)});
        InterfaceOptions.AddColorPicker({id="TIMER_COLOR", label="Ability duration color", default={tint=(Component.GetSetting("TIMER_COLOR") or SETTINGS.FONT.COLOR.text_timer)}});
        InterfaceOptions.AddColorPicker({id="TIMER_COLOR_OUTLINE", label="Ability duration outline color", default={tint=(Component.GetSetting("TIMER_COLOR_OUTLINE") or SETTINGS.FONT.COLOR.text_timer_outline)}});
    InterfaceOptions.StopGroup();

    -- Dreadnaught
    InterfaceOptions.StartGroup({label="Dreadnaught"});
        InterfaceOptions.AddCheckBox({id="ABSORPTION_BOMB_ENABLED", label="Absorption Bomb enabled", default=(Component.GetSetting("ABSORPTION_BOMB_ENABLED") or SETTINGS.TIMERS["Absorption Bomb"])});
        InterfaceOptions.AddCheckBox({id="DREADFIELD_ENABLED", label="Dreadfield enabled", default=(Component.GetSetting("DREADFIELD_ENABLED") or SETTINGS.TIMERS["Dreadfield"])});
        InterfaceOptions.AddCheckBox({id="HEAVY_ARMOR_ENABLED", label="Heavy Armor enabled", default=(Component.GetSetting("HEAVY_ARMOR_ENABLED") or SETTINGS.TIMERS["Heavy Armor"])});
        InterfaceOptions.AddCheckBox({id="THUNDERDOME_ENABLED", label="Thunderdome enabled", default=(Component.GetSetting("THUNDERDOME_ENABLED") or SETTINGS.TIMERS["Thunderdome"])});
    InterfaceOptions.StopGroup();

    -- Biotech
    InterfaceOptions.StartGroup({label="Biotech"});
        InterfaceOptions.AddCheckBox({id="CREEPING_DEATH_ENABLED", label="Creeping Death enabled", default=(Component.GetSetting("CREEPING_DEATH_ENABLED") or SETTINGS.TIMERS["Creeping Death"])});
        InterfaceOptions.AddCheckBox({id="ADRENALINE_RUSH_ENABLED", label="Adrenaline Rush enabled", default=(Component.GetSetting("ADRENALINE_RUSH_ENABLED") or SETTINGS.TIMERS["Adrenaline"])});
        InterfaceOptions.AddCheckBox({id="NECROSIS_ENABLED", label="Necrosis enabled", default=(Component.GetSetting("NECROSIS_ENABLED") or SETTINGS.TIMERS["Necrosis"])});
        InterfaceOptions.AddCheckBox({id="HEROISM_ENABLED", label="Heroism enabled", default=(Component.GetSetting("HEROISM_ENABLED") or SETTINGS.TIMERS["Heroism"])});
        InterfaceOptions.AddCheckBox({id="POISON_BALL_ENABLED", label="Poison Ball enabled", default=(Component.GetSetting("POISON_BALL_ENABLED") or SETTINGS.TIMERS["Poison Ball"])});
        InterfaceOptions.AddCheckBox({id="POISON_TRAIL_ENABLED", label="Poison Trail enabled", default=(Component.GetSetting("POISON_TRAIL_ENABLED") or SETTINGS.TIMERS["Poison Trail"])});
    InterfaceOptions.StopGroup();

    -- Recon
    InterfaceOptions.StartGroup({label="Recon"});
        InterfaceOptions.AddCheckBox({id="ARTILLERY_STRIKE_ENABLED", label="Artillery Strike enabled", default=(Component.GetSetting("ARTILLERY_STRIKE_ENABLED") or SETTINGS.TIMERS["Artillery Strike"])});
        InterfaceOptions.AddCheckBox({id="CRYO_BOLT_ENABLED", label="Cryo Shot enabled", default=(Component.GetSetting("CRYO_BOLT_ENABLED") or SETTINGS.TIMERS["Cryo Bolt"])});
        InterfaceOptions.AddCheckBox({id="DECOY_ENABLED", label="Decoy enabled", default=(Component.GetSetting("DECOY_ENABLED") or SETTINGS.TIMERS["Decoy"])});
        InterfaceOptions.AddCheckBox({id="SIN_BEACON_ENABLED", label="SIN Beacon enabled", default=(Component.GetSetting("SIN_BEACON_ENABLED") or SETTINGS.TIMERS["SIN Beacon"])});
        InterfaceOptions.AddCheckBox({id="TELEPORT_BEACON_ENABLED", label="Teleport Beacon enabled", default=(Component.GetSetting("TELEPORT_BEACON_ENABLED") or SETTINGS.TIMERS["Teleport Beacon"])});
    InterfaceOptions.StopGroup();

    -- Assault
    InterfaceOptions.StartGroup({label="Assault"});
        InterfaceOptions.AddCheckBox({id="HELLFIRE_ENABLED", label="Hellfire enabled", default=(Component.GetSetting("HELLFIRE_ENABLED") or SETTINGS.TIMERS["Hellfire"])});
        InterfaceOptions.AddCheckBox({id="OVERCHARGE_ENABLED", label="Overcharge enabled", default=(Component.GetSetting("OVERCHARGE_ENABLED") or SETTINGS.TIMERS["Overcharge"])});
        InterfaceOptions.AddCheckBox({id="THERMAL_WAVE_ENABLED", label="Thermal Wave enabled", default=(Component.GetSetting("THERMAL_WAVE_ENABLED") or SETTINGS.TIMERS["Thermal Wave"])});
    InterfaceOptions.StopGroup();

    -- Engineer
    InterfaceOptions.StartGroup({label="Engineer"});
        InterfaceOptions.AddCheckBox({id="FORTIFY_ENABLED", label="Fortify enabled", default=(Component.GetSetting("FORTIFY_ENABLED") or SETTINGS.TIMERS["Fortify"])});
        InterfaceOptions.AddCheckBox({id="BULWARK_ENABLED", label="Bulwark enabled", default=(Component.GetSetting("BULWARK_ENABLED") or SETTINGS.TIMERS["Bulwark"])});
        InterfaceOptions.AddCheckBox({id="OVERCLOCK_ENABLED", label="Overclock enabled", default=(Component.GetSetting("OVERCLOCK_ENABLED") or SETTINGS.TIMERS["Overclock"])});
    InterfaceOptions.StopGroup();

    -- Miscellaneous
    InterfaceOptions.StartGroup({label="Miscellaneous"});
        InterfaceOptions.AddCheckBox({id="ROCKETEERS_WINGS_ENABLED", label="Rocketeer's Wings enabled", default=(Component.GetSetting("ROCKETEERS_WINGS_ENABLED") or SETTINGS.TIMERS["Activate: Rocket Wings"])});
    InterfaceOptions.StopGroup();
end

-- =============================================================================
--  Events
-- =============================================================================

function OnComponentLoad()
    BuildOptions();

    InterfaceOptions.SetCallbackFunc(OnOptionChanged, "Ability Duration Timer");

    LIB_SLASH.BindCallback({slash_list=slash_list, func=OnSlash});

    RUMPEL.GetKnownAbilities();
end

function OnComponentUnload()
    LIB_SLASH.UnbindCallback(slash_list);
end

function OnSlash(ARGS)
    -- RUMPEL.ConsoleLog("OnSlash with args: "..tostring(ARGS));

    if 42 == tonumber(ARGS[1]) then
        RUMPEL.TestTimers();
    elseif "rm" == ARGS[1] then
        AbilityDurationTimer.KillAll();
    elseif "pstats" == ARGS[1] then
        log(tostring(Player.GetAllStats()));
    elseif "timers" == ARGS[1] then
        RUMPEL.SystemMsg("Active Timers: "..tostring(AbilityDurationTimer.GetActive()));
    elseif "test" == ARGS[1] then
        RUMPEL.Test();
    else
        RUMPEL.SystemMsg("Unknown slash argument!");
    end
end

function OnShow(ARGS)
    UI.FRAME:Show(ARGS.show);
end

function OnBattleframeChanged()
    AbilityDurationTimer.KillAll();
end

function OnDeath()
    AbilityDurationTimer.KillAll();
end

function OnOptionChanged(id, value)
    AbilityDurationTimer.KillAll();

    if "DEBUG_ENABLED" == id then
        SETTINGS.debug = value;
        Component.SaveSetting("DEBUG_ENABLED", value);
    elseif "SYSMSG_ENABLED" == id then
        SETTINGS.system_message = value;
        Component.SaveSetting("SYSMSG_ENABLED", value);
    elseif "MAX_TIMERS" == id then
        SETTINGS.max_timers = value;
        Component.SaveSetting("MAX_TIMERS", value);
        AbilityDurationTimer.SetMaxVisible(value);
    elseif "TIMERS_ALIGNMENT" == id then
        SETTINGS.timers_alignment = value;
        Component.SaveSetting("TIMERS_ALIGNMENT", value);
        AbilityDurationTimer.SetAlignment(UI.ALIGNMENT[value]);
    elseif "FONT" == id then
        SETTINGS.FONT.name = value;
        Component.SaveSetting("FONT", value);
        AbilityDurationTimer.SetFontName(value);
    elseif "FONT_SIZE" == id then
        SETTINGS.FONT.size = value;
        Component.SaveSetting("FONT_SIZE", value);
        AbilityDurationTimer.SetFontSize(value);
    elseif "TIMER_COLOR" == id then
        SETTINGS.FONT.COLOR.text_timer = value.tint;
        Component.SaveSetting("TIMER_COLOR", value.tint);
        AbilityDurationTimer.SetFontColor(value.tint);
    elseif "TIMER_COLOR_OUTLINE" == id then
        SETTINGS.FONT.COLOR.text_timer_outline = value.tint;
        Component.SaveSetting("TIMER_COLOR_OUTLINE", value.tint);
        AbilityDurationTimer.SetFontColorOutline(value.tint);
    elseif "HEAVY_ARMOR_ENABLED" == id then
        SETTINGS.TIMERS["Heavy Armor"] = value;
        Component.SaveSetting("HEAVY_ARMOR_ENABLED", value);
    elseif "THUNDERDOME_ENABLED" == id then
        SETTINGS.TIMERS["Thunderdome"] = value;
        Component.SaveSetting("THUNDERDOME_ENABLED", value);
    elseif "DREADFIELD_ENABLED" == id then
        SETTINGS.TIMERS["Dreadfield"] = value;
        Component.SaveSetting("DREADFIELD_ENABLED", value);
    elseif "ABSORPTION_BOMB_ENABLED" == id then
        SETTINGS.TIMERS["Absorption Bomb"] = value;
        Component.SaveSetting("ABSORPTION_BOMB_ENABLED", value);
    elseif "ADRENALINE_RUSH_ENABLED" == id then
        SETTINGS.TIMERS["Adrenaline"] = value;
        Component.SaveSetting("ADRENALINE_RUSH_ENABLED", value);
    elseif "NECROSIS_ENABLED" == id then
        SETTINGS.TIMERS["Necrosis"] = value;
        Component.SaveSetting("NECROSIS_ENABLED", value);
    elseif "HEROISM_ENABLED" == id then
        SETTINGS.TIMERS["Heroism"] = value;
        Component.SaveSetting("HEROISM_ENABLED", value);
    elseif "TELEPORT_BEACON_ENABLED" == id then
        SETTINGS.TIMERS["Teleport Beacon"] = value;
        Component.SaveSetting("TELEPORT_BEACON_ENABLED", value);
    elseif "OVERCHARGE_ENABLED" == id then
        SETTINGS.TIMERS["Overcharge"] = value;
        Component.SaveSetting("OVERCHARGE_ENABLED", value);
    elseif "THERMAL_WAVE_ENABLED" == id then
        SETTINGS.TIMERS["Thermal Wave"] = value;
        Component.SaveSetting("THERMAL_WAVE_ENABLED", value);
    elseif "HELLFIRE_ENABLED" == id then
        SETTINGS.TIMERS["Hellfire"] = value;
        Component.SaveSetting("HELLFIRE_ENABLED", value);
    elseif "BULWARK_ENABLED" == id then
        SETTINGS.TIMERS["Bulwark"] = value;
        Component.SaveSetting("BULWARK_ENABLED", value);
    elseif "OVERCLOCK_ENABLED" == id then
        SETTINGS.TIMERS["Overclock"] = value;
        Component.SaveSetting("OVERCLOCK_ENABLED", value);
    elseif "FORTIFY_ENABLED" == id then
        SETTINGS.TIMERS["Fortify"] = value;
        Component.SaveSetting("FORTIFY_ENABLED", value);
    elseif "ROCKETEERS_WINGS_ENABLED" == id then
        SETTINGS.TIMERS["Activate: Rocket Wings"] = value;
        Component.SaveSetting("ROCKETEERS_WINGS_ENABLED", value);
    elseif "CREEPING_DEATH_ENABLED" == id then
        SETTINGS.TIMERS["Creeping Death"] = value;
        Component.SaveSetting("CREEPING_DEATH_ENABLED", value);
    elseif "POISON_BALL_ENABLED" == id then
        SETTINGS.TIMERS["Poison Ball"] = value;
        Component.SaveSetting("POISON_BALL_ENABLED", value);
    elseif "POISON_TRAIL_ENABLED" == id then
        SETTINGS.TIMERS["Poison Trail"] = value;
        Component.SaveSetting("POISON_TRAIL_ENABLED", value);
    elseif "ARTILLERY_STRIKE_ENABLED" == id then
        SETTINGS.TIMERS["Artillery Strike"] = value;
        Component.SaveSetting("ARTILLERY_STRIKE_ENABLED", value);
    elseif "CRYO_BOLT_ENABLED" == id then
        SETTINGS.TIMERS["Cryo Bolt"] = value;
        Component.SaveSetting("CRYO_BOLT_ENABLED", value);
    elseif "DECOY_ENABLED" == id then
        SETTINGS.TIMERS["Decoy"] = value;
        Component.SaveSetting("DECOY_ENABLED", value);
    elseif "SIN_BEACON_ENABLED" == id then
        SETTINGS.TIMERS["SIN Beacon"] = value;
        Component.SaveSetting("SIN_BEACON_ENABLED", value);
    end

    RUMPEL.Log("OnOptionChanged("..tostring(id)..", "..tostring(value)..")");
end

function OnAbilityUsed(ARGS)
    if -1 ~= ARGS.index then
        local ABILITY_INFO = Player.GetAbilityInfo(ARGS.id);

        RUMPEL.ConsoleLog("Ability '"..ABILITY_INFO.name.."' fired Event 'ON_ABILITY_USED'!");
        RUMPEL.ConsoleLog("ID: "..tostring(ARGS.id));
        RUMPEL.ConsoleLog("NAME: "..ABILITY_INFO.name);
        RUMPEL.ConsoleLog("ICON ID: "..tostring(ABILITY_INFO.iconId));

        local ability_duration = ABILITY_DURATIONS[ABILITY_INFO.name] or RUMPEL.GetAbilityDuration((ABILITY_ALIAS["[PLAYER_STATS]"][ABILITY_INFO.name] or ABILITY_INFO.name));

        RUMPEL.ConsoleLog("DURATION: "..tostring(ability_duration));

        local ability_reports_duration = 0;

        if nil ~= ability_duration then
            ability_reports_duration = 1;
        end

        RUMPEL.PostAbilityInfos(
        {
            ability_id               = tostring(ARGS.id),
            ability_icon_id          = tostring(ABILITY_INFO.iconId),
            ability_name             = tostring(ABILITY_INFO.name),
            ability_event            = "ON_ABILITY_USED",
            ability_reports_duration = tostring(ability_reports_duration)
        });

        -- RUMPEL.SystemMsg("ON_ABILITY_USED");

        local name_check = ABILITY_INFO.name;

        if nil ~= ABILITY_ALIAS["[ON_ABILITY_STATE]"][ABILITY_INFO.name] then
            name_check = name_check.."|"..ABILITY_ALIAS["[ON_ABILITY_STATE]"][ABILITY_INFO.name]; -- ON_ABILITY_STATE last
        elseif nil ~= ABILITY_ALIAS["[ON_ABILITY_USED]"][ABILITY_INFO.name] then -- meh
            -- RUMPEL.SystemMsg(RUMPEL.ABILITIES_RM_ON_REUSE[name_check.."|"..ABILITY_ALIAS["[ON_ABILITY_USED]"][ABILITY_INFO.name]]);
            -- RUMPEL.SystemMsg(RUMPEL.ABILITIES_RM_ON_REUSE[ABILITY_ALIAS["[ON_ABILITY_USED]"][ABILITY_INFO.name].."|"..name_check]);

            if nil ~= RUMPEL.ABILITIES_RM_ON_REUSE[name_check.."|"..ABILITY_ALIAS["[ON_ABILITY_USED]"][ABILITY_INFO.name]] then
                name_check = name_check.."|"..ABILITY_ALIAS["[ON_ABILITY_USED]"][ABILITY_INFO.name];
            elseif nil ~= RUMPEL.ABILITIES_RM_ON_REUSE[ABILITY_ALIAS["[ON_ABILITY_USED]"][ABILITY_INFO.name].."|"..name_check] then
                name_check = ABILITY_ALIAS["[ON_ABILITY_USED]"][ABILITY_INFO.name].."|"..name_check;
            end
        end

        -- RUMPEL.SystemMsg(name_check);
        -- RUMPEL.SystemMsg(RUMPEL.ABILITIES_RM_ON_REUSE[name_check]);

        if nil ~= RUMPEL.ABILITIES_RM_ON_REUSE[name_check] and "table" == type(RUMPEL.ABILITIES_RM_ON_REUSE[name_check]) then
            RUMPEL.ABILITIES_RM_ON_REUSE[name_check]:Reschedule(0);
        elseif nil ~= ability_duration and true ~= ON_ABILITY_STATE[ABILITY_INFO.name] and true == SETTINGS.TIMERS[ABILITY_INFO.name] then
            RUMPEL.ConsoleLog("AbilityDurationTimer.New()");

            local ADT = AbilityDurationTimer.New(UI.FRAME);

            RUMPEL.SetRmOnReuse(ADT);

            ADT:SetAbilityID(ARGS.id);
            ADT:SetAbilityName(ABILITY_INFO.name);
            ADT:SetNameCheck(name_check);
            ADT:SetIconID(ABILITY_INFO.iconId);
            ADT:SetDuration(ability_duration);
            ADT:StartTimer(RUMPEL.Callback);
        end
    end
end

function OnAbilityState(ARGS)
    if -1 ~= ARGS.index then
        local ability_name = tostring(ARGS.state);
        local ability_id   = tonumber(ARGS.id);
        local icon_id      = 0;

        if nil ~= ABILITY_INFOS[ability_id] then
            icon_id = ABILITY_INFOS[ability_id].icon_id;
        end

        RUMPEL.ConsoleLog("Ability '"..ability_name.."' fired Event 'ON_ABILITY_STATE'!");
        RUMPEL.ConsoleLog("ID: "..tostring(ability_id));
        RUMPEL.ConsoleLog("NAME: "..ability_name);
        RUMPEL.ConsoleLog("ICON ID: "..tostring(icon_id));
        RUMPEL.ConsoleLog("DURATION: "..tostring(ARGS.state_dur_total));
        RUMPEL.ConsoleLog("ON_ABILITY_STATE[ability_id]: "..tostring(ON_ABILITY_STATE[ability_id] or 0));

        local ability_reports_duration = 0;

        if nil ~= ARGS.state_dur_total then
            ability_reports_duration = 1;
        end

        RUMPEL.PostAbilityInfos(
        {
            ability_id               = tostring(ability_id),
            ability_icon_id          = tostring(icon_id),
            ability_name             = ability_name,
            ability_event            = "ON_ABILITY_STATE",
            ability_reports_duration = tostring(ability_reports_duration)
        });

        -- RUMPEL.SystemMsg("ON_ABILITY_STATE");

        local name_check = ability_name;

        if nil ~= ABILITY_ALIAS["[ON_ABILITY_USED]"][ability_name] then
            name_check = ABILITY_ALIAS["[ON_ABILITY_USED]"][ability_name].."|"..name_check; -- ON_ABILITY_STATE last
        elseif nil ~= ABILITY_ALIAS["[ON_ABILITY_STATE]"][ability_name] then -- meh
            -- RUMPEL.SystemMsg(RUMPEL.ABILITIES_RM_ON_REUSE[name_check.."|"..ABILITY_ALIAS["[ON_ABILITY_STATE]"][ability_name]]);
            -- RUMPEL.SystemMsg(RUMPEL.ABILITIES_RM_ON_REUSE[ABILITY_ALIAS["[ON_ABILITY_STATE]"][ability_name].."|"..name_check]);

            if nil ~= RUMPEL.ABILITIES_RM_ON_REUSE[name_check.."|"..ABILITY_ALIAS["[ON_ABILITY_STATE]"][ability_name]] then
                name_check = name_check.."|"..ABILITY_ALIAS["[ON_ABILITY_STATE]"][ability_name];
            elseif nil ~= RUMPEL.ABILITIES_RM_ON_REUSE[ABILITY_ALIAS["[ON_ABILITY_STATE]"][ability_name].."|"..name_check] then
                name_check = ABILITY_ALIAS["[ON_ABILITY_STATE]"][ability_name].."|"..name_check;
            end
        end

        -- RUMPEL.SystemMsg(name_check);
        -- RUMPEL.SystemMsg(RUMPEL.ABILITIES_RM_ON_REUSE[name_check]);

        if nil ~= RUMPEL.ABILITIES_RM_ON_REUSE[name_check] and "table" == type(RUMPEL.ABILITIES_RM_ON_REUSE[name_check]) then
            RUMPEL.ABILITIES_RM_ON_REUSE[name_check]:Reschedule(0);
        elseif true == SETTINGS.TIMERS[ability_name] and false ~= ON_ABILITY_STATE[ability_name] and false ~= ON_ABILITY_STATE[ability_id] then
            RUMPEL.ConsoleLog("AbilityDurationTimer.New()");

            local ADT = AbilityDurationTimer.New(UI.FRAME);

            RUMPEL.SetRmOnReuse(ADT);

            ADT:SetAbilityID(ability_id);
            ADT:SetAbilityName(ability_name);
            ADT:SetNameCheck(name_check);
            ADT:SetIconID(icon_id);
            ADT:SetDuration(ARGS.state_dur_total);
            ADT:StartTimer(RUMPEL.Callback);
        end
    end
end

-- =============================================================================
--  Functions
-- =============================================================================

function RUMPEL.Callback(ADT)
    local name_check = ADT:GetNameCheck();

    if nil ~= RUMPEL.ABILITIES_RM_ON_REUSE[name_check] and "table" == type(RUMPEL.ABILITIES_RM_ON_REUSE[name_check]) then
        RUMPEL.ABILITIES_RM_ON_REUSE[name_check] = true;
    end
end

function RUMPEL.SetRmOnReuse(ADT) -- TODO: look into this
    local name_check = ADT:GetNameCheck();
    if nil ~= RUMPEL.ABILITIES_RM_ON_REUSE[name_check] then
        if true == RUMPEL.ABILITIES_RM_ON_REUSE[name_check] then
            RUMPEL.ABILITIES_RM_ON_REUSE[name_check] = ADT;
        elseif "table" == type(RUMPEL.ABILITIES_RM_ON_REUSE[name_check]) then
            RUMPEL.ABILITIES_RM_ON_REUSE[name_check]:Reschedule(0);

            while "table" == type(RUMPEL.ABILITIES_RM_ON_REUSE[name_check]) do
                -- nothing
            end

            RUMPEL.ABILITIES_RM_ON_REUSE[ADT.name_check] = ADT;
        end
    end
end

function RUMPEL.GetAbilityDuration(ability_name)
    local PLAYER_ALL_STATS = Player.GetAllStats();

    ability_name = string.lower(ability_name);

    for i,_ in pairs(PLAYER_ALL_STATS.item_attributes) do
        local designer_name = string.lower(PLAYER_ALL_STATS.item_attributes[i].designer_name);
        local MATCH         = {
            {string.find(designer_name, "^(.*) ability duration")},
            {string.find(designer_name, "^(.*) buff duration")},
            {string.find(designer_name, "^(.*) duration")}
        };

        -- RUMPEL.ConsoleLog("RUMPEL.GetAbilityDuration()::MATCH[1][3]: "..tostring(MATCH[1][3]));
        -- RUMPEL.ConsoleLog("RUMPEL.GetAbilityDuration()::MATCH[2][3]: "..tostring(MATCH[2][3]));
        -- RUMPEL.ConsoleLog("RUMPEL.GetAbilityDuration()::MATCH[3][3]: "..tostring(MATCH[3][3]));

        if ability_name == MATCH[1][3] or ability_name == MATCH[2][3] or ability_name == MATCH[3][3] then
            RUMPEL.ConsoleLog("RUMPEL.GetAbilityDuration()::PLAYER_ALL_STATS.item_attributes[i].current_value: "..tostring(PLAYER_ALL_STATS.item_attributes[i].current_value));
            return tonumber(PLAYER_ALL_STATS.item_attributes[i].current_value);
        end
    end
end

function RUMPEL.GetKnownAbilities()
    HTTP.IssueRequest("http://php.bitshifting.de/api/firefall.adt.json", "GET", nil, RUMPEL.SaveKnownAbilities);
end

function RUMPEL.SaveKnownAbilities(ARGS, ERR)
    if ERR then
        RUMPEL.Log(ERR);
    else
        for _,ABILITY in pairs(ARGS) do
            local key = tostring(ABILITY.ability_id)..tostring(ABILITY.ability_icon_id)..tostring(ABILITY.ability_name)..tostring(ABILITY.ability_event)..tostring(ABILITY.ability_reports_duration);

            if nil == RUMPEL.KNOWN_ABILITIES[ABILITY.ability_event][key] then
                RUMPEL.KNOWN_ABILITIES[ABILITY.ability_event][key] = true;
            end

            ABILITY.ability_id               = tonumber(ABILITY.ability_id);
            ABILITY.ability_icon_id          = tonumber(ABILITY.ability_icon_id);
            ABILITY.ability_reports_duration = tonumber(ABILITY.ability_reports_duration);
            ABILITY.ability_used_by_addon    = tonumber(ABILITY.ability_used_by_addon);

            if nil ~= ABILITY.ability_icon_id and 0 < ABILITY.ability_icon_id and 1 == ABILITY.ability_used_by_addon then
                ABILITY_INFOS[ABILITY.ability_id] = {
                    icon_id = ABILITY.ability_icon_id,
                    ability_name = ABILITY.ability_name,
                    reports_duration = (1 == ABILITY.ability_reports_duration and true or false),
                    event = ABILITY.ability_event
                };
            end
        end

        RUMPEL.Log(RUMPEL.KNOWN_ABILITIES);
    end
end

function RUMPEL.PostAbilityInfos(DATA)
    local key = tostring(DATA.ability_id)..tostring(DATA.ability_icon_id)..tostring(DATA.ability_name)..tostring(DATA.ability_event)..tostring(DATA.ability_reports_duration);

    if true == RUMPEL.KNOWN_ABILITIES[DATA.ability_event][key] then
        do return end
    end

    if not HTTP.IsRequestPending() then
        -- for results see
        -- http://php.bitshifting.de/api/firefall.adt.html
        -- or
        -- http://php.bitshifting.de/api/firefall.adt.lua
        HTTP.IssueRequest("http://php.bitshifting.de/api/firefall.adt.json", "POST", DATA, nil);

        RUMPEL.KNOWN_ABILITIES[DATA.ability_event][key] = true; -- if it not worked, we'll send it next session anyways
    else
        Callback2.FireAndForget(RUMPEL.PostAbilityInfos, DATA, 1);
    end
end

function RUMPEL.ConsoleLog(message)
    if true == SETTINGS.debug then
        message = "[DEBUG] "..tostring(message);

        RUMPEL.log(message);

        RUMPEL.SystemMsg(message);
    end
end

function RUMPEL.Log(message)
    log(tostring(message));
end

function RUMPEL.SystemMsg(message)
    Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text = "[ADT] "..tostring(message)});
end

function RUMPEL.DurTimerMsg(ability_name)
    if true == SETTINGS.system_message then
        RUMPEL.SystemMsg("Starting duration timer for '"..(ABILITY_ALIAS[ability_name] or ability_name).."'.");
    end
end

function RUMPEL.TestTimers()
    RUMPEL.CreateUiTimer(202130, 25, "Heavy Armor", 3782);
    RUMPEL.CreateUiTimer(222527, 15, "Thunderdome", 1726);
    RUMPEL.CreateUiTimer(492574, 20, "Adrenaline Rush", 15206);
    RUMPEL.CreateUiTimer(202115, 30, "Teleport Beacon", 12305);
end

function RUMPEL.Test()
    RUMPEL.SystemMsg(ABILITY_INFOS);

    local test = function ()
        RUMPEL.CreateUiTimer(202130, 25, "Heavy Armor", 3782);
    end

    RUMPEL.SystemMsg(type(test));
end
