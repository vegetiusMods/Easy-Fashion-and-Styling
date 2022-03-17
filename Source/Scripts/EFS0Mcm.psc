Scriptname EFS0Mcm extends SKI_ConfigBase

EFS0MainQuest Property Main Auto
EFS1Undergarments Property UndergarmentsModule Auto
EFS2BodyHair Property BodyHairModule Auto



; Pages
string generalPage = "General"

; Modules gen
int IdModuleActive

; Consts
int minArmorSlot = 30
int maxArmorSlot = 61

event OnConfigOpen()
    Pages = new string[3]
    Pages[0] = generalPage
    Pages[1] = UndergarmentsModule.ModuleName
    Pages[2] = BodyHairModule.ModuleName
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

int Id0QuicksaveConfig
int Id0QuickloadConfig

; General
State General
    Event OnBeginState()
        AddHeaderOption("Daily Update Triggers")
        Id0QuicksaveConfig = AddTextOption("Save as default", "CLICK")
        Id0DailyUpdateOnSleepTrigger = AddToggleOption("On Sleep", Main.OnSleepTrigger)
        Id0QuickloadConfig = AddTextOption("Load default", "CLICK")
        Id0DailyUpdateOnEquipmentChange = AddToggleOption("On (Un)Equip", Main.OnEquipmentChangeTrigger)
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
            Debug.MessageBox("The current configuration has been saved as the default one.")
        elseif(OptionID == Id0QuickloadConfig)
            Main.LoadDefaultConfig()
            Debug.MessageBox("The default configuration has been loaded.")
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
int Id2BHDaysForGrowthDefault
int Id2BHUndergarmentsIntegration
int[] Id2BHAreasPresets
int[] Id2BHAreasStages

int BHcurrentAreaIndex
string[] BHcurrentPresets

State BodyHair
    Event OnBeginState()
        IdModuleActive = AddToggleOption("Module active", BodyHairModule.IsModuleStarted())
        Id2BHOutfitRestrictAccess = AddToggleOption("Outfit restrict access", BodyHairModule.OutfitRestrictAccess)
        ; Id2BHDaysForGrowthDefault = AddSliderOption("Days for growth",  BodyHairModule.DaysForGrowthDefault)
        Id2BHUndergarmentsIntegration = AddToggleOption("Undergarments integration", BodyHairModule.UndergarmentsIntegration)

        AddHeaderOption(BodyHairModule.BodyHairAreas[0])
        AddHeaderOption(BodyHairModule.BodyHairAreas[1])

        Id2BHAreasPresets = new int[2]
        Id2BHAreasPresets[0] = AddMenuOption("Preset", BodyHairModule.BodyHairAreasPresets[0])
        Id2BHAreasPresets[1] = AddMenuOption("Preset", BodyHairModule.BodyHairAreasPresets[1])
    endevent

    Event OnOptionHighlight(int option)
        If (Option == IdModuleActive)
            SetInfoText("Toggle this module on/off.")
        elseif (option == Id2BHOutfitRestrictAccess)
            SetInfoText("If active, wearing armor while prevent you from shaving.")
        elseif (option == Id2BHDaysForGrowthDefault)
            SetInfoText("Number of days between each growth stage. Does not impact performance, so set to your liking.")
        elseif (option == Id2BHUndergarmentsIntegration)
            SetInfoText("If this and 'Outfit restrict access' are active, wearing undergarments will also prevent you from shaving.")
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
        endif
    EndEvent

    Event OnOptionSliderOpen(int OptionID)
        if (OptionID == Id2BHDaysForGrowthDefault)
            ; SetSliderOptions(BodyHairModule.DaysForGrowthDefault, BodyHairModule.DaysForGrowthDefault, 0, 30, 1)
        endif
    EndEvent

    Event OnOptionSliderAccept(int optionid, float value)
        if (OptionID == Id2BHDaysForGrowthDefault)
            ; BodyHairModule.DaysForGrowthDefault = value as int
            SetSliderOptionValue(Id2BHDaysForGrowthDefault, value)
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