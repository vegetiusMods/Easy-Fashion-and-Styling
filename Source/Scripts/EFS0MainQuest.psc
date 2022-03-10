Scriptname EFS0MainQuest extends Quest  

; Properties
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
int lastVersion
EFSzModule[] modules

; Init and mod lifecycle
Event OnInit()
    Load()
EndEvent

Function Load()
    int currentVer = 1000200

    ; 0.2.Alpha BodyHair + Undergarments
    if (lastVersion < 1000200)
        ManagedActors = new Actor[1]
        ManagedActors[0] = PlayerAlias.GetActorRef()

        modules = new EFSzmodule[2]
        modules[0] = UndergarmentsModule
        modules[1] = BodyHairModule

        OnSleepTrigger = true
        OnEquipmentChangeTrigger = false

        UndergarmentsModule.Toggle()
        BodyHairModule.Toggle()
    endif 

    LoadAll(lastVersion)

    lastVersion = currentVer
    
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