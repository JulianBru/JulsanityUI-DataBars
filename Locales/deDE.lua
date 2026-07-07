--------------------------------------------------------------------------------
--  Locales/deDE.lua  -  German translations
--------------------------------------------------------------------------------
local _, ns = ...
if GetLocale() ~= "deDE" then return end

local L = ns.L

-- Sections
L["Layout"]            = "Layout"
L["Appearance"]        = "Aussehen"
L["Behavior"]          = "Verhalten"
L["Advanced"]          = "Erweitert"

-- Layout
L["Width"]             = "Breite"
L["Width Offset"]      = "Breiten-Offset"
L["Height"]            = "Hoehe"
L["Padding"]           = "Innenabstand"
L["Margin"]            = "Aussenabstand"
L["Spacing"]           = "Abstand"
L["Orientation"]       = "Ausrichtung"
L["Growth Direction"]  = "Wachstumsrichtung"
L["Auto Size"]         = "Automatische Groesse"
L["Horizontal"]        = "Horizontal"
L["Vertical"]          = "Vertikal"
L["Left"]              = "Links"
L["Right"]             = "Rechts"
L["Up"]                = "Oben"
L["Down"]              = "Unten"

-- Appearance
L["Font"]              = "Schriftart"
L["Font Size"]         = "Schriftgroesse"
L["Font Outline"]      = "Schriftkontur"
L["Text Color"]        = "Textfarbe"
L["Background Color"]  = "Hintergrundfarbe"
L["Background Texture"] = "Hintergrundtextur"
L["Solid Color"]       = "Einfarbig"
L["Border"]            = "Rahmen"
L["Border Size"]       = "Rahmenstaerke"
L["Border Color"]      = "Rahmenfarbe"
L["Shadow"]            = "Schatten"
L["Transparency"]      = "Transparenz"
L["Mouseover Fade"]    = "Einblenden bei Mouseover"
L["Faded Alpha"]       = "Transparenz (ausgeblendet)"
L["Auto Hide"]         = "Automatisch ausblenden"
L["None"]              = "Keine"
L["Outline"]           = "Kontur"
L["Thick Outline"]     = "Dicke Kontur"

-- Behavior
L["Number of DataTexts"] = "Anzahl der DataTexts"
L["DataText"]          = "DataText"
L["Lock Position"]     = "Position sperren"
L["Snap"]              = "Einrasten"

-- Advanced
L["Debug Mode"]        = "Debug-Modus"
L["Reload UI"]         = "UI neu laden"
L["Reset Position"]    = "Position zuruecksetzen"
L["Reset Profile"]     = "Profil zuruecksetzen"
L["Export Profile"]    = "Profil exportieren"
L["Import Profile"]    = "Profil importieren"
L["Profiles"]          = "Profile"
L["New Profile"]       = "Neues Profil"
L["Copy Profile"]      = "Profil kopieren"
L["Delete Profile"]    = "Profil loeschen"

-- Difficulty datatext
L["Difficulty"]               = "Schwierigkeit"
L["Dungeon"]                  = "Dungeon"
L["Raid"]                     = "Schlachtzug"
L["Dungeon Difficulty"]       = "Dungeon-Schwierigkeit"
L["Raid Difficulty"]          = "Schlachtzug-Schwierigkeit"
L["Click to change difficulty."] = "Klicken zum Aendern der Schwierigkeit."
L["Active Profile"]    = "Aktives Profil"

-- Specialization datatext (loot spec)
L["Loot Specialization"]            = "Beutespezialisierung"
L["Current Specialization"]         = "Aktuelle Spezialisierung"
L["Left-click: open specialization"] = "Linksklick: Spezialisierung oeffnen"
L["Right-click: set loot spec"]     = "Rechtsklick: Beutespez. waehlen"

-- Gold datatext (Syndicator cross-character)
L["Silver"]            = "Silber"
L["Copper"]            = "Kupfer"
L["Alliance"]          = "Allianz"
L["Horde"]             = "Horde"
L["Neutral"]           = "Neutral"
L["Warband Bank"]      = "Kriegsmeute-Bank"
L["Total"]             = "Gesamt"
L["Characters"]        = "Charaktere"

-- Multi-bar controls
L["Bar"]               = "Leiste"
L["Enabled"]           = "Aktiviert"
L["Main Bar"]          = "Hauptleiste"
L["Minimap Bar"]       = "Minimap-Leiste"

-- Loot Spec datatext
L["Loot Spec"]                        = "Beutespez."
L["Left-click: set loot spec"]        = "Linksklick: Beutespez. waehlen"
L["Right-click: open specialization"] = "Rechtsklick: Spezialisierung oeffnen"

-- Blizzard AddOns options panel
L["Open Configuration"] = "Konfiguration oeffnen"
L["ElvUI-style configurable data texts, native to EllesmereUI."] = "Konfigurierbare DataTexts im ElvUI-Stil, nativ fuer EllesmereUI."

-- Config window header
L["Unlock Mode"]       = "Entsperrmodus"

-- About page
L["About"]             = "Info"
L["Copy Support Link"] = "Support-Link kopieren"
L["JulsanityUI DataBars is an independent, third-party plugin for EllesmereUI."] = "JulsanityUI DataBars ist ein unabhaengiges Drittanbieter-Plugin fuer EllesmereUI."
L["It is not part of EllesmereUI and is not created, maintained, or endorsed by the EllesmereUI team."] = "Es ist nicht Teil von EllesmereUI und wird nicht vom EllesmereUI-Team erstellt, gepflegt oder unterstuetzt."
L["Please do not request support for this addon in the EllesmereUI Discord."] = "Bitte fordere fuer dieses Addon keinen Support im EllesmereUI-Discord an."
L["For bugs or feature requests, use this addon's own GitHub or CurseForge page."] = "Nutze fuer Fehler oder Wuensche die eigene GitHub- oder CurseForge-Seite dieses Addons."
L["Copy the link (Ctrl+C), then close."] = "Link kopieren (Strg+C), dann schliessen."
L["Section Separators"] = "Abschnittstrenner"
L["Separator Uses Accent"] = "Trennlinie nutzt Akzentfarbe"
L["Separator Color"]   = "Trennlinienfarbe"
L["Hide Prefixes"]     = "Prefixe ausblenden"
L["Separators"]        = "Trennlinien"
L["Changelog"]         = "Changelog"
L["Use Custom Text Color"] = "Eigene Textfarbe nutzen"
L["Legacy Raid Difficulty"] = "Legacy-Schlachtzug"

-- Per-slot datatext options
L["Local Time"]        = "Lokalzeit"
L["24-Hour Format"]    = "24-Stunden-Format"

-- Batch 1 datatext options
L["Show Zone"]         = "Zone anzeigen"
L["Decimals"]          = "Nachkommastellen"
L["Display"]           = "Anzeige"
L["Latency"]           = "Latenz"
L["Value"]             = "Wert"
L["Short Numbers"]     = "Kurze Zahlen"
L["Session Gold"]      = "Gold seit Login"
L["Count Reagent Bag"] = "Reagenzientasche zaehlen"
L["World"]             = "Welt"
L["Home"]              = "Heim"
L["Lowest"]            = "Niedrigster"
L["Average"]           = "Durchschnitt"
L["Free"]              = "Frei"
L["Used"]              = "Belegt"
L["Gold Only"]        = "Nur Gold"

-- Datatext options (batch 2)
L["Source"] = "Quelle"
L["Equipped"] = "Angelegt"
L["Overall"] = "Gesamt"
L["Format"] = "Format"
L["Show Rested"] = "Erholung anzeigen"
L["Percent"] = "Prozent"
L["Current"] = "Aktuell"
L["Remaining"] = "Verbleibend"
L["Standing"] = "Ansehen"
L["Both"] = "Beide"
L["WoW"] = "WoW"
L["Battle.net"] = "Battle.net"
L["Online"] = "Online"
L["Online / Total"] = "Online / Gesamt"
L["Show"] = "Anzeigen"
L["Names"] = "Namen"
L["Abbreviated"] = "Abgekürzt"
L["Full"] = "Vollständig"
L["Auto"] = "Auto"
L["Count"] = "Anzahl"
L["Abbreviate Dungeon"] = "Dungeon abkürzen"
L["Addon Memory"]      = "Addon-Speicher"
L["All"]               = "Alle"
