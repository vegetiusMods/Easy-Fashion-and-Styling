Scriptname EFS3Hair extends EFSzModule  

; Properties
Int Property DaysForGrowthBase  Auto  
Bool Property ProgressiveGrowth  Auto  

; Constants
int hairHeadPartIndexSE = 3 ; Would be different for LE, see the CK wiki

string sLastUpdateDayKey = "EFS_HS_LastUpdateDay"
string sCurrentAreaStageKey = "EFS_HS_CurrentAreaStage"
string sCurrentTypeKey = "EFS_HS_CurrentType"
string sCurrentCategoryKey = "EFS_HS_CurrentCategory"
string sCurrentStyleKey = "EFS_HS_CurrentStyle"
string sNaturalhairColorKey = "EFS_HS_NaturalHairColor"

string typesFolder = "Types/"
string typeConfigFileName = "config"

string jLengthKey = "length"
string jNaturalKey = "default"
string jhairdosKey = "hairdos"

; Shaving menu
string chooseTypeMsg = "[Choose a type]"
string chooseLengthMsg = "[Choose a length]"
string chooseHairstyleMsg = "[Choose a hairstyle]"
string lastButtonPre = "[Last: "
string lastButtonSu = "]"
string cancelBtn = "[Cancel]"
string stringListSeparator = ":::"
string combedCat = "Combed"
string tiedCat = "Tied"
string combedAndTiedCat = "Combed & Tied"

int lastCutLength = -1

Function LoadModule(int loadedVersion)
    if (loadedVersion < EFSzUtil.Get03AlphaVersion() && !IsModuleStarted())
        Log("First loading")
        ProgressiveGrowth = true
        DaysForGrowthBase = 0
        
        Toggle()
    endif

    RegisterForSleep()
EndFunction

State Started

    Function Toggle()
        GoToState("Stopping")
    EndFunction

    Function DoRefresh()

    EndFunction

    Event OnSleepStop(bool abInterrupted)
        if (Main.OnSleepTrigger)
            UpdateGrowthAll()
        endif
    EndEvent    

    Function ObjectUnequipped(Actor target, Form akBaseObject, ObjectReference akReference)
        if (Main.OnEquipmentChangeTrigger)
            Armor arm = akBaseObject as Armor
            if (arm && EFSzUtil.HasSlot(arm, 31))
                UpdateGrowth(target)
            endif
        endif
    EndFunction

    Function UpdateGrowthAll()
        int i = 0
    
        while (i < Main.GetManagedActors().Length)
            UpdateGrowth(Main.GetManagedActors()[i])
    
            i += 1
        EndWhile
    EndFunction
    
    Function UpdateGrowth(Actor target)
        if (!target.IsOnMount())
            int gameDaysPassedValue = Main.GameDaysPassed.GetValueInt()
    
            int stage = GetCurrentStage(target)
            int daysPassed = gameDaysPassedValue - StorageUtil.GetIntValue(target, sLastUpdateDayKey, missing = 0)
            int daysForGrowth = DaysForGrowthBase
    
            if (ProgressiveGrowth)
                daysForGrowth += stage
            endif
    
            if (daysPassed >= daysForGrowth)
                EFSzUtil.log(daysPassed + " days passed, it is greater than or equal to " + daysForGrowth + ", hair has grown")
                StorageUtil.SetIntValue(target, sLastUpdateDayKey, gameDaysPassedValue)
    
                string currentType = GetCurrentType(target)
                string currentCategory = GetCurrentCategory(target)
                string currentStyle = GetCurrentStyle(target)
                string newCategory = currentCategory
                int maxStage = GetMaxStage(target)
                EFSzUtil.log("Current: " + stage + " Max: " + maxStage)
                
                if(stage < maxStage)
                    stage += 1
                    HeadPart hairStyle = GetHairPart(target, currentType, currentCategory, currentStyle, stage)
                    if (!hairStyle)
                        hairStyle = GetDefaultHairPart(target, stage)
                        newCategory = jNaturalKey
                    endif
                    EFSzUtil.log("Style : " + GetCurrentTypeFolder(target) + " Key: " + jNaturalKey)
                    EFSzUtil.log("New stage: " + stage + " Hair: " + hairStyle)
                    
                    ApplyHairStyle(target, hairStyle, stage)
                    if (currentCategory == newCategory)
                        Debug.Notification("You notice your hair has grown")
                    else
                        Debug.Notification("Your hair has grown wild to you default style")
                        SetCurrentCategory(target, newCategory)
                        ClearCurrentStyle(target)
                    endif
                    
                endif
            else
                EFSzUtil.log(daysPassed + " days passed, it is lesser than " + daysForGrowth + ", no hair growth")
            endif
        endif
    EndFunction

    bool Function StartCut(Actor target)
        if (target.IsOnMount())
            Debug.MessageBox("Your can't be mounted to do this.")
            return false
        elseif (Main.HasHandsTied(target))
            return false
        elseif (Main.IsHeadConcealingWorn(target))
            Debug.MessageBox("Your hair is not accessible, please remove any headwear.")
            return false
        elseif(!StyleAllowCut(target))
            Debug.MessageBox("Your current style does not allow cutting your hair, please unbraid/untie your hair first.")
            return false
        endif
        
        int currentStage = GetCurrentStage(target)
        int minStageForCut = 2
    
        if (currentStage < minStageForCut)
            Debug.MessageBox("Your hair is too short to be cut.")
            return false
        endif
    
        Game.DisablePlayerControls(true, true, true, false, true, true, true, true)
        Game.ForceThirdPerson()
    
        bool lastLengthFound = lastCutLength > 0
        UIListMenu cutMenu = uiextensions.GetMenu("UIListMenu") as UIListMenu
        cutMenu.AddEntryItem(chooseLengthMsg)
    
        string currentTypeConfig = GetCurrentTypeConfig(target)
        string[] lengths = GetLengths(currentTypeConfig)
        string[] styleHairDos = JsonUtil.StringListToArray(currentTypeConfig, jNaturalKey)
    
        ; Last
        if (lastLengthFound)
            cutMenu.AddEntryItem(lastButtonPre + lengths[lastCutLength] + lastButtonSu)
        endif
    
        ; Others
        int i = 1
    
        While i < currentStage
            cutMenu.AddEntryItem(lengths[i])
            i += 1
        EndWHILE
    
        cutMenu.AddEntryItem(cancelBtn)
    
        cutMenu.OpenMenu(none)
        int desiredLength = -1
        string desiredLengthName = cutMenu.GetResultString()
    
        if StringUtil.Find(desiredLengthName, lastButtonPre) > -1
            desiredLength = lastCutLength
        else
            desiredLength = lengths.Find(desiredLengthName)
        endIf
    
        if (desiredLength < 0)
            Game.EnablePlayerControls()
            return false
        endif

        bool messedUp = false
        HeadPart desiredHairPart = GetCurrentStyleHairPart(target, desiredLength)
        if (!desiredHairPart)
            desiredHairPart = GetDefaultHairPart(target, desiredLength)
            messedUp = true
        endif
    
        ; Preview
        bool preview = (Main.EFS_PreviewAsk.Show() == 0)
        bool previewConfirm = false
        HeadPart currentHairDo = GetCurrentHair(target.GetActorBase())

        if (preview)
            SetHair(target, desiredHairPart)
    
            Utility.Wait(Main.PreviewDur)
            previewConfirm = Main.EFS_PreviewConfirm.Show() == 0
    
            SetHair(target, currentHairDo)
        endIf
    
        ; Actual cut
        if (preview && !previewConfirm)
            Game.EnablePlayerControls()
            return false
        endif

        ; Shaving
        Idle shavingIddle = JsonUtil.GetFormValue(GetConfigFile(target), "cutidle") as Idle
        If target.IsWeaponDrawn()
            target.SheatheWeapon()
            Utility.Wait(1.500000)
        Else
            Utility.Wait(0.200000)
        EndIf
        
        target.PlayIdle(shavingIddle)
        EFSCut.Play(target)
        Utility.Wait(1.0)
        EFSCut.Play(target)
        ApplyHairStyle(target, desiredHairPart, desiredLength)
        Utility.Wait(1.0)
        EFSCut.Play(target)
        Utility.Wait(4.0)
        target.PlayIdle(Main.IdleStop)
     
        if (!messedUp)
            Debug.Notification("You have cut your hair")
        else
            Debug.Notification("Your cut messed your style to your your default one")
            SetCurrentCategory(target, jNaturalKey)
            ClearCurrentStyle(target)
        endif
    
        Utility.Wait(0.500000)
    
        Game.EnablePlayerControls()
        return true
    EndFunction
    
    bool Function StartStyling(Actor target, string category)
        if (target.IsOnMount())
            Debug.MessageBox("Your can't be mounted to do this.")
            return false
        elseif (Main.HasHandsTied(target))
            return false
        elseif (Main.IsHeadConcealingWorn(target))
            Debug.MessageBox("Your hair is not accessible, please remove any headwear.")
            return false
        endif
    
        ; TODO add specific categories checks
    
        Game.DisablePlayerControls(true, true, true, false, true, true, true, true)
        Game.ForceThirdPerson()
    
        int currentStage = GetCurrentStage(target)
        string currentCategory = GetCurrentCategory(target)
    
        int stylesCount = 0
        UIListMenu stylesMenu = uiextensions.GetMenu("UIListMenu") as UIListMenu
    
        ; Default style
        stylesMenu.AddEntryItem(jNaturalKey)
        stylesCount += 1
    
        ; Get the available brushed style
        
        string CategoryFolder = GetCurrentTypeCategoryFolder(target, category)
        string[] styles = JsonUtil.JsonInFolder(CategoryFolder)
    
        Log(styles)
        
        int i = 0
        while i < styles.Length
            if (JsonUtil.StringListGet(CategoryFolder + styles[i], jhairdosKey, currentStage) != "")
                stylesMenu.AddEntryItem(EFSzUtil.RemoveJsonExtension(styles[i]))
                stylesCount += 1
            endIf
            i += 1
        endWhile
    
        ; If default and no style available we stop
        if (currentCategory == jNaturalKey && stylesCount == 1)
            Debug.MessageBox("No matching style is available for your hair length.")
            Game.EnablePlayerControls()
            return false
        endIf
    
        stylesMenu.AddEntryItem(cancelBtn)
    
        stylesMenu.OpenMenu(none)
        string desiredStyle = stylesMenu.GetResultString()
    
        if desiredStyle == cancelBtn || desiredStyle == chooseHairstyleMsg
            Game.EnablePlayerControls()
            return false
        endIf
    
        Log(desiredStyle)
        Log(desiredHairPart)
        HeadPart desiredHairPart = GetCurrentTypeHairPart(target, category, desiredStyle, currentStage)
        if (!desiredHairPart)
            Debug.MessageBox("Easy body hair was unable to find the corresponding hairdo, please check the configs file.")
            Game.EnablePlayerControls()
            return false
        endif
    
         ; Preview
         HeadPart currentHairDo = GetCurrentHair(target.GetActorBase())
         bool preview = (Main.EFS_PreviewAsk.Show() == 0)
         bool previewConfirm = false
    
         if (preview)
             SetHair(target, desiredHairPart)
    
             Utility.Wait(Main.PreviewDur)
             previewConfirm = Main.EFS_PreviewConfirm.Show() == 0
    
             SetHair(target, currentHairDo)
         endIf
    
         ; Actual cut
         if (preview && !previewConfirm)
            Game.EnablePlayerControls()
            return false
         endIf
    
             ; Shaving
         Idle shavingIddle = JsonUtil.GetFormValue(GetConfigFile(target), "cutidle") as Idle
        
         If target.IsWeaponDrawn()
             target.SheatheWeapon()
             Utility.Wait(1.500000)
         Else
             Utility.Wait(0.200000)
         EndIf
         
         target.PlayIdle(shavingIddle)
         EFSShaving.Play(target)
         Utility.Wait(1.0)
         EFSShaving.Play(target)
         ApplyHairStyle(target, desiredHairPart, currentStage)
         SetCurrentCategory(target, category)
         SetCurrentStyle(target, desiredStyle)
         Utility.Wait(1.0)
         EFSShaving.Play(target)
         Utility.Wait(4.0)
         target.PlayIdle(Main.IdleStop)
    
         Debug.Notification("Your have styled your hair")
    
         Utility.Wait(0.500000)
    
         Game.EnablePlayerControls()
         return true
    EndFunction
    
    String Function GetStatus(Actor target)
        int gameDaysPassedValue = Main.GameDaysPassed.GetValueInt()
        string statusMessage = "--- Hair ---"
        statusMessage += "\nHair style: " + GetCurrentHairName(target.GetActorBase())
        statusMessage += "\nType: " + GetCurrentType(target)
        statusMessage += "\nStyle: " + GetCurrentCategory(target)
        statusMessage += "\nSub Style: " + GetCurrentStyle(target)
        int stage = GetCurrentStage(target)
        int maxStage = GetMaxStage(target)
        string lenghtName = GetLengthName(target, stage)
        statusMessage += "\nLength: " + lenghtName + " (" + stage + " on " + maxStage + ")"

        return statusMessage
    EndFunction
EndState

Function ScanAll()
    int i = 0
    while (i < Main.GetManagedActors().Length)
        ScanInitActor(Main.GetManagedActors()[i])
        i += 1
    EndWhile
EndFunction

; Find the actor hair type from the current hair
; Stores the current hair color as natural hair color
Function ScanInitActor(Actor target)
    Debug.MessageBox("Easy Body Hair is scanning the actor to determine its starting hair data, it can take some time so please wait until you get the confirmation message.")

    int found = 0
    string hairTypesFolder = GetHairTypesFolder(target, relative = false)
    string[] types = MiscUtil.FoldersInFolder(hairTypesFolder)
    string currentHairName = GetCurrentHairName(target.GetActorBase())
    string[] categories = new string[3]
    categories[0] = combedCat
    categories[1] = tiedCat
    categories[2] = combedAndTiedCat
    string foundTypes = ""
    string foundCategories = ""
    string foundStyles = ""
    string foundStages = ""
    int i = 0

    Log(currentHairName)
    Log(hairTypesFolder)
    Log(types)

    while i < types.Length
        
        bool break = false

        ; Scan natural
        string[] hairDos = JsonUtil.StringListToArray(GetTypeConfig(target, types[i]), jNaturalKey)
        int foundIndex = hairDos.Find(currentHairName)
        if (foundIndex > -1)
            found += 1
            foundTypes += types[i] + stringListSeparator
            foundCategories += jNaturalKey + stringListSeparator
            foundStyles += "none" + stringListSeparator
            foundStages += foundIndex + stringListSeparator
            break = true
        endif

        ; TODO scan other categories
        int j = 0
        string typeFolder = GetTypeFolder(target, types[i])
        while j < categories.Length && !break
        string categoryFolder = typeFolder + categories[j] + "/"
            string[] styles = JsonUtil.JsonInFolder(categoryFolder)
            int k = 0
            while k < styles.Length && !break
                hairDos = JsonUtil.StringListToArray(categoryFolder + styles[k], jhairdosKey)
                foundIndex = hairDos.Find(currentHairName)
                if (foundIndex > -1)
                    found += 1
                    foundTypes += types[i] + stringListSeparator
                    foundCategories += categories[j] + stringListSeparator
                    foundStyles += EFSzUtil.RemoveJsonExtension(styles[k]) + stringListSeparator
                    foundStages += foundIndex + stringListSeparator
                    break = true
                endif
                k += 1
            endwhile

            j += 1
        endWhile

        i += 1
    endWhile

    ; Natural hair color, will be used eventually
    StorageUtil.SetIntValue(target, sNaturalhairColorKey, target.GetActorBase().GetHairColor().GetColor())
    
    if (found > 0)
        int selectedType = 0
        Log("Found type: " + foundTypes)
        Log("Found categories: " + foundCategories)
        Log("Found style: " + foundStyles)
        Log("Found stage: " + foundStages)
        string[] possibleTypes = StringUtil.Split(foundTypes, stringListSeparator)

        if (found > 1)
            Debug.MessageBox("Easy Body Hair has found several hair Types that could match the current hair style, please select one.")
            UIListMenu typesMenu = uiextensions.GetMenu("UIListMenu") as UIListMenu
            i = 0
            while (i < found)
                typesMenu.AddEntryItem(possibleTypes[i])
                i += 1
            endWhile

            typesMenu.OpenMenu(none)
            selectedType = possibleTypes.find(typesMenu.GetResultString())
        endIf

        SetCurrentType(target, possibleTypes[selectedType])
        SetCurrentCategory(target, StringUtil.Split(foundCategories, stringListSeparator)[selectedType])
        string[] possibleStyles = StringUtil.Split(foundStyles, stringListSeparator)
        if (possibleStyles[selectedType] == "none")
            ClearCurrentStyle(target)
        else
            SetCurrentStyle(target, possibleStyles[selectedType])
        endif
        Log(GetCurrentStyle(target))
        SetCurrentStage(target, StringUtil.Split(foundStages, stringListSeparator)[selectedType] as int)   
        Debug.MessageBox("Easy Body Hair has successfully initialized the actor hair data. Have a good game.")
    else
        Debug.MessageBox("Easy Body Hair was not able to initialize the actor.\nPlease make sure your hair types config files contains the current hair style (" + currentHairName +") or use the MCM to choose a configured style.")
    endIf

EndFunction


Function PrepareSelectPlayerHair()
    RegisterForMenu("Journal Menu") 
EndFunction

Event OnMenuClose(String MenuName)
    Log(MenuName)
    SelectPlayerHair()
    UnregisterForAllMenus()
EndEvent

Function SelectPlayerHair()
    Actor player = Main.PlayerAlias.GetActorRef()
    string hairTypesFolder = GetHairTypesFolder(player, relative = false)
    string[] types = MiscUtil.FoldersInFolder(hairTypesFolder)
    UIListMenu menu = uiextensions.GetMenu("UIListMenu") as uilistmenu
    menu.AddEntryItem(chooseTypeMsg)
    int i = 0
    while (i < types.length)
        menu.AddEntryItem(types[i])
        i += 1
    endWhile

    string desiredType = ""
    Log("init menu")
    menu.OpenMenu(none)
    desiredType = menu.GetResultString()
    Log(desiredType)

    string[] lengths = GetLengths(GetTypeConfig(player, desiredType))
    menu = uiextensions.GetMenu("UIListMenu") as uilistmenu
    menu.AddEntryItem(chooseLengthMsg)
    i = 0
    while (i < lengths.length)
        menu.AddEntryItem(lengths[i])
        i += 1
    endWhile

    string desiredLengthName = ""
    menu.OpenMenu(none)
    desiredLengthName = menu.GetResultString()
    int desiredLength = lengths.find(desiredLengthName)

    SetCurrentType(player, desiredType)
    SetCurrentCategory(player, jNaturalKey)
    SetCurrentStage(player, desiredLength)   

    ApplyHairStyle(player, GetDefaultHairPart(player, desiredLength), desiredLength)
    Debug.MessageBox("Easy Body Hair has successfully initialized the actor hair data. Have a good game.")
EndFunction

Function UpdateGrowthAll()
EndFunction

Function UpdateGrowth(Actor target)
EndFunction

bool Function StyleAllowCut(Actor target)
    string category = GetCurrentCategory(target)
    return category == jNaturalKey || category == combedCat
EndFunction

bool Function StartCut(Actor target)
    ShowInactiveMessage()
    return false
EndFunction

bool Function StartStyling(Actor target, string category)
    ShowInactiveMessage()
    return false
EndFunction

bool Function StartBrush(Actor target)
    return StartStyling(target, combedCat)
EndFunction

bool Function StartTie(Actor target)
    return StartStyling(target, tiedCat)
EndFunction

bool Function StartCombAndTie(Actor target)
    return StartStyling(target, combedAndTiedCat)
EndFunction

Function ApplyHairStyle(Actor target, HeadPart hairDo, int stage)
    if (SetHair(target, hairDo))
        SetCurrentStage(target, stage)
    endif
EndFunction

int Function GetCurrentStage(Actor target)
    int stage = StorageUtil.GetIntValue(target, sCurrentAreaStageKey, missing = -1)
    if (stage < 0)
        Log("Current stage was not set! Setting stage to 0 but expect strange behavior.")
        stage = 0
        StorageUtil.SetIntValue(target, sCurrentAreaStageKey, stage)
    endif
    return stage
EndFunction

Function SetCurrentStage(Actor target, int stage)
    StorageUtil.SetIntValue(target, sCurrentAreaStageKey, stage)   
EndFunction

int Function GetMaxStage(Actor target)
    Return JsonUtil.StringListCount(GetCurrentTypeConfig(target), jNaturalKey)
EndFunction

HeadPart Function GetDefaultHairPart(Actor target, int stage)
    string hairName = JsonUtil.StringListGet(GetCurrentTypeConfig(target), jNaturalKey, stage)
    HeadPart part = HeadPart.GetHeadPart(hairName)
    if (!part)
        EFSzUtil.log("HeadPart name: " + hairName + " was not found")
    endif
    return part
EndFunction

HeadPart Function GetHairPart(Actor target, string typeKey, string category, string styleKey, int stage)
    Log(GetStyleFile(target, typeKey, category, styleKey))
    string hairName = JsonUtil.StringListGet(GetStyleFile(target, typeKey, category, styleKey), jhairdosKey, stage)
    HeadPart part = HeadPart.GetHeadPart(hairName)
    if (!part)
        EFSzUtil.log("HeadPart name: " + hairName + " was not found")
    endif
    return part
EndFunction

HeadPart Function GetCurrentTypeHairPart(Actor target, string category, string style, int stage)
    return GetHairPart(target, GetCurrentType(target), category, style, stage)
EndFunction

HeadPart Function GetCurrentStyleHairPart(Actor target, int stage)
    return GetCurrentTypeHairPart(target, GetCurrentCategory(target), GetCurrentStyle(target), stage)
EndFunction

Function SetCurrentType(Actor target, string type)
    StorageUtil.SetStringValue(target, sCurrentTypeKey, type)
EndFunction

string Function GetCurrentType(Actor target)
    return StorageUtil.GetStringValue(target, sCurrentTypeKey)
EndFunction

string Function GetCurrentCategory(Actor target)
    return StorageUtil.GetStringValue(target, sCurrentCategoryKey)
EndFunction

Function SetCurrentCategory(Actor target, string newStyle)
    StorageUtil.SetStringValue(target, sCurrentCategoryKey, newStyle)
EndFunction

Function ClearCurrentStyle(Actor target)
    StorageUtil.UnsetStringValue(target, sCurrentStyleKey)
EndFunction

Function SetCurrentStyle(Actor target, string newStyle)
    StorageUtil.SetStringValue(target, sCurrentStyleKey, newStyle)
EndFunction

string Function GetCurrentStyle(Actor target)
    return StorageUtil.GetStringValue(target, sCurrentStyleKey)
EndFunction

; Head parts
string Function GetCurrentHairName(ActorBase targetBase)
    HeadPart hairPart = GetCurrentHair(targetBase)
    return StringUtil.Split(StringUtil.Split(hairPart as string, "<")[1], " ")[0]
EndFunction

HeadPart Function GetCurrentHair(ActorBase targetBase)
    return targetBase.GetNthHeadPart(targetBase.GetIndexOfHeadPartByType(hairHeadPartIndexSE))
EndFunction

bool Function SetHair(Actor target, HeadPart hairPart)
    if (!target.IsOnMount() && hairPart)
        target.ChangeHeadPart(hairPart)
        target.QueueNiNodeUpdate()
        return true
    endif
    return false
EndFunction

string Function GetLengthName(Actor target, int stage)
    return JsonUtil.StringListGet(GetTypeConfig(target, GetCurrentType(target)), jLengthKey, stage)
EndFunction

string[] Function GetLengths(string typeFile)
    return JsonUtil.StringListToArray(typeFile, jLengthKey)
EndFunction
;Files and folders

string Function GetHairTypesFolder(Actor target, bool relative = true)
    return GetSexFolder(target, relative) + typesFolder
EndFunction

string Function GetCurrentTypeFolder(Actor target)
    return GetHairTypesFolder(target) + GetCurrentType(target) + "/"
EndFunction

string Function GetCurrentTypeConfig(Actor target)
    return GetCurrentTypeFolder(target) + typeConfigFileName
EndFunction

string Function GetCurrentTypeCategoryFolder(Actor target, string category)
    return GetCurrentTypeFolder(target) + category + "/"
EndFunction

string Function GetTypeFolder(Actor target, String typeName)
    return GetHairTypesFolder(target) + typeName + "/"
EndFunction

string Function GetTypeConfig(Actor target, String typeName)
    return GetTypeFolder(target, typeName) + typeConfigFileName
EndFunction

string Function GetStyleFile(Actor target, String typeName, String stylename, String subStyleName)
    return GetTypeFolder(target, typeName) + stylename + "/" + subStyleName
EndFunction

string Function GetConfigFile(Actor target)
    ;log("AreaConfigFile: " + GetAreaFolder(areaName) + "config")
    return GetSexFolder(target) + "config"
EndFunction

String Function GetStatus(Actor target)
    return "--- Hair ---\nModule Disabled"
EndFunction

; Dev

; Function ScanHairParts(Actor target)
;     int hpc = target.GetActorBase().GetNumHeadParts()
;     Log("Player HeadParts Num : "+hpc)
;     int i = 0
;     WHILE i < hpc
;         HeadPart hp = target.GetActorBase().GetNthHeadPart(i)
;         string hpi = hp as string
;         Log("Player HeadPart("+i+") : "+ hpi + " " + hp.GetType())
;         ; Log("Player HeadPartName("+i+") : "+ hp.GetName())
;         ; int ehpc = hp.GetNumExtraParts()
;         ; int j = 0
;         ; while j < ehpc
;         ;     Log("Player HeadPart("+i+") extra ("+j+"): "+ hp.GetNthExtraPart(j))
;         ;     Log("Player HeadPart("+i+") extra name ("+j+"): "+ hp.GetNthExtraPart(j).GetName())
;         ;     j += 1
;         ; endwhile
;         i += 1
;     EndWHILE
; EndFunction

; DataAccess

; Find the type / stage / style from current hair (low priority => can be slow)

; Find the next hair style from current (growth) 

; Find  the available styles from current (tying, braiding)

; Rules

; Must be untied/unbraided for cut

; Natural can be brushed with a brush

; Natural/brushed can be tied with 1 ruban + brush

; Natural/brushed can be braided with 2 rubans + brush

; At least and only one natural hair style per length / type

; Type switching

; Growth rules

; Natural > Natural (ez)

; Brushed 

; Tied

; Braided
Sound Property EFSCut  Auto  

Sound Property EFSShaving  Auto  
