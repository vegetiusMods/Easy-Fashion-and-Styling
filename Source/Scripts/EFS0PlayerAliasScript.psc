Scriptname EFS0PlayerAliasScript extends ReferenceAlias  

EFS0MainQuest Property EFSMain Auto  

Event OnPlayerLoadGame()
	EFSMain.Load()
EndEvent

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
	;EFSzUtil.log("Receiving equip event")
	; FIXME
	EFSMain.ObjectEquipped(Game.GetPlayer(), akBaseObject, akReference)
EndEvent

Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
	;EFSzUtil.log("Receiving unequip event")
	; FIXME
	EFSMain.ObjectUnequipped(Game.GetPlayer(), akBaseObject, akReference)
EndEvent