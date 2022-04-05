Scriptname EFS2BodyHair extends EFSzModule  

; Constants
string growthPresetsFolder = "growth_presets/"
string trimmingsFolder = "trimmings/"
string areaConfigFileName = "config"

string sLastUpdateDayKeyPrefix = "EFS_BH_LastUpdateDay_"
string sCurrentAreaStageKeyPrefix = "EFS_BH_CurrentAreaStage_"
string sOverlayNodeStorageKeyPrefix = "EFS_BH_OverlayNode_"
string sCurrentTrimmingPrefix = "EFS_BH_CurrentTrimming_"

string jStagesKey = "stages"

string creamKeywordPrefix = "EFS_ShavingCream"

; Shaving menu
string chooseTrimmingMsg = "[Choose a trimming]"
string lastTrimmingButtonPre = "[Last: "
string lastTrimmingButtonSu = "]"
string cleanlyShavedButton = "Cleanly Shaven"
string cancelBtn = "[Cancel]"

; Properties
String[] Property BodyHairAreas  Auto  
String[] Property BodyHairAreasPresets  Auto  
Int[] Property DaysForGrowth  Auto  

Bool Property UndergarmentsIntegration  Auto  
Bool Property OutfitRestrictAccess  Auto  
Bool Property ProgressiveGrowth  Auto  

Sound Property EFSShaving Auto

; Fields
string[] AreasLastTrimmings

Event OnInit()
    ModuleName = "Body Hair"
EndEvent

Function LoadModule(int loadedVersion)
    if (loadedVersion < EFSzUtil.Get02AlphaVersion() && !IsModuleStarted())
        Log("First loading")
        BodyHairAreas = new string[2]
        BodyHairAreas[0] = "Armpits"
        BodyHairAreas[1] = "Pubes"

        BodyHairAreasPresets = new string[2]
        BodyHairAreasPresets[0] = GetPresetsNames(true, BodyHairAreas[0])[0]
        BodyHairAreasPresets[1] = GetPresetsNames(true, BodyHairAreas[1])[0]

        DaysForGrowth = new Int[2]
        DaysForGrowth[0] = 2
        DaysForGrowth[1] = 2

        AreasLastTrimmings = new String[2]

        UndergarmentsIntegration = true
        OutfitRestrictAccess = true

        FlaggedForRefresh = false

        Toggle()
    endif

    RegisterForSleep()
EndFunction

State Started

    Function Toggle()
        GoToState("Stopping")
    EndFunction

    Function DoRefresh()
        EFSzUtil.log("Refreshing body hair")

        int i = 0
        while (i < Main.GetManagedActors().Length)
            Refresh(Main.GetManagedActors()[i])
            i += 1
        EndWhile
    EndFunction

    Event OnSleepStop(bool abInterrupted)
        if (Main.OnSleepTrigger)
            UpdateGrowthAll()
        endif
    EndEvent    

    Function ObjectUnequipped(Actor target, Form akBaseObject, ObjectReference akReference)
        if (Main.OnEquipmentChangeTrigger)
            Armor arm = akBaseObject as Armor
            if (arm && EFSzUtil.HasSlot(arm, 32))
                UpdateGrowth(target)
            endif
        endif
    EndFunction

    Function UpdateGrowthAll()
        int i = 0

        while (i < Main.GetManagedActors().Length)
            UpdateGrowth(Main.GetManagedActors()[i])

            i += 1
        EndWhile
    EndFunction

    Function Refresh(Actor target)
        int i = 0
        while i < BodyHairAreas.Length
            RefreshZoneOverlay(target, BodyHairAreas[i])
            i += 1
        endWhile
    EndFunction

    Function UpdateGrowth(Actor target)
        int gameDaysPassedValue = Main.GameDaysPassed.GetValueInt()

        int i = 0
        while (i < BodyHairAreas.Length)
            UpdateAreaHair(target, i, gameDaysPassedValue)    

            i += 1
        endWhile
    EndFunction

    Function UpdateAreaHair(Actor target, int areaIndex, int gameDaysPassedValue)
        string areaName = BodyHairAreas[areaIndex]
        if (BodyHairAreasPresets[areaIndex] == "")
            EFSzUtil.log("No active preset for area " + areaName + ", aborting growth update.")
            return
        endIf
    
        int zoneStage = GetAreaStage(target, areaName)
        int daysPassed = GetDaysPassedArea(target, areaName, gameDaysPassedValue)
        int daysForGrowthArea = GetDaysForGrowth(target, areaIndex, zoneStage)

        if (daysPassed >= daysForGrowthArea)
            StorageUtil.SetIntValue(target, sLastUpdateDayKeyPrefix + areaName, gameDaysPassedValue)
            ; Update stage
            EFSzUtil.log(daysPassed + " days passed, it is greater than or equal to " + daysForGrowthArea + ", " + areaName + " hair has grown")
            int maxStage = GetMaxAreaStage(target, areaName)
            EFSzUtil.log("Current: " + zoneStage + " Max: " + maxStage)
            if(zoneStage < maxStage)
                zoneStage += 1

                ApplyZoneStage(target, areaName, zoneStage, maxStage)

                StorageUtil.UnsetStringValue(target, sCurrentTrimmingPrefix + areaName)
                Debug.Notification("You notice your " + areaName + " hair has grown")
            endIf
        else
            EFSzUtil.log(daysPassed + " days passed, it is lesser than " + daysForGrowthArea + ", no " + areaName + " hair growth")
        endIf
    EndFunction

    Function ApplyZoneStage(Actor target, String areaName, int desiredStage, int maxStage = -1, string pattern = "")
        if (maxStage < 0)
            maxStage = GetMaxAreaStage(target, areaName)
        endif

        if (desiredStage > maxStage)
            desiredStage = maxStage
        endIf

        if pattern == ""
            pattern = JsonUtil.StringListGet(GetActivePresetFile(target, areaName), jStagesKey, desiredStage)
        endIf

        EFSzUtil.log("Current: " + desiredStage + " Max: " + maxStage)
        StorageUtil.SetIntValue(target, sCurrentAreaStageKeyPrefix + areaName, desiredStage)
    
        RefreshZoneOverlay(target, areaName, desiredStage, pattern)
    EndFunction

    Function RefreshZoneOverlay(Actor target, string areaName, int desiredStage = -1, string texture = "")
        if (desiredStage < 0)
            desiredStage = GetAreaStage(target, areaName)
        endIf
    
        ; Update overlay
        if texture == ""
            if (StorageUtil.HasStringValue(target, sCurrentTrimmingPrefix + areaName))
                texture = JsonUtil.GetStringValue(GetTrimmingFile(target, areaName, StorageUtil.GetStringValue(target, sCurrentTrimmingPrefix + areaName)), "texture")
            endif
            if texture == ""
                texture = JsonUtil.StringListGet(GetActivePresetFile(target, areaName), jStagesKey, desiredStage)
            endif
        endIf

        EFSzUtil.ApplyTexture(target, "EFS_Node_BodyHair_" + areaName, texture, target.GetActorBase().GetHairColor().GetColor())
    EndFunction

    bool Function IsAreaAccessible(Actor target, int areaIndex)
        If(Main.IsBodyConcealingWorn(target))
            EFSzUtil.log("Wearing concealing armor, area not accessible")
            return false
        endif

        string areaname = GetAreaName(areaIndex)
        String[] preventKeywordsJson = JsonUtil.StringListToArray(GetConfigFile(target, areaname), "preventaccesskeywords")
        int i = 0
        While (i < preventKeywordsJson.Length)
            Keyword k = Keyword.GetKeyWord(preventKeywordsJson[i])
            if (k && target.WornHasKeyword(k))
                EFSzUtil.log("Can't access to area.")
                return false
            endif
            i += 1
        EndWhile

        string undergarmentPreventAccessType = JsonUtil.GetStringValue(GetConfigFile(target, areaname), "preventaccessundergarment")
        if (UndergarmentsIntegration && UndergarmentsModule.IsVisibleUndergarmentWorn(target, undergarmentPreventAccessType))
            EFSzUtil.log("Undergarments prevent access to area.")
            return false
        endif
    
        return true
    EndFunction

    bool Function ApplyCream(Actor target, Spell[] creamSpells)
        if (Main.HasHandsTied(target))
            return false
        endif

        int areaIndex = EFS_SelectShavingArea.Show()
        if (areaIndex < 0 || areaIndex >= 2)
            return false
        endif

        if (!IsAreaAccessible(target, areaIndex))
            Debug.MessageBox("This area is not accessible, it must be uncovered for you to be able to apply cream.")
            return false
        endif

        Game.DisablePlayerControls(true, true, true, false, true, true, true, true)
        Game.ForceThirdPerson()

        ; Shaving
        Idle shavingIddle = JsonUtil.GetFormValue(GetConfigFile(target, GetAreaName(areaIndex)), "shavingIdle") as Idle
            
        If target.IsWeaponDrawn()
            target.SheatheWeapon()
            Utility.Wait(1.500000)
        Else
            Utility.Wait(0.200000)
        EndIf

        target.PlayIdle(shavingIddle)
        Utility.Wait(1.0)
        creamSpells[areaIndex].Cast(target, target)
        Utility.Wait(4.0)
        target.PlayIdle(Main.IdleStop)
        Utility.Wait(0.500000)

        Game.EnablePlayerControls()
    EndFunction

    bool Function Shave(Actor target)
        if (Main.HasHandsTied(target))
            return false
        endif

        int areaIndex = EFS_SelectShavingArea.Show()

        if (areaIndex > 1)
            return false
        elseif (!IsAreaAccessible(target, areaIndex))
            Debug.MessageBox("This area is not accessible, it must be uncovered for you to be able to shave.")
            return false
        endif

        string areaName = GetAreaName(areaIndex)
        if (!target.HasMagicEffectWithKeyword(Keyword.GetKeyword(creamKeywordPrefix + areaName)))
            Debug.MessageBox("You must first apply cream on an area in order to save it.")
            return false
        endif
    
        Game.DisablePlayerControls(true, true, true, false, true, true, true, true)
        Game.ForceThirdPerson()
    
        ; Pattern selection
        int newStage = 0
        int currentStage = GetAreaStage(target, areaName)
    
        String trimming = ""
        String texture = ""
        String[] trimmings = GetTrimmingsNames(target, areaName)
    
        if (trimmings.Length > 0)
            UIListMenu trimmingMenu = uiextensions.GetMenu("UIListMenu") as UIListMenu
    
            trimmingMenu.AddEntryItem(chooseTrimmingMsg)
    
            bool lastUsedFound = false
            int iTrimming = 0
            int addedTrimmings = 0
            while iTrimming < trimmings.Length
                if (JsonUtil.GetIntValue(GetTrimmingFile(target, areaName, trimmings[iTrimming]), "stage") < currentStage)
                    addedTrimmings += 1
                    EFSzUtil.log(AreasLastTrimmings[areaIndex] + ":" + trimmings[iTrimming])
                    if AreasLastTrimmings[areaIndex] == trimmings[iTrimming]
                        lastUsedFound = true
                    endIf
                else
                    trimmings[iTrimming] = ""
                endIf
                iTrimming += 1
            endWhile
    
            if (lastUsedFound)
                trimmingMenu.AddEntryItem(lastTrimmingButtonPre + AreasLastTrimmings[areaIndex] + lastTrimmingButtonSu)
            endIf
    
            if BodyHairAreasPresets[areaIndex] != ""
                trimmingMenu.AddEntryItem(cleanlyShavedButton)
            endIf
    
            if (addedTrimmings > 0)
                iTrimming = 0
                while iTrimming < trimmings.Length
                    if (trimmings[iTrimming] != "")
                        trimmingMenu.AddEntryItem(trimmings[iTrimming])
                    endIf
                    iTrimming += 1
                endWhile
            endIf
            
            EFSzUtil.log(addedTrimmings + " found for stage " + currentStage)
    
            if (addedTrimmings > 0)
                trimmingMenu.AddEntryItem(cancelBtn)
    
                trimmingMenu.OpenMenu(none)
                trimming = trimmingMenu.GetResultString()
    
                if trimming == chooseTrimmingMsg || trimming == cancelBtn
                    Game.EnablePlayerControls()
                    return false
                elseif StringUtil.Find(trimming, lastTrimmingButtonPre) > -1
                    trimming = AreasLastTrimmings[areaIndex]
                elseif trimming != cleanlyShavedButton
                    AreasLastTrimmings[areaIndex] = trimming
                endIf
                
                string trimmingFile = GetTrimmingFile(target, areaName, trimming)
                EFSzUtil.log("Chosen trimming file: " + trimmingFile)
                texture = JsonUtil.GetStringValue(trimmingFile, "texture")
                newStage = JsonUtil.GetIntValue(trimmingFile, "stage")
            endIf
        endIf

        ; Preview
        bool preview = (Main.EFS_PreviewAsk.Show() == 0)
        bool previewConfirm = false

        if (preview)
            ; TODO Acutal preview
            RefreshZoneOverlay(target, areaName, newStage, texture)

            Utility.Wait(Main.PreviewDur)
            previewConfirm = Main.EFS_PreviewConfirm.Show() == 0

            RefreshZoneOverlay(target, areaName, currentStage)
        endIf
    
        if (!preview || previewConfirm)

            ; Shaving
            Idle shavingIddle = JsonUtil.GetFormValue(GetConfigFile(target, areaName), "shavingIdle") as Idle
        
            If target.IsWeaponDrawn()
                target.SheatheWeapon()
                Utility.Wait(1.500000)
            Else
                Utility.Wait(0.200000)
            EndIf
            
            target.PlayIdle(shavingIddle)
            EFSShaving.Play(target)
            Utility.Wait(1.0)
            EFSShaving.Play(target)
            RemoveCreamSpells[areaIndex].Cast(target, target)
            ApplyZoneStage(target, areaName, newStage, GetMaxAreaStage(target, areaName), texture)
            StorageUtil.SetIntValue(target, sLastUpdateDayKeyPrefix + areaName, Main.GameDaysPassed.GetValueInt())
            Utility.Wait(1.0)
            EFSShaving.Play(target)
            Utility.Wait(4.0)
            target.PlayIdle(Main.IdleStop)
            if(texture == "")
                StorageUtil.UnsetStringValue(target, sCurrentTrimmingPrefix + areaName)
                Debug.Notification("You have cleanly shaved your " + areaName)
            Else
                StorageUtil.SetStringValue(target, sCurrentTrimmingPrefix + areaName, trimming)
                Debug.Notification("You have trimmed your " + areaName)
            endIf
            Utility.Wait(0.500000)
        
        endif
        Game.EnablePlayerControls()
        return true
    EndFunction

    String Function GetStatus(Actor target)
        int gameDaysPassedValue = Main.GameDaysPassed.GetValueInt()
        string statusMessage = "--- Body Hair ---"
        
        int i = 0
        while (i < BodyHairAreas.length)
            string areaName = GetAreaName(i)
            statusMessage += "\n- " + areaName + " -"
            if (IsAreaAccessible(target, i))
                int zoneStage = GetAreaStage(target, areaName)
                statusMessage += "\nStage: " + zoneStage + " on " + GetMaxAreaStage(target, areaName)
                string trimming = StorageUtil.GetStringValue(target, sCurrentTrimmingPrefix + areaName)
                if (trimming != "")
                    statusMessage += " (" + trimming + ")"
                endif
                int daysPassed = GetDaysPassedArea(target, areaName, gameDaysPassedValue)
                int daysForGrowthArea = GetDaysForGrowth(target, i, zoneStage)
                statusMessage += "\nDays before next: " + (daysForGrowthArea - daysPassed)
            else
                statusMessage += "\n?\n?"
            endif

            i += 1
        endwhile

        return statusMessage
    EndFunction
EndState

Function CleanModule()
    int i = 0
    Actor[] managedActs = Main.GetManagedActors()

    while i < managedActs.length
    Actor target = managedActs[i]
        int j = 0
        while j < BodyHairAreas.Length
        string areaName = BodyHairAreas[j]
            string overlayNode = StorageUtil.GetStringValue(target, sOverlayNodeStorageKeyPrefix + areaName, missing = "")
            if (overlayNode != "")
                EFSzUtil.ClearOverlay(target, overlayNode)
            endif
            StorageUtil.UnsetStringValue(target, sOverlayNodeStorageKeyPrefix + areaName)
            Storageutil.UnsetIntValue(target, sLastUpdateDayKeyPrefix + areaName)
            Storageutil.UnsetIntValue(target, sCurrentAreaStageKeyPrefix + areaName)
            j += 1
        endWhile
        i += 1
    endWhile
EndFunction

Function UpdateGrowthAll()
EndFunction

Function UpdateGrowth(Actor target)
EndFunction

Function Refresh(Actor target)
EndFunction

Function UpdateAreaHair(Actor target, int areaIndex, int gameDayPassedValue)
EndFunction

Function ApplyZoneStage(Actor target, String areaName, int desiredStage, int maxStage = -1, string pattern = "")
EndFunction

Function RefreshZoneOverlay(Actor target, string areaName, int desiredStage = -1, string texture = "")
EndFunction

bool Function IsAreaAccessible(Actor target, int areaIndex)
    return false
EndFunction

bool Function ApplyCream(Actor target, Spell[] creamSpells)
    ShowInactiveMessage()
    return false
EndFunction

bool Function Shave(Actor target)
    ShowInactiveMessage()
    return false
EndFunction

string Function GetAreaName(int areaIndex)
    return BodyHairAreas[areaIndex]
EndFunction

int Function GetAreaIndex(string areaName)
    return BodyHairAreas.Find(areaName)
EndFunction

int Function GetAreaStage(Actor target, string areaname)
    return StorageUtil.GetIntValue(target, sCurrentAreaStageKeyPrefix + areaname, missing = 0)
EndFunction

int Function GetMaxAreaStage(Actor target, string areaname)
    return JsonUtil.StringListCount(GetActivePresetFile(target, areaname), jStagesKey) - 1
EndFunction

string Function GetAreaFolder(bool female, string areaName, bool relative = true)
    ;log("AreaFolder: " + GetSexFolder(relative) + areaName + "/")
    return GetSexFolder(female, relative) + areaName + "/"
endFunction

string Function GetTrimmingsFolder(Actor target, string areaName)
    ;log("TrimmingsFolder: " + GetAreaFolder(areaName) + trimmingsFolder)
    return GetAreaFolder(target, areaName) + trimmingsFolder
endFunction

string[] Function GetTrimmingsNames(Actor target, string areaName)
    string[] trimmings = JsonUtil.JsonInFolder(GetTrimmingsFolder(target, areaName))
    int i = 0
    while i < trimmings.length
        trimmings[i] = EFSzUtil.RemoveJsonExtension(trimmings[i])
        i += 1
    endWhile
    return trimmings
endFunction

string Function GetTrimmingFile(Actor target, string areaName, string trimming)
    ;log("TrimmingsFolder: " + GetAreaFolder(areaName) + trimmingsFolder)
    return GetAreaFolder(target, areaName) + trimmingsFolder + trimming
endFunction

string function GetPresetsFolder(bool female, string areaName, bool relative = true)
    ;log("PresetsFolder: " + GetAreaFolder(areaName, relative) + growthPresetsFolder)
    return GetAreaFolder(female, areaName, relative) + growthPresetsFolder
endFunction

string[] Function GetPresetsNames(bool female, string areaName)
    string[] presets = JsonUtil.JsonInFolder(GetPresetsFolder(female, areaName))
    int i = 0
    while i < presets.length
        presets[i] = EFSzUtil.RemoveJsonExtension(presets[i])
        i += 1
    endWhile
    return presets
EndFunction

string Function GetPresetFilePath(Actor target, string areaName, string presetName, bool relative = true)
    ;log("AreaPresetFile: " + GetAreaFolder(areaName, relative) + growthPresetsFolder)
    return GetPresetsFolder(target, areaName, relative) + presetName
EndFunction

string Function GetActivePresetFile(Actor target, string areaName, bool relative = true)
    string presetFile = GetPresetFilePath(target, areaName, BodyHairAreasPresets[GetAreaIndex(areaName)], relative)
    if (!relative)
        presetFile += ".json"
    endIf
    ;log("ActivePresetFile: " + presetFile)
    return presetFile
EndFunction

string Function GetConfigFile(Actor target, string areaName)
    ;log("AreaConfigFile: " + GetAreaFolder(areaName) + "config")
    return GetAreaFolder(target, areaName) + "config"
EndFunction
EFS1Undergarments Property UndergarmentsModule  Auto  
SPELL[] Property RemoveCreamSpells  Auto  

int Function GetDaysForGrowth(Actor target, int areaIndex, int zoneStage)
    int daysForGrowthArea = DaysForGrowth[areaIndex]
    If ProgressiveGrowth
        daysForGrowthArea += zoneStage
    EndIf

    return daysForGrowthArea
EndFunction

int Function GetDaysPassedArea(Actor target, string areaName, int gameDaysPassedValue)
    return gameDaysPassedValue - StorageUtil.GetIntValue(target, sLastUpdateDayKeyPrefix + areaName, missing = 0)
EndFunction

String Function GetStatus(Actor target)
    return "--- Body Hair ---\nModule Disabled"
EndFunction
Message Property EFS_SelectShavingArea  Auto  
