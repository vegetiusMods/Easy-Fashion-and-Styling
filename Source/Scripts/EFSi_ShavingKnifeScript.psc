Scriptname EFSi_ShavingKnifeScript extends ObjectReference  
; TODO Breaking chances ?

EFS2BodyHair Property BodyHairModule  Auto  

Message Property EFS_SelectShavingArea  Auto  

Event OnEquipped(Actor akActor)
    int areaSelected = EFS_SelectShavingArea.Show()

    if (areaSelected > 1)
        return
    elseif (!BodyHairModule.IsModuleStarted())
        Debug.MessageBox("The Body Hair module is disabled.")
        return
    elseif (!BodyHairModule.IsAreaAccessible(akActor, areaSelected))
        Debug.MessageBox("This area is not accessible, it must be uncovered for you to be able to shave.")
        return
    endif
    
    BodyHairModule.Shave(akActor, areaSelected)
EndEvent

