; RunControl

; Deze includefile bevat de logica
; - om te laten zien dat een programma draait
; - om te voorkomen dat een programma dubbel draait
; - om een programma te starten als achtergrond proces
; - om een programma te laten pauzeren, vervolgen of stoppen

Global BeatFile.s = RunControlDir.s + LCase(#Prog) + ".beat"
Global StopFile.s = RunControlDir.s + LCase(#Prog) + ".stop"
Global PauseFile.s = RunControlDir.s + LCase(#Prog) + ".pause"

Procedure HeartBeat()
  Static LastRun  
  If Date() > LastRun + 1
    Touch(BeatFile)
    LastRun = Date()
  EndIf
EndProcedure  

;{ Handle program argument
If CountProgramParameters() > 0
  Select LCase(ProgramParameter())
    Case "start"
      PID = ProgramID(RunProgram(ProgramFilename(),"",GetPathPart(ProgramFilename())))
      OpenConsole()
      PrintN("Started as PID " + Str(PID))
      End
      
    Case "stop"
      If CreateFile(0, StopFile)
        CloseFile(0)
        End
      Else
        OpenConsole()
        PrintN("Unable to create " + StopFile)
        End 1
      EndIf
      
    Case "pause"
      If CreateFile(0, PauseFile)
        CloseFile(0)
        End
      Else
        OpenConsole()
        PrintN("Unable to create " + PauseFile)
        End 1
      EndIf
      
    Case "resume"
      If Not DeleteFile(PauseFile)
        OpenConsole()
        PrintN("Unable to delete " + PauseFile)
        End 1
      EndIf
      End 
        
    Default
      OpenConsole()
      PrintN("Usage: " + #Prog + " [start|stop|pause|resume]")
      End 1
      
  EndSelect
EndIf
;}

If FileDate(BeatFile) > Date() - 10
  OpenConsole()
  PrintN("The program is probably running because recent " + BeatFile)
  Debug BeatFile + " exists"
  End 1
EndIf

Touch(BeatFile)

;If Not CreateThread(@HeartBeat(), 1000)
;  LogMsg("Critical: Unable to create thread HeartBeat")
;EndIf
; IDE Options = PureBasic 5.11 (Linux - x86)
; CursorPosition = 10
; Folding = -
; EnableXP