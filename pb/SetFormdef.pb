#Prog = "setFormdef"
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
  PrintN("A program to set the job's formdef based on form and destination")
  PrintN("Usage: "+#Prog+" <form> <destination> <outputfile>")
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
  Form.s = "225761"
  Destination.s = "mps"
  OutputFile.s = "overrides.txt"
Else
  If CountProgramParameters() <> 3
    Usage("")
  EndIf
  Form.s = ProgramParameter()
  Destination.s = UCase(ProgramParameter())
  OutputFile.s = ProgramParameter()
EndIf
OpenConsole()
PrintN(Form)
PrintN(Destination)
PrintN(OutputFile)

If Not CreateFile(1, OutputFile)
  Usage("Error: Unable to create " + OutputFile)
EndIf

;}

;{ Main 

Up.s = GetMaterialInfo(Form, "Up")

If Up = "1" Or Up = ""
ElseIf Up = "2"
  If Destination = "MPS"
    Formdef.s = "F1A42UPX"
  Else
    Formdef.s = "F1A42UPD"
  EndIf
ElseIf Up = "4"
  If UCase(Destination) = "MPS"
    Formdef.s = "F1A54UPX"
  Else
    Formdef.s = "F1A54UPD"
  EndIf
Else
  Usage("Error: Unknown Up for " + Form + " in MaterialInfo")
EndIf

If Formdef <> ""
  WriteStringN(1, "Job.Line2AFP.FORMDEF=" + Formdef)
EndIf

;}

;{ Afsluiting

CloseFile(1)

End

;}

; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 97
; FirstLine = 41
; Folding = y-
; EnableXP
; Executable = setFormdef