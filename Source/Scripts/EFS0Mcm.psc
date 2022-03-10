Scriptname EFS0Mcm extends SKI_ConfigBase

EFS0MainQuest Property Main Auto
EFS1Undergarments Property UndergarmentsModule Auto
EFS2BodyHair Property BodyHairModule Auto

; Pages
string generalPage = "General"
string undergarmentsPage = "Undergarments"

; Modules gen
int IdModuleActive

; Refresh
; There is prolly a better solution, but I'll wait at least a second module to come up with it to avoid over ingeniering
bool undergarmentsModuleNeedsRefresh

; Consts
int minArmorSlot = 30
int maxArmorSlot = 61

event OnConfigOpen()
    Pages = new string[2]
    Pages[0] = generalPage
    Pages[1] = UndergarmentsModule.ModuleName
    Pages[2] = BodyHairModule.ModuleName

    undergarmentsModuleNeedsRefresh = false
EndEvent

Event OnPageReset(String Page)
    if (Page == "")
        Page = "General"
    endif
	
	GoToState(EFSzUtil.Escape(Page, " "))
endEvent

event OnConfigClose()
    if (undergarmentsModuleNeedsRefresh)
        UndergarmentsModule.RefreshModule()
    endif
endEvent

int IdGModActive
int IdGDailyUpdateOnSleepTrigger
int IdGDailyUpdateOnEquipmentChange

; General
State General
    Event OnBeginState()
        AddHeaderOption("Daily Update Triggers")
        AddEmptyOption()
        IdGDailyUpdateOnSleepTrigger = AddToggleOption("On Sleep", Main.OnSleepTrigger)
        AddEmptyOption()
        IdGDailyUpdateOnEquipmentChange = AddToggleOption("On (Un)Equip", Main.OnEquipmentChangeTrigger)
    EndEvent

    Event OnOptionHighlight(int option)
        If (Option == IdGDailyUpdateOnSleepTrigger)
            SetInfoText("The daily update of the various modules will trigger on sleep. Highly advised.")
        elseIf (Option == IdGDailyUpdateOnEquipmentChange)
            SetInfoText("The daily update of the various modules will trigger on equipment change. Each module will only process the event it the changed item is relevant to him, so it souldn't be too heavy. If you sleep regularly, the 'On Sleep' trigger is probably enough.")
        endif
    EndEvent

    Event OnOptionSelect(Int OptionID)
        if (OptionID == IdGDailyUpdateOnSleepTrigger)
            Main.OnSleepTrigger = !Main.OnSleepTrigger
            SetToggleOptionValue(IdGDailyUpdateOnSleepTrigger, Main.OnSleepTrigger)
        elseif (OptionID == IdGDailyUpdateOnEquipmentChange)
            Main.OnEquipmentChangeTrigger = !Main.OnEquipmentChangeTrigger
            SetToggleOptionValue(IdGDailyUpdateOnEquipmentChange, Main.OnEquipmentChangeTrigger)
        endif
    EndEvent
EndState

; Undergraments
int IdConcealingPreventInteract
int[] IdsUndergarmentsSlots
int[] IdsUndergarmentsConcealable

string concealableLabel = "Concealable"

State Undergarments

    Event OnBeginState()
        IdsUndergarmentsConcealable = new int[5]
        IdsUndergarmentsSlots = new int[5]

        IdModuleActive = AddToggleOption("Module active", UndergarmentsModule.IsModuleStarted())
        IdConcealingPreventInteract = AddToggleOption("Block concealed interaction", UndergarmentsModule.ConcealingPreventInteract)

        AddHeaderOption("Slots")
        AddEmptyOption()
        int i = 0
        while i < IdsUndergarmentsSlots.Length
            string title = UndergarmentsModule.UndergarmentsList[i]
            IdsUndergarmentsSlots[i] = AddSliderOption(title, UndergarmentsModule.UndergarmentsSlots[i])
            IdsUndergarmentsConcealable[i] = AddToggleOption(concealableLabel, UndergarmentsModule.UndergarmentsConcealable[i])
            i += 1
        endwhile
    EndEvent

    Event OnOptionHighlight(int option)
        If (Option == IdConcealingPreventInteract)
            SetInfoText("If active, you won't be able to put/remove undergarment while they are concealed.")
        else
            int i = 0
            while (i < IdsUndergarmentsSlots.Length)
                if (option == IdsUndergarmentsSlots[i])
                    SetInfoText("Sets the body slot that will be considered as being this body part undergarment.")
                elseif (option == IdsUndergarmentsConcealable[i])
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
        elseif (OptionID == IdConcealingPreventInteract)
            UndergarmentsModule.ConcealingPreventInteract = !UndergarmentsModule.ConcealingPreventInteract
            SetToggleOptionValue(IdConcealingPreventInteract, UndergarmentsModule.ConcealingPreventInteract)
        else
            int i = 0
            bool break = false
            while i < IdsUndergarmentsConcealable.Length && !break
                If OptionID == IdsUndergarmentsConcealable[i]
                    UndergarmentsModule.UndergarmentsConcealable[i] = !UndergarmentsModule.UndergarmentsConcealable[i]
                    SetToggleOptionValue(IdsUndergarmentsConcealable[i], UndergarmentsModule.UndergarmentsConcealable[i])
                    undergarmentsModuleNeedsRefresh = true
                    break = true
                EndIf
                i += 1
            endWhile
        endif
    EndEvent

    Event OnOptionSliderOpen(int OptionID)
        int i = 0
        bool break = false
        while i < IdsUndergarmentsSlots.Length && !break
            If OptionID == IdsUndergarmentsSlots[i]
                SetSliderOptions(Value = UndergarmentsModule.UndergarmentsSlots[i], Default = UndergarmentsModule.UndergarmentsSlots[i], Min = minArmorSlot, Max = maxArmorSlot, Interval = 1)
                break = true
            EndIf
            i += 1
        endWhile
    EndEvent

    Event OnOptionSliderAccept(int optionid, float value)
        int i = 0
        bool break = false
        while i < IdsUndergarmentsSlots.Length && !break
            If OptionID == IdsUndergarmentsSlots[i]
                UndergarmentsModule.UndergarmentsSlots[i] = value as int
                SetSliderOptionValue(IdsUndergarmentsSlots[i], value)
                undergarmentsModuleNeedsRefresh = true
                break = true
            EndIf
            i += 1
        endWhile
    EndEvent

EndState

; Body hair

int IdBHOutfitRestrictAccess
int IdBHDaysForGrowthDefault
int IdBHUndergarmentsIntegration
int[] IdBHAreasPresets
int[] IdBHAreasStages

int BHcurrentAreaIndex
string[] BHcurrentPresets

State BodyHair
    Event OnBeginState()
        IdModuleActive = AddToggleOption("Module active", BodyHairModule.IsModuleStarted())
        IdBHOutfitRestrictAccess = AddToggleOption("Outfit restrict access", BodyHairModule.OutfitRestrictAccess)
        IdBHDaysForGrowthDefault = AddSliderOption("Days for growth",  BodyHairModule.DaysForGrowthDefault)
        IdBHUndergarmentsIntegration = AddToggleOption("Undergarments integration", BodyHairModule.UndergarmentsIntegration)

        AddHeaderOption(BodyHairModule.BodyHairAreas[0])
        AddHeaderOption(BodyHairModule.BodyHairAreas[1])

        IdBHAreasPresets[0] = AddMenuOption("Preset", BodyHairModule.BodyHairAreasPresets[0])
        IdBHAreasPresets[1] = AddMenuOption("Preset", BodyHairModule.BodyHairAreasPresets[0])
    endevent

    Event OnOptionHighlight(int option)
        If (Option == IdModuleActive)
            SetInfoText("Toggle this module on/off.")
        elseif (option == IdBHOutfitRestrictAccess)
            SetInfoText("If active, wearing armor while prevent you from shaving.")
        elseif (option == IdBHDaysForGrowthDefault)
            SetInfoText("Number of days between each growth stage. Does not impact performance, so set to your liking.")
        elseif (option == IdBHUndergarmentsIntegration)
            SetInfoText("If this and 'Outfit restrict access' are active, wearing undergarments will also prevent you from shaving.")
        endif
    EndEvent

    Event OnOptionSelect(Int OptionID)
        if (OptionID == IdModuleActive)
            BodyHairModule.Toggle()
            SetToggleOptionValue(IdModuleActive, BodyHairModule.IsModuleStarted())
        elseif (OptionID == IdBHOutfitRestrictAccess)
            BodyHairModule.OutfitRestrictAccess = !BodyHairModule.OutfitRestrictAccess
            SetToggleOptionValue(IdBHOutfitRestrictAccess, BodyHairModule.OutfitRestrictAccess)
        elseif (OptionID == IdBHUndergarmentsIntegration)
            BodyHairModule.UndergarmentsIntegration = !BodyHairModule.UndergarmentsIntegration
            SetToggleOptionValue(IdBHUndergarmentsIntegration, BodyHairModule.UndergarmentsIntegration)
        endif
    EndEvent

    Event OnOptionSliderOpen(int OptionID)
        if (OptionID == IdBHDaysForGrowthDefault)
            SetSliderOptions(BodyHairModule.DaysForGrowthDefault, BodyHairModule.DaysForGrowthDefault, 0, 30, 1)
        endif
    EndEvent

    Event OnOptionSliderAccept(int optionid, float value)
        if (OptionID == IdBHDaysForGrowthDefault)
            BodyHairModule.DaysForGrowthDefault = value as int
            SetSliderOptionValue(IdBHDaysForGrowthDefault, value)
        endif
    EndEvent

    Event OnOptionMenuOpen(int option)
        int i = 0
        while (i < BodyHairModule.BodyHairAreas.Length)
            if (option == IdBHAreasPresets[i])
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
        BodyHairModule.BodyHairAreasPresets[BHcurrentAreaIndex] = BHcurrentPresets[index]
    EndEvent

EndState

; Utils

Function SetSliderOptions(Float Value, Float Default, Float Min, Float Max, Float Interval)
	SetSliderDialogStartValue(Value)
	SetSliderDialogDefaultValue(Default)
	SetSliderDialogRange(Min, Max)
	SetSliderDialogInterval(Interval)
EndFunction

bool Function IsGeneralPage(string Page)
    return Page == "" || Page == generalPage
EndFunction