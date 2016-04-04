-- ===============================
-- Ability Duration Timer
-- by: Rumpel, Vollmond
-- ===============================
-- 
-- ===============================

require "string";
require "lib/lib_Callback2";
require "lib/lib_InterfaceOptions";

-- ===============================
--  Variables
-- ===============================

local DEV_MODE         = false;
local UI               = {};
local RUMPEL           = {};
local SETTINGS         = {};
local ABILITY_INFOS    = {};
local SHOW_TIMERS      = {};
local ON_ABILITY_STATE = {};

UI.ui_timers_count = 1;
UI.UI_TIMERS       = {};
UI.POSITIONS       = {};
UI.FRAME           = Component.GetFrame("adt_frame");

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

UI.POSITIONS[1] = false;
UI.POSITIONS[2] = false;
UI.POSITIONS[3] = false;
UI.POSITIONS[4] = false;

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
SETTINGS.TIMERS["Overcharge"] = true;

-- Engineer
SETTINGS.TIMERS["Overclock"] = true;
SETTINGS.TIMERS["Bulwark"]   = true;
SETTINGS.TIMERS["Fortify"]   = true;

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
    InterfaceOptions.StopGroup();

    -- Engineer
    InterfaceOptions.StartGroup({label="Engineer"});
        InterfaceOptions.AddCheckBox({id="BULWARK_ENABLED", label="Bulwark enabled", default=(Component.GetSetting("BULWARK_ENABLED") or SETTINGS.TIMERS["Bulwark"])});
        InterfaceOptions.AddCheckBox({id="OVERCLOCK_ENABLED", label="Overclock enabled", default=(Component.GetSetting("OVERCLOCK_ENABLED") or SETTINGS.TIMERS["Overclock"])});
        InterfaceOptions.AddCheckBox({id="FORTIFY_ENABLED", label="Fortify enabled", default=(Component.GetSetting("FORTIFY_ENABLED") or SETTINGS.TIMERS["Fortify"])});
    InterfaceOptions.StopGroup();
end

-- ===============================
--  Events
-- ===============================

function OnComponentLoad()
    BuildOptions();

    InterfaceOptions.SetCallbackFunc(OnOptionChanged, "Ability Duration Timer");
end

function OnPlayerReady()
    if true == DEV_MODE then
        local PLAYER_ALL_STATS = Player.GetAllStats();

        log(tostring(PLAYER_ALL_STATS));
    end
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
        Component.SaveSetting("TIMER_COLOR", value);
    elseif "TIMER_COLOR_OUTLINE" == id then
        SETTINGS.FONT.COLOR.text_timer_outline = value.tint;
        Component.SaveSetting("TIMER_COLOR_OUTLINE", value);
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
    elseif "BULWARK_ENABLED" == id then
        SETTINGS.TIMERS["Bulwark"] = value;
        Component.SaveSetting("BULWARK_ENABLED", value);
    elseif "OVERCLOCK_ENABLED" == id then
        SETTINGS.TIMERS["Overclock"] = value;
        Component.SaveSetting("OVERCLOCK_ENABLED", value);
    elseif "FORTIFY_ENABLED" == id then
        SETTINGS.TIMERS["Fortify"] = value;
        Component.SaveSetting("FORTIFY_ENABLED", value);
    end
end

function OnAbilityUsed(args)
    if -1 ~= args.index then
        local ABILITY_INFO = Player.GetAbilityInfo(args.id);

        RUMPEL.ConsoleLog("Ability '"..ABILITY_INFO.name.."' fired Event 'ON_ABILITY_USED'!");
        RUMPEL.ConsoleLog("ID: "..tostring(args.id));
        RUMPEL.ConsoleLog("NAME: "..ABILITY_INFO.name);
        RUMPEL.ConsoleLog("ICON ID: "..tostring(ABILITY_INFO.iconId));

        local ability_duration = RUMPEL.GetAbilityDuration(ABILITY_INFO.name);

        RUMPEL.ConsoleLog("DURATION: "..tostring(ability_duration));

        if nil ~= ability_duration and true ~= ON_ABILITY_STATE[ABILITY_INFO.name] and true == SETTINGS.TIMERS[ABILITY_INFO.name] then
            RUMPEL.ConsoleLog("OnAbilityUsed:CreateIcon");
            RUMPEL.CreateIcon(ABILITY_INFO.iconId, ability_duration, ABILITY_INFO.name);
        end
    end
end

function OnAbilityState(args)
    if -1 ~= args.index then
        -- local ability_id    = tonumber(args.id);
        -- local ability_state = Player.GetAbilityState(ability_id);
        -- local ability_info  = Player.GetAbilityInfo(ability_id);

        -- RUMPEL.ConsoleLog("Ability ID: "..tostring(ability_id));
        -- RUMPEL.ConsoleLog("Player.GetAbilityState()");
        -- RUMPEL.ConsoleLog(ability_state);
        -- RUMPEL.ConsoleLog("Player.GetAbilityInfo()");
        -- RUMPEL.ConsoleLog(ability_info);

        local ability_name = args.state;
        local ability_id   = tonumber(args.id);

        RUMPEL.ConsoleLog("Ability '"..ability_name.."' fired Event 'ON_ABILITY_STATE'!");
        RUMPEL.ConsoleLog("ID: "..tostring(ability_id));
        RUMPEL.ConsoleLog("NAME: "..ability_name);
        RUMPEL.ConsoleLog("ICON ID: "..tostring(ABILITY_INFOS[tonumber(ability_id)].icon_id));
        RUMPEL.ConsoleLog("DURATION: "..tostring(args.state_dur_total));
        RUMPEL.ConsoleLog("ON_ABILITY_STATE[ability_id]: "..tostring(ON_ABILITY_STATE[ability_id]));

        if true == SETTINGS.TIMERS[ability_name] and false ~= ON_ABILITY_STATE[ability_name] and false ~= ON_ABILITY_STATE[ability_id] then
            RUMPEL.ConsoleLog("OnAbilityState:CreateIcon");
            RUMPEL.CreateIcon(ABILITY_INFOS[ability_id].icon_id, args.state_dur_total, ability_name);
        end
    end
end

-- ===============================
--  Functions
-- ===============================

function RUMPEL.CreateIcon(icon_id, duration, ability_name)
    local ALIGNMENT = {};
    local position  = nil;

    if "ltr" == SETTINGS.timers_alignment then
        ALIGNMENT[1] = 1;
        ALIGNMENT[2] = 2;
        ALIGNMENT[3] = 3;
        ALIGNMENT[4] = 4;
    else
        ALIGNMENT[1] = 4;
        ALIGNMENT[2] = 3;
        ALIGNMENT[3] = 2;
        ALIGNMENT[4] = 1;
    end

    if false == UI.POSITIONS[ALIGNMENT[1]] then
        UI.POSITIONS[ALIGNMENT[1]] = true;
        position                   = ALIGNMENT[1];
    elseif false == UI.POSITIONS[ALIGNMENT[2]] then
        UI.POSITIONS[ALIGNMENT[2]] = true;
        position                   = ALIGNMENT[2];
    elseif false == UI.POSITIONS[ALIGNMENT[3]] then
        UI.POSITIONS[ALIGNMENT[3]] = true;
        position                   = ALIGNMENT[3];
    elseif false == UI.POSITIONS[ALIGNMENT[4]] then
        UI.POSITIONS[ALIGNMENT[4]] = true;
        position                   = ALIGNMENT[4];
    end

    -- widgets from blueprint in xml
    local GRP     = Component.CreateWidget("BP_IconTimer_"..position, UI.FRAME);
    local CONTENT = Component.CreateWidget("BP_IconTimer_Content_"..position, GRP);

    UI.UI_TIMERS[UI.ui_timers_count] = {
        id       = UI.ui_timers_count,
        position = position,
        GRP      = GRP,
        CONTENT  = CONTENT
    };

    RUMPEL.DurTimerMsg(ability_name);
    RUMPEL.SetTimer(UI.UI_TIMERS[UI.ui_timers_count], icon_id, duration, position);

    if 100 <= UI.ui_timers_count then
        UI.ui_timers_count = 1;
    else
        UI.ui_timers_count = UI.ui_timers_count + 1;
    end
end

function RUMPEL.SetTimer(UI_TIMER, icon_id, duration, position)
    local UPDATE_TIMER    = Callback2.Create();
    local TIMER           = UI_TIMER.CONTENT:GetChild("text_timer");
    local TIMER_OUTLINE_1 = UI_TIMER.CONTENT:GetChild("text_timer_outline_1");
    local TIMER_OUTLINE_2 = UI_TIMER.CONTENT:GetChild("text_timer_outline_2");
    local TIMER_OUTLINE_3 = UI_TIMER.CONTENT:GetChild("text_timer_outline_3");
    local TIMER_OUTLINE_4 = UI_TIMER.CONTENT:GetChild("text_timer_outline_4");
    local ICON            = UI_TIMER.CONTENT:GetChild("icon");
    local font            = SETTINGS.FONT.name.."_"..tostring(SETTINGS.FONT.size);

    -- Font
    TIMER:SetFont(font);
    TIMER_OUTLINE_1:SetFont(font);
    TIMER_OUTLINE_2:SetFont(font);
    TIMER_OUTLINE_3:SetFont(font);
    TIMER_OUTLINE_4:SetFont(font);

    -- Font color
    TIMER:SetTextColor("#"..SETTINGS.FONT.COLOR.text_timer);
    TIMER_OUTLINE_1:SetTextColor("#"..SETTINGS.FONT.COLOR.text_timer_outline);
    TIMER_OUTLINE_2:SetTextColor("#"..SETTINGS.FONT.COLOR.text_timer_outline);
    TIMER_OUTLINE_3:SetTextColor("#"..SETTINGS.FONT.COLOR.text_timer_outline);
    TIMER_OUTLINE_4:SetTextColor("#"..SETTINGS.FONT.COLOR.text_timer_outline);

    ICON:SetIcon(icon_id);

    TIMER:StartTimer(duration, true);
    TIMER_OUTLINE_1:StartTimer(duration, true);
    TIMER_OUTLINE_2:StartTimer(duration, true);
    TIMER_OUTLINE_3:StartTimer(duration, true);
    TIMER_OUTLINE_4:StartTimer(duration, true);
    TIMER:ParamTo("alpha", 1, 0.1);
    TIMER_OUTLINE_1:ParamTo("alpha", 1, 0.1);
    TIMER_OUTLINE_2:ParamTo("alpha", 1, 0.1);
    TIMER_OUTLINE_3:ParamTo("alpha", 1, 0.1);
    TIMER_OUTLINE_4:ParamTo("alpha", 1, 0.1);

    -- RUMPEL.ConsoleLog(UI_TIMER.GRP:GetBounds());

    UPDATE_TIMER:Bind(
        function()
            TIMER:ParamTo("alpha", 0, 0.1);
            TIMER_OUTLINE_1:ParamTo("alpha", 0, 0.1);
            TIMER_OUTLINE_2:ParamTo("alpha", 0, 0.1);
            TIMER_OUTLINE_3:ParamTo("alpha", 0, 0.1);
            TIMER_OUTLINE_4:ParamTo("alpha", 0, 0.1);
            Component.RemoveWidget(UI_TIMER.GRP);
            UI_TIMER = nil;
            UI.POSITIONS[position] = false;
        end
    );
    UPDATE_TIMER:Schedule(tonumber(duration));
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
        RUMPEL.SystemMsg("Starting duration timer for '"..ability_name.."'.");
    end
end
