Scriptname EFSzUtil

function log(string in, string moduleName = "") global
    if (moduleName != "")
        MiscUtil.PrintConsole("Easy Fashion and Styling: " + moduleName + " module : " + In)
    else
        MiscUtil.PrintConsole("Easy Fashion and Styling: " + In)
    endIf
EndFunction

bool Function IsFemale(Actor target) global
    return target.GetActorBase().GetSex() == 1
EndFunction

; Strings

string Function RemoveJsonExtension(string jsonFileName) global
    if (StringUtil.Find(jsonFileName, ".json") > -1)
        return StringUtil.Substring(jsonFileName, 0, StringUtil.GetLength(jsonFileName) - 5)
    else
        return jsonFileName
    endIf
EndFunction

string Function Escape(String str, string charsToEscape) global
    string[] parts = StringUtil.Split(str, charsToEscape)
    string res = ""
    int i = 0
    while i < parts.length
        res += parts[i]
        i += 1
    endWhile
    return res
EndFunction

; Armors

bool Function HasOneSlot(Armor akArmor, int[] slots) global
    int i = 0
    while (i < slots.Length)
        if (HasSlot(akArmor, slots[i]))
            return true
        endIf
        i += 1
    EndWhile

    return false
EndFunction

bool Function HasOneSlotFromMask(Armor akArmor, int slotMask) global
    return Math.LogicalAnd(akArmor.GetSlotMask(), slotmask) > 0
EndFunction

bool Function HasSlot(Armor akArmor, int slot) global
    return HasSlotMask(akArmor, Armor.GetMaskForSlot(slot))
EndFunction

bool Function HasSlotMask(Armor akArmor, int slotmask) global
    return Math.LogicalAnd(akArmor.GetSlotMask(), slotmask) == slotmask
EndFunction

bool Function HasOneKeyword(Armor akArmor, String[] keywords) global
    int i = 0
    while (i < keywords.Length)
        if (akArmor.HasKeywordString(keywords[i]))
            return true
        endIf
        i += 1
    EndWhile

    return false
EndFunction

; NIO
bool function IsDefaultOrEmptyTexture(string texturePath) global
    return texturePath == "" || StringUtil.Find(texturePath, "efault.dds") > -1
EndFunction

Function ApplyTexture(Actor target, String uniquekey, String texture, int tintColor) global
    string overlayNode = StorageUtil.GetStringValue(target, uniquekey, missing = "")
    if (EFSzUtil.IsDefaultOrEmptyTexture(texture) && overlayNode != "")
        EFSzUtil.log("Texture string is empty or default, removing current overlay")
        EFSzUtil.ClearOverlay(target, overlayNode)
        StorageUtil.UnsetStringValue(target, uniquekey)
    Else
        if (overlayNode == "" || overlayNode == "None")
            overlayNode = EFSzUtil.GetAvailableBodyNode(target)
            if (overlayNode == "")
                Debug.MessageBox("Easy Fashion and Styling was not able to find an available overlay node to apply an override.\nPlease increase the number of available nodes in NiOverride.ini.")
                return
            else
                StorageUtil.SetStringValue(target, uniquekey, overlayNode)
            endif
        endIf
        
        EFSzUtil.log("Applying overlay to node: " + overlayNode)
        EFSzUtil.ApplyOverlay(target, overlayNode, texture, target.GetActorBase().GetHairColor().GetColor())
    endIf
EndFunction

String Function GetAvailableBodyNode(Actor target) global
	Int i = 0
	Int NumSlots = NiOverride.GetNumBodyOverlays()
	Bool FirstPass = true
    string[] reservedNodes = StorageUtil.StringListToArray(target, "EFS_reserved_nio_nodes")

	While i < NumSlots
        string bodyOvl = "Body [ovl" + i + "]"
        if (reservedNodes.Find(bodyOvl) < 0)
            String TexPath = NiOverride.GetNodeOverrideString(target, true, bodyOvl, 9, 0)
            If IsDefaultOrEmptyTexture(TexPath)
                log("Slot " + i + " chosen")
                Return bodyOvl
            EndIf
        endif
        
		i += 1
		If FirstPass && i == NumSlots
			FirstPass = false
			i = 0
		EndIf
	EndWhile

	Return ""
EndFunction

Function ApplyOverlay(Actor target, String node, String texture, int tintColor) global
    StorageUtil.StringListAdd(target, "EFS_reserved_nio_nodes", node, allowDuplicate = false)
    bool female = IsFemale(target)
    NiOverride.AddNodeOverrideString(target, female, node, 9, 0, texture, true)
    Utility.Wait(0.01)
    NiOverride.AddNodeOverrideInt(target, female, node, 7, -1, tintColor, true)
    Utility.Wait(0.01)
    NiOverride.AddNodeOverrideInt(target, female, node, 0, -1, 0, true)
    Utility.Wait(0.01)
    ;NiOverride.AddNodeOverrideFloat(target, female, node, 1, -1, 1.0, true)
    ;Utility.Wait(0.01)
    ; 8 - float - ShaderAlpha
    NiOverride.AddNodeOverrideFloat(target, female, node, 8, -1, 1.0, true)
    Utility.Wait(0.01)
    NiOverride.AddNodeOverrideFloat(target, female, node, 2, -1, 0.0, true)
    Utility.Wait(0.01)
    NiOverride.AddNodeOverrideFloat(target, female, node, 3, -1, 0.0, true)
    NiOverride.ApplyNodeOverrides(target)
EndFunction

Function ClearOverlay(Actor target, String node) global
    ; TODO Try RemoveAllNodeNameOverrides
    bool female = IsFemale(target)
    log(NiOverride.GetNodeOverrideString(target, female, Node, 9, 0))
    log(NiOverride.GetNodeOverrideString(target, female, Node, 9, 1))
    log(NiOverride.GetNodeOverrideString(target, female, Node, 9, 2))
    NiOverride.AddNodeOverrideString(target, female, Node, 9, 0, "actors\\character\\overlays\\default.dds", false)
    if NiOverride.HasNodeOverride(target, female, node, 9, 1)
        NiOverride.AddNodeOverrideString(target, female, node, 9, 1, "actors\\character\\overlays\\default.dds", false)
        Utility.Wait(0.01)
        NiOverride.RemoveNodeOverride(target, female, node, 9, 1)
        Utility.Wait(0.01)
    endif
	NiOverride.RemoveNodeOverride(target, female, node , 9, 0)
	NiOverride.RemoveNodeOverride(target, female, Node, 7, -1)
	NiOverride.RemoveNodeOverride(target, female, Node, 0, -1)
	NiOverride.RemoveNodeOverride(target, female, Node, 8, -1)
	NiOverride.RemoveNodeOverride(target, female, Node, 2, -1)
	NiOverride.RemoveNodeOverride(target, female, Node, 3, -1)
    StorageUtil.StringListRemove(target, "EFS_reserved_nio_nodes", node, allInstances = true)
EndFunction

Function ClearAllFaceNodes(Actor target) global
	Int i = 0
	Int NumSlots = NiOverride.GetNumFaceOverlays()

	While i < NumSlots
        string node = "Face [ovl" + i + "]"
        ClearOverlay(target, node)
        i += 1
    endwhile
    
    NiOverride.ApplyNodeOverrides(target)
EndFunction

; Versioning
int Function GetModVersion() global
    return Get03AlphaVersion()
EndFunction

int Function Get02AlphaVersion() global
    return 1000200
EndFunction

int Function Get03AlphaVersion() global
    return 1000300
EndFunction