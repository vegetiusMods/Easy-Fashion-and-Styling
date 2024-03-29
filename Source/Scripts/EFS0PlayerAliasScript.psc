Scriptname EFS0PlayerAliasScript extends ReferenceAlias  

EFS0MainQuest Property EFSMain Auto  

Event OnPlayerLoadGame()
	EFSMain.Load(firstStart = false)
EndEvent

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
	;EFSzUtil.log("Receiving equip event")
	EFSMain.ObjectEquipped(GetActorRef(), akBaseObject, akReference)
EndEvent

Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
	;EFSzUtil.log("Receiving unequip event")
	EFSMain.ObjectUnequipped(GetActorRef(), akBaseObject, akReference)
EndEvent

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	EFSMain.OnHit(GetActorRef(), akAggressor, akSource, akProjectile, abPowerAttack, abSneakAttack, abBashAttack, abHitBlocked)
EndEvent