Scriptname EFS0MainQuest extends Quest  

; Hello, I'm a stupidly complex and configurable but easy to use mod to simulate body hair growth.
; Please love me

;Properties
ReferenceAlias Property PlayerAlias Auto

; Modules
EFS1Undergarments property UndergarmentsModule Auto

Actor Player

; Init and mod lifecycle
Event OnInit()
    Player = PlayerAlias.GetActorRef()

    UndergarmentsModule.Toggle()

    Load()
EndEvent

Function Load()
    UndergarmentsModule.LoadModule()
    EFSzUtil.log("Started")
EndFunction

Function ObjectEquipped(Actor target, Form akBaseObject, ObjectReference akReference)
    UndergarmentsModule.ObjectEquipped(target, akBaseObject, akReference)
EndFunction

Function ObjectUnequipped(Actor target, Form akBaseObject, ObjectReference akReference)
    UndergarmentsModule.ObjectUnequipped(target, akBaseObject, akReference)
EndFunction