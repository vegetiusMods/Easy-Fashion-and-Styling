Scriptname EFSzUtil

function log(string in) global
	MiscUtil.PrintConsole("Easy Fashion and Styling: " + In)
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

; NIO
bool function IsDefaultOrEmptyTexture(string texturePath) global
    return texturePath == "" || StringUtil.Find(texturePath, "efault.dds") > -1
EndFunction

String Function GetAvailableBodyNode(Actor target) global
	Int i = 0
	Int NumSlots = NiOverride.GetNumBodyOverlays()
	String TexPath
	Bool FirstPass = true

	While i < NumSlots
        string bodyOvl = "Body [ovl" + i + "]"

            TexPath = NiOverride.GetNodeOverrideString(target, true, bodyOvl, 9, 0)
            If IsDefaultOrEmptyTexture(TexPath)
                log("Slot " + i + " chosen")
                Return bodyOvl
            EndIf
		i += 1
	EndWhile

	Return ""
EndFunction

Function ApplyOverlay(Actor target, String node, String texture, int tintColor) global
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
    bool female = IsFemale(target)
    NiOverride.AddNodeOverrideString(target, female, Node, 9, 0, "actors\\character\\overlays\\default.dds", false)
	NiOverride.RemoveNodeOverride(target, female, node , 9, 0)
	NiOverride.RemoveNodeOverride(target, female, Node, 7, -1)
	NiOverride.RemoveNodeOverride(target, female, Node, 0, -1)
	NiOverride.RemoveNodeOverride(target, female, Node, 8, -1)
	NiOverride.RemoveNodeOverride(target, female, Node, 2, -1)
	NiOverride.RemoveNodeOverride(target, female, Node, 3, -1)
EndFunction