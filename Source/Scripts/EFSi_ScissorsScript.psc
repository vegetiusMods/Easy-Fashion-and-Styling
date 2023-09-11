Scriptname EFSi_ScissorsScript extends ObjectReference  

EFS3Hair Property HairModule  Auto  

Event OnEquipped(Actor akActor)
    if (HairModule.StartCut(akActor) && Utility.RandomInt(0, 99) < BreakChances)
        Debug.MessageBox("Your scissors broke.")
        akActor.RemoveItem(Scissors)
    endif
EndEvent
Int Property BreakChances  Auto  

MiscObject Property Scissors  Auto  
