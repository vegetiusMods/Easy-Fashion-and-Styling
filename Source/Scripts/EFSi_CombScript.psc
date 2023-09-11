Scriptname EFSi_CombScript extends ObjectReference  

EFS3Hair Property HairModule  Auto  

Event OnEquipped(Actor akActor)
    bool success = false

    if (akActor.GetItemCount(EFS_Hairband) > 0)
        int result = EFS_CombOrTie.Show()
        if (result == 0)
            success = HairModule.StartBrush(akActor)
        elseif (result == 1)
            success = HairModule.StartCombAndTie(akActor)
            if(success)
                akActor.RemoveItem(EFS_Hairband)
            endIf
        endif
    else
        success = HairModule.StartBrush(akActor)
    endif

    if success && Utility.RandomInt(0, 99) < BreakChances
        Debug.MessageBox("Your comb has broken!")
        akActor.RemoveItem(Comb)
    endif
EndEvent
MiscObject Property EFS_Hairband  Auto  

Message Property EFS_CombOrTie  Auto  

Int Property BreakChances  Auto  

MiscObject Property Comb  Auto  
