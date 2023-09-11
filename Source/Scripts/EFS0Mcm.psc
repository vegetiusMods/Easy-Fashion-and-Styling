Scriptname EFS0Mcm extends SKI_ConfigBase

EFS0MainQuest Property Main Auto
EFS1Undergarments Property UndergarmentsModule Auto
EFS2BodyHair Property BodyHairModule Auto
EFS3Hair Property HairModule  Auto  


; Pages
string generalPage = "General"

; Modules gen
int IdModuleActive

; Consts
int minArmorSlot = 30
int maxArmorSlot = 61

event OnConfigOpen()
    Pages = new string[4]
    Pages[0] = generalPage
    Pages[1] = UndergarmentsModule.ModuleName
    Pages[2] = BodyHairModule.ModuleName
    Pages[3] = HairModule.ModuleName
EndEvent

Event OnPageReset(String Page)
    if (Page == "")
        Page = generalPage
    endif
	
	SwitchPage(Page)
endEvent

event OnConfigClose()
    Main.StartAsynchReload()
endEvent

int Id0ModActive
int Id0DailyUpdateOnSleepTrigger
int Id0DailyUpdateOnEquipmentChange

int Id0PreviewLength

int Id0QuicksaveConfig
int Id0ProfileSave
int Id0QuickloadConfig
int Id0ProfileLoad

string[] profileNames

; General
State General
    Event OnBeginState()
        AddHeaderOption("Daily Update Triggers")
        Id0QuicksaveConfig = AddTextOption("Save as default", "CLICK")
        Id0DailyUpdateOnSleepTrigger = AddToggleOption("On Sleep", Main.OnSleepTrigger)
        Id0ProfileSave = AddInputOption("Save as profile", "CLICK")
        Id0DailyUpdateOnEquipmentChange = AddToggleOption("On (Un)Equip", Main.OnEquipmentChangeTrigger)
        Id0QuickloadConfig = AddTextOption("Load default", "CLICK")
        AddEmptyOption()
        Id0ProfileLoad = AddMenuOption("Load profile", "CLICK")
        Id0PreviewLength = AddSliderOption("Preview duration", Main.PreviewDur, "{0}s")
    EndEvent

    Event OnOptionHighlight(int option)
        If (Option == Id0DailyUpdateOnSleepTrigger)
            SetInfoText("The daily update of the various modules will trigger on sleep. Highly advised.")
        elseIf (Option == Id0DailyUpdateOnEquipmentChange)
            SetInfoText("The daily update of the various modules will trigger on equipment change. Each module will only process the event it the changed item is relevant to him, so it souldn't be too heavy. If you sleep regularly, the 'On Sleep' trigger is probably enough.")
        elseif(Option == Id0QuicksaveConfig)
            SetInfoText("Saves the current configuration as the default one.")
        elseif(Option == Id0QuickloadConfig)
            SetInfoText("Reload the default configuration.")
        elseif(Option == Id0PreviewLength)
            SetInfoText("The duration of previews in seconds (before confirming cut/shave).")
        elseif(Option == Id0ProfileSave)
            SetInfoText("Save the current configuration as a named profile.")
        elseif(Option == Id0ProfileLoad)
            SetInfoText("Load a named profile.")
        endif
    EndEvent

    Event OnOptionSelect(Int OptionID)
        if (OptionID == Id0DailyUpdateOnSleepTrigger)
            Main.OnSleepTrigger = !Main.OnSleepTrigger
            SetToggleOptionValue(Id0DailyUpdateOnSleepTrigger, Main.OnSleepTrigger)
        elseif (OptionID == Id0DailyUpdateOnEquipmentChange)
            Main.OnEquipmentChangeTrigger = !Main.OnEquipmentChangeTrigger
            SetToggleOptionValue(Id0DailyUpdateOnEquipmentChange, Main.OnEquipmentChangeTrigger)
        elseif(OptionID == Id0QuicksaveConfig)
            Main.SaveDefaultConfig()
            ShowMessage("The current configuration has been saved as the default one.")
        elseif(OptionID == Id0PreviewLength)
            Main.LoadDefaultConfig()
            ShowMessage("The default configuration has been loaded.")
        endif
    EndEvent

    Event OnOptionSliderOpen(int OptionID)
        If OptionID == Id0PreviewLength
            SetSliderOptions(Value = Main.PreviewDur, Default = Main.PreviewDur, Min = 0, Max = 30, Interval = 1)
        EndIf
    EndEvent

    Event OnOptionSliderAccept(int optionid, float value)
        If OptionID == Id0PreviewLength
            Main.PreviewDur = value as int
            SetSliderOptionValue(Id0PreviewLength, value)
        EndIf
    EndEvent

    Event OnOptionMenuOpen(int option)
        if (option == Id0ProfileLoad)
            profileNames = Main.GetProfileFileNames()
            SetMenuDialogOptions(profileNames)
            SetMenuDialogDefaultIndex(0)
        endif
    EndEvent

    Event OnOptionMenuAccept(int option, int index) 
        if (option == Id0ProfileLoad)
            string profile = profileNames[index]
            Main.LoadConfig(profile)
            ShowMessage("The profile " + profile + " has been loaded.")
        endif
    EndEvent

    Event OnOptionInputAccept(int option, string akinput)
        if (option == Id0ProfileSave)
            Main.SaveConfig(akinput)
            ShowMessage("The current configuration has been saved as " + akinput + ".")
        endif
    EndEvent
EndState

; Undergraments
int Id1ConcealingPreventInteract
int[] Ids1UndergarmentsSlots
int[] Ids1UndergarmentsConcealable

string concealableLabel = "Concealable"

State Undergarments

    Event OnBeginState()
        Ids1UndergarmentsConcealable = new int[5]
        Ids1UndergarmentsSlots = new int[5]

        IdModuleActive = AddToggleOption("Module active", UndergarmentsModule.IsModuleStarted())
        Id1ConcealingPreventInteract = AddToggleOption("Block concealed interaction", UndergarmentsModule.ConcealingPreventInteract)

        AddHeaderOption("Slots")
        AddEmptyOption()
        int i = 0
        while i < Ids1UndergarmentsSlots.Length
            string title = UndergarmentsModule.UndergarmentsList[i]
            Ids1UndergarmentsSlots[i] = AddSliderOption(title, UndergarmentsModule.UndergarmentsSlots[i])
            Ids1UndergarmentsConcealable[i] = AddToggleOption(concealableLabel, UndergarmentsModule.UndergarmentsConcealable[i])
            i += 1
        endwhile
    EndEvent

    Event OnOptionHighlight(int option)
        If (Option == Id1ConcealingPreventInteract)
            SetInfoText("If active, you won't be able to put/remove undergarment while they are concealed.")
        else
            int i = 0
            while (i < Ids1UndergarmentsSlots.Length)
                if (option == Ids1UndergarmentsSlots[i])
                    SetInfoText("Sets the body slot that will be considered as being this body part undergarment.")
                elseif (option == Ids1UndergarmentsConcealable[i])
                    SetInfoText("Sets if undergarments covering this body part can be concealed by armor or clothes.")
                endif

                i += 1
            endwhile
        endif
    EndEvent

    Event OnOptionSelect(Int OptionID)
        if (OptionID == IdModuleActive)
            UndergarmentsModule.Toggle()
            SetToggleOptionValue(IdModuleActive, UndergarmentsModule.IsModuleStarted())
        elseif (OptionID == Id1ConcealingPreventInteract)
            UndergarmentsModule.ConcealingPreventInteract = !UndergarmentsModule.ConcealingPreventInteract
            SetToggleOptionValue(Id1ConcealingPreventInteract, UndergarmentsModule.ConcealingPreventInteract)
        else
            int i = 0
            bool break = false
            while i < Ids1UndergarmentsConcealable.Length && !break
                If OptionID == Ids1UndergarmentsConcealable[i]
                    UndergarmentsModule.UndergarmentsConcealable[i] = !UndergarmentsModule.UndergarmentsConcealable[i]
                    SetToggleOptionValue(Ids1UndergarmentsConcealable[i], UndergarmentsModule.UndergarmentsConcealable[i])
                    UndergarmentsModule.FlaggedForRefresh = true
                    break = true
                EndIf
                i += 1
            endWhile
        endif
    EndEvent

    Event OnOptionSliderOpen(int OptionID)
        int i = 0
        bool break = false
        while i < Ids1UndergarmentsSlots.Length && !break
            If OptionID == Ids1UndergarmentsSlots[i]
                SetSliderOptions(Value = UndergarmentsModule.UndergarmentsSlots[i], Default = UndergarmentsModule.UndergarmentsSlots[i], Min = minArmorSlot, Max = maxArmorSlot, Interval = 1)
                break = true
            EndIf
            i += 1
        endWhile
    EndEvent

    Event OnOptionSliderAccept(int optionid, float value)
        int i = 0
        bool break = false
        while i < Ids1UndergarmentsSlots.Length && !break
            If OptionID == Ids1UndergarmentsSlots[i]
                UndergarmentsModule.UndergarmentsSlots[i] = value as int
                SetSliderOptionValue(Ids1UndergarmentsSlots[i], value)
                UndergarmentsModule.FlaggedForRefresh = true
                break = true
            EndIf
            i += 1
        endWhile
    EndEvent

EndState

; Body hair

int Id2BHOutfitRestrictAccess
int Id2BHUndergarmentsIntegration
int Id2BHProgressiveGrowth
int[] Id2BHAreasPresets
int[] Id2BHAreasStages
int[] Id2BHDaysForGrowth

int BHcurrentAreaIndex
string[] BHcurrentPresets

State BodyHair
    Event OnBeginState()
        IdModuleActive = AddToggleOption("Module active", BodyHairModule.IsModuleStarted())
        Id2BHOutfitRestrictAccess = AddToggleOption("Outfit restrict access", BodyHairModule.OutfitRestrictAccess)
        Id2BHUndergarmentsIntegration = AddToggleOption("Undergarments integration", BodyHairModule.UndergarmentsIntegration)
        Id2BHProgressiveGrowth = AddToggleOption("Progressive growth interval", BodyHairModule.ProgressiveGrowth)

        AddHeaderOption(BodyHairModule.BodyHairAreas[0])
        AddHeaderOption(BodyHairModule.BodyHairAreas[1])

        Id2BHAreasPresets = new int[2]
        Id2BHAreasPresets[0] = AddMenuOption("Preset", BodyHairModule.BodyHairAreasPresets[0])
        Id2BHAreasPresets[1] = AddMenuOption("Preset", BodyHairModule.BodyHairAreasPresets[1])

        Id2BHDaysForGrowth = new int[2]
        Id2BHDaysForGrowth[0] = AddSliderOption("Days for growth",  BodyHairModule.DaysForGrowth[0])
        Id2BHDaysForGrowth[1] = AddSliderOption("Days for growth",  BodyHairModule.DaysForGrowth[1])
    endevent

    Event OnOptionHighlight(int option)
        If (Option == IdModuleActive)
            SetInfoText("Toggle this module on/off.")
        elseif (option == Id2BHOutfitRestrictAccess)
            SetInfoText("If active, wearing armor while prevent you from shaving.")
        elseif (option == Id2BHUndergarmentsIntegration)
            SetInfoText("If this and 'Outfit restrict access' are active, wearing undergarments will also prevent you from shaving.")
        elseif (option == Id2BHProgressiveGrowth)
            SetInfoText("If checked, for each stage the interval for growth will be increased by your current stage (Interval = Base Value + Current Stage).")
        elseif (Id2BHAreasPresets.Find(option) >= 0)
            SetInfoText("Growth preset to use for this area.")
        elseif (Id2BHDaysForGrowth.Find(option) >= 0)
            SetInfoText("Number of days between each growth stage. Does not impact performance, so set to your liking.")
        endif
    EndEvent

    Event OnOptionSelect(Int OptionID)
        if (OptionID == IdModuleActive)
            BodyHairModule.Toggle()
            SetToggleOptionValue(IdModuleActive, BodyHairModule.IsModuleStarted())
        elseif (OptionID == Id2BHOutfitRestrictAccess)
            BodyHairModule.OutfitRestrictAccess = !BodyHairModule.OutfitRestrictAccess
            SetToggleOptionValue(Id2BHOutfitRestrictAccess, BodyHairModule.OutfitRestrictAccess)
        elseif (OptionID == Id2BHUndergarmentsIntegration)
            BodyHairModule.UndergarmentsIntegration = !BodyHairModule.UndergarmentsIntegration
            SetToggleOptionValue(Id2BHUndergarmentsIntegration, BodyHairModule.UndergarmentsIntegration)
        elseif (OptionID == Id2BHProgressiveGrowth)
            BodyHairModule.ProgressiveGrowth = !BodyHairModule.ProgressiveGrowth
            SetToggleOptionValue(Id2BHProgressiveGrowth, BodyHairModule.ProgressiveGrowth)
        endif
    EndEvent

    Event OnOptionSliderOpen(int OptionID)
        int index = Id2BHDaysForGrowth.Find(OptionID)
        if (index >= 0)
            SetSliderOptions(BodyHairModule.DaysForGrowth[index], BodyHairModule.DaysForGrowth[index], 0, 30, 1)
        endif
    EndEvent

    Event OnOptionSliderAccept(int optionid, float value)
        int index = Id2BHDaysForGrowth.Find(OptionID)
        if (index >= 0)
            BodyHairModule.DaysForGrowth[index] = value as int
            SetSliderOptionValue(optionid, value)
            BodyHairModule.FlaggedForRefresh = true
        endif
    EndEvent

    Event OnOptionMenuOpen(int option)
        int i = 0
        while (i < Id2BHAreasPresets.Length)
            if (option == Id2BHAreasPresets[i])
                BHcurrentAreaIndex = i
                BHcurrentPresets = BodyHairModule.GetPresetsNames(true, BodyHairModule.BodyHairAreas[i])
                SetMenuDialogOptions(BHcurrentPresets)
                SetMenuDialogDefaultIndex(0)
                return
            endif

            i += 1
        endWhile
    EndEvent

    Event OnOptionMenuAccept(int option, int index)
        string preset = BHcurrentPresets[index]
        SetMenuOptionValue(option, preset)
        BodyHairModule.BodyHairAreasPresets[BHcurrentAreaIndex] = preset
        BodyHairModule.FlaggedForRefresh = true
    EndEvent

EndState

; Hair

int Id3HForceRescan
int Id3HDaysForGrowth
int Id3HProgressiveGrowth
int Id3HSelectHair

int Id3HOnHitMessChances
int Id3HOnSleepMessChances
int Id3HOnRemoveHelmetMessChances
int Id3HOnAssaultMessChances
int Id3HOnHitOnlyPowerAttack
int Id3HOnHitOnlyUnblocked

State Hair
    Event OnBeginState()
        IdModuleActive = AddToggleOption("Module active", HairModule.IsModuleStarted())
        Id3HForceRescan = AddTextOption("Force player scan", "CLICK")
        Id3HDaysForGrowth = AddSliderOption("Days for growth",  HairModule.DaysForGrowthBase)
        Id3HSelectHair = AddTextOption("Manually select hair", "CLICK")
        Id3HProgressiveGrowth = AddToggleOption("Progressive growth interval", HairModule.ProgressiveGrowth)
        AddEmptyOption()
        AddHeaderOption("Hair mess up")
        AddEmptyOption()
        Id3HOnSleepMessChances = AddSliderOption("On sleep chances",  HairModule.OnSleepMessChances, "{0}%")
        AddEmptyOption()
        Id3HOnRemoveHelmetMessChances = AddSliderOption("On remove headwear chances",  HairModule.OnRemoveHelmetMessChances, "{0}%")
        AddEmptyOption()
        Id3HOnAssaultMessChances = AddSliderOption("On assault chances",  HairModule.OnAssaultMessChances, "{0}%")
        AddEmptyOption()
        Id3HOnHitMessChances = AddSliderOption("On hit chances",  HairModule.OnHitMessChances, "{0}%")
        AddEmptyOption()
        Id3HOnHitOnlyPowerAttack = AddToggleOption("Only power attacks", HairModule.OnHitOnlyPowerAttack)
        AddEmptyOption()
        Id3HOnHitOnlyUnblocked = AddToggleOption("Only unblocked", HairModule.OnHitOnlyUnblocked)
    endevent

    Event OnOptionHighlight(int option)
        If (Option == IdModuleActive)
            SetInfoText("Toggle this module on/off.")
        elseif (option == Id3HDaysForGrowth)
            SetInfoText("If checked, for each stage the interval for growth will be increased by your current stage (Interval = Base Value + Current Stage).")
        elseif (option == Id3HProgressiveGrowth)
            SetInfoText("Number of days between each growth stage. Does not impact performance, so set to your liking.")
        elseif (option == Id3HSelectHair)
            SetInfoText("If you have trouble starting the module, click here to manually select your hair type.")
        elseif (option == Id3HOnSleepMessChances)
            SetInfoText("Chances your hair style will be messed up on sleep. Set to 0 to disable.")
        elseif (option == Id3HOnRemoveHelmetMessChances)
            SetInfoText("Chances your hair style will be messed up on removing your headwear. Set to 0 to disable.")
        elseif (option == Id3HOnAssaultMessChances)
            SetInfoText("Chances your hair style will be messed up on assault (require SexLab). Set to 0 to disable.")
        elseif (option == Id3HOnHitMessChances)
            SetInfoText("Chances your hair style will be messed up on being hit. Set to 0 to disable.")
        elseif (option == Id3HOnHitOnlyPowerAttack)
            SetInfoText("If on, your hair can only be messed up by power attacks.")
        elseif (option == Id3HOnHitOnlyUnblocked)
            SetInfoText("If on, your hair can only be messed up by unblocked attacks.")
        endif
    EndEvent

    Event OnOptionSelect(Int OptionID)
        if (OptionID == IdModuleActive)
            HairModule.Toggle()
            SetToggleOptionValue(IdModuleActive, HairModule.IsModuleStarted())
        elseif (OptionID == Id3HProgressiveGrowth)
            HairModule.ProgressiveGrowth = !HairModule.ProgressiveGrowth
            SetToggleOptionValue(Id3HProgressiveGrowth, HairModule.ProgressiveGrowth)
        elseif(OptionID == Id3HForceRescan)
            HairModule.ScanAll()
        elseif(OptionID == Id3HSelectHair)
            HairModule.PrepareSelectPlayerHair()
            ShowMessage("You will be able to configure your hair upon exiting the menu.")
        elseif(OptionID == Id3HOnHitOnlyPowerAttack)
            HairModule.OnHitOnlyPowerAttack = !HairModule.OnHitOnlyPowerAttack
            SetToggleOptionValue(Id3HOnHitOnlyPowerAttack, HairModule.OnHitOnlyPowerAttack)
        elseif(OptionID == Id3HOnHitOnlyUnblocked)
            HairModule.OnHitOnlyUnblocked = !HairModule.OnHitOnlyUnblocked
            SetToggleOptionValue(Id3HOnHitOnlyUnblocked, HairModule.OnHitOnlyUnblocked)
        endif
    EndEvent

    Event OnOptionSliderOpen(int OptionID)
        if (OptionID == Id3HDaysForGrowth)
            SetSliderOptions(HairModule.DaysForGrowthBase,  HairModule.DaysForGrowthBase, 0, 60, 1)
        elseif (OptionID == Id3HOnSleepMessChances)
            SetSliderOptions(HairModule.OnSleepMessChances,  HairModule.OnSleepMessChances, 0, 100, 1)
        elseif (OptionID == Id3HOnRemoveHelmetMessChances)
            SetSliderOptions(HairModule.OnRemoveHelmetMessChances,  HairModule.OnRemoveHelmetMessChances, 0, 100, 1)
        elseif (OptionID == Id3HOnAssaultMessChances)
            SetSliderOptions(HairModule.OnAssaultMessChances,  HairModule.OnAssaultMessChances, 0, 100, 1)
        elseif (OptionID == Id3HOnHitMessChances)
            SetSliderOptions(HairModule.OnHitMessChances,  HairModule.OnHitMessChances, 0, 100, 1)
        endif
    EndEvent

    Event OnOptionSliderAccept(int optionid, float value)
        
        if (OptionID == Id3HDaysForGrowth)  
            HairModule.DaysForGrowthBase = value as int
            SetSliderOptionValue(optionid, value)
            HairModule.FlaggedForRefresh = true
        elseif (OptionID == Id3HOnSleepMessChances)
            HairModule.OnSleepMessChances = value as int
            SetSliderOptionValue(optionid, value, "{0}%")
        elseif (OptionID == Id3HOnRemoveHelmetMessChances)
            HairModule.OnRemoveHelmetMessChances = value as int
            SetSliderOptionValue(optionid, value, "{0}%")
        elseif (OptionID == Id3HOnAssaultMessChances)
            HairModule.OnAssaultMessChances = value as int
            SetSliderOptionValue(optionid, value, "{0}%")
        elseif (OptionID == Id3HOnHitMessChances)
            HairModule.OnHitMessChances = value as int
            SetSliderOptionValue(optionid, value, "{0}%")
        endif
    EndEvent

    Event OnOptionMenuOpen(int option)
    EndEvent

    Event OnOptionMenuAccept(int option, int index)
    EndEvent
EndState

; Utils

Function SwitchPage(string pageLabel)
    GoToState(EFSzUtil.Escape(pageLabel, " "))
EndFunction

Function SetSliderOptions(Float Value, Float Default, Float Min, Float Max, Float Interval)
	SetSliderDialogStartValue(Value)
	SetSliderDialogDefaultValue(Default)
	SetSliderDialogRange(Min, Max)
	SetSliderDialogInterval(Interval)
EndFunction

bool Function IsGeneralPage(string Page)
    return Page == "" || Page == generalPage
EndFunction

