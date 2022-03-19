Scriptname EFSme_ApplyShavingCreamScript extends ActiveMagicEffect  

EFS2BodyHair Property BodyHairModule  Auto  

SPELL[] Property CreamSpells  Auto  

Message Property EFS_SelectShavingArea  Auto  

Potion Property ShavingCreamObject  Auto  

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    int areaSelected = EFS_SelectShavingArea.Show()

    if (areaSelected >= 0 && areaSelected < 2)
        if (!BodyHairModule.IsModuleStarted())
            Debug.MessageBox("The Body Hair module is disabled.")
        elseif (!BodyHairModule.IsAreaAccessible(akTarget, areaSelected))
            Debug.MessageBox("This area is not accessible, it must be uncovered for you to be able to apply cream.")
        else
            BodyHairModule.ApplyCream(akTarget, areaSelected, CreamSpells[areaSelected])
            return
        endif
    endif

    akCaster.AddItem(ShavingCreamObject, abSilent = True)
EndEvent

