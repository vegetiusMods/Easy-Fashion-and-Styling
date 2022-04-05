Scriptname EFSi_ShavingKnifeScript extends ObjectReference  
; TODO Breaking chances ?

EFS2BodyHair Property BodyHairModule  Auto  

Event OnEquipped(Actor akActor) 
    BodyHairModule.Shave(akActor)
EndEvent

