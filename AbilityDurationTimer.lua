-- ===============================
-- Ability Duration Timer
-- by: Rumpel, Vollmond
-- ===============================
-- 
-- ===============================

require "string";
require "lib/lib_Callback2";
require "lib/lib_InterfaceOptions";
require "lib/lib_Slash";

-- ===============================
--  Variables
-- ===============================

local UI                         = {};
local RUMPEL                     = {};
local SETTINGS                   = {};
local ABILITY_INFOS              = {};
local ABILITY_ALIAS              = {};
local ABILITY_ALIAS_PLAYER_STATS = {};
local ABILITY_DURATIONS          = {};
local SHOW_TIMERS                = {};
local ON_ABILITY_STATE           = {};
local slash_list                 = "adt";

UI.max_timers        = 6;
UI.active_timers     = 0;
UI.TIMERS            = {};
UI.GRP_POSITIONS     = {};
UI.GRP_POSITIONS.LTR = {};
UI.GRP_POSITIONS.RTL = {};
UI.FRAME             = Component.GetFrame("adt_frame");

SETTINGS = {
    debug            = false,
    system_message   = true,
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

-- no ability infos on event 'ON_ABILITY_STATE'
ABILITY_INFOS[3782]  = {icon_id = 202130}; -- Heavy Armor
ABILITY_INFOS[1726]  = {icon_id = 222527}; -- Thunderdome
ABILITY_INFOS[34066] = {icon_id = 202138}; -- Dreadfield
ABILITY_INFOS[41881] = {icon_id = 212177}; -- Absorption Bomb
ABILITY_INFOS[15206] = {icon_id = 492574}; -- Adrenaline Rush
ABILITY_INFOS[12305] = {icon_id = 202115}; -- Teleport Beacon
ABILITY_INFOS[3639]  = {icon_id = 222507}; -- Overcharge
ABILITY_INFOS[41880] = {icon_id = 222507}; -- Overclock [ON_ABILITY_USED]
ABILITY_INFOS[15229] = {icon_id = 222507}; -- Overclock [ON_ABILITY_STATE] (named Overcharge ...)
ABILITY_INFOS[35455] = {icon_id = 222475}; -- Bulwark
ABILITY_INFOS[41886] = {icon_id = 222491}; -- Fortify
-- ABILITY_INFOS[38620] = {icon_id = 392110}; -- Rocketeer's Wings

ABILITY_ALIAS["Adrenaline"]             = "Adrenaline Rush";
ABILITY_ALIAS["Activate: Rocket Wings"] = "Rocketeer's Wings";

ABILITY_ALIAS_PLAYER_STATS["Hellfire"] = "Missile Barrage";

ABILITY_DURATIONS["Activate: Rocket Wings"] = 16;

UI.GRP_POSITIONS.LTR[1] = "left:0; top:0; height:64; width:64;";
UI.GRP_POSITIONS.LTR[2] = "left:68; top:0; height:64; width:64;";
UI.GRP_POSITIONS.LTR[3] = "left:136; top:0; height:64; width:64;";
UI.GRP_POSITIONS.LTR[4] = "left:204; top:0; height:64; width:64;";
UI.GRP_POSITIONS.LTR[5] = "left:272; top:0; height:64; width:64;";
UI.GRP_POSITIONS.LTR[6] = "left:340; top:0; height:64; width:64;";

UI.GRP_POSITIONS.RTL[1] = "left:340; top:0; height:64; width:64;";
UI.GRP_POSITIONS.RTL[2] = "left:272; top:0; height:64; width:64;";
UI.GRP_POSITIONS.RTL[3] = "left:204; top:0; height:64; width:64;";
UI.GRP_POSITIONS.RTL[4] = "left:136; top:0; height:64; width:64;";
UI.GRP_POSITIONS.RTL[5] = "left:68; top:0; height:64; width:64;";
UI.GRP_POSITIONS.RTL[6] = "left:0; top:0; height:64; width:64;";

ON_ABILITY_STATE["Heavy Armor"]     = true;
ON_ABILITY_STATE["Thunderdome"]     = true;
ON_ABILITY_STATE["Adrenaline"]      = true;
ON_ABILITY_STATE["Teleport Beacon"] = true;
ON_ABILITY_STATE["Overcharge"]      = true;
ON_ABILITY_STATE[15229]             = false; -- Overclock [ON_ABILITY_STATE] (named Overcharge ...)

-- Dreadnaught
SETTINGS.TIMERS["Heavy Armor"]     = true;
SETTINGS.TIMERS["Thunderdome"]     = true;
SETTINGS.TIMERS["Dreadfield"]      = true;
SETTINGS.TIMERS["Absorption Bomb"] = true;

-- Biotech
SETTINGS.TIMERS["Adrenaline"] = true;
SETTINGS.TIMERS["Necrosis"]   = true;
SETTINGS.TIMERS["Heroism"]    = true;

-- Recon
SETTINGS.TIMERS["Teleport Beacon"] = true;

-- Assault
SETTINGS.TIMERS["Overcharge"]   = true;
SETTINGS.TIMERS["Thermal Wave"] = true;
SETTINGS.TIMERS["Hellfire"]     = true;

-- Engineer
SETTINGS.TIMERS["Overclock"] = true;
SETTINGS.TIMERS["Bulwark"]   = true;
SETTINGS.TIMERS["Fortify"]   = true;

-- Miscellaneous
SETTINGS.TIMERS["Activate: Rocket Wings"] = true;

-- ===============================
--  Options
-- ===============================

function BuildOptions()
    InterfaceOptions.AddMovableFrame({frame=UI.FRAME, label="Ability Duration Timer", scalable=true});

    InterfaceOptions.StartGroup({label="Ability Duration Timer: Main Settings"});
        InterfaceOptions.AddCheckBox({id="DEBUG_ENABLED", label="Debug enabled", default=(Component.GetSetting("DEBUG_ENABLED") or SETTINGS.debug)});
        InterfaceOptions.AddCheckBox({id="SYSMSG_ENABLED", label="Chat output (Starting duration timer ...) enabled", default=(Component.GetSetting("SYSMSG_ENABLED") or SETTINGS.system_message)});
        InterfaceOptions.AddChoiceMenu({id="TIMERS_ALIGNMENT", label="Timer alignment", default=(Component.GetSetting("TIMERS_ALIGNMENT") or SETTINGS.timers_alignment)});
        InterfaceOptions.AddChoiceEntry({menuId="TIMERS_ALIGNMENT", val="ltr", label="left to right"});
        InterfaceOptions.AddChoiceEntry({menuId="TIMERS_ALIGNMENT", val="rtl", label="right to left"});
        InterfaceOptions.AddChoiceMenu({id="FONT", label="Font", default=(Component.GetSetting("FONT") or SETTINGS.FONT.name)});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Demi", label="Eurostile Medium"});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Bold", label="Eurostile Bold"});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuMedium", label="Ubuntu Medium"});
        InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuBold", label="Ubuntu Bold"});
        InterfaceOptions.AddSlider({id="FONT_SIZE", label="Font size", min=8, max=20, inc=2, suffix="px", default=(Component.GetSetting("FONT_SIZE") or SETTINGS.FONT.size)});
        InterfaceOptions.AddColorPicker({id="TIMER_COLOR", label="Ability duration color", default={tint=(Component.GetSetting("TIMER_COLOR") or SETTINGS.FONT.COLOR.text_timer)}});
        InterfaceOptions.AddColorPicker({id="TIMER_COLOR_OUTLINE", label="Ability duration outline color", default={tint=(Component.GetSetting("TIMER_COLOR_OUTLINE") or SETTINGS.FONT.COLOR.text_timer_outline)}});
    InterfaceOptions.StopGroup();

    -- Dreadnaught
    InterfaceOptions.StartGroup({label="Dreadnaught"});
        InterfaceOptions.AddCheckBox({id="HEAVY_ARMOR_ENABLED", label="Heavy Armor enabled", default=(Component.GetSetting("HEAVY_ARMOR_ENABLED") or SETTINGS.TIMERS["Heavy Armor"])});
        InterfaceOptions.AddCheckBox({id="THUNDERDOME_ENABLED", label="Thunderdome enabled", default=(Component.GetSetting("THUNDERDOME_ENABLED") or SETTINGS.TIMERS["Thunderdome"])});
        InterfaceOptions.AddCheckBox({id="DREADFIELD_ENABLED", label="Dreadfield enabled", default=(Component.GetSetting("DREADFIELD_ENABLED") or SETTINGS.TIMERS["Dreadfield"])});
        InterfaceOptions.AddCheckBox({id="ABSORPTION_BOMB_ENABLED", label="Absorption Bomb enabled", default=(Component.GetSetting("ABSORPTION_BOMB_ENABLED") or SETTINGS.TIMERS["Absorption Bomb"])});
    InterfaceOptions.StopGroup();

    -- Biotech
    InterfaceOptions.StartGroup({label="Biotech"});
        InterfaceOptions.AddCheckBox({id="ADRENALINE_RUSH_ENABLED", label="Adrenaline Rush enabled", default=(Component.GetSetting("ADRENALINE_RUSH_ENABLED") or SETTINGS.TIMERS["Adrenaline"])});
        InterfaceOptions.AddCheckBox({id="NECROSIS_ENABLED", label="Necrosis enabled", default=(Component.GetSetting("NECROSIS_ENABLED") or SETTINGS.TIMERS["Necrosis"])});
        InterfaceOptions.AddCheckBox({id="HEROISM_ENABLED", label="Heroism enabled", default=(Component.GetSetting("HEROISM_ENABLED") or SETTINGS.TIMERS["Heroism"])});
    InterfaceOptions.StopGroup();

    -- Recon
    InterfaceOptions.StartGroup({label="Recon"});
        InterfaceOptions.AddCheckBox({id="TELEPORT_BEACON_ENABLED", label="Teleport Beacon enabled", default=(Component.GetSetting("TELEPORT_BEACON_ENABLED") or SETTINGS.TIMERS["Teleport Beacon"])});
    InterfaceOptions.StopGroup();

    -- Assault
    InterfaceOptions.StartGroup({label="Assault"});
        InterfaceOptions.AddCheckBox({id="OVERCHARGE_ENABLED", label="Overcharge enabled", default=(Component.GetSetting("OVERCHARGE_ENABLED") or SETTINGS.TIMERS["Overcharge"])});
        InterfaceOptions.AddCheckBox({id="THERMAL_WAVE_ENABLED", label="Thermal Wave enabled", default=(Component.GetSetting("THERMAL_WAVE_ENABLED") or SETTINGS.TIMERS["Thermal Wave"])});
        InterfaceOptions.AddCheckBox({id="HELLFIRE_ENABLED", label="Hellfire enabled", default=(Component.GetSetting("HELLFIRE_ENABLED") or SETTINGS.TIMERS["Hellfire"])});
    InterfaceOptions.StopGroup();

    -- Engineer
    InterfaceOptions.StartGroup({label="Engineer"});
        InterfaceOptions.AddCheckBox({id="BULWARK_ENABLED", label="Bulwark enabled", default=(Component.GetSetting("BULWARK_ENABLED") or SETTINGS.TIMERS["Bulwark"])});
        InterfaceOptions.AddCheckBox({id="OVERCLOCK_ENABLED", label="Overclock enabled", default=(Component.GetSetting("OVERCLOCK_ENABLED") or SETTINGS.TIMERS["Overclock"])});
        InterfaceOptions.AddCheckBox({id="FORTIFY_ENABLED", label="Fortify enabled", default=(Component.GetSetting("FORTIFY_ENABLED") or SETTINGS.TIMERS["Fortify"])});
    InterfaceOptions.StopGroup();

    -- Miscellaneous
    InterfaceOptions.StartGroup({label="Miscellaneous"});
        InterfaceOptions.AddCheckBox({id="ROCKETEERS_WINGS_ENABLED", label="Rocketeer's Wings enabled", default=(Component.GetSetting("ROCKETEERS_WINGS_ENABLED") or SETTINGS.TIMERS["Activate: Rocket Wings"])});
    InterfaceOptions.StopGroup();
end

-- ===============================
--  Events
-- ===============================

function OnComponentLoad()
    BuildOptions();

    InterfaceOptions.SetCallbackFunc(OnOptionChanged, "Ability Duration Timer");

    LIB_SLASH.BindCallback({slash_list=slash_list, func=OnSlash});
end

function OnComponentUnload()
    LIB_SLASH.UnbindCallback(slash_list);
end

function OnSlash(ARGS)
    -- RUMPEL.ConsoleLog("OnSlash with args: "..tostring(ARGS));

    if 42 == tonumber(ARGS[1]) then
        RUMPEL.TestTimers();
    elseif "rm" == ARGS[1] then
        RUMPEL.RemoveTimers();
    elseif "pstats" == ARGS[1] then
        log(tostring(Player.GetAllStats()));
    elseif "timers" == ARGS[1] then
        RUMPEL.SystemMsg("UI.active_timers: "..tostring(UI.active_timers));
    end
end

function OnShow(ARGS)
    UI.FRAME:Show(ARGS.show);
end

function OnBattleframeChanged()
    RUMPEL.RemoveTimers();
end

function OnDeath()
    RUMPEL.RemoveTimers();
end

function OnOptionChanged(id, value)
    if "DEBUG_ENABLED" == id then
        SETTINGS.debug = value;
        Component.SaveSetting("DEBUG_ENABLED", value);
    elseif "SYSMSG_ENABLED" == id then
        SETTINGS.system_message = value;
        Component.SaveSetting("SYSMSG_ENABLED", value);
    elseif "TIMERS_ALIGNMENT" == id then
        SETTINGS.timers_alignment = value;
        Component.SaveSetting("TIMERS_ALIGNMENT", value);
    elseif "FONT" == id then
        SETTINGS.FONT.name = value;
        Component.SaveSetting("FONT", value);
    elseif "FONT_SIZE" == id then
        SETTINGS.FONT.size = value;
        Component.SaveSetting("FONT_SIZE", value);
    elseif "TIMER_COLOR" == id then
        SETTINGS.FONT.COLOR.text_timer = value.tint;
        Component.SaveSetting("TIMER_COLOR", value.tint);
    elseif "TIMER_COLOR_OUTLINE" == id then
        SETTINGS.FONT.COLOR.text_timer_outline = value.tint;
        Component.SaveSetting("TIMER_COLOR_OUTLINE", value.tint);
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
    end
end

function OnAbilityUsed(ARGS)
    if -1 ~= ARGS.index then
        local ABILITY_INFO = Player.GetAbilityInfo(ARGS.id);

        RUMPEL.ConsoleLog("Ability '"..ABILITY_INFO.name.."' fired Event 'ON_ABILITY_USED'!");
        RUMPEL.ConsoleLog("ID: "..tostring(ARGS.id));
        RUMPEL.ConsoleLog("NAME: "..ABILITY_INFO.name);
        RUMPEL.ConsoleLog("ICON ID: "..tostring(ABILITY_INFO.iconId));

        local ability_duration = ABILITY_DURATIONS[ABILITY_INFO.name] or RUMPEL.GetAbilityDuration((ABILITY_ALIAS_PLAYER_STATS[ABILITY_INFO.name] or ABILITY_INFO.name));

        RUMPEL.ConsoleLog("DURATION: "..tostring(ability_duration));

        if nil ~= ability_duration and true ~= ON_ABILITY_STATE[ABILITY_INFO.name] and true == SETTINGS.TIMERS[ABILITY_INFO.name] then
            RUMPEL.ConsoleLog("OnAbilityUsed:CreateIcon");
            RUMPEL.CreateUiTimer(ABILITY_INFO.iconId, ability_duration, ABILITY_INFO.name, ARGS.id);
        end
    end
end

function OnAbilityState(ARGS)
    if -1 ~= ARGS.index then
        local ability_name = ARGS.state;
        local ability_id   = tonumber(ARGS.id);

        RUMPEL.ConsoleLog("Ability '"..ability_name.."' fired Event 'ON_ABILITY_STATE'!");
        RUMPEL.ConsoleLog("ID: "..tostring(ability_id));
        RUMPEL.ConsoleLog("NAME: "..ability_name);
        RUMPEL.ConsoleLog("ICON ID: "..tostring(ABILITY_INFOS[tonumber(ability_id)].icon_id));
        RUMPEL.ConsoleLog("DURATION: "..tostring(ARGS.state_dur_total));
        RUMPEL.ConsoleLog("ON_ABILITY_STATE[ability_id]: "..tostring(ON_ABILITY_STATE[ability_id]));

        if true == SETTINGS.TIMERS[ability_name] and false ~= ON_ABILITY_STATE[ability_name] and false ~= ON_ABILITY_STATE[ability_id] then
            RUMPEL.ConsoleLog("OnAbilityState:CreateIcon");
            RUMPEL.CreateUiTimer(ABILITY_INFOS[ability_id].icon_id, ARGS.state_dur_total, ability_name, ability_id);
        end
    end
end

-- ===============================
--  Functions
-- ===============================

function RUMPEL.CreateUiTimer(icon_id, duration, ability_name, ability_id)
    UI.active_timers = UI.active_timers + 1;

    if UI.max_timers < UI.active_timers then
        UI.active_timers = UI.max_timers;

        do return end
    end

    local i = UI.active_timers; -- to shorten the following lines

    UI.TIMERS[i] = {
        id           = UI.active_timers,
        ability_id   = ability_id,
        icon_id      = icon_id,
        ability_name = ability_name,
        duration     = duration,
        BP           = Component.CreateWidget("BP_IconTimer", UI.FRAME) -- from blueprint in xml
    };

    UI.TIMERS[i].GRP             = UI.TIMERS[i].BP:GetChild("timer_grp");
    UI.TIMERS[i].TIMER_OUTLINE_1 = UI.TIMERS[i].GRP:GetChild("text_timer_outline_1");
    UI.TIMERS[i].TIMER_OUTLINE_2 = UI.TIMERS[i].GRP:GetChild("text_timer_outline_2");
    UI.TIMERS[i].TIMER_OUTLINE_3 = UI.TIMERS[i].GRP:GetChild("text_timer_outline_3");
    UI.TIMERS[i].TIMER_OUTLINE_4 = UI.TIMERS[i].GRP:GetChild("text_timer_outline_4");
    UI.TIMERS[i].TIMER           = UI.TIMERS[i].GRP:GetChild("text_timer");
    UI.TIMERS[i].ICON            = UI.TIMERS[i].GRP:GetChild("icon");
    UI.TIMERS[i].UPDATE_TIMER    = Callback2.Create();

    RUMPEL.ConsoleLog("RUMPEL.CreateUiTimer()::UI.active_timers: "..tostring(i));
    RUMPEL.SetTimer(UI.TIMERS[i]);
end

function RUMPEL.SetTimer(UI_TIMER)
    local GRP_POSITIONS   = nil;
    local font            = SETTINGS.FONT.name.."_"..tostring(SETTINGS.FONT.size);

    RUMPEL.DurTimerMsg(UI_TIMER.ability_name);

    if "ltr" == SETTINGS.timers_alignment then
        GRP_POSITIONS = UI.GRP_POSITIONS.LTR;
        UI_TIMER.GRP:MoveTo(UI.GRP_POSITIONS.RTL[1], 0); -- start opposite to slide in
    else
        GRP_POSITIONS = UI.GRP_POSITIONS.RTL;
        UI_TIMER.GRP:MoveTo(UI.GRP_POSITIONS.LTR[1], 0); -- start opposite to slide in
    end

    UI_TIMER.GRP:MoveTo(GRP_POSITIONS[UI_TIMER.id], 0.1); -- slide in

    -- Font
    UI_TIMER.TIMER:SetFont(font);
    UI_TIMER.TIMER_OUTLINE_1:SetFont(font);
    UI_TIMER.TIMER_OUTLINE_2:SetFont(font);
    UI_TIMER.TIMER_OUTLINE_3:SetFont(font);
    UI_TIMER.TIMER_OUTLINE_4:SetFont(font);

    -- Font color
    UI_TIMER.TIMER:SetTextColor("#"..SETTINGS.FONT.COLOR.text_timer);
    UI_TIMER.TIMER_OUTLINE_1:SetTextColor("#"..SETTINGS.FONT.COLOR.text_timer_outline);
    UI_TIMER.TIMER_OUTLINE_2:SetTextColor("#"..SETTINGS.FONT.COLOR.text_timer_outline);
    UI_TIMER.TIMER_OUTLINE_3:SetTextColor("#"..SETTINGS.FONT.COLOR.text_timer_outline);
    UI_TIMER.TIMER_OUTLINE_4:SetTextColor("#"..SETTINGS.FONT.COLOR.text_timer_outline);

    if "Activate: Rocket Wings" == UI_TIMER.ability_name then
        UI_TIMER.GRP:GetChild("rocketeers_wings"):ParamTo("alpha", 1, 0);
    else
        UI_TIMER.ICON:SetIcon(UI_TIMER.icon_id);
    end

    -- start timer
    UI_TIMER.TIMER:StartTimer(UI_TIMER.duration, true);
    UI_TIMER.TIMER_OUTLINE_1:StartTimer(UI_TIMER.duration, true);
    UI_TIMER.TIMER_OUTLINE_2:StartTimer(UI_TIMER.duration, true);
    UI_TIMER.TIMER_OUTLINE_3:StartTimer(UI_TIMER.duration, true);
    UI_TIMER.TIMER_OUTLINE_4:StartTimer(UI_TIMER.duration, true);

    -- UI_TIMER.TIMER:ParamTo("alpha", 1, 0.1);
    -- UI_TIMER.TIMER_OUTLINE_1:ParamTo("alpha", 1, 0.1);
    -- UI_TIMER.TIMER_OUTLINE_2:ParamTo("alpha", 1, 0.1);
    -- UI_TIMER.TIMER_OUTLINE_3:ParamTo("alpha", 1, 0.1);
    -- UI_TIMER.TIMER_OUTLINE_4:ParamTo("alpha", 1, 0.1);

    UI_TIMER.UPDATE_TIMER:Bind(
        function()
            RUMPEL.UpdateTimerBind(UI_TIMER, GRP_POSITIONS);
        end
    );
    UI_TIMER.UPDATE_TIMER:Schedule(tonumber(UI_TIMER.duration));
end

function RUMPEL.UpdateTimerBind(UI_TIMER, GRP_POSITIONS)
    Component.RemoveWidget(UI_TIMER.BP);

    local active_timers = UI.active_timers;
    local id            = UI_TIMER.id + 1;

    UI.TIMERS[UI_TIMER.id] = nil;
    UI.active_timers       = UI.active_timers - 1;

    while id <= active_timers do
        local new_id = id - 1;

        UI.TIMERS[id].id = new_id;
        UI.TIMERS[id].GRP:MoveTo(GRP_POSITIONS[new_id], 0.1);

        UI.TIMERS[new_id] = UI.TIMERS[id];
        UI.TIMERS[id]     = nil;

        -- RUMPEL.ConsoleLog(UI.TIMERS[new_id]);
        -- RUMPEL.ConsoleLog(UI.TIMERS[id]);

        id = id + 1;
    end

    if 0 > UI.active_timers then
        UI.active_timers = 0;
    end

    RUMPEL.ConsoleLog("RUMPEL.UpdateTimerBind()::UI.active_timers: "..tostring(UI.active_timers));
end

function RUMPEL.RemoveTimers()
    local id            = 1;
    local active_timers = UI.active_timers;

    while id <= active_timers do
        Component.RemoveWidget(UI.TIMERS[id].BP);

        UI.TIMERS[id].UPDATE_TIMER:Release();

        UI.active_timers = UI.active_timers - 1;
        id               = id + 1;
    end

    -- should be always 0 ... but meh
    if 0 > UI.active_timers then
        UI.active_timers = 0;
    end

    RUMPEL.ConsoleLog("RUMPEL.RemoveTimers()::UI.active_timers: "..tostring(UI.active_timers));
end

function RUMPEL.GetAbilityDuration(ability_name)
    local PLAYER_ALL_STATS = Player.GetAllStats();

    for i,_ in pairs(PLAYER_ALL_STATS.item_attributes) do
        local MATCH = {
            {string.find(PLAYER_ALL_STATS.item_attributes[i].designer_name, "^(.*) Ability Duration")},
            {string.find(PLAYER_ALL_STATS.item_attributes[i].designer_name, "^(.*) Buff Duration")},
            {string.find(PLAYER_ALL_STATS.item_attributes[i].designer_name, "^(.*) Duration")}
        };

        if ability_name == MATCH[1][3] or ability_name == MATCH[2][3] or ability_name == MATCH[3][3] then
            return tonumber(PLAYER_ALL_STATS.item_attributes[i].current_value);
        end
    end
end

function RUMPEL.TestTimers()
    RUMPEL.CreateUiTimer(202130, 25, "Heavy Armor", 3782);
    RUMPEL.CreateUiTimer(222527, 15, "Thunderdome", 1726);
    RUMPEL.CreateUiTimer(492574, 20, "Adrenaline Rush", 15206);
    RUMPEL.CreateUiTimer(202115, 30, "Teleport Beacon", 12305);
end

function RUMPEL.ConsoleLog(message)
    if true == SETTINGS.debug then
        message = "[DEBUG] "..tostring(message);

        log(message);

        RUMPEL.SystemMsg(message);
    end
end

function RUMPEL.SystemMsg(message)
    Component.GenerateEvent("MY_SYSTEM_MESSAGE", {text = "[ADT] "..tostring(message)});
end

function RUMPEL.DurTimerMsg(ability_name)
    if true == SETTINGS.system_message then
        RUMPEL.SystemMsg("Starting duration timer for '"..(ABILITY_ALIAS[ability_name] or ability_name).."'.");
    end
end
