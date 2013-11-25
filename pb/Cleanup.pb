#Prog = "Cleanup" 

;{ Documentation

; Dit programma schoont bestanden uit directories op door ze te verplaatsen
; of te verwijderen.
; Dit gebeurt aan de hand van een stuurbestand.

;}

;{ Declarations

IncludeFile "Common.pbi"

Global ConfigDir.s
Global RunControlDir.s

;}

Procedure.s ReduceWhiteSpace(Line.s, Separator.s)
  If Separator
    Line = ReplaceString(Line, Separator, " ")
    While FindString(Line, "  ", 0)
      Line = ReplaceString(Line, "  ", " ")
    Wend
    Line = ReplaceString(Line, " ", Separator)
  EndIf
  ProcedureReturn Line
EndProcedure

Procedure ProcessLine(Line.s)

  If Left(Line, 1) = "#": ProcedureReturn: EndIf
  
  Separator.s = Chr(9)
  
  Line = ReduceWhiteSpace(Line, Separator)
  
  If CountString(Line, Separator) < 2: ProcedureReturn: EndIf
  
  Directory.s = StringField(Line, 1, Separator)
    
  Pattern.s = StringField(Line, 2, Separator)
  Days = Val(StringField(Line, 3, Separator))
  Target.s = StringField(Line, 4, Separator)
  OldDate = AddDate(Date(), #PB_Date_Day, - Days)
  DirectoryNr = ExamineDirectory(#PB_Any, Directory, Pattern)
  If DirectoryNr
    While NextDirectoryEntry(DirectoryNr)
      If DirectoryEntryType(DirectoryNr) = #PB_DirectoryEntry_File
        FileName.s = DirectoryEntryName(DirectoryNr)
        FileDate = DirectoryEntryDate(DirectoryNr, #PB_Date_Modified)
        If FileDate < OldDate
          If Target
            If RenameFile(Directory + "\" + FileName, Target + "\" + FileName)
              If DebugMode
                LogMsg(FileName + " moved from " + Directory + " to " + Target)
              EndIf
            Else
              LogMsg("Critical: Unable to move " + FileName + " from " + Directory + " to " + Target)
            EndIf
          Else
            If DeleteFile(Directory + "\" + FileName)
              If DebugMode
                LogMsg(Directory + "\" + FileName + " deleted")
              EndIf
            Else
              LogMsg("Critical: Unable to delete " + FileName + " from " + Directory)
            EndIf
          EndIf
        EndIf
      EndIf
    Wend
    FinishDirectory(DirectoryNr)
  Else
    LogMsg("Warning: Directory '" + Directory + "' not found")
  EndIf
  
EndProcedure

Procedure ProcessControlFile(FileName.s)

  Static LastRun
  If Date() < LastRun + 60 ; Every minute
    ProcedureReturn
  EndIf
  LastRun = Date()
  
  FileNr = ReadFile(#PB_Any, FileName)
  If Not FileNr
    LogMsg("Critival: Unable to open " + FileName)
  Else
    While Not Eof(FileNr)
      Line.s = ReadString(FileNr)
      ProcessLine(Line)
    Wend
    CloseFile(FileNr)
  EndIf
  
EndProcedure

;{ Init
If Not OpenPreferences("openloop.ini")
  LogMsg("Critical: Unable to open openloop.ini")
EndIf

ConfigDir.s = CheckDirectory(ReadPreferenceString("ConfigDir",""))
LogDir = CheckDirectory(ReadPreferenceString("LogsDir",""))
RunControlDir.s = CheckDirectory(ReadPreferenceString("RunControlDir",""))
ClosePreferences()

IncludeFile "RunControl.pbi"

LogMsg(#Prog + " started")
;}

;{ Main loop
Quit = 0
Repeat
  
  Quit = Bool(FileSize(StopFile) = 0)

  If FileSize(PauseFile) < 0 And Not Quit
    
    ProcessControlFile(ConfigDir + "Cleanup.txt")
  
  EndIf
  
  LogMsg("")
  Delay(1000)
  
  ; TEST
  ;Quit = 1
  
Until Quit
;}

;{ Afsluiting
LogMsg(#Prog + " ended")
DeleteFile(StopFile)
End
;}

; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 101
; FirstLine = 26
; Folding = Y9
; Executable = O:\Program Files\STIOK\Cleanup.exe