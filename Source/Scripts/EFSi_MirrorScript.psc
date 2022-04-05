Scriptname EFSi_MirrorScript extends ObjectReference  

Message Property EFS_SelectMirrorCheck  Auto  

EFS2BodyHair Property BodyHairModule  Auto  

Event OnEquipped(Actor akActor)
    int result = EFS_SelectMirrorCheck.Show()
    if (result == 0)
        Debug.MessageBox(BodyHairModule.GetStatus(akActor))
    elseif (result == 1)
        Debug.MessageBox(HairModule.GetStatus(akActor))
    endif
EndEvent


EFS3Hair Property HairModule  Auto  
