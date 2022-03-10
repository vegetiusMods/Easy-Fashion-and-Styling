Scriptname EFSzModule extends Quest

EFS0MainQuest Property Main Auto
string Property ModuleName Auto
string Property ModuleVersion Auto

bool Function IsModuleStarted()
    return GetState() == "Started"
EndFunction

Function Toggle()
    GoToState("Started")
EndFunction

Function LoadModule(int lastVersion)

EndFunction

Function RefreshModule()

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