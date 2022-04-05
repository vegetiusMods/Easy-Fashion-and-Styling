Scriptname EFSzModule extends Quest

EFS0MainQuest Property Main Auto
string Property ModuleName Auto
bool Property FlaggedForRefresh Auto

string maleFolder = "m/"
string femaleFolder = "f/"

bool Function IsModuleStarted()
    return GetState() == "Started"
EndFunction

Function Toggle()
    GoToState("Started")
EndFunction

Function LoadModule(int loadedVersion)

EndFunction

Function RefreshModule(bool force)
    if (force || FlaggedForRefresh)
        DoRefresh()
    endif
    FlaggedForRefresh = false
EndFunction

State Stopping
    Event OnBeginState()
        GoToState("")
    EndEvent

    Event OnEndState()
        CleanModule()
    EndEvent
EndState

Function CleanModule()

EndFunction

Function DoRefresh()

EndFunction

Function ObjectEquipped(Actor target, Form akBaseObject, ObjectReference akReference)
EndFunction

Function ObjectUnequipped(Actor target, Form akBaseObject, ObjectReference akReference)

EndFunction

string Function GetModuleFolderPath(bool relative = true)
    return Main.GetPluginFolderPath(relative) + ModuleName + "/"
EndFunction

string Function GetSexFolder(bool female, bool relative = true)
    string folderPath = GetModuleFolderPath(relative)
    
    if (female)
        folderPath += femaleFolder
    else
        folderPath += maleFolder
    endIf
    ;log("SexFolder: " + folderPath)
    return folderPath
EndFunction

string Function GetFilePath(string fileName, bool relative = true)
    return GetModuleFolderPath(relative) + fileName
EndFunction

Function ShowInactiveMessage()
    Debug.MessageBox("The " + ModuleName + " module is disabled.")
EndFunction

Function Log(string in)
    EFSzUtil.log(in, ModuleName)
EndFunction