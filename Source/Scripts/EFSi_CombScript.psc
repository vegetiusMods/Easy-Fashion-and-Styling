Scriptname EFSi_CombScript extends ObjectReference  

EFS3Hair Property HairModule  Auto  

Event OnEquipped(Actor akActor)
    if (akActor.GetItemCount(EFS_Hairband) > 0)
        int result = EFS_CombOrTie.Show()
        if (result == 0)
            HairModule.StartBrush(akActor)
        elseif (result == 1)
            if(HairModule.StartCombAndTie(akActor))
                akActor.RemoveItem(EFS_Hairband)
            endIf
        endif
    else
        HairModule.StartBrush(akActor)
    endif
EndEvent
MiscObject Property EFS_Hairband  Auto  

Message Property EFS_CombOrTie  Auto  
