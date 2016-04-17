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

require "math";
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
local NAMES    = {};
local PERKS             = {};
local SLOTTED_PERKS     = {};
local slash_list        = "adt";

-- global for sure shot
local burst_time     = 0;
local last_shot_time = 0;

UI.ALIGNMENT = {};
UI.FRAME     = Component.GetFrame("adt_frame");

UI.ALIGNMENT["ltr"] = 68;
UI.ALIGNMENT["rtl"] = -68;

RUMPEL.KNOWN_ABILITIES                     = {};
RUMPEL.KNOWN_ABILITIES["ON_ABILITY_USED"]  = {};
RUMPEL.KNOWN_ABILITIES["ON_ABILITY_STATE"] = {};

RUMPEL.ABILITIES_RM_ON_REUSE        = {};
RUMPEL.ABILITIES_RM_ON_REUSE[35455] = {ADT = true, alias = false}; -- Bulwark -- TODO: check this
RUMPEL.ABILITIES_RM_ON_REUSE[35909] = {ADT = true, alias = 12305}; -- Teleport Beacon
RUMPEL.ABILITIES_RM_ON_REUSE[12305] = {ADT = true, alias = 35909}; -- ort Beacon
RUMPEL.ABILITIES_RM_ON_REUSE[38620] = {ADT = true, alias = false}; -- Rocketeers

-- Perks
RUMPEL.ABILITIES_RM_ON_REUSE["P[86118]"] = {ADT = true, alias = false}; -- Sure Shot

SETTINGS = {
    debug               = false,
    system_message      = false,
    system_message_text = "Starting duration timer for '${name}' (${duration}s).",
    max_timers          = 12,
    timers_alignment    = "ltr",
    track_perks         = true,
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

NAMES[41881] = "Absorption Bomb";
NAMES[34066] = "Dreadfield";
NAMES[3782]  = "Heavy Armor";
NAMES[1726]  = "Thunderdome";
NAMES[34066] = "Dreadfield";
NAMES[34734] = "Creeping Death";
NAMES[34066] = "Dreadfield";
NAMES[41867] = "Heroism";
NAMES[35620] = "Necrosis";
NAMES[34066] = "Dreadfield";
NAMES[40592] = "Poison Trail";
NAMES[34066] = "Dreadfield";
NAMES[34066] = "Dreadfield";
NAMES[34526] = "SIN Beacon";
NAMES[34066] = "Dreadfield";
NAMES[3639]  = "Overcharge";
NAMES[34066] = "Dreadfield";
NAMES[35455] = "Bulwark";
NAMES[34066] = "Dreadfield";
NAMES[41880] = "Overclock";
NAMES[34066] = "Dreadfield";
NAMES[15206] = "Adrenaline";
NAMES[35567] = "Accord Artillery Strike";
NAMES[39405] = "Cryo Bomb Snare"; -- Cryo Shot
NAMES[35458] = "Fuel Air Bomb Fire Patch"; -- Thermal Wave
NAMES[41682] = "Missile Barrage"; -- Hellfire
NAMES[38620] = "Activate: Rocket Wings";
NAMES[34928] = "Healing Dome";
NAMES[41875] = "Penetrating Rounds";
NAMES[35345] = "Smoke Screen";
-- NAMES[] = ""; -- NEW

-- Perks
NAMES["P[86118]"] = "Sure Shot";

ABILITY_DURATIONS[38620] = 16; -- Activate: Rocket Wings

-- Perks
ABILITY_DURATIONS["P[86118]"] = 3; -- Sure Shot

ON_ABILITY_STATE[15206] = true; -- Adrenaline
ON_ABILITY_STATE[3782]  = true; -- Heavy Armor
ON_ABILITY_STATE[3639]  = true; -- Overcharge
ON_ABILITY_STATE[12305] = true; -- Teleport Beacon
ON_ABILITY_STATE[1726]  = true; -- Thunderdome
ON_ABILITY_STATE[15229] = false; -- Overclock [ON_ABILITY_STATE] (named Overcharge ...)
ON_ABILITY_STATE[2843]  = false; -- Decoy [ON_ABILITY_STATE] (named Heavy Armor ...)
ON_ABILITY_STATE[15231] = false; -- Absorption Bomb
ON_ABILITY_STATE[35455] = false; -- Bulwark

-- Dreadnaught
SETTINGS.TIMERS[41881] = true; -- Absorption Bomb
SETTINGS.TIMERS[34066] = true; -- Dreadfield
SETTINGS.TIMERS[3782]  = true; -- Heavy Armor
SETTINGS.TIMERS[41875] = true; -- Penetrating Rounds
SETTINGS.TIMERS[1726]  = true; -- Thunderdome

-- Biotech
SETTINGS.TIMERS[15206] = true; -- Adrenaline
SETTINGS.TIMERS[34734] = true; -- Creeping Death
SETTINGS.TIMERS[34928] = true; -- Healing Dome
SETTINGS.TIMERS[41867] = true; -- Heroism
SETTINGS.TIMERS[35620] = true; -- Necrosis
SETTINGS.TIMERS[41865] = true; -- Poison Ball
SETTINGS.TIMERS[40592] = true; -- Poison Trail

-- Recon
SETTINGS.TIMERS[35567] = true; -- Artillery Strike
SETTINGS.TIMERS[39405] = true; -- Cryo Bolt -- Cryo Shot
SETTINGS.TIMERS[34957] = true; -- Decoy
SETTINGS.TIMERS[34526] = true; -- SIN Beacon
SETTINGS.TIMERS[35345] = true; -- Smoke Screen
SETTINGS.TIMERS[12305] = true; -- Teleport Beacon

-- Assault
SETTINGS.TIMERS[41682] = true; -- Hellfire
SETTINGS.TIMERS[3639]  = true; -- Overcharge
SETTINGS.TIMERS[35458] = true; -- Thermal Wave

-- Engineer
SETTINGS.TIMERS[35455] = true; -- Bulwark
SETTINGS.TIMERS[41886] = true; -- Fortify
SETTINGS.TIMERS[41880] = true; -- Overclock

-- Miscellaneous
SETTINGS.TIMERS[38620] = true; -- Activate: Rocket Wings

-- Perks
-- SETTINGS.TIMERS["P[86118]"] = true; -- Sure Shot

-- =============================================================================
--  Options
-- =============================================================================

function BuildOptions()
    InterfaceOptions.AddMovableFrame({frame=UI.FRAME, label="Ability Duration Timer", scalable=true});

    InterfaceOptions.StartGroup({label="Ability Duration Timer: Main Settings"});
        InterfaceOptions.AddCheckBox({id="DEBUG_ENABLED", label="Debug enabled", default=(Component.GetSetting("DEBUG_ENABLED") or SETTINGS.debug)});
        InterfaceOptions.AddCheckBox({id="SYSMSG_ENABLED", label="Chat output (Starting duration timer ...) enabled", default=(Component.GetSetting("SYSMSG_ENABLED") or SETTINGS.system_message)});
        InterfaceOptions.AddTextInput({id="SYSMSG_TEXT", label="Chat output message", default=SETTINGS.system_message_text, tooltip="Message to show when the timer starts.\nAvailable parameter: ${name} and ${duration}"});
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
        InterfaceOptions.AddCheckBox({id="PERKS_ENABLED", label="Perks enabled (experimental)", default=(Component.GetSetting("PERKS_ENABLED") or SETTINGS.track_perks)});
    InterfaceOptions.StopGroup();

    -- Dreadnaught
    InterfaceOptions.StartGroup({label="Dreadnaught"});
        InterfaceOptions.AddCheckBox({id="ABSORPTION_BOMB_ENABLED", label="Absorption Bomb enabled", default=(Component.GetSetting("ABSORPTION_BOMB_ENABLED") or SETTINGS.TIMERS[41881])});
        InterfaceOptions.AddCheckBox({id="DREADFIELD_ENABLED", label="Dreadfield enabled", default=(Component.GetSetting("DREADFIELD_ENABLED") or SETTINGS.TIMERS[34066])});
        InterfaceOptions.AddCheckBox({id="HEAVY_ARMOR_ENABLED", label="Heavy Armor enabled", default=(Component.GetSetting("HEAVY_ARMOR_ENABLED") or SETTINGS.TIMERS[3782])});
        InterfaceOptions.AddCheckBox({id="PENETRATING_ROUNDS_ENABLED", label="Penetrating Rounds enabled", default=(Component.GetSetting("PENETRATING_ROUNDS_ENABLED") or SETTINGS.TIMERS[41875])});
        InterfaceOptions.AddCheckBox({id="THUNDERDOME_ENABLED", label="Thunderdome enabled", default=(Component.GetSetting("THUNDERDOME_ENABLED") or SETTINGS.TIMERS[1726])});
    InterfaceOptions.StopGroup();

    -- Biotech
    InterfaceOptions.StartGroup({label="Biotech"});
        InterfaceOptions.AddCheckBox({id="ADRENALINE_RUSH_ENABLED", label="Adrenaline Rush enabled", default=(Component.GetSetting("ADRENALINE_RUSH_ENABLED") or SETTINGS.TIMERS[15206])});
        InterfaceOptions.AddCheckBox({id="CREEPING_DEATH_ENABLED", label="Creeping Death enabled", default=(Component.GetSetting("CREEPING_DEATH_ENABLED") or SETTINGS.TIMERS[34734])});
        InterfaceOptions.AddCheckBox({id="HEALING_DOME_ENABLED", label="Healing Dome enabled", default=(Component.GetSetting("HEALING_DOME_ENABLED") or SETTINGS.TIMERS[34928])});
        InterfaceOptions.AddCheckBox({id="NECROSIS_ENABLED", label="Necrosis enabled", default=(Component.GetSetting("NECROSIS_ENABLED") or SETTINGS.TIMERS[41867])});
        InterfaceOptions.AddCheckBox({id="HEROISM_ENABLED", label="Heroism enabled", default=(Component.GetSetting("HEROISM_ENABLED") or SETTINGS.TIMERS[35620])});
        InterfaceOptions.AddCheckBox({id="POISON_BALL_ENABLED", label="Poison Ball enabled", default=(Component.GetSetting("POISON_BALL_ENABLED") or SETTINGS.TIMERS[41865])});
        InterfaceOptions.AddCheckBox({id="POISON_TRAIL_ENABLED", label="Poison Trail enabled", default=(Component.GetSetting("POISON_TRAIL_ENABLED") or SETTINGS.TIMERS[40592])});
    InterfaceOptions.StopGroup();

    -- Recon
    InterfaceOptions.StartGroup({label="Recon"});
        InterfaceOptions.AddCheckBox({id="ARTILLERY_STRIKE_ENABLED", label="Artillery Strike enabled", default=(Component.GetSetting("ARTILLERY_STRIKE_ENABLED") or SETTINGS.TIMERS[35567])});
        InterfaceOptions.AddCheckBox({id="CRYO_BOLT_ENABLED", label="Cryo Shot enabled", default=(Component.GetSetting("CRYO_BOLT_ENABLED") or SETTINGS.TIMERS[39405])});
        InterfaceOptions.AddCheckBox({id="DECOY_ENABLED", label="Decoy enabled", default=(Component.GetSetting("DECOY_ENABLED") or SETTINGS.TIMERS[34957])});
        InterfaceOptions.AddCheckBox({id="SIN_BEACON_ENABLED", label="SIN Beacon enabled", default=(Component.GetSetting("SIN_BEACON_ENABLED") or SETTINGS.TIMERS[34526])});
        InterfaceOptions.AddCheckBox({id="SMOKE_SCREEN_ENABLED", label="Smoke Screen enabled", default=(Component.GetSetting("SMOKE_SCREEN_ENABLED") or SETTINGS.TIMERS[35345])});
        InterfaceOptions.AddCheckBox({id="TELEPORT_BEACON_ENABLED", label="Teleport Beacon enabled", default=(Component.GetSetting("TELEPORT_BEACON_ENABLED") or SETTINGS.TIMERS[12305])});
    InterfaceOptions.StopGroup();

    -- Assault
    InterfaceOptions.StartGroup({label="Assault"});
        InterfaceOptions.AddCheckBox({id="HELLFIRE_ENABLED", label="Hellfire enabled", default=(Component.GetSetting("HELLFIRE_ENABLED") or SETTINGS.TIMERS[41682])});
        InterfaceOptions.AddCheckBox({id="OVERCHARGE_ENABLED", label="Overcharge enabled", default=(Component.GetSetting("OVERCHARGE_ENABLED") or SETTINGS.TIMERS[3639])});
        InterfaceOptions.AddCheckBox({id="THERMAL_WAVE_ENABLED", label="Thermal Wave enabled", default=(Component.GetSetting("THERMAL_WAVE_ENABLED") or SETTINGS.TIMERS[35458])});
    InterfaceOptions.StopGroup();

    -- Engineer
    InterfaceOptions.StartGroup({label="Engineer"});
        InterfaceOptions.AddCheckBox({id="FORTIFY_ENABLED", label="Fortify enabled", default=(Component.GetSetting("FORTIFY_ENABLED") or SETTINGS.TIMERS[35455])});
        InterfaceOptions.AddCheckBox({id="BULWARK_ENABLED", label="Bulwark enabled", default=(Component.GetSetting("BULWARK_ENABLED") or SETTINGS.TIMERS[41886])});
        InterfaceOptions.AddCheckBox({id="OVERCLOCK_ENABLED", label="Overclock enabled", default=(Component.GetSetting("OVERCLOCK_ENABLED") or SETTINGS.TIMERS[41880])});
    InterfaceOptions.StopGroup();

    -- Miscellaneous
    InterfaceOptions.StartGroup({label="Miscellaneous"});
        InterfaceOptions.AddCheckBox({id="ROCKETEERS_WINGS_ENABLED", label="Rocketeer's Wings enabled", default=(Component.GetSetting("ROCKETEERS_WINGS_ENABLED") or SETTINGS.TIMERS[38620])});
    InterfaceOptions.StopGroup();
end

-- =============================================================================
--  Events
-- =============================================================================

function OnComponentLoad()
    BuildOptions();

    InterfaceOptions.SetCallbackFunc(OnOptionChanged, "Ability Duration Timer");

    LIB_SLASH.BindCallback({slash_list=slash_list, func=OnSlash});

    getmetatable("").__mod = function (s, tab)
        return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
    end

    RUMPEL.GetKnownAbilities();
end

function OnPlayerReady()
    ADTStatic.Init();

    RUMPEL.GetPerks();
    RUMPEL.GetLoadoutPerks();
end

function OnComponentUnload()
    LIB_SLASH.UnbindCallback(slash_list);
end

function OnSlash(ARGS)
    -- RUMPEL.ConsoleLog("OnSlash with args: "..tostring(ARGS));

    if 42 == tonumber(ARGS[1]) then
        RUMPEL.TestTimers();
    elseif "rm" == ARGS[1] then
        ADTStatic.KillAll();
    elseif "bw" == ARGS[1] then
        local rm_on_reuse       = nil;
        local rm_on_reuse_alias = nil;

        if "table" == type(RUMPEL.ABILITIES_RM_ON_REUSE[35455]) then
            rm_on_reuse = 35455;

            if false ~= RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].alias then
                rm_on_reuse_alias = RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].alias;
            end

            if "AbilityDurationTimer" == type(RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT) then
                RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT:Reschedule(0);
                RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT = true;

                if nil ~= rm_on_reuse_alias then
                    RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse_alias].ADT = true;
                end
            end
        end

        local ADT = AbilityDurationTimer.New(UI.FRAME)

        ADT:SetAbilityID(35455);
        ADT:SetAbilityName("Bulwark");
        ADT:SetIconID(222475);
        ADT:SetDuration(45);
        ADT:StartTimer(RUMPEL.Callback);

        if nil ~= rm_on_reuse and true == RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT then
            RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT = ADT;

            if nil ~= rm_on_reuse_alias and true == RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse_alias].ADT then
                RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse_alias].ADT = ADT;
            end
        end
    elseif "pstats" == ARGS[1] then
        log(tostring(Player.GetAllStats()));
    elseif "timers" == ARGS[1] then
        RUMPEL.SystemMsg("Active Timers: "..tostring(ADTStatic.GetActive()));
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
    ADTStatic.KillAll();

    RUMPEL.GetLoadoutPerks();
end

function OnDeath()
    ADTStatic.KillAll();
end

function OnOptionChanged(id, value)
    ADTStatic.KillAll();

    if "DEBUG_ENABLED" == id then
        SETTINGS.debug = value;
        Component.SaveSetting("DEBUG_ENABLED", value);
    elseif "SYSMSG_ENABLED" == id then
        SETTINGS.system_message = value;
        Component.SaveSetting("SYSMSG_ENABLED", value);
    elseif "SYSMSG_TEXT" == id then
        SETTINGS.system_message_text = value;
        Component.SaveSetting("SYSMSG_TEXT", value);
    elseif "MAX_TIMERS" == id then
        SETTINGS.max_timers = value;
        Component.SaveSetting("MAX_TIMERS", value);
        ADTStatic.SetMaxVisible(value);
    elseif "TIMERS_ALIGNMENT" == id then
        SETTINGS.timers_alignment = value;
        Component.SaveSetting("TIMERS_ALIGNMENT", value);
        ADTStatic.SetAlignment(UI.ALIGNMENT[value]);
    elseif "FONT" == id then
        SETTINGS.FONT.name = value;
        Component.SaveSetting("FONT", value);
        ADTStatic.SetFontName(value);
    elseif "FONT_SIZE" == id then
        SETTINGS.FONT.size = value;
        Component.SaveSetting("FONT_SIZE", value);
        ADTStatic.SetFontSize(value);
    elseif "TIMER_COLOR" == id then
        SETTINGS.FONT.COLOR.text_timer = value.tint;
        Component.SaveSetting("TIMER_COLOR", value.tint);
        ADTStatic.SetFontColor(value.tint);
    elseif "TIMER_COLOR_OUTLINE" == id then
        SETTINGS.FONT.COLOR.text_timer_outline = value.tint;
        Component.SaveSetting("TIMER_COLOR_OUTLINE", value.tint);
        ADTStatic.SetFontColorOutline(value.tint);
    elseif "HEAVY_ARMOR_ENABLED" == id then
        SETTINGS.TIMERS[3782] = value;
        Component.SaveSetting("HEAVY_ARMOR_ENABLED", value);
    elseif "THUNDERDOME_ENABLED" == id then
        SETTINGS.TIMERS[1726] = value;
        Component.SaveSetting("THUNDERDOME_ENABLED", value);
    elseif "DREADFIELD_ENABLED" == id then
        SETTINGS.TIMERS[34066] = value;
        Component.SaveSetting("DREADFIELD_ENABLED", value);
    elseif "ABSORPTION_BOMB_ENABLED" == id then
        SETTINGS.TIMERS[41881] = value;
        Component.SaveSetting("ABSORPTION_BOMB_ENABLED", value);
    elseif "ADRENALINE_RUSH_ENABLED" == id then
        SETTINGS.TIMERS[15206] = value;
        Component.SaveSetting("ADRENALINE_RUSH_ENABLED", value);
    elseif "NECROSIS_ENABLED" == id then
        SETTINGS.TIMERS[35620] = value;
        Component.SaveSetting("NECROSIS_ENABLED", value);
    elseif "HEROISM_ENABLED" == id then
        SETTINGS.TIMERS[41867] = value;
        Component.SaveSetting("HEROISM_ENABLED", value);
    elseif "TELEPORT_BEACON_ENABLED" == id then
        SETTINGS.TIMERS[12305] = value;
        Component.SaveSetting("TELEPORT_BEACON_ENABLED", value);
    elseif "OVERCHARGE_ENABLED" == id then
        SETTINGS.TIMERS[3639] = value;
        Component.SaveSetting("OVERCHARGE_ENABLED", value);
    elseif "THERMAL_WAVE_ENABLED" == id then
        SETTINGS.TIMERS[35458] = value;
        Component.SaveSetting("THERMAL_WAVE_ENABLED", value);
    elseif "HELLFIRE_ENABLED" == id then
        SETTINGS.TIMERS[41682] = value;
        Component.SaveSetting("HELLFIRE_ENABLED", value);
    elseif "BULWARK_ENABLED" == id then
        SETTINGS.TIMERS[35455] = value;
        Component.SaveSetting("BULWARK_ENABLED", value);
    elseif "OVERCLOCK_ENABLED" == id then
        SETTINGS.TIMERS[41880] = value;
        Component.SaveSetting("OVERCLOCK_ENABLED", value);
    elseif "FORTIFY_ENABLED" == id then
        SETTINGS.TIMERS[41886] = value;
        Component.SaveSetting("FORTIFY_ENABLED", value);
    elseif "ROCKETEERS_WINGS_ENABLED" == id then
        SETTINGS.TIMERS[38620] = value;
        Component.SaveSetting("ROCKETEERS_WINGS_ENABLED", value);
    elseif "CREEPING_DEATH_ENABLED" == id then
        SETTINGS.TIMERS[34734] = value;
        Component.SaveSetting("CREEPING_DEATH_ENABLED", value);
    elseif "POISON_BALL_ENABLED" == id then
        SETTINGS.TIMERS[41865] = value;
        Component.SaveSetting("POISON_BALL_ENABLED", value);
    elseif "POISON_TRAIL_ENABLED" == id then
        SETTINGS.TIMERS[40592] = value;
        Component.SaveSetting("POISON_TRAIL_ENABLED", value);
    elseif "ARTILLERY_STRIKE_ENABLED" == id then
        SETTINGS.TIMERS[35567] = value;
        Component.SaveSetting("ARTILLERY_STRIKE_ENABLED", value);
    elseif "CRYO_BOLT_ENABLED" == id then
        SETTINGS.TIMERS[39405] = value;
        Component.SaveSetting("CRYO_BOLT_ENABLED", value);
    elseif "DECOY_ENABLED" == id then
        SETTINGS.TIMERS[34957] = value;
        Component.SaveSetting("DECOY_ENABLED", value);
    elseif "SIN_BEACON_ENABLED" == id then
        SETTINGS.TIMERS[34526] = value;
        Component.SaveSetting("SIN_BEACON_ENABLED", value);
    elseif "PENETRATING_ROUNDS_ENABLED" == id then
        SETTINGS.TIMERS[41875] = value;
        Component.SaveSetting("PENETRATING_ROUNDS_ENABLED", value);
    elseif "HEALING_DOME_ENABLED" == id then
        SETTINGS.TIMERS[34928] = value;
        Component.SaveSetting("HEALING_DOME_ENABLED", value);
    elseif "SMOKE_SCREEN_ENABLED" == id then
        SETTINGS.TIMERS[35345] = value;
        Component.SaveSetting("SMOKE_SCREEN_ENABLED", value);
    elseif "PERKS_ENABLED" == id then
        SETTINGS.track_perks = value;
        Component.SaveSetting("PERKS_ENABLED", value);
    end

    RUMPEL.Log("OnOptionChanged("..tostring(id)..", "..tostring(value)..")");
end

function OnEffectsChanged(ARGS)
    -- RUMPEL.SystemMsg(ARGS);
end

function OnAbilityUsed(ARGS)
    -- RUMPEL.SystemMsg(ARGS);

    if -1 ~= ARGS.index then
        local ABILITY_INFO      = Player.GetAbilityInfo(ARGS.id);
        local ability_id        = tonumber(ARGS.id);
        local rm_on_reuse       = nil;
        local rm_on_reuse_alias = nil;

        RUMPEL.ConsoleLog("Ability '"..ABILITY_INFO.name.."' fired Event 'ON_ABILITY_USED'!");
        RUMPEL.ConsoleLog("ID: "..tostring(ability_id));
        RUMPEL.ConsoleLog("NAME: "..ABILITY_INFO.name);
        RUMPEL.ConsoleLog("ICON ID: "..tostring(ABILITY_INFO.iconId));

        local ability_duration = ABILITY_DURATIONS[ability_id] or RUMPEL.GetAbilityDuration(ability_id);

        RUMPEL.ConsoleLog("DURATION: "..tostring(ability_duration));

        local ability_reports_duration = 0;

        if nil ~= ability_duration then
            ability_reports_duration = 1;
        end

        RUMPEL.PostAbilityInfos(
        {
            ability_id               = tostring(ability_id),
            ability_icon_id          = tostring(ABILITY_INFO.iconId),
            ability_name             = tostring(ABILITY_INFO.name),
            ability_event            = "ON_ABILITY_USED",
            ability_reports_duration = tostring(ability_reports_duration)
        });

        if "table" == type(RUMPEL.ABILITIES_RM_ON_REUSE[ability_id]) then
            rm_on_reuse = ability_id;

            if false ~= RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].alias then
                rm_on_reuse_alias = RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].alias;
            end

            if "AbilityDurationTimer" == type(RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT) then
                RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT:Reschedule(0);
                RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT = true;

                if nil ~= rm_on_reuse_alias then
                    RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse_alias].ADT = true;
                end
            end
        end

        if nil ~= ability_duration and true ~= ON_ABILITY_STATE[ability_id] and true == SETTINGS.TIMERS[ability_id] then
            RUMPEL.ConsoleLog("AbilityDurationTimer.New()");
            RUMPEL.DurTimerMsg(ABILITY_INFO.name, ability_duration);

            local ADT = AbilityDurationTimer(UI.FRAME);

            ADT:SetAbilityID(ability_id);
            ADT:SetAbilityName(ABILITY_INFO.name);
            ADT:SetIconID(ABILITY_INFO.iconId);
            ADT:SetDuration(ability_duration);
            ADT:StartTimer(RUMPEL.Callback);

            if 38620 == ability_id then
                Callback2.FireAndForget(
                    RUMPEL.CheckGlidingStart,
                    {
                        ADT        = ADT,
                        is_gliding = Player.GetPermissions().glider,
                        count      = 1
                    },
                    1
                );
            end

            if nil ~= rm_on_reuse and true == RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT then
                RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT = ADT;

                if nil ~= rm_on_reuse_alias and true == RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse_alias].ADT then
                    RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse_alias].ADT = ADT;
                end
            end
        end
    end
end

function OnAbilityState(ARGS)
    -- RUMPEL.SystemMsg(ARGS);

    if -1 ~= ARGS.index then
        local ability_name      = tostring(ARGS.state);
        local ability_id        = tonumber(ARGS.id);
        local rm_on_reuse       = nil;
        local rm_on_reuse_alias = nil;
        local icon_id           = 0;

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

        if "table" == type(RUMPEL.ABILITIES_RM_ON_REUSE[ability_id]) then
            rm_on_reuse = ability_id;

            if false ~= RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].alias then
                rm_on_reuse_alias = RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].alias;
            end

            if "AbilityDurationTimer" == type(RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT) then
                RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT:Reschedule(0);
                RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT = true;

                if nil ~= rm_on_reuse_alias then
                    RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse_alias].ADT = true;
                end
            end
        end

        if true == SETTINGS.TIMERS[ability_id] and false ~= ON_ABILITY_STATE[ability_id] then
            RUMPEL.ConsoleLog("AbilityDurationTimer.New()");
            RUMPEL.DurTimerMsg(ability_name, ARGS.state_dur_total);

            local ADT = AbilityDurationTimer(UI.FRAME);

            ADT:SetAbilityID(ability_id);
            ADT:SetAbilityName(ability_name);
            ADT:SetIconID(icon_id);
            ADT:SetDuration(ARGS.state_dur_total);
            ADT:StartTimer(RUMPEL.Callback);

            if 38620 == ability_id then
                Callback2.FireAndForget(
                    RUMPEL.CheckGlidingStart,
                    {
                        ADT        = ADT,
                        is_gliding = Player.GetPermissions().glider,
                        count      = 1
                    },
                    1
                );
            end

            if nil ~= rm_on_reuse and true == RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT then
                RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT = ADT;

                if nil ~= rm_on_reuse_alias and true == RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse_alias].ADT then
                    RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse_alias].ADT = ADT;
                end
            end
        end
    end
end

function OnWeaponBurst()
    -- experimental
    if true == SETTINGS.track_perks and true == RUMPEL.CheckPerkEquipped("P[86118]") then
        local client_time    = tonumber(System.GetClientTime());
        local new_burst_time = client_time - last_shot_time;

        if new_burst_time > burst_time / 3.5 and new_burst_time < burst_time / 1.8 then
            local ADT = AbilityDurationTimer(UI.FRAME);

            ADT:SetAbilityID("P[86118]");
            ADT:SetAbilityName(SLOTTED_PERKS["P[86118]"].name);
            ADT:SetIconID(SLOTTED_PERKS["P[86118]"].web_icon_id);
            ADT:SetDuration(3);
            ADT:StartTimer(RUMPEL.Callback);
        end

        burst_time     = new_burst_time;
        last_shot_time = client_time;
    end
end

-- =============================================================================
--  Functions
-- =============================================================================

function RUMPEL.Callback(ADT)
    local ability_id        = ADT:GetAbilityID();
    local rm_on_reuse       = nil;
    local rm_on_reuse_alias = nil;

    if "table" == type(RUMPEL.ABILITIES_RM_ON_REUSE[ability_id]) then
        rm_on_reuse = ability_id;

        if false ~= RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].alias then
            rm_on_reuse_alias = RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].alias;
        end

        if "AbilityDurationTimer" == type(RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT) then
            RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse].ADT = true;

            if nil ~= rm_on_reuse_alias then
                RUMPEL.ABILITIES_RM_ON_REUSE[rm_on_reuse_alias].ADT = true;
            end
        end
    end
end

function RUMPEL.CheckGlidingStart(ARGS)
    -- RUMPEL.SystemMsg("RUMPEL.CheckGlidingStart()");

    if 50 < ARGS.count then
        return;
    elseif false == ARGS.is_gliding then
        ARGS.count      = ARGS.count + 1;
        ARGS.is_gliding = Player.GetPermissions().glider;

        Callback2.FireAndForget(RUMPEL.CheckGlidingStart, ARGS, 0.1);

        return;
    end

    Callback2.FireAndForget(RUMPEL.CheckGliding, ARGS, 0.1);
end

function RUMPEL.CheckGliding(ARGS)
    -- RUMPEL.SystemMsg("RUMPEL.CheckGliding()");

    if true == ARGS.is_gliding then
        ARGS.is_gliding = Player.GetPermissions().glider;

        Callback2.FireAndForget(RUMPEL.CheckGliding, ARGS, 0.1);

        return;
    end

    ARGS.ADT:Reschedule(0);
end

function RUMPEL.GetAbilityDuration(ability_id)
    local PLAYER_ALL_STATS = Player.GetAllStats();
    local ability_name     = nil;

    if nil ~= NAMES[ability_id] then
        ability_name = string.lower(NAMES[ability_id]);
    end

    if nil == ability_name then
        return nil;
    end

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

    return nil;
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
    if "en" ~= string.lower(tostring(System.GetLocale())) then
        return RUMPEL;
    end

    local key = tostring(DATA.ability_id)..tostring(DATA.ability_icon_id)..tostring(DATA.ability_name)..tostring(DATA.ability_event)..tostring(DATA.ability_reports_duration);

    if true == RUMPEL.KNOWN_ABILITIES[DATA.ability_event][key] then
        return RUMPEL;
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

        RUMPEL.Log(message);

        RUMPEL.SystemMsg(message);
    end
end

function RUMPEL.Log(message)
    log(tostring(message));
end

function RUMPEL.SystemMsg(message)
    Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text = "[ADT] "..tostring(message)});
end

function RUMPEL.DurTimerMsg(ability_name, duration)
    if true == SETTINGS.system_message then
        RUMPEL.SystemMsg(SETTINGS.system_message_text % {
            name     = ability_name,
            duration = tostring(math.floor((tonumber(duration) * 100) + 0.5) / 100)
        });
    end
end

function RUMPEL.TestTimers()
    local ADTS = {
        ["1"] = AbilityDurationTimer.New(UI.FRAME),
        ["2"] = AbilityDurationTimer.New(UI.FRAME),
        ["3"] = AbilityDurationTimer.New(UI.FRAME),
        ["4"] = AbilityDurationTimer.New(UI.FRAME)
    };

    ADTS["1"]:SetAbilityID(3782);
    ADTS["2"]:SetAbilityID(1726);
    ADTS["3"]:SetAbilityID(15206);
    ADTS["4"]:SetAbilityID(34928);

    ADTS["1"]:SetAbilityName("Heavy Armor");
    ADTS["2"]:SetAbilityName("Thunderdome");
    ADTS["3"]:SetAbilityName("Adrenaline Rush");
    ADTS["4"]:SetAbilityName("Healing Dome");

    ADTS["1"]:SetIconID(202130);
    ADTS["2"]:SetIconID(222527);
    ADTS["3"]:SetIconID(492574);
    ADTS["4"]:SetIconID(222495);

    ADTS["1"]:SetDuration(25);
    ADTS["2"]:SetDuration(15);
    ADTS["3"]:SetDuration(20);
    ADTS["4"]:SetDuration(30);

    ADTS["1"]:StartTimer();
    ADTS["2"]:StartTimer();
    ADTS["3"]:StartTimer();
    ADTS["4"]:StartTimer();
end

function RUMPEL.Test()
    RUMPEL.Log(Game.GetPerkModuleInfo());
    RUMPEL.Log(Player.GetCurrentLoadout());
end

function RUMPEL.GetPerks()
    local PERK_INFO = Game.GetPerkModuleInfo();

    for _,PERK in pairs(PERK_INFO) do
        PERKS["P["..tostring(PERK.id).."]"] = PERK;
    end
end

function RUMPEL.GetLoadoutPerks()
    local LOADOUT = Player.GetCurrentLoadout();

    SLOTTED_PERKS = {};

    if LOADOUT then
        for _,MODULE in ipairs(LOADOUT.modules.chassis) do
            local id   = "P["..tostring(MODULE.item_sdb_id).."]";
            local PERK = PERKS[id];

            if PERK then
                SLOTTED_PERKS[id] = PERK;
            end
        end
    end

    RUMPEL.Log(SLOTTED_PERKS);
end

function RUMPEL.CheckPerkEquipped(id)
    if nil ~= SLOTTED_PERKS[id] then
        return true;
    end

    return false;
end
