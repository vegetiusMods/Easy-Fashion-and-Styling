Scriptname EFS1Undergarments extends EFSzModule  
; TODO LIST
; MCM interactions
; Ignore kw list (DD)
; TODO Breaking chances ?
String[] Property UndergarmentsList  Auto  
Int[] Property UndergarmentsSlots  Auto  

Bool[] Property UndergarmentsConcealable  Auto  
bool Property ConcealingPreventInteract = true Auto

; JSON
string jmainFile = "config"
string jignoreKeywordsKey = "ignoreKeywords"
string jliveSaveFile = "tmp"
string jconcealedArmorsKey = "concealedArmors"
string jconcealedArmorsSlotsKey = "concealedArmorsSlots"

Event OnInit()
    ModuleName = "Undergarments"
EndEvent

State Started

    Function Toggle()
        GoToState("Stopping")
    EndFunction

    Function DoRefresh()
        EFSzUtil.log("Refreshing undergarments")
        int i = 0

        while (i < Main.GetManagedActors().Length)
            Actor player = Main.GetManagedActors()[i]
            bool concealingWorn = Main.IsConcealingWorn(player)

            EFSzUtil.log("Concealing worn: " + concealingWorn)
            ; Reveal all conceled
            ; Armors concealed before reload will still be invisible
            RevealAll(player, refreshEquip = !concealingWorn)

            ; Check if concealed and if so conceal all
            if (concealingWorn)
                ConcealAll(player)
            endif

            i += 1
        endwhile
    EndFunction

    Function ObjectEquipped(Actor target, Form akBaseObject, ObjectReference akReference)
        ; Check if masking
        if (Main.IsConcealing(akBaseObject))
            EFSzUtil.log("Equipped a concealing armor")
            if (ConcealAll(target, RefreshEquip = false))
                RefreshEquip(target, akBaseObject)
            endif
        elseif (IsConcealable(akBaseObject) && Main.IsConcealingWorn(target) && !IsConcealed(akBaseObject))
            If (ConcealingPreventInteract)
                EFSzUtil.log("Equipping concealable item but concealing armor prevents it")
                target.UnequipItem(akBaseObject, abSilent = true)
                Debug.MessageBox("Your worn outfit prevents you from putting on this undergarment")
            else
                ; Else check if hideable
                EFSzUtil.log("Equipping concealable item while wearing concealing armor, concealing")
                RevealAllWithOneCommonSlotAndUnequip(target, akBaseObject as Armor)
                Conceal(target, akBaseObject as Armor)
            Endif
        elseif (HasConcealableSlot(akBaseObject))
            RevealAllWithOneCommonSlotAndUnequip(target, akBaseObject as Armor)
        EndIf
    EndFunction

    Function ObjectUnequipped(Actor target, Form akBaseObject, ObjectReference akReference)
        if (IsConcealed(akBaseObject) && !target.IsEquipped(akBaseObject))
            If (ConcealingPreventInteract && Main.IsConcealingWorn(target))
                target.EquipItem(akBaseObject, abSilent = true)
                Debug.MessageBox("Your worn outfit prevents you from removing this undergarment.")
            Else
                EFSzUtil.log("Unequipping concealed item, revealing")
                Reveal(target, akBaseObject as Armor)
            EndIf
        elseif (Main.IsConcealing(akBaseObject) && !Main.IsConcealingWorn(target))
            EFSzUtil.log("Unequipping concealing armor, revealing all")
            RevealAll(target)
        elseif (IsConcealable(akBaseObject) && Main.IsConcealingWorn(target) && !IsConcealed(akBaseObject))
            Conceal(target, akBaseObject as Armor, false)
            target.EquipItem(akBaseObject, abSilent = true)
        endif
    EndFunction

    ; Only checks for visible undergarments
    bool Function IsVisibleUndergarmentWorn(Actor target, string undergarmentType)
        if (undergarmentType == "")
            return false
        endif

        int undergarmentTypeIndex = UndergarmentsList.Find(undergarmentType)
        if (undergarmentTypeIndex < 0)
            EFSzUtil.log("Checking if target is wearing an undergarment type, but said type is unknown: " + undergarmentType)
            return false
        endIf

        return target.GetWornForm(Armor.GetMaskForSlot(UndergarmentsSlots[undergarmentTypeIndex]))
    EndFunction
EndState

Function LoadModule(int loadedVersion)
    ; Should always refresh on load
    FlaggedForRefresh = true

    if (loadedVersion < EFSzUtil.Get02AlphaVersion())
        UndergarmentsList = new string[5]
        UndergarmentsList[0] = "Breast"
        UndergarmentsList[1] = "Chest"
        UndergarmentsList[2] = "Belt"
        UndergarmentsList[3] = "Crotch"
        UndergarmentsList[4] = "Legs"
    
        UndergarmentsSlots = new int[5]
        UndergarmentsSlots[0] = 46
        UndergarmentsSlots[1] = 58
        UndergarmentsSlots[2] = 48
        UndergarmentsSlots[3] = 52
        UndergarmentsSlots[4] = 53
    
        UndergarmentsConcealable = new bool[5]
        UndergarmentsConcealable[0] = true
        UndergarmentsConcealable[1] = true
        UndergarmentsConcealable[2] = true
        UndergarmentsConcealable[3] = false
        UndergarmentsConcealable[4] = false

        FlaggedForRefresh = false
        
        Toggle()
    endif
EndFunction

Function CleanModule()
    int i = 0
    Actor[] managedActs = Main.GetManagedActors()
    while (i < managedActs.Length)
        RevealAll(managedActs[i])
        i += 1
    EndWhile
EndFunction

bool Function IsConcealable(Form obj)
    return HasConcealableSlot(obj) && !EFSzUtil.HasOneKeyword(obj as Armor, GetIgnoreKeywords())
EndFunction

bool Function HasConcealableSlot(Form obj)
    Armor arm = obj as Armor
    if (arm)
        While (i < UndergarmentsList.Length)
            if (UndergarmentsConcealable[i])
                int slotmask = Armor.GetMaskForSlot(UndergarmentsSlots[i])
                if (EFSzUtil.HasSlotMask(arm, slotmask))
                    EFSzUtil.log("Object has concealable slot")
                    return true
                EndIf
            endif
            i += 1
        EndWhile
    endIf

    int i = 0

    return false
EndFunction

bool Function IsConcealed(Form obj)
    return JSonUtil.FormListFind(GetFilePath(jliveSaveFile), jconcealedArmorsKey, obj) > -1
EndFunction

Function Conceal(Actor target, Armor akArmor, bool refreshEquip = true)
    int i = 0
    int slotMaskToRemove = 0
    bool break = false

    While (!break && i < UndergarmentsList.Length)
        
        if (UndergarmentsConcealable[i])
            int slotmask = Armor.GetMaskForSlot(UndergarmentsSlots[i])
            if (EFSzUtil.HasSlotMask(akArmor, slotmask) && !Main.IsConcealing(akArmor))
                slotMaskToRemove = akArmor.GetSlotMask()
                break = true
            EndIf
        endif

        i += 1
    EndWhile

    ; Reveal armor on same slot in case of repalcement while concealed
    Form[] concealedArmors = GetConcealedArmors()
    i = 0

    while (i < concealedArmors.Length)
        if (target.IsEquipped(concealedArmors[i]) &&  Math.LogicalAnd(GetConcealedArmorOriginalSlotmask(concealedArmors[i]), slotMaskToRemove) > 0)
            target.UnequipItem(concealedArmors[i])
        endif

        i += 1
    endWhile

    if (slotMaskToRemove > 0)
        Hide(akArmor)
        if (refreshEquip)
            RefreshEquip(target, akArmor)
        EndIf
    endif
EndFunction

; Returns true if at least one object was concealed, else false
bool Function ConcealAll(Actor target, bool refreshEquip = true)
    int i = 0
    bool concealed = false

    While (i < UndergarmentsList.Length)
        if (UndergarmentsConcealable[i])
            int slotmask = Armor.GetMaskForSlot(UndergarmentsSlots[i])
            Armor toConceal = target.GetWornForm(slotmask) as Armor
            if (toConceal && !Main.IsConcealing(toConceal))
                EFSzUtil.log("Found concealable armor " + toConceal + " in slot " + UndergarmentsSlots[i] + ", concealing")
                Conceal(target, toConceal, refreshEquip = refreshEquip)
                concealed = true
            endIf
        endIf

        i += 1
    endWhile

    return concealed
EndFunction

Function Reveal(Actor target, Armor akArmor, bool refreshEquip = true)
    Unhide(akArmor)
    EFSzUtil.log("Revealing item")
    if (target.IsEquipped(akArmor))
        if (refreshEquip)
            EFSzUtil.log("Item is worn, refreshing equip")
            RefreshEquip(target, akArmor)
        endif
    endIf
EndFunction

Function RevealAll(Actor target, bool refreshEquip = true)
    Form[] concealedArmors = GetConcealedArmors()

    int i = 0

    while (i < concealedArmors.Length)            
        EFSzUtil.log("Found worn concealed item, revealing")
        Reveal(target, concealedArmors[i] as Armor, refreshEquip)
        i += 1
    endWhile
EndFunction

Function RevealAllWithOneCommonSlotAndUnequip(Actor target, Armor armorRef)
    Form[] concealedArmors = GetConcealedArmors()

    int i = 0

    while (i < concealedArmors.Length)
        Armor concealed = concealedArmors[i] as Armor
        int concealedArmorOriginalSlotmask = GetConcealedArmorOriginalSlotmask(concealed)
        if (target.IsEquipped(concealed) && EFSzUtil.HasOneSlotFromMask(armorRef, concealedArmorOriginalSlotmask))
            EFSzUtil.log("Found worn concealed item, revealing and unequipping")
            Reveal(target, concealed, RefreshEquip = false)
            target.UnequipItem(concealed)
        endif

        i += 1
    endWhile
EndFunction


string[] Function GetIgnoreKeywords()
    return JSonUtil.StringListToArray(GetFilePath(jmainFile), jignoreKeywordsKey)
EndFunction

Form[] Function GetConcealedArmors()
    return JSonUtil.FormListToArray(GetFilePath(jliveSaveFile), jconcealedArmorsKey)
EndFunction

int Function GetConcealedArmorOriginalSlotmask(Form akArmor)
    int index = JSonUtil.FormListFind(GetFilePath(jliveSaveFile), jconcealedArmorsKey, akArmor)
    if (index > -1)
        return JSonUtil.IntListGet(GetFilePath(jliveSaveFile), jconcealedArmorsSlotsKey, index)
    endIf
    return 0
EndFunction

Function Hide(Armor akArmor)
    int slotmask = akArmor.GetSlotMask()
    JsonUtil.FormListAdd(GetFilePath(jliveSaveFile), jconcealedArmorsKey, akArmor)
    JsonUtil.IntListAdd(GetFilePath(jliveSaveFile), jconcealedArmorsSlotsKey, slotmask)
    JsonUtil.Save(GetFilePath(jliveSaveFile))
    akArmor.RemoveSlotFromMask(slotmask)
EndFunction

Function Unhide(Armor akArmor)
    int index = JsonUtil.FormListFind(GetFilePath(jliveSaveFile), jconcealedArmorsKey, akArmor)
    if (index > -1)
        int originalSlotmaks = JSonUtil.IntListGet(GetFilePath(jliveSaveFile), jconcealedArmorsSlotsKey, index)
        JsonUtil.FormListRemoveAt(GetFilePath(jliveSaveFile), jconcealedArmorsKey, index)
        JsonUtil.IntListRemoveAt(GetFilePath(jliveSaveFile), jconcealedArmorsSlotsKey, index)
        JsonUtil.Save(GetFilePath(jliveSaveFile))
        akArmor.AddSlotToMask(originalSlotmaks)
    endif
EndFunction

Function RefreshEquip(Actor target, Form item)
    target.UnequipItem(item, abSilent = true)
    target.EquipItem(item, abSilent = true)
EndFunction

bool Function IsVisibleUndergarmentWorn(Actor target, string undergarmentType)
    return false
EndFunction