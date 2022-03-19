Scriptname EFS0MainQuest extends Quest  

; Properties
int Property LoadedVersion Auto
ReferenceAlias Property PlayerAlias Auto
GlobalVariable Property GameDaysPassed Auto

; Modules
EFS1Undergarments property UndergarmentsModule Auto
EFS2BodyHair property BodyHairModule Auto

; DailyUpdateTriggers
bool Property OnSleepTrigger Auto
bool Property OnEquipmentChangeTrigger Auto

; Fields
Actor[] ManagedActors
EFSzModule[] modules

; Config
string fullMcmConfigLocation = "data/skse/plugins/Easy Fashion and Styling/Mcm/"
string relativeMcmConfigLocation = "../Easy Fashion and Styling/Mcm/"
string defaultConfigFileName = "default"

string jmainFile = "config"
string jconcealSlotsKey = "concealSlots"
string jconcealKeywordsKey = "concealKeywords"

; Init and mod lifecycle
Event OnInit()
    LoadedVersion = 0
    Load(firstStart = true)
EndEvent

Function Load(bool firstStart = false)
    RegisterForModEvent("EFS_ReloadNeeded", "OnReloadNeeded")

    int currentVer = EFSzUtil.GetModVersion()

    ManagedActors = new Actor[1]
    ManagedActors[0] = Game.GetPlayer()

    modules = new EFSzmodule[2]
    modules[0] = UndergarmentsModule
    modules[1] = BodyHairModule

    ; 0.2.Alpha BodyHair + Undergarments
    if (LoadedVersion < EFSzUtil.Get02AlphaVersion())
        OnSleepTrigger = true
        OnEquipmentChangeTrigger = false
    endif 

    LoadAll(LoadedVersion)

    If (firstStart)
        LoadDefaultConfig()
    Else
        ; We do not want to force refresh all mods !!!
        RefreshAll(force = false)
    EndIf

    LoadedVersion = currentVer

    EFSzUtil.log("Started")
EndFunction

Function ObjectEquipped(Actor target, Form akBaseObject, ObjectReference akReference)
    int i = 0
    while (i < modules.Length)
        modules[i].ObjectEquipped(target, akBaseObject, akReference)
        i += 1
    EndWhile
EndFunction

Function ObjectUnequipped(Actor target, Form akBaseObject, ObjectReference akReference)
    int i = 0
    while (i < modules.Length)
        modules[i].ObjectUnequipped(target, akBaseObject, akReference)
        i += 1
    EndWhile
EndFunction

Actor[] Function GetManagedActors()
    return ManagedActors
EndFunction

Function StartAsynchReload()
    int handle = ModEvent.Create("EFS_ReloadNeeded")
    if (handle)
        ModEvent.Send(handle)
    endIf
EndFunction

Event OnReloadNeeded()
    EFSzUtil.log("Receive ReloadNeeded event")
    RefreshAll()
EndEvent

Function ToggleAll()
    int i = 0
    while (i < modules.Length)
        modules[i].Toggle()

        i += 1
    EndWhile
EndFunction

Function LoadAll(int lastVer)
    int i = 0
    while (i < modules.Length)
        modules[i].LoadModule(lastVer)

        i += 1
    EndWhile
EndFunction

Function RefreshAll(bool force = false)
    int i = 0
    while (i < modules.Length)
        modules[i].RefreshModule(force)

        i += 1
    EndWhile
EndFunction


; Config

Function SaveConfig(string fileName)
    string filePath = relativeMcmConfigLocation + fileName
    ; 0 - General
    JsonUtil.SetIntValue(filePath, "Id0DailyUpdateOnSleepTrigger", OnSleepTrigger as int)
    JsonUtil.SetIntValue(filePath, "Id0DailyUpdateOnEquipmentChange", OnEquipmentChangeTrigger as int)

    ; 1 - Undergarments
    JsonUtil.SetIntValue(filePath, "Id1ModuleActive", UndergarmentsModule.IsModuleStarted() as int)
    JsonUtil.SetIntValue(filePath, "Id1ConcealingPreventInteract", UndergarmentsModule.ConcealingPreventInteract as int)

    JsonUtil.IntListClear(filePath, "Ids1UndergarmentsSlots")
    JsonUtil.IntListClear(filePath, "Ids1UndergarmentsConcealable")
    int i = 0
    while i < UndergarmentsModule.UndergarmentsList.Length
        JsonUtil.IntListAdd(filePath, "Ids1UndergarmentsSlots", UndergarmentsModule.UndergarmentsSlots[i])
        JsonUtil.IntListAdd(filePath, "Ids1UndergarmentsConcealable", UndergarmentsModule.UndergarmentsConcealable[i] as int)
        i += 1
    endwhile

    ; 2 - Body Hair
    JsonUtil.SetIntValue(filePath, "Id2ModuleActive", BodyHairModule.IsModuleStarted() as int)
    JsonUtil.SetIntValue(filePath, "Id2BHOutfitRestrictAccess", BodyHairModule.OutfitRestrictAccess as int)
    JsonUtil.SetIntValue(filePath, "Id2BHUndergarmentsIntegration", BodyHairModule.UndergarmentsIntegration as int)
    JsonUtil.SetIntValue(filePath, "Id2BHProgressiveGrowth", BodyHairModule.ProgressiveGrowth as int)

    JsonUtil.IntListClear(filePath, "Id2BHDaysForGrowth")
    JsonUtil.IntListAdd(filePath, "Id2BHDaysForGrowth", BodyHairModule.DaysForGrowth[0])
    JsonUtil.IntListAdd(filePath, "Id2BHDaysForGrowth", BodyHairModule.DaysForGrowth[1])

    JsonUtil.StringListClear(filePath, "Id2BHAreasPresets")
    JsonUtil.StringListAdd(filePath, "Id2BHAreasPresets", BodyHairModule.BodyHairAreasPresets[0])
    JsonUtil.StringListAdd(filePath, "Id2BHAreasPresets", BodyHairModule.BodyHairAreasPresets[1])

	JsonUtil.Save(filePath)
EndFunction

Function SaveDefaultConfig()
    SaveConfig(defaultConfigFileName)
EndFunction

Function LoadConfig(string fileName)
    if (HasConfig(fileName))
        string filePath = relativeMcmConfigLocation + fileName
        JsonUtil.Load(filePath)

        ; 0 - General
        OnSleepTrigger = JsonUtil.GetIntValue(filePath, "Id0DailyUpdateOnSleepTrigger") as bool
        OnEquipmentChangeTrigger = JsonUtil.GetIntValue(filePath, "Id0DailyUpdateOnEquipmentChange") as bool

        ; 1 - Undergarments    
        UndergarmentsModule.ConcealingPreventInteract = JsonUtil.GetIntValue(filePath, "Id1ConcealingPreventInteract") as bool
        int i = 0
        while i < UndergarmentsModule.UndergarmentsList.Length
            UndergarmentsModule.UndergarmentsSlots[i] = JsonUtil.IntListGet(filePath, "Ids1UndergarmentsSlots", i)
            UndergarmentsModule.UndergarmentsConcealable[i] = JsonUtil.IntListGet(filePath, "Ids1UndergarmentsConcealable", i) as bool
            i += 1
        endwhile

        ToggleLoadModule(filePath, "Id1ModuleActive", UndergarmentsModule)

        ; 2 - Body Hair
        BodyHairModule.OutfitRestrictAccess = JsonUtil.GetIntValue(filePath, "Id2BHOutfitRestrictAccess") as bool
        BodyHairModule.UndergarmentsIntegration = JsonUtil.GetIntValue(filePath, "Id2BHUndergarmentsIntegration") as bool
        BodyHairModule.ProgressiveGrowth = JsonUtil.GetIntValue(filePath, "Id2BHProgressiveGrowth") as bool

        BodyHairModule.BodyHairAreasPresets[0] = JsonUtil.StringListGet(filePath, "Id2BHAreasPresets", 0)
        BodyHairModule.BodyHairAreasPresets[1] = JsonUtil.StringListGet(filePath, "Id2BHAreasPresets", 1)

        BodyHairModule.DaysForGrowth[0] = JsonUtil.IntListGet(filePath, "Id2BHDaysForGrowth", 0)
        BodyHairModule.DaysForGrowth[1] = JsonUtil.IntListGet(filePath, "Id2BHDaysForGrowth", 1)

        ToggleLoadModule(filePath, "Id2ModuleActive", BodyHairModule)
    endif
EndFunction

bool Function IsConcealing(Form obj)
    Armor arm = obj as Armor
    if (arm)
        return EFSzUtil.HasOneSlot(arm, GetConcealSlots()) || EFSzUtil.HasOneKeyword(arm, GetConcealKeywords())
    endIf

    return false
EndFunction

bool Function IsConcealingWorn(Actor target)
    int i = 0
    int[] concealSlots = GetConcealSlots()
    while (i < concealSlots.Length)
        if (target.GetWornForm(Armor.GetMaskForSlot(concealSlots[i])) != none)
            return true
        endIf

        i += 1
    endWhile

    i = 0
    string[] concealKeywords = GetConcealKeywords()
    while (i < concealKeywords.Length)
        Keyword kwd = Keyword.GetKeyword(concealKeywords[i])
        if (kwd && target.WornHasKeyword(kwd))
            return true
        endIf

        i += 1
    endWhile

    return false
EndFunction

int[] Function GetConcealSlots()
    return JSonUtil.IntListToArray(GetFilePath(jmainFile), jconcealSlotsKey)
EndFunction

string[] Function GetConcealKeywords()
    return JSonUtil.StringListToArray(GetFilePath(jmainFile), jconcealKeywordsKey)
EndFunction

string Function GetPluginFolderPath(bool relative = true)
    string root
    if (relative)
        root = ".."
    else
        root = "data/skse/plugins"
    endif

    return root + "/Easy Fashion and Styling/" 
EndFunction

string Function GetFilePath(string fileName, bool relative = true)
    return GetPluginFolderPath(relative) + fileName
EndFunction

Function LoadDefaultConfig()
    LoadConfig(defaultConfigFileName)
EndFunction

Function ToggleLoadModule(String filePath, string startKey, EFSzModule module)
    if (JsonUtil.GetIntValue(filePath, startKey) as bool != module.IsModuleStarted())
        module.Toggle()
    else
        module.FlaggedForRefresh = true
    endif
EndFunction

bool Function HasConfig(string fileName)
	return MiscUtil.FileExists(fullMcmConfigLocation + fileName + ".json")
EndFunction
