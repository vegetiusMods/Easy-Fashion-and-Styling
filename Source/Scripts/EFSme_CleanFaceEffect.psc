Scriptname EFSme_CleanFaceEffect extends ActiveMagicEffect  

Event OnEffectStart(Actor akTarget, Actor akCaster)
    EFSzUtil.log("Clean face cast")
    if (akTarget)
        EFSzUtil.ClearAllFaceNodes(akTarget)
    else
        EFSzUtil.ClearAllFaceNodes(akCaster)
    endif
EndEvent