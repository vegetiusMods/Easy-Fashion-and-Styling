Scriptname EFSzModule extends Quest

EFS0MainQuest Property Main Auto
string Property ModuleName Auto
bool Property FlaggedForRefresh Auto

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
    string root
    if (relative)
        root = ".."
    else
        root = "data/skse/plugins"
    endif

    return root + "/Easy Fashion and Styling/" + ModuleName + "/"
EndFunction

string Function GetFilePath(string fileName, bool relative = true)
    return GetModuleFolderPath(relative) + fileName
EndFunction