;{ RunControl
#LockFile = #Prog + ".lock"
#PauseFile = #Prog + ".pause"
#StopFile = #Prog + ".stop"

Procedure LockFile(Option.s)
  
  Static LockFileNr
  
  Select LCase(Option)
      
    Case "open"
      
      LockFileNr = CreateFile(#PB_Any, #LockFile)
      ProcedureReturn LockFileNr

    Case "close"
      
      CloseFile(LockFileNr)
      LockFileNr = 0
      DeleteFile(#StopFile)
      ProcedureReturn DeleteFile(#LockFile)
      
  EndSelect
  
EndProcedure

;{ Handle program argument
If CountProgramParameters() > 0
  Select LCase(ProgramParameter())
    Case "start"
      
    Case "stop"
      If CreateFile(0, #StopFile)
        CloseFile(0)
        End
      Else
        OpenConsole()
        PrintN("Unable to create " + #StopFile)
        End 1
      EndIf
      
    Case "pause"
      If CreateFile(0, #PauseFile)
        CloseFile(0)
        End
      Else
        OpenConsole()
        PrintN("Unable to create " + #PauseFile)
        End 1
      EndIf
      
    Case "resume"
      If Not DeleteFile(#PauseFile)
        OpenConsole()
        PrintN("Unable to delete " + #PauseFile)
        End 1
      EndIf
        
        
    Default
      OpenConsole()
      PrintN("Usage: " + #Prog + " [start|stop|pause|resume]")
      End 1
      
  EndSelect
EndIf
;}

If Not LockFile("open")
  OpenConsole()
  PrintN("Unable to create " + #LockFile + " Program already running?")
  End 1
EndIf
;}

; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 58
; FirstLine = 16
; Folding = -
; EnableXP