;{ RunControl
#LockFile = #Prog + ".lock"
#PauseFile = #Prog + ".pause"
#StopFile = #Prog + ".stop"

Procedure LockFile(Option.s)
   
  Select LCase(Option)
      
    Case "open"
      
      If FileSize(GetPathPart(ProgramFilename()) + "/" + #LockFile) < 0
        CloseFile(CreateFile(#PB_Any, GetPathPart(ProgramFilename()) + "/" + #LockFile))
        ProcedureReturn #True
      Else
        ProcedureReturn #True
      EndIf

    Case "close"
      
      DeleteFile(GetPathPart(ProgramFilename()) + "/" + #StopFile)
      ProcedureReturn DeleteFile(GetPathPart(ProgramFilename()) + "/" + #LockFile)
      
  EndSelect
  
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
      If CreateFile(0, GetPathPart(ProgramFilename()) + "/" + #StopFile)
        CloseFile(0)
        End
      Else
        OpenConsole()
        PrintN("Unable to create " + #StopFile)
        End 1
      EndIf
      
    Case "pause"
      If CreateFile(0, GetPathPart(ProgramFilename()) + "/" + #PauseFile)
        CloseFile(0)
        End
      Else
        OpenConsole()
        PrintN("Unable to create " + #PauseFile)
        End 1
      EndIf
      
    Case "resume"
      If Not DeleteFile(GetPathPart(ProgramFilename()) + "/" + #PauseFile)
        OpenConsole()
        PrintN("Unable to delete " + #PauseFile)
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

If Not LockFile("open")
  OpenConsole()
  PrintN("The program is probably running because " + #LockFile + " exists")
  Debug #LockFile + " exists"
  End 1
EndIf
;}
; IDE Options = PureBasic 5.20 LTS (Linux - x64)
; CursorPosition = 18
; Folding = -
; EnableXP