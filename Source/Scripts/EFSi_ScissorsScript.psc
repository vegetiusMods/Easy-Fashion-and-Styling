Scriptname EFSi_ScissorsScript extends ObjectReference  

EFS3Hair Property HairModule  Auto  

Event OnEquipped(Actor akActor)
    HairModule.StartCut(akActor)
EndEvent