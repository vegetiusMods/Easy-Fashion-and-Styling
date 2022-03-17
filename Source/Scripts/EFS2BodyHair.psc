Scriptname EFS2BodyHair extends EFSzModule  

; Constants
string maleFolder = "m/"
string femaleFolder = "f/"
string growthPresetsFolder = "growth_presets/"
string trimmingsFolder = "trimmings/"
string areaConfigFileName = "config"

string sLastUpdateDayKeyPrefix = "EFS_BH_LastUpdateDay_"
string sCurrentAreaStageKeyPrefix = "EFS_BH_CurrentAreaStage_"
string sOverlayNodeStorageKeyPrefix = "EFS_OverlayNode_"

string jStagesKey = "stages"

; Properties
Sound Property EFSShaving Auto
String[] Property BodyHairAreas  Auto  
String[] Property BodyHairAreasPresets  Auto  

Bool Property UndergarmentsIntegration  Auto  
Bool Property OutfitRestrictAccess  Auto  
Bool Property ProgressiveGrowth  Auto  

Event OnInit()
    ModuleName = "Body Hair"
EndEvent

Function LoadModule(int loadedVersion)
    if (loadedVersion < EFSzUtil.Get02AlphaVersion())
        BodyHairAreas = new string[2]
        BodyHairAreas[0] = "Armpits"
        BodyHairAreas[1] = "Pubes"

        BodyHairAreasPresets = new string[2]
        BodyHairAreasPresets[0] = GetPresetsNames(true, BodyHairAreas[0])[0]
        BodyHairAreasPresets[1] = GetPresetsNames(true, BodyHairAreas[1])[0]

        ; DaysForGrowthDefault = 2
        UndergarmentsIntegration = true
        OutfitRestrictAccess = true

        FlaggedForRefresh = false

        Toggle()
    endif
EndFunction

State Started

    Function Toggle()
        GoToState("Stopping")
    EndFunction

    Function DoRefresh()
        if (Main.OnSleepTrigger)
            RegisterForSleep()
        endif

        EFSzUtil.log("Refreshing body hair")

        int i = 0
        while (i < Main.GetManagedActors().Length)
            Refresh(Main.GetManagedActors()[i])
            i += 1
        EndWhile
    EndFunction

    Event OnSleepStop(bool abInterrupted)
        UpdateGrowthAll()
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
    
        int daysPassed = gameDaysPassedValue - StorageUtil.GetIntValue(target, sLastUpdateDayKeyPrefix + areaName, missing = 0)

        int zoneStage = GetAreaStage(target, areaName)
    
        ; if (daysPassed >= DaysForGrowthDefault)
        ;     StorageUtil.SetIntValue(target, sLastUpdateDayKeyPrefix + areaName, gameDaysPassedValue)
        ;     ; Update stage
        ;     EFSzUtil.log(daysPassed + " days passed, it is greater than or equal to " + DaysForGrowthDefault + ", " + areaName + " hair has grown")
        ;     int maxStage = GetMaxAreaStage(target, areaName)
        ;     EFSzUtil.log("Current: " + zoneStage + " Max: " + maxStage)
        ;     if(zoneStage < maxStage)
        ;         zoneStage += 1

        ;         ApplyZoneStage(target, areaName, zoneStage, maxStage)

        ;         Debug.Notification("You notice your " + areaName + " hair has grown")
        ;     endIf
        ; else
        ;     EFSzUtil.log(daysPassed + " days passed, it is lesser than " + DaysForGrowthDefault + ", no " + areaName + " hair growth")
        ; endIf
    EndFunction

    Function ApplyZoneStage(Actor target, String areaName, int desiredStage, int maxStage = -1, string pattern = "")
        if (maxStage < 0)
            maxStage = GetMaxAreaStage(target, areaName)
        endif

        if (desiredStage > maxStage)
            desiredStage = maxStage
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
            texture = JsonUtil.StringListGet(GetActivePresetFile(target, areaName), jStagesKey, desiredStage)
        endIf

        EFSzUtil.ApplyTexture(target, "EFS_Node_BodyHair_" + areaName, texture, target.GetActorBase().GetHairColor().GetColor())
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

int Function GetAreaIndex(string areaName)
    return BodyHairAreas.Find(areaName)
EndFunction

int Function GetAreaStage(Actor target, string areaname)
    return StorageUtil.GetIntValue(target, sCurrentAreaStageKeyPrefix + areaname, missing = 0)
EndFunction

int Function GetMaxAreaStage(Actor target, string areaname)
    return JsonUtil.StringListCount(GetActivePresetFile(target, areaname), jStagesKey) - 1
EndFunction

string Function GetSexFolder(bool female, bool relative = true)
    string folderPath = GetModuleFolderPath()
    
    if (female)
        folderPath += femaleFolder
    else
        folderPath += maleFolder
    endIf
    ;log("SexFolder: " + folderPath)
    return folderPath
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