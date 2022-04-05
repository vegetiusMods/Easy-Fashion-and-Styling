Scriptname EFSme_ApplyShavingCreamScript extends ActiveMagicEffect  

EFS2BodyHair Property BodyHairModule  Auto  

SPELL[] Property CreamSpells  Auto  

Potion Property ShavingCreamObject  Auto  

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    if (!BodyHairModule.ApplyCream(akTarget, CreamSpells))
        akCaster.AddItem(ShavingCreamObject, abSilent = True)
    endIf
EndEvent

