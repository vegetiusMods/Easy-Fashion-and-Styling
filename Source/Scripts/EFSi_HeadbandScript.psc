Scriptname EFSi_HeadbandScript extends ObjectReference  

Event OnEquipped(Actor akActor)
    if (HairModule.StartTie(akActor))
        akActor.RemoveItem(EFS_Hairband)
    endif
EndEvent
MiscObject Property EFS_Hairband  Auto  

EFS3Hair Property HairModule  Auto  
