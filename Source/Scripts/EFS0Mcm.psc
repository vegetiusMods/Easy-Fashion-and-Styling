Scriptname EFS0Mcm extends SKI_ConfigBase

EFS1Undergarments Property UndergarmentsModule Auto

; Pages
string generalPage = "General"
string undergarmentsPage = "Undergarments"

; Refresh
; There is prolly a better solution, but I'll wait at least a second module to come up with it to avoid over ingeniering
bool undergarmentsModuleNeedsRefresh

; Consts
int minArmorSlot = 30
int maxArmorSlot = 61

event OnConfigOpen()
    Pages = new string[2]
    Pages[0] = generalPage
    Pages[1] = undergarmentsPage

    undergarmentsModuleNeedsRefresh = false
EndEvent

Event OnPageReset(String Page)
    if (Page == "")
        Page = "General"
    endif
	
	GoToState(Page)
endEvent



event OnConfigClose()
    if (undergarmentsModuleNeedsRefresh)
        UndergarmentsModule.RefreshModule()
    endif
endEvent

; General
State General
EndState

; Undergraments

int IdModuleActive
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
        if CurrentPage == undergarmentsPage
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
        endIf
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