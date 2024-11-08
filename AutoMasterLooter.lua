-- Create the frame and register the LOOT_OPENED event
AutoMasterLooter = CreateFrame("Frame", "AutoMasterLooter", UIParent)
AutoMasterLooter:RegisterEvent("LOOT_OPENED")
AutoMasterLooter:SetScript("OnEvent", function() AutoMasterLootEvent() end)

-- Tables for soulbound and non-soulbound items

LootedItemsTable = {}
--LootedItemsTable["Ancient Qiraji Artifact"] = "example of an item you may wanna loot"
--LootedItemsTable["Qiraji Lord's Insignia"] = "remove the comment from these lines to make AML loot them"

ExcludedItemsTable = {}
--ExcludedItemsTable["Dripping Spider Mandible"] = "ugly vendor trash that we all hate"
--ExcludedItemsTable["Runecloth"] = "remove the comment from these lines to make AML ignore them"
ExcludedItemsTable["Bracers of Might"] = "t1" -- delete these lines if you want to Masterloot t1 BoEs to yourself
ExcludedItemsTable["Belt of Might"] = "t1"
ExcludedItemsTable["Vambraces of Prophecy"] = "t1"
ExcludedItemsTable["Girdle of Prophecy"] = "t1"
ExcludedItemsTable["Nightslayer Belt"] = "t1"
ExcludedItemsTable["Nightslayer Bracelets"] = "t1"
ExcludedItemsTable["Arcanist Belt"] = "t1"
ExcludedItemsTable["Arcanist Bindings"] = "t1"
ExcludedItemsTable["Cenarion Bracers"] = "t1"
ExcludedItemsTable["Cenarion Belt"] = "t1"
ExcludedItemsTable["Earthfury Belt"] = "t1"
ExcludedItemsTable["Earthfury Bracers"] = "t1"
ExcludedItemsTable["Felheart Belt"] = "t1"
ExcludedItemsTable["Felheart Bracers"] = "t1"
ExcludedItemsTable["Giantstalker's Belt"] = "t1"
ExcludedItemsTable["Giantstalker's Bracers"] = "t1"
ExcludedItemsTable["Lawbringer Bracers"] = "t1"
ExcludedItemsTable["Lawbringer Belt"] = "t1"

-- Variables to control the auto master looter state
local AutoMasterLooter = 0
local TemporarilyDisabled = false

-- Function to check if an item is soulbound
function LootSlotIsSoulbound(arg)
    AMLTooltip:ClearLines()
    AMLTooltip:SetLootItem(arg)
    local tooltipScan = getglobal("AMLTooltipTextLeft2")
    if tooltipScan then
        local BindingStatus = tooltipScan:GetText()
        if BindingStatus == "Binds when picked up" then
            return true
        end
    end
    return nil
end

-- Function to determine the looting action
local function ShouldAutolootItem(lootedindex)
    lootIcon, lootName, lootQuantity, rarity = GetLootSlotInfo(lootedindex)
    
    if LootedItemsTable[lootName] then
        return 1 -- loot item
    end
    
    if LootSlotIsSoulbound(lootedindex) then
        return 2 -- leave on corpse & announce
    end
    
    if ExcludedItemsTable[lootName] then
        return 3 -- leave on corpse, no announce
    end
    return 1
end

-- Function to toggle the auto master looter
local function AutoMasterLooterSwitch(cmd)
    if AutoMasterLooter == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("AutoMasterLooter |cffFF0000ON")
        AutoMasterLooter = 1
    else
        DEFAULT_CHAT_FRAME:AddMessage("AutoMasterLooter |cffFF0000OFF")
        AutoMasterLooter = 0
    end
end

-- Slash commands to control the auto master looter
SLASH_AUTOMASTERLOOTER1 = '/automasterlooter'
SLASH_AUTOMASTERLOOTER2 = '/automl'
SLASH_AUTOMASTERLOOTER3 = '/automasterloot'
SlashCmdList.AUTOMASTERLOOTER = AutoMasterLooterSwitch

-- Function to handle the LOOT_OPENED event
local dummy = 0;
function AutoMasterLootEvent()
    if dummy == 1 then
        dummy = 0; return;
    elseif dummy == 0 then
        dummy = 1
    end

    local targetClassification = UnitClassification("target")
    
    -- Check if the target is a worldboss, boss, or elite and temporarily disable auto looter if so
    if targetClassification == "worldboss" or targetClassification == "boss" then
        if AutoMasterLooter == 1 then
            TemporarilyDisabled = true
            AutoMasterLooter = 0
            DEFAULT_CHAT_FRAME:AddMessage("AutoMasterLooter temporarily disabled for elite or boss.")
        end
        return
    end
    
    lootmethod, masterlooterID = GetLootMethod()
    if masterlooterID == 0 and AutoMasterLooter == 1 then -- Only run if the player is the master looter.
        local announcestring = "Items inside:" -- Generate announce message
        for looterindex = 1, 40 do
            if (GetMasterLootCandidate(looterindex) == UnitName("player")) then
                for lootedindex = 1, GetNumLootItems() do
                    if ShouldAutolootItem(lootedindex) == 1 then
                        GiveMasterLoot(lootedindex, looterindex)
                    elseif ShouldAutolootItem(lootedindex) == 2 then
                        announcestring = announcestring.." "..GetLootSlotLink(lootedindex)
                    end
                end
            end
        end
        if announcestring ~= "Items inside:" then
            DEFAULT_CHAT_FRAME:AddMessage(announcestring) -- Announce the message if any epics were added into it.
            --PlaySound("AuctionWindowClose") -- Play a warning sound. I chose auction house close, you can choose any sound you want from https://wowwiki-archive.fandom.com/wiki/API_PlaySound?oldid=313344 
        end
    end
    
    -- Re-enable auto-looter if it was temporarily disabled
    if TemporarilyDisabled then
        AutoMasterLooter = 1
        TemporarilyDisabled = false
        DEFAULT_CHAT_FRAME:AddMessage("AutoMasterLooter re-enabled.")
    end
end
