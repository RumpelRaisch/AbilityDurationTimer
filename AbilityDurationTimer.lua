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
require "unicode";
require "lib/lib_Callback2";
require "lib/lib_ChatLib";
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
local ABILITY_OPTIONS   = {};
local ON_ABILITY_USED   = {};
local ON_ABILITY_STATE  = {};
local NAMES             = {};
local PERKS             = {};
local SLOTTED_PERKS     = {};
local slash_list        = "adt";
local output_prefix     = "[ADT] ";
local debug_prefix      = "[DEBUG] ";
local hero_proc_time    = 0; -- for Hero perk
local fire_rate_mod     = 0; -- for Sure Shot perk

UI.ALIGNMENT        = {};
UI.ALIGNMENT["ltr"] = 68;
UI.ALIGNMENT["rtl"] = -68;

UI.FRAMES    = {};
UI.FRAMES[1] = {id = 1, alignment = "ltr", OBJ = Component.GetFrame("adt_frame_1")};
UI.FRAMES[2] = {id = 2, alignment = "ltr", OBJ = Component.GetFrame("adt_frame_2")};
UI.FRAMES[3] = {id = 3, alignment = "ltr", OBJ = Component.GetFrame("adt_frame_3")};
UI.FRAMES[4] = {id = 4, alignment = "ltr", OBJ = Component.GetFrame("adt_frame_4")};

RUMPEL.KNOWN_ABILITIES                     = {};
RUMPEL.KNOWN_ABILITIES["ON_ABILITY_USED"]  = {};
RUMPEL.KNOWN_ABILITIES["ON_ABILITY_STATE"] = {};

RUMPEL.ABILITIES_RM_ON_REUSE        = {};
RUMPEL.ABILITIES_RM_ON_REUSE[35455] = {ADT = true, alias = false}; -- Bulwark -- TODO: check this
RUMPEL.ABILITIES_RM_ON_REUSE[35909] = {ADT = true, alias = 12305}; -- Teleport Beacon
RUMPEL.ABILITIES_RM_ON_REUSE[12305] = {ADT = true, alias = 35909}; -- ort Beacon
RUMPEL.ABILITIES_RM_ON_REUSE[38620] = {ADT = true, alias = false}; -- Rocketeers

-- Perks
RUMPEL.ABILITIES_RM_ON_REUSE["P[85888]"] = {ADT = true, alias = false}; -- Hyper Kinesis Surge
RUMPEL.ABILITIES_RM_ON_REUSE["P[85818]"] = {ADT = true, alias = false}; -- Health Surge
RUMPEL.ABILITIES_RM_ON_REUSE["P[95078]"] = {ADT = true, alias = false}; -- Invigorate

SETTINGS = {
    debug               = false,
    system_message      = false,
    system_message_text = "Starting duration timer for '${name}' (${duration}s).",
    max_timers          = 12,
    -- objects
    TIMERS      = {},
    FONT        = {
        name = "Demi",
        size = 16,
        -- objects
        COLOR = {
            text_timer         = "FF8800",
            text_timer_outline = "000000"
        }
    },
    ARC = {
        show    = true,
        warning = 5,
        COLOR   = {
            normal  = "FF8800",
            warning = "FF0000"
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
NAMES[34734] = "Creeping Death";
NAMES[41867] = "Heroism";
NAMES[35620] = "Necrosis";
NAMES[40592] = "Poison Trail";
NAMES[34526] = "SIN Beacon";
NAMES[3639]  = "Overcharge";
NAMES[35455] = "Bulwark";
NAMES[41880] = "Overclock";
NAMES[15206] = "Adrenaline";
NAMES[35567] = "Accord Artillery Strike";
NAMES[39405] = "Cryo Bomb Snare"; -- Cryo Shot
NAMES[35458] = "Thermal Wave";
NAMES[41682] = "Missile Barrage"; -- Hellfire
NAMES[38620] = "Activate: Rocket Wings";
NAMES[34928] = "Healing Dome";
NAMES[41875] = "Penetrating Rounds";
NAMES[35345] = "Smoke Screen";
NAMES[35583] = "Electrical Storm";
NAMES[34770] = "Boomerang";
NAMES[35637] = "Supercharge";
NAMES[35618] = "Overload";
NAMES[12305] = "Teleport Beacon";
-- NAMES[] = ""; -- NEW

-- Perks
NAMES["P[86118]"] = "Sure Shot";
NAMES["P[85995]"] = "Hero";
NAMES["P[85888]"] = "Hyper Kinesis Surge";
NAMES["P[85818]"] = "Health Surge";
NAMES["P[95078]"] = "Invigorate";
-- NAMES["P[]"] = ""; -- NEW

ABILITY_DURATIONS[38620] = 16; -- Activate: Rocket Wings

-- Perks
ABILITY_DURATIONS["P[86118]"] = 3; -- Sure Shot
ABILITY_DURATIONS["P[85995]"] = 5; -- Hero
ABILITY_DURATIONS["P[85888]"] = 12; -- Hyper Kinesis Surge
ABILITY_DURATIONS["P[85818]"] = 10; -- Health Surge
ABILITY_DURATIONS["P[95078]"] = 6; -- Invigorate
-- ABILITY_DURATIONS["P[]"] = ; --

ABILITY_DURATIONS["P[85995][CD]"] = 900; -- Hero cooldown

ON_ABILITY_STATE[15206] = true; -- Adrenaline
ON_ABILITY_STATE[3782]  = true; -- Heavy Armor
ON_ABILITY_STATE[3639]  = true; -- Overcharge
ON_ABILITY_STATE[12305] = true; -- Teleport Beacon
ON_ABILITY_STATE[1726]  = true; -- Thunderdome
ON_ABILITY_STATE[15229] = false; -- Overclock [ON_ABILITY_STATE] (named Overcharge ...)
ON_ABILITY_STATE[2843]  = false; -- Decoy [ON_ABILITY_STATE] (named Heavy Armor ...)
ON_ABILITY_STATE[15231] = false; -- Absorption Bomb
ON_ABILITY_STATE[35455] = false; -- Bulwark
ON_ABILITY_STATE[41881] = false; -- Absorption Bomb
ON_ABILITY_STATE[34066] = false; -- Dreadfield
ON_ABILITY_STATE[34734] = false; -- Creeping Death
ON_ABILITY_STATE[41867] = false; -- Heroism
ON_ABILITY_STATE[35620] = false; -- Necrosis
ON_ABILITY_STATE[40592] = false; -- Poison Trail
ON_ABILITY_STATE[34526] = false; -- SIN Beacon
ON_ABILITY_STATE[41880] = false; -- Overclock
ON_ABILITY_STATE[35567] = false; -- Accord Artillery Strike
ON_ABILITY_STATE[39405] = false; -- Cryo Shot
ON_ABILITY_STATE[35458] = false; -- Thermal Wave
ON_ABILITY_STATE[41682] = false; -- Hellfire
ON_ABILITY_STATE[38620] = false; -- Activate: Rocket Wings
ON_ABILITY_STATE[34928] = false; -- Healing Dome
ON_ABILITY_STATE[41875] = false; -- Penetrating Rounds
ON_ABILITY_STATE[35345] = false; -- Smoke Screen
ON_ABILITY_STATE[35583] = false; -- Electrical Storm
ON_ABILITY_STATE[34770] = false; -- Boomerang
ON_ABILITY_STATE[35637] = false; -- Supercharge
ON_ABILITY_STATE[35618] = false; -- Overload

-- Assault
SETTINGS.TIMERS[41682] = {show = true, frame = 1}; -- Hellfire
SETTINGS.TIMERS[3639]  = {show = true, frame = 1}; -- Overcharge
SETTINGS.TIMERS[35637] = {show = true, frame = 1}; -- Supercharge
SETTINGS.TIMERS[35458] = {show = true, frame = 1}; -- Thermal Wave

-- Biotech
SETTINGS.TIMERS[15206] = {show = true, frame = 1}; -- Adrenaline
SETTINGS.TIMERS[34734] = {show = true, frame = 1}; -- Creeping Death
SETTINGS.TIMERS[34928] = {show = true, frame = 1}; -- Healing Dome
SETTINGS.TIMERS[41867] = {show = true, frame = 1}; -- Heroism
SETTINGS.TIMERS[35620] = {show = true, frame = 1}; -- Necrosis
SETTINGS.TIMERS[41865] = {show = true, frame = 1}; -- Poison Ball
SETTINGS.TIMERS[40592] = {show = true, frame = 1}; -- Poison Trail

-- Dreadnaught
SETTINGS.TIMERS[41881] = {show = true, frame = 1}; -- Absorption Bomb
SETTINGS.TIMERS[34066] = {show = true, frame = 1}; -- Dreadfield
SETTINGS.TIMERS[3782]  = {show = true, frame = 1}; -- Heavy Armor
SETTINGS.TIMERS[41875] = {show = true, frame = 1}; -- Penetrating Rounds
SETTINGS.TIMERS[1726]  = {show = true, frame = 1}; -- Thunderdome

-- Engineer
SETTINGS.TIMERS[34770] = {show = true, frame = 1}; -- Boomerang Shot
SETTINGS.TIMERS[35455] = {show = true, frame = 1}; -- Bulwark
SETTINGS.TIMERS[35583] = {show = true, frame = 1}; -- Electrical Storm
SETTINGS.TIMERS[41886] = {show = true, frame = 1}; -- Fortify
SETTINGS.TIMERS[41880] = {show = true, frame = 1}; -- Overclock

-- Recon
SETTINGS.TIMERS[35567] = {show = true, frame = 1}; -- Artillery Strike
SETTINGS.TIMERS[39405] = {show = true, frame = 1}; -- Cryo Bolt -- Cryo Shot
SETTINGS.TIMERS[34957] = {show = true, frame = 1}; -- Decoy
SETTINGS.TIMERS[35618] = {show = true, frame = 1}; -- Overload
SETTINGS.TIMERS[34526] = {show = true, frame = 1}; -- SIN Beacon
SETTINGS.TIMERS[35345] = {show = true, frame = 1}; -- Smoke Screen
SETTINGS.TIMERS[12305] = {show = true, frame = 1}; -- Teleport Beacon

-- Miscellaneous
SETTINGS.TIMERS[38620] = {show = true, frame = 1}; -- Activate: Rocket Wings

-- Perks
SETTINGS.TIMERS["P[86118]"] = {show = true, frame = 1}; -- Sure Shot
SETTINGS.TIMERS["P[85995]"] = {show = true, frame = 1}; -- Hero
SETTINGS.TIMERS["P[85888]"] = {show = true, frame = 1}; -- Hyper Kinesis Surge
SETTINGS.TIMERS["P[85818]"] = {show = true, frame = 1}; -- Health Surge
SETTINGS.TIMERS["P[95078]"] = {show = true, frame = 1}; -- Invigorate
-- SETTINGS.TIMERS["P[]"] = {show = true, frame = 1}; --

-- =============================================================================
--  Options
-- =============================================================================

function BuildOptions()
    local SUBTAB = {};

    InterfaceOptions.AddMovableFrame({frame=UI.FRAMES[1].OBJ, label="Ability Duration Timer (Frame 1)", scalable=true});
    InterfaceOptions.AddMovableFrame({frame=UI.FRAMES[2].OBJ, label="Ability Duration Timer (Frame 2)", scalable=true});
    InterfaceOptions.AddMovableFrame({frame=UI.FRAMES[3].OBJ, label="Ability Duration Timer (Frame 3)", scalable=true});
    InterfaceOptions.AddMovableFrame({frame=UI.FRAMES[4].OBJ, label="Ability Duration Timer (Frame 4)", scalable=true});

    InterfaceOptions.AddCheckBox({id="DEBUG_ENABLED", label="Debug", default=(Component.GetSetting("DEBUG_ENABLED") or SETTINGS.debug)});
    InterfaceOptions.AddCheckBox({id="SYSMSG_ENABLED", label="Chat output (Starting duration timer ...)", default=(Component.GetSetting("SYSMSG_ENABLED") or SETTINGS.system_message)});
    InterfaceOptions.AddTextInput({id="SYSMSG_TEXT", label="Chat output message", default=SETTINGS.system_message_text, tooltip="Message to show when the timer starts.\nAvailable parameter: ${name} and ${duration}"});
    InterfaceOptions.AddSlider({id="MAX_TIMERS", label="Max timers", min=1, max=50, inc=1, suffix="", default=(Component.GetSetting("MAX_TIMERS") or SETTINGS.max_timers)});
    InterfaceOptions.AddChoiceMenu({id="FRAME_1_ALIGNMENT", label="Frame 1 alignment", default=(Component.GetSetting("FRAME_1_ALIGNMENT") or UI.FRAMES[1].alignment)});
        InterfaceOptions.AddChoiceEntry({menuId="FRAME_1_ALIGNMENT", val="ltr", label="left to right"});
        InterfaceOptions.AddChoiceEntry({menuId="FRAME_1_ALIGNMENT", val="rtl", label="right to left"});
    InterfaceOptions.AddChoiceMenu({id="FRAME_2_ALIGNMENT", label="Frame 2 alignment", default=(Component.GetSetting("FRAME_2_ALIGNMENT") or UI.FRAMES[2].alignment)});
        InterfaceOptions.AddChoiceEntry({menuId="FRAME_2_ALIGNMENT", val="ltr", label="left to right"});
        InterfaceOptions.AddChoiceEntry({menuId="FRAME_2_ALIGNMENT", val="rtl", label="right to left"});
    InterfaceOptions.AddChoiceMenu({id="FRAME_3_ALIGNMENT", label="Frame 3 alignment", default=(Component.GetSetting("FRAME_3_ALIGNMENT") or UI.FRAMES[3].alignment)});
        InterfaceOptions.AddChoiceEntry({menuId="FRAME_3_ALIGNMENT", val="ltr", label="left to right"});
        InterfaceOptions.AddChoiceEntry({menuId="FRAME_3_ALIGNMENT", val="rtl", label="right to left"});
    InterfaceOptions.AddChoiceMenu({id="FRAME_4_ALIGNMENT", label="Frame 4 alignment", default=(Component.GetSetting("FRAME_4_ALIGNMENT") or UI.FRAMES[4].alignment)});
        InterfaceOptions.AddChoiceEntry({menuId="FRAME_4_ALIGNMENT", val="ltr", label="left to right"});
        InterfaceOptions.AddChoiceEntry({menuId="FRAME_4_ALIGNMENT", val="rtl", label="right to left"});

    SUBTAB = {"Font"};

    InterfaceOptions.AddChoiceMenu({id="FONT", label="Type", default=(Component.GetSetting("FONT") or SETTINGS.FONT.name), subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Demi", label="Eurostile Medium", subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Narrow", label="Eurostile Narrow", subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Wide", label="Eurostile Wide", subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Bold", label="Eurostile Bold", subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuRegular", label="Ubuntu Regular", subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuMedium", label="Ubuntu Medium", subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuBold", label="Ubuntu Bold", subtab=SUBTAB});
    InterfaceOptions.AddSlider({id="FONT_SIZE", label="Size", min=1, max=20, inc=1, suffix="", default=(Component.GetSetting("FONT_SIZE") or SETTINGS.FONT.size), subtab=SUBTAB});
    InterfaceOptions.AddColorPicker({id="TIMER_COLOR", label="Duration color", default={tint=(Component.GetSetting("TIMER_COLOR") or SETTINGS.FONT.COLOR.text_timer)}, subtab=SUBTAB});
    InterfaceOptions.AddColorPicker({id="TIMER_COLOR_OUTLINE", label="Duration outline color", default={tint=(Component.GetSetting("TIMER_COLOR_OUTLINE") or SETTINGS.FONT.COLOR.text_timer_outline)}, subtab=SUBTAB});

    SUBTAB = {"Arc"};

    InterfaceOptions.AddCheckBox({id="ARC_ENABLED", label="Enabled", default=(Component.GetSetting("ARC_ENABLED") or SETTINGS.ARC.show), subtab=SUBTAB});
    InterfaceOptions.AddColorPicker({id="ARC_COLOR", label="Color", default={tint=(Component.GetSetting("ARC_COLOR") or SETTINGS.ARC.COLOR.normal)}, subtab=SUBTAB});
    InterfaceOptions.AddColorPicker({id="ARC_WARNING_COLOR", label="Warning color", default={tint=(Component.GetSetting("ARC_WARNING_COLOR") or SETTINGS.ARC.COLOR.warning)}, subtab=SUBTAB});
    InterfaceOptions.AddSlider({id="ARC_WARNING_SECONDS", label="Warning start at X seconds remain", min=1, max=20, inc=1, suffix="", default=(Component.GetSetting("ARC_WARNING_SECONDS") or SETTINGS.ARC.warning), subtab=SUBTAB});

    SUBTAB = {"Perks"};

    RUMPEL.AddAbilityOptions("Sure Shot", "P[86118]", SUBTAB);
    RUMPEL.AddAbilityOptions("Hero", "P[85995]", SUBTAB);
    RUMPEL.AddAbilityOptions("Hyper Kinesis Surge", "P[85888]", SUBTAB);
    RUMPEL.AddAbilityOptions("Health Surge", "P[85818]", SUBTAB);
    RUMPEL.AddAbilityOptions("Invigorate", "P[95078]", SUBTAB);

    -- Assault
    SUBTAB = {"Abilities", "Assault"};

    RUMPEL.AddAbilityOptions("Hellfire", 41682, SUBTAB);
    RUMPEL.AddAbilityOptions("Overcharge", 3639, SUBTAB);
    RUMPEL.AddAbilityOptions("Thermal Wave", 35458, SUBTAB);

    InterfaceOptions.StartGroup({label="Ultimate/HKM", subtab=SUBTAB});
        RUMPEL.AddAbilityOptions("Supercharge", 35637, SUBTAB);
    InterfaceOptions.StopGroup({subtab=SUBTAB});

    -- Biotech
    SUBTAB = {"Abilities", "Biotech"};

    RUMPEL.AddAbilityOptions("Adrenaline Rush", 15206, SUBTAB);
    RUMPEL.AddAbilityOptions("Creeping Death", 34734, SUBTAB);
    RUMPEL.AddAbilityOptions("Poison Ball", 41865, SUBTAB);
    RUMPEL.AddAbilityOptions("Poison Trail", 40592, SUBTAB);

    InterfaceOptions.StartGroup({label="Ultimate/HKM", subtab=SUBTAB});
        RUMPEL.AddAbilityOptions("Healing Dome", 34928, SUBTAB);
        RUMPEL.AddAbilityOptions("Heroism", 41867, SUBTAB);
        RUMPEL.AddAbilityOptions("Necrosis", 35620, SUBTAB);
    InterfaceOptions.StopGroup({subtab=SUBTAB});

    -- Dreadnaught
    SUBTAB = {"Abilities", "Dreadnaught"};

    RUMPEL.AddAbilityOptions("Heavy Armor", 3782, SUBTAB);
    RUMPEL.AddAbilityOptions("Penetrating Rounds", 41875, SUBTAB);
    RUMPEL.AddAbilityOptions("Thunderdome", 1726, SUBTAB);

    InterfaceOptions.StartGroup({label="Ultimate/HKM", subtab=SUBTAB});
        RUMPEL.AddAbilityOptions("Absorption Bomb", 41881, SUBTAB);
        RUMPEL.AddAbilityOptions("Dreadfield", 34066, SUBTAB);
    InterfaceOptions.StopGroup({subtab=SUBTAB});

    -- Engineer
    SUBTAB = {"Abilities", "Engineer"};

    RUMPEL.AddAbilityOptions("Boomerang Shot", 34770, SUBTAB);
    RUMPEL.AddAbilityOptions("Bulwark", 41886, SUBTAB);
    RUMPEL.AddAbilityOptions("Overclock", 41880, SUBTAB);

    InterfaceOptions.StartGroup({label="Ultimate/HKM", subtab=SUBTAB});
        RUMPEL.AddAbilityOptions("Electrical Storm", 35583, SUBTAB);
        RUMPEL.AddAbilityOptions("Fortify", 35455, SUBTAB);
    InterfaceOptions.StopGroup({subtab=SUBTAB});

    -- Recon
    SUBTAB = {"Abilities", "Recon"};

    RUMPEL.AddAbilityOptions("Cryo Shot", 39405, SUBTAB);
    RUMPEL.AddAbilityOptions("Decoy", 34957, SUBTAB);
    RUMPEL.AddAbilityOptions("SIN Beacon", 34526, SUBTAB);
    RUMPEL.AddAbilityOptions("Smoke Screen", 35345, SUBTAB);
    RUMPEL.AddAbilityOptions("Teleport Beacon", 12305, SUBTAB);

    InterfaceOptions.StartGroup({label="Ultimate/HKM", subtab=SUBTAB});
        RUMPEL.AddAbilityOptions("Artillery Strike", 35567, SUBTAB);
        RUMPEL.AddAbilityOptions("Overload", 35618, SUBTAB);
    InterfaceOptions.StopGroup({subtab=SUBTAB});

    -- Miscellaneous
    SUBTAB = {"Abilities", "Miscellaneous"};

    RUMPEL.AddAbilityOptions("Rocketeer's Wings", 38620, SUBTAB);
end

-- =============================================================================
--  Events
-- =============================================================================

function OnComponentLoad()
    ADTStatic
        .SetAlignment(UI.ALIGNMENT)
        .SetArcShow(SETTINGS.ARC.show)
        .SetArcColor(SETTINGS.ARC.COLOR.normal)
        .SetArcColorWarning(SETTINGS.ARC.COLOR.warning)
        .SetWarningSeconds(SETTINGS.ARC.warning)
        .SetMaxVisible(SETTINGS.max_timers)
        .SetFontName(SETTINGS.FONT.name)
        .SetFontSize(SETTINGS.FONT.size)
        .SetFontColor(SETTINGS.FONT.COLOR.text_timer)
        .SetFontColorOutline(SETTINGS.FONT.COLOR.text_timer_outline)
        .RegisterFrame(UI.FRAMES[1])
        .RegisterFrame(UI.FRAMES[2])
        .RegisterFrame(UI.FRAMES[3])
        .RegisterFrame(UI.FRAMES[4])
        .Init({1, 2, 3, 4});

    BuildOptions();

    InterfaceOptions.SetCallbackFunc(OnOptionChanged, "Ability Duration Timer");

    LIB_SLASH.BindCallback({slash_list=slash_list, func=OnSlash});

    getmetatable("").__mod = function (s, tab)
        return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
    end

    RUMPEL.GetKnownAbilities();
end

function OnPlayerReady()
    RUMPEL.GetPerks();
    RUMPEL.GetLoadoutPerks();
end

function OnComponentUnload()
    LIB_SLASH.UnbindCallback(slash_list);
end

function OnSlash(ARGS)
    -- RUMPEL.ConsoleLog("OnSlash with args: "..tostring(ARGS));

    if 42 == tonumber(ARGS[1]) and nil ~= ARGS[2] then
        RUMPEL.TestTimers(tonumber(ARGS[2]));
    elseif "rm" == ARGS[1] then
        ADTStatic.KillAll();
    elseif "bw" == ARGS[1] and nil ~= ARGS[2] then
        RUMPEL.TestBulwark(tonumber(ARGS[2]));
    elseif "pstats" == ARGS[1] then
        log(tostring(Player.GetAllStats()));
    elseif "timers" == ARGS[1] then
        RUMPEL.SystemMsg("Active Timers: "..tostring(ADTStatic.GetActive()));
    elseif "life" == ARGS[1] then
        RUMPEL.SystemMsg(Player.GetLifeInfo());
        RUMPEL.SystemMsg(RUMPEL.CurrentHealth());
    elseif "perks" == ARGS[1] then
        RUMPEL.GetLoadoutPerks();
    elseif "weapon" == ARGS[1] then
        RUMPEL.SystemMsg("Player.GetWeaponInfo():\n"..tostring(Player.GetWeaponInfo()));
        RUMPEL.SystemMsg("Player.GetWeaponState():\n"..tostring(Player.GetWeaponState()));
        -- RUMPEL.SystemMsg("Player.GetWeaponMode():\n"..tostring(Player.GetWeaponMode()));
        -- RUMPEL.SystemMsg("Player.GetWeaponIndex():\n"..tostring(Player.GetWeaponIndex()));
        -- RUMPEL.SystemMsg("Player.GetWeaponCharge():\n"..tostring(Player.GetWeaponCharge()));
    elseif "loadout" == ARGS[1] then
        RUMPEL.Log("Player.GetCurrentLoadout():\n"..tostring(Player.GetCurrentLoadout()));
    elseif "test" == ARGS[1] then
        RUMPEL.Test();
    else
        RUMPEL.SystemMsg("Unknown slash command.");
    end
end

function OnShow(ARGS)
    for i,_ in pairs(UI.FRAMES) do
        UI.FRAMES[i].OBJ:Show(ARGS.show);
    end
end

function OnBattleframeChanged()
    ADTStatic.KillAll();

    RUMPEL.GetLoadoutPerks();
end

function OnDeath()
    -- ADTStatic.KillAll();
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
    elseif "FRAME_1_ALIGNMENT" == id then
        UI.FRAMES[1].alignment = value;
        Component.SaveSetting("FRAME_1_ALIGNMENT", value);
        ADTStatic.UpdateFrame(UI.FRAMES[1]);
    elseif "FRAME_2_ALIGNMENT" == id then
        UI.FRAMES[2].alignment = value;
        Component.SaveSetting("FRAME_2_ALIGNMENT", value);
        ADTStatic.UpdateFrame(UI.FRAMES[2]);
    elseif "FRAME_3_ALIGNMENT" == id then
        UI.FRAMES[3].alignment = value;
        Component.SaveSetting("FRAME_3_ALIGNMENT", value);
        ADTStatic.UpdateFrame(UI.FRAMES[3]);
    elseif "FRAME_4_ALIGNMENT" == id then
        UI.FRAMES[4].alignment = value;
        Component.SaveSetting("FRAME_4_ALIGNMENT", value);
        ADTStatic.UpdateFrame(UI.FRAMES[4]);
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
    elseif "ARC_ENABLED" == id then
        SETTINGS.ARC.show = value;
        Component.SaveSetting("ARC_ENABLED", value);
        ADTStatic.SetArcShow(value);
    elseif "ARC_COLOR" == id then
        SETTINGS.ARC.COLOR.normal = value.tint;
        Component.SaveSetting("ARC_COLOR", value.tint);
        ADTStatic.SetArcColor(value.tint);
    elseif "ARC_WARNING_COLOR" == id then
        SETTINGS.ARC.COLOR.warning = value.tint;
        Component.SaveSetting("ARC_WARNING_COLOR", value.tint);
        ADTStatic.SetArcColorWarning(value.tint);
    elseif "ARC_WARNING_SECONDS" == id then
        SETTINGS.ARC.warning = value;
        Component.SaveSetting("ARC_WARNING_SECONDS", value);
        ADTStatic.SetWarningSeconds(value);
    elseif "PERKS_ENABLED" == id then
        SETTINGS.TRACK_PERKS.show = value;
        Component.SaveSetting("PERKS_ENABLED", value);
    elseif "PERKS_FRAME" == id then
        SETTINGS.TRACK_PERKS.frame = tonumber(value);
        Component.SaveSetting("PERKS_FRAME", value);
    else
        for i,opt in pairs(ABILITY_OPTIONS) do
            local full_opt_enabled = opt.."_ENABLED";
            local full_opt_frame   = opt.."_FRAME";

            if full_opt_enabled == id then
                SETTINGS.TIMERS[i].show = value;
                Component.SaveSetting(full_opt_enabled, value);

                break;
            elseif full_opt_frame == id then
                SETTINGS.TIMERS[i].frame = tonumber(value);
                Component.SaveSetting(full_opt_frame, value);

                break;
            end
        end
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

        if 4 >= ARGS.index then
            RUMPEL.CheckOnAbilityPerks(ARGS);
        end

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

        if nil ~= ability_duration and true ~= ON_ABILITY_STATE[ability_id] and nil ~= SETTINGS.TIMERS[ability_id] and true == SETTINGS.TIMERS[ability_id].show then
            RUMPEL.ConsoleLog("AbilityDurationTimer()");
            RUMPEL.DurTimerMsg(ABILITY_INFO.name, ability_duration);

            local ADT = AbilityDurationTimer(SETTINGS.TIMERS[ability_id].frame);

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

        if 4 >= ARGS.index then
            RUMPEL.CheckOnAbilityPerks(ARGS);
        end

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

        if nil ~= SETTINGS.TIMERS[ability_id] and true == SETTINGS.TIMERS[ability_id].show and false ~= ON_ABILITY_STATE[ability_id] then
            RUMPEL.ConsoleLog("AbilityDurationTimer()");
            RUMPEL.DurTimerMsg(ability_name, ARGS.state_dur_total);

            local ADT = AbilityDurationTimer(SETTINGS.TIMERS[ability_id].frame);

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
    if true == RUMPEL.CheckPerkEquipped("P[86118]") and true == SETTINGS.TIMERS["P[86118]"].show then
        local fire_rate_mod_new   = Player.GetWeaponState().FireRateMod;
        local fire_rate_mod_check = fire_rate_mod * 0.5;

        if fire_rate_mod_new == fire_rate_mod_check then
            local ADT = AbilityDurationTimer(SETTINGS.TIMERS["P[86118]"].frame);

            ADT:SetAbilityID("P[86118]");
            ADT:SetAbilityName(SLOTTED_PERKS["P[86118]"].name);
            ADT:SetIconID(SLOTTED_PERKS["P[86118]"].web_icon_id);
            ADT:SetDuration(ABILITY_DURATIONS["P[86118]"]);
            ADT:StartTimer(RUMPEL.Callback);
        end

        fire_rate_mod = fire_rate_mod_new;
    end
end

function OnTookHit(ARGS)
    if true == RUMPEL.CheckPerkEquipped("P[85995]") and true == SETTINGS.TIMERS["P[85995]"].show and "Healing" ~= ARGS.damageType then
        local LIFE_INFO = Player.GetLifeInfo();
        local health    = LIFE_INFO["Health"] - ARGS.damage;

        -- RUMPEL.SystemMsg(LIFE_INFO);
        -- RUMPEL.SystemMsg(hero_proc_time);
        -- RUMPEL.SystemMsg(ARGS);

        if 0 >= health and 0 == hero_proc_time then
            local ADT    = AbilityDurationTimer(SETTINGS.TIMERS["P[85995]"].frame);
            local ADT_CD = AbilityDurationTimer(SETTINGS.TIMERS["P[85995]"].frame);

            hero_proc_time = tonumber(System.GetClientTime());

            ADT:SetAbilityID("P[85995]");
            ADT_CD:SetAbilityID("P[85995]");
            ADT:SetAbilityName(SLOTTED_PERKS["P[85995]"].name);
            ADT_CD:SetAbilityName(SLOTTED_PERKS["P[85995]"].name);
            ADT:SetIconID(SLOTTED_PERKS["P[85995]"].web_icon_id);
            ADT_CD:SetIconID(SLOTTED_PERKS["P[85995]"].web_icon_id);
            ADT:SetDuration(ABILITY_DURATIONS["P[85995]"]);
            ADT_CD:SetDuration(ABILITY_DURATIONS["P[85995][CD]"]);
            ADT:StartTimer(RUMPEL.Callback);
            ADT_CD:StartTimer(RUMPEL.Callback);

            Callback2.FireAndForget(RUMPEL.ResetHeroProcTime, {}, 0.1);
        end
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

function RUMPEL.ResetHeroProcTime()
    local time       = tonumber(System.GetClientTime());
    local reset_time = hero_proc_time + ABILITY_DURATIONS["P[85995]"] * 1000 + 1000;

    -- RUMPEL.SystemMsg(hero_proc_time);
    -- RUMPEL.SystemMsg(time);
    -- RUMPEL.SystemMsg(reset_time);

    if time > reset_time then
        hero_proc_time = 0;
    else
        Callback2.FireAndForget(RUMPEL.ResetHeroProcTime, {}, 0.1);
    end
end

function RUMPEL.AddAbilityOptions(name, id, SUBTAB)
    local name_for_id = string.gsub(string.gsub(string.upper(name), "%s+", "_"), "[^%a]", "");

    ABILITY_OPTIONS[id] = name_for_id;

    InterfaceOptions.AddCheckBox({id=name_for_id.."_ENABLED", label=name, default=(Component.GetSetting(name_for_id.."_ENABLED") or SETTINGS.TIMERS[id].show), subtab=SUBTAB});
    InterfaceOptions.AddChoiceMenu({id=name_for_id.."_FRAME", label=name.." frame", default=(Component.GetSetting(name_for_id.."_FRAME") or SETTINGS.TIMERS[id].frame), subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId=name_for_id.."_FRAME", val="1", label="1", subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId=name_for_id.."_FRAME", val="2", label="2", subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId=name_for_id.."_FRAME", val="3", label="3", subtab=SUBTAB});
        InterfaceOptions.AddChoiceEntry({menuId=name_for_id.."_FRAME", val="4", label="4", subtab=SUBTAB});
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

function RUMPEL.CheckOnAbilityPerks(ARGS)
    if 4 == ARGS.index and true == RUMPEL.CheckPerkEquipped("P[85888]") and true == SETTINGS.TIMERS["P[85888]"].show then
        if "AbilityDurationTimer" == type(RUMPEL.ABILITIES_RM_ON_REUSE["P[85888]"].ADT) then
            RUMPEL.ABILITIES_RM_ON_REUSE["P[85888]"].ADT:Reschedule(ABILITY_DURATIONS["P[85888]"]);
        else
            local ADT = AbilityDurationTimer(SETTINGS.TIMERS["P[85888]"].frame);

            ADT:SetAbilityID("P[85888]");
            ADT:SetAbilityName(SLOTTED_PERKS["P[85888]"].name);
            ADT:SetIconID(SLOTTED_PERKS["P[85888]"].web_icon_id);
            ADT:SetDuration(ABILITY_DURATIONS["P[85888]"]);
            ADT:StartTimer(RUMPEL.Callback);

            RUMPEL.ABILITIES_RM_ON_REUSE["P[85888]"].ADT = ADT;
        end
    end

    if true == RUMPEL.CheckPerkEquipped("P[85818]") and true == SETTINGS.TIMERS["P[85818]"].show then
        if "AbilityDurationTimer" == type(RUMPEL.ABILITIES_RM_ON_REUSE["P[85818]"].ADT) then
            RUMPEL.ABILITIES_RM_ON_REUSE["P[85818]"].ADT:Reschedule(ABILITY_DURATIONS["P[85818]"]);
        else
            local ADT = AbilityDurationTimer(SETTINGS.TIMERS["P[85818]"].frame);

            ADT:SetAbilityID("P[85818]");
            ADT:SetAbilityName(SLOTTED_PERKS["P[85818]"].name);
            ADT:SetIconID(SLOTTED_PERKS["P[85818]"].web_icon_id);
            ADT:SetDuration(ABILITY_DURATIONS["P[85818]"]);
            ADT:StartTimer(RUMPEL.Callback);

            RUMPEL.ABILITIES_RM_ON_REUSE["P[85818]"].ADT = ADT;
        end
    end

    if true == RUMPEL.CheckPerkEquipped("P[95078]") and true == SETTINGS.TIMERS["P[95078]"].show then
        if "AbilityDurationTimer" == type(RUMPEL.ABILITIES_RM_ON_REUSE["P[95078]"].ADT) then
            RUMPEL.ABILITIES_RM_ON_REUSE["P[95078]"].ADT:Reschedule(ABILITY_DURATIONS["P[95078]"]);
        else
            local ADT = AbilityDurationTimer(SETTINGS.TIMERS["P[95078]"].frame);

            ADT:SetAbilityID("P[95078]");
            ADT:SetAbilityName(SLOTTED_PERKS["P[95078]"].name);
            ADT:SetIconID(SLOTTED_PERKS["P[95078]"].web_icon_id);
            ADT:SetDuration(ABILITY_DURATIONS["P[95078]"]);
            ADT:StartTimer(RUMPEL.Callback);

            RUMPEL.ABILITIES_RM_ON_REUSE["P[95078]"].ADT = ADT;
        end
    end
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
        message = debug_prefix..tostring(message);

        RUMPEL.Log(message);

        RUMPEL.SystemMsg(message);
    end
end

function RUMPEL.Log(message)
    log(tostring(message));
end

function RUMPEL.SystemMsg(message)
    ChatLib.SystemMessage({text = output_prefix..tostring(message)});
end

function RUMPEL.DurTimerMsg(ability_name, duration)
    if true == SETTINGS.system_message then
        RUMPEL.SystemMsg(SETTINGS.system_message_text % {
            name     = ability_name,
            duration = tostring(math.floor((tonumber(duration) * 100) + 0.5) / 100)
        });
    end
end

function RUMPEL.Test()
    RUMPEL.SystemMsg(UI.FRAMES[1].OBJ == UI.FRAMES[1].OBJ);
    RUMPEL.SystemMsg(UI.FRAMES[1].OBJ == UI.FRAMES[2].OBJ);
    RUMPEL.SystemMsg(UI.FRAMES[1].OBJ == UI.FRAMES[3].OBJ);
    RUMPEL.SystemMsg(UI.FRAMES[1].OBJ == UI.FRAMES[4].OBJ);

    RUMPEL.SystemMsg(UI.FRAMES[4].OBJ == UI.FRAMES[1].OBJ);
    RUMPEL.SystemMsg(UI.FRAMES[4].OBJ == UI.FRAMES[2].OBJ);
    RUMPEL.SystemMsg(UI.FRAMES[4].OBJ == UI.FRAMES[3].OBJ);
    RUMPEL.SystemMsg(UI.FRAMES[4].OBJ == UI.FRAMES[4].OBJ);
end

function RUMPEL.TestTimers(frame_id)
    if nil == frame_id then
        frame_id = 1;
    end

    local ADTS = {
        ["1"] = AbilityDurationTimer(frame_id),
        ["2"] = AbilityDurationTimer(frame_id),
        ["3"] = AbilityDurationTimer(frame_id),
        ["4"] = AbilityDurationTimer(frame_id)
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

function RUMPEL.TestBulwark(frame_id)
    if nil == frame_id then
        frame_id = 1;
    end

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

    local ADT = AbilityDurationTimer(frame_id);

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
end
