Scriptname EFSzModule extends Quest

string Property ModuleName Auto

bool Function IsModuleStarted()
    return GetState() == "Started"
EndFunction

Function Toggle()
    GoToState("Started")
EndFunction

Function LoadModule()

EndFunction

Function RefreshModule()

EndFunction

string Function GetFilePath(string fileName)
    return "../Easy Fashion and Styling/" + ModuleName + "/" + fileName
EndFunction