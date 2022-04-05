Scriptname EFS0MainQuest extends Quest  

; Properties
int Property LoadedVersion Auto
ReferenceAlias Property PlayerAlias Auto
GlobalVariable Property GameDaysPassed Auto

Quest Property MQ101  Auto 

; Modules
EFS1Undergarments property UndergarmentsModule Auto
EFS2BodyHair property BodyHairModule Auto
EFS3Hair Property HairModule  Auto  

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
string jbodyConcealSlotsKey = "bodyconcealSlots"
string jheadConcealSlotsKey = "headconcealSlots"
string jbodyConcealKeywordsKey = "bodyconcealKeywords"
string jheadConcealKeywordsKey = "headconcealkeywords"
string jhandsTiedKeywordsKey = "handstiedkeywords"

float initInterval = 5.0

; Init and mod lifecycle
Event OnInit()
    LoadedVersion = 0
    RegisterForSingleUpdate(initInterval)
EndEvent

Event OnUpdate()
    if MQ101.GetStageDone(250)
        Load(firstStart = true)
    else
        RegisterForSingleUpdate(initInterval)
    endif
EndEvent

Function Load(bool firstStart = false)
    RegisterForModEvent("EFS_ReloadNeeded", "OnReloadNeeded")

    int currentVer = EFSzUtil.GetModVersion()

    ManagedActors = new Actor[1]
    ManagedActors[0] = Game.GetPlayer()

    modules = new EFSzmodule[3]
    modules[0] = UndergarmentsModule
    modules[1] = BodyHairModule
    modules[2] = HairModule

    ; 0.2.Alpha BodyHair + Undergarments
    if (LoadedVersion < EFSzUtil.Get02AlphaVersion())
        OnSleepTrigger = true
        OnEquipmentChangeTrigger = false
    endif 

    If (firstStart)
        LoadAll(0)
        LoadDefaultConfig()
    Else
        LoadAll(LoadedVersion)
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

string[] Function GetProfileFileNames()
    return JsonUtil.JsonInFolder(relativeMcmConfigLocation)
EndFunction

Function SaveConfig(string fileName)
    string filePath = relativeMcmConfigLocation + fileName
    ; 0 - General
    JsonUtil.SetIntValue(filePath, "Id0DailyUpdateOnSleepTrigger", OnSleepTrigger as int)
    JsonUtil.SetIntValue(filePath, "Id0DailyUpdateOnEquipmentChange", OnEquipmentChangeTrigger as int)
    JsonUtil.SetFloatValue(filePath, "Id0PreviewLength", PreviewDur)

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

    ; 3 - Hair
    JsonUtil.SetIntValue(filePath, "Id3ModuleActive", HairModule.IsModuleStarted() as int)
    JsonUtil.SetIntValue(filePath, "Id3HDaysForGrowth",  HairModule.DaysForGrowthBase)
    JsonUtil.SetIntValue(filePath, "Id3HProgressiveGrowth", HairModule.ProgressiveGrowth as int)

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
        PreviewDur = JsonUtil.GetFloatValue(filePath, "Id0PreviewLength")

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

        ; 3 - Hair
        HairModule.DaysForGrowthBase = JsonUtil.GetIntValue(filePath, "Id3HDaysForGrowth")
        HairModule.ProgressiveGrowth = JsonUtil.GetIntValue(filePath, "Id3HProgressiveGrowth") as bool

        ToggleLoadModule(filePath, "Id3ModuleActive", HairModule)
    endif
EndFunction

bool Function HasHandsTied(Actor target)
    int i = 0
    string[] handsTiedKeywords = GetHandsTiedKeywords()
    while (i < handsTiedKeywords.Length)
        Keyword kwd = Keyword.GetKeyword(handsTiedKeywords[i])
        if (kwd && target.WornHasKeyword(kwd))
            Debug.MessageBox("You can do that with your hand tied!")
            return true
        endIf

        i += 1
    endWhile

    return false
EndFunction

bool Function IsBodyConcealing(Form obj)
    Armor arm = obj as Armor
    if (arm)
        return EFSzUtil.HasOneSlot(arm, GetBodyConcealSlots()) || EFSzUtil.HasOneKeyword(arm, GetBodyConcealKeywords())
    endIf

    return false
EndFunction

bool Function IsBodyConcealingWorn(Actor target)
    int i = 0
    int[] concealSlots = GetBodyConcealSlots()
    while (i < concealSlots.Length)
        if (target.GetWornForm(Armor.GetMaskForSlot(concealSlots[i])) != none)
            return true
        endIf

        i += 1
    endWhile

    i = 0
    string[] concealKeywords = GetBodyConcealKeywords()
    while (i < concealKeywords.Length)
        Keyword kwd = Keyword.GetKeyword(concealKeywords[i])
        if (kwd && target.WornHasKeyword(kwd))
            return true
        endIf

        i += 1
    endWhile

    return false
EndFunction

bool Function IsHeadConcealingWorn(Actor target)
    int i = 0
    int[] concealSlots = GetHeadConcealSlots()
    while (i < concealSlots.Length)
        if (target.GetWornForm(Armor.GetMaskForSlot(concealSlots[i])) != none)
            return true
        endIf

        i += 1
    endWhile

    ; TODO check keywords, if a case ever occurs
EndFunction

int[] Function GetBodyConcealSlots()
    return JSonUtil.IntListToArray(GetFilePath(jmainFile), jbodyConcealSlotsKey)
EndFunction

int[] Function GetHeadConcealSlots()
    return JSonUtil.IntListToArray(GetFilePath(jmainFile), jheadConcealSlotsKey)
EndFunction

string[] Function GetHandsTiedKeywords()
    return JSonUtil.StringListToArray(GetFilePath(jmainFile), jhandsTiedKeywordsKey)
EndFunction

string[] Function GetBodyConcealKeywords()
    return JSonUtil.StringListToArray(GetFilePath(jmainFile), jbodyConcealKeywordsKey)
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
    if (StringUtil.Find(fileName, ".json") < 0)
        fileName += ".json"
    endIf
	return MiscUtil.FileExists(fullMcmConfigLocation + fileName)
EndFunction
Message Property EFS_PreviewAsk  Auto  

Message Property EFS_PreviewConfirm  Auto  

Idle Property IdleStop  Auto  

Float Property PreviewDur = 5.0 Auto  
