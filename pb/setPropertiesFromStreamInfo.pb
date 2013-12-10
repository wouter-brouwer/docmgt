#Prog = "setPropertiesFromStreamInfo"
#Version = "0.1"
OpenConsole()
PrintN(#Prog + "started")
;{ Documentatie

; Dit programma maakte het mogelijk om job properties te zetten vanuit StreamInfo.
;
; Het stream ID wordt ontleend aan de jobnaam (1e parameter)
; De set property regels worden geschreven naar een overrides file (2e parameter)

;}

Procedure Usage(Message.s)
  OpenConsole()
  If Message <> "" 
    ConsoleError(Message)
    ExitCode = 1
  EndIf
  PrintN(#Prog + " version " + #Version + " by Wouter Brouwer")
  PrintN("A program to get properties from AFP NOP records")
  PrintN("Usage: "+#Prog+" <jobname> <overrides file>")
  Delay(5000)
  End ExitCode
EndProcedure

IncludeFile "Common.pbi"

Global ConfigDir.s

IncludeFile "StreamInfo.pbi"

Procedure.s GetStreamInfo(Stream.s, Keyword.s)
  StreamInfo.s = StreamInfo(Stream, Keyword)
  If FindString(StreamInfo, "Error:") + FindString(StreamInfo, "Critical:") > 0
    Usage(StreamInfo)
  EndIf
  ProcedureReturn StreamInfo
EndProcedure

IncludeFile "MaterialInfo.pbi"

Procedure.s GetMaterialInfo(Material.s, Keyword.s)
  MaterialInfo.s = MaterialInfo(Material, Keyword)
  If FindString(MaterialInfo, "Error:") + FindString(MaterialInfo, "Critical:") > 0
    Usage(MaterialInfo)
  EndIf
  ProcedureReturn MaterialInfo
EndProcedure

If Not OpenPreferences(GetPathPart(ProgramFilename())+"/openloop.ini")
  Usage("Error: Unable to open openloop.ini")
EndIf
ConfigDir.s = CheckDirectory(ReadPreferenceString("ConfigDir",""))
ClosePreferences()


;{ Initialisatie

Test = #False

If Test And CountProgramParameters() = 0
  JobName.s = "82_cards.afp"
  OutputFile.s = "overrides.txt"
Else
  If CountProgramParameters() <> 2
    Usage("")
  EndIf
  JobName.s = ProgramParameter()
  OutputFile.s = ProgramParameter()
EndIf
OpenConsole()
PrintN(JobName)
PrintN(OutputFile)

If CountString(JobName, "_") < 1
  Usage("Error: Jobname should have format <Stream>_<Something...>")
EndIf
Stream.s = StringField(JobName, 1, "_")

If Not CreateFile(1, OutputFile)
  Usage("Error: Unable to create " + OutputFile)
EndIf

;}

;{ Main 

Forms.s = GetStreamInfo(Stream, "PaperCode")
Description.s = GetStreamInfo(Stream, "Description")
Destination.s = GetStreamInfo(Stream, "Inserting")
Dim Insert.s(6)
For i = 1 To 6
  Insert(i) = GetStreamInfo(Stream, "Insert" + Str(i))
  If Insert(i) <> ""
    Insert(i) + " " + GetMaterialInfo(Insert(i),"Description")
  EndIf
Next i

WriteStringN(1, "Job.Description=" + Description)
WriteStringN(1, "Job.Destination=" + Destination)
WriteStringN(1, "Job.Form=" + Forms)
For i = 1 To 4
  If Insert(i) <> ""
    WriteStringN(1, "Job.Info.Address" + Str(i) + "=Station-" + Str(i) + " " + Insert(i))
  EndIf
Next
If Insert(5) <> ""
  WriteStringN(1, "Job.Info.Room=Station-5 " + Insert(5))
EndIf
If Insert(6) <> ""
  WriteStringN(1, "Job.Info.Department=Station-6 " + Insert(6))
EndIf

;}

;{ Afsluiting

CloseFile(1)

End

;}

; IDE Options = PureBasic 5.11 (Linux - x86)
; CursorPosition = 101
; FirstLine = 60
; Folding = 9-
; EnableXP
; Executable = setPropertiesFromStreamInfo