Scriptname EFSxSLInterface extends Quest  

SexLabFramework sexLab

Function LoadInterface()
    sexLab = game.GetFormFromFile(0x000D62, "SexLab.esm") as SexLabFramework

    if (sexLab)
        RegisterForModEvent("PlayerTrack_End", "OnPlayerEndScene")   
    endif
EndFunction

Event OnPlayerEndScene(Form FormRef, int tid)
    sslThreadController thread = sexlab.GetController(tid)
    Actor player = Game.GetPlayer()
    if (thread.IsVictim(player))
        Main.OnAggressiveAnimEnds(player)
    endIf
EndEvent

EFS0MainQuest Property Main  Auto  
