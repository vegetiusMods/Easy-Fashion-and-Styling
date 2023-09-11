Scriptname EFSi_ShavingKnifeScript extends ObjectReference  
; TODO Breaking chances ?

EFS2BodyHair Property BodyHairModule  Auto  

Event OnEquipped(Actor akActor) 
    if (BodyHairModule.Shave(akActor) && Utility.RandomInt(0, 99) < BreakChances)
        Debug.MessageBox("Your shaving knife dulled out.")
        akActor.RemoveItem(Knife)
    endif
EndEvent


Int Property BreakChances  Auto  

MiscObject Property Knife  Auto  
