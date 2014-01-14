#Prog = "Reconcile"

;{ Documentatie

; Dit programma verwerkt de couverteer resultaten.
; Niet volledig verwerkte documenten worden terug geplaatst in de pool
; De wel goed verwerkte documenten krijgen met de job de status done.
; NB In tegenstelling to closed loop moeten deze job ook in DC Verify 
; als afgehandeld worden beschouwd.

; Het programma polt de XFB receive directory op result files die horen bij 
; de jobs die status busy hebben.

;}

IncludeFile "Common.pbi"

Global ConfigDir.s
Global RunControlDir.s

IncludeFile "StreamInfo.pbi"

;{ Initialisatie

If Not OpenPreferences("openloop.ini")
  LogMsg("Critical: Unable to open openloop.ini")
EndIf

ConfigDir.s = CheckDirectory(ReadPreferenceString("ConfigDir",""))
TmpDir.s = CheckDirectory(ReadPreferenceString("TmpDir",""))
LogDir = CheckDirectory(ReadPreferenceString("LogsDir",""))
JobsDir.s = CheckDirectory(ReadPreferenceString("JobsDir",""))
InputResultDir.s = CheckDirectory(ReadPreferenceString("InputResultDir",""))
TodoDir.s = CheckDirectory(ReadPreferenceString("ToDoDir",""))
RunControlDir.s = CheckDirectory(ReadPreferenceString("RunControlDir",""))
ClosePreferences()

IncludeFile "RunControl.pbi"

NewList JobNames.s()
NewList DocumentFileNames.s()

LogMsg(#Prog + " started")

;}

;{ Main loop
Quit = 0
Repeat
  
  Quit = Bool(FileSize(StopFile) = 0)

  If FileSize(PauseFile) < 0 And Not Quit

    ;{ Loop door de busy jobs    
    GetDirSorted(JobNames(), JobsDir, "*.busy", #PB_DirectoryEntry_Directory)
    ForEach JobNames()
      JobName.s = StringField(JobNames(), 1, ".busy")
      Stream.s = StringField(JobName, 1, "_")
      JobNr.s = StringField(JobName, 2, "_")
      ResultFile.s = InputResultDir + JobNr + ".out"
      If FileSize(ResultFile) > 0
        Gosub VerwerkResult
      EndIf
    Next
    ;}
  
  EndIf
  
  LogMsg("")
  HeartBeat()
  Delay(100)
  
  ; TEST
  ;Quit = 1
  
Until Quit
;}

;{ Afsluiting
LogMsg(#Prog + " ended")
DeleteFile(StopFile)
DeleteFile(BeatFile)
End
;}

;{ VerwerkResult:
VerwerkResult:
  OK = 0
  NOK = 0
  ResFileNr = ReadFile(#PB_Any, ResultFile)
  If ResFileNr = 0
    LogMsg("Critical: Unable to open " + ResultFile)
  EndIf
  JobDir.s = JobsDir + JobName
  GetDirSorted(DocumentFileNames(), JobDir + ".busy", "*.*", #PB_DirectoryEntry_File)
  
  While Not Eof(ResFileNr)
    DocumentFileName.s = ""
    Line.s = ReadString(ResFileNr)
    DocumentID.s = Trim(Mid(Line, 484, 30))
    ForEach DocumentFileNames()
      If DocumentID = StringField(DocumentFileNames(), 1, "_P")
        DocumentFileName = DocumentFileNames()
        DeleteElement(DocumentFileNames())
        Break
      EndIf
    Next  
    ResultCode.s = Mid(Line,452,2)
    If ResultCode = "05" Or ResultCode = "08"
      OK + 1
      ; OK 
    Else
      NOK + 1
      ; NOK Move document to pool
      ;CloseFile(OpenFile(#PB_Any, JobDir + ".busy/" + DocumentFileName)) ; om de filetime aan te passen
      
      CopyFile(JobDir + ".busy/" + DocumentFileName, TodoDir + Stream + "/" + DocumentFileName)
      DeleteFile(JobDir + ".busy/" + DocumentFileName)
    EndIf
  Wend
  
  RenameFile(JobDir + ".busy", JobDir + ".done")
  LogMsg("Info: Job " + JobName + " completed with " + Str(OK) + " OK documents and " + Str(NOK) + " not OK documents")
Return
;}
; IDE Options = PureBasic 5.11 (Linux - x86)
; CursorPosition = 83
; FirstLine = 31
; Folding = e-
; EnableXP
; Executable = reconcile