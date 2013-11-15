#Prog = "SplitAFP"
test
; Dit programma splitst AFP bestanden naar losse documenten
; De AFP header wordt apart opgeslagen.

; Input filenamen dienen te bestaan uit <stroom>_<iets unieks>.afp

; Bij de verwerking wordt een <timestamp> bepaald uit systeemdatum yyyymmddhhiiss
; als deze gelijk is aan de vorige wordt een seconde gewacht.

; De uitvoer bestanden heten <stroom>_yyyymmdduuiiss_header.afp in /aiw/aiw1/documenten/headers
;  en <stroom>_<timestamp>_<sequencenr>_p<pages>.afp

Global LogDir.s

Procedure LogMsg(Msg.s)
  
  Static LogFileNr, LastRun
  
  ; Logfile sluiten als er 10 seconden geen echte logging geweest is
  If LCase(Msg) = ""
    If LogFileNr > 0 And Date() > LastRun + 10
      CloseFile(LogFileNr)
      LogFileNr = 0
    EndIf
    ProcedureReturn
  EndIf  
  LastRun = Date()
  
  ; Indien nodig de logfile openen
  If LogFileNr = 0
    ; Als hij te groot is aan een nieuwe beginnen
    If FileSize(LogDir + #Prog + ".log") > 1024 * 1024 ; 1 MB
      RenameFile(LogDir + #Prog + ".log", LogDir + #Prog + FormatDate("_%yyyy-%mm-%dd", Date()) + ".log")
    EndIf
    LogFileNr = OpenFile(#PB_Any, LogDir + #Prog + ".log")
    FileSeek(LogFileNr, Lof(LogFileNr))
  EndIf
  
  ; De boodschap met tijd naar de log schrijven
  TimeStamp.s = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  Regel.s = TimeStamp + " - " + Msg
  Debug Regel
  WriteStringN(LogFileNr, Regel)
  
  ; Stoppen bij ernstige fout
  If FindString(LCase(Msg), "critical") = 1
    End
  EndIf
  
EndProcedure

Procedure.s HexString(String.s)

  For i = 1 To Len(String)
    HexString.s + Right("0" + Hex(Asc(Mid(String,i,1))),2)
  Next i
  
  ProcedureReturn HexString

EndProcedure

Procedure DebugHexMem(*Pointer, Length)
    s.s = ""
    For i = 0 To Length - 1
      s + Right("0" + Hex(PeekC(*Pointer + i)),2) + " "
      If Len(s) >= 3 * 16
        Debug s
        s = ""
      EndIf
    Next i
    If s
      Debug s
    EndIf
  ;CallDebugger
EndProcedure

Procedure.s EbcdicToAscii(String.s)
  code.s = Space(75)
  code + ".<(+|&" + Space(9)
  code + "!$*); -/" + Space(9)
  code + ",%_>?" + Space(10)
  code + ":#@'="+Chr(34)+" "
  code + "abcdefghi" + Space(7)
  code + "jklmnopqr" + Space(8)
  code + "stuvwxyz" + Space(23)
  code + "ABCDEFGHI" + Space(7)
  code + "JKLMNOPQR" + Space(8)
  code + "STUVWXYZ" + Space(6)
  code + "0123456789" + Space(6)
  For i = 1 To Len(String)
    Letter = Asc(Mid(String,i,1)) + 1
    Result.s + Mid(Code,Letter,1)
  Next i
  ProcedureReturn Result
EndProcedure

Procedure.s AsciiToEbcdic(String.s)
  code.s = Space(75)
  code + ".<(+|&" + Space(9)
  code + "!$*); -/" + Space(9)
  code + ",%_>?" + Space(10)
  code + ":#@'="+Chr(34)+" "
  code + "abcdefghi" + Space(7)
  code + "jklmnopqr" + Space(8)
  code + "stuvwxyz" + Space(23)
  code + "ABCDEFGHI" + Space(7)
  code + "JKLMNOPQR" + Space(8)
  code + "STUVWXYZ" + Space(6)
  code + "0123456789" + Space(6)
  For i = 1 To Len(String)
    If Mid(String,i,1) <> " "
      p = FindString(code, Mid(String,i,1),0) - 1
    Else
      p = 64
    EndIf
    Result.s + Chr(p)
  Next i
  ProcedureReturn Result
EndProcedure

Procedure.s PeekHexString(*Pointer, Length)
  s.s = ""
  For i = 0 To Length - 1
    s + Right("0" + Hex(PeekC(*Pointer + i)),2)
  Next i
  ProcedureReturn s
EndProcedure

Procedure PokeHexString(*Pointer,String.s)
  OffSet = 0
  For i = 1 To Len(String) Step 2
    h = Asc(Mid(String,i,1))
    h - 48
    If h > 10
      h - 7
    EndIf
    l = Asc(Mid(String,i+1,1))
    l - 48
    If l > 10
      l - 7
    EndIf
    PokeC(*Pointer + OffSet, h * 16 + l)
    OffSet + 1
  Next i
EndProcedure

Procedure.s CheckDirectory(Dir.s)
  If FileSize(Dir) <> -2
    If Not CreateDirectory(Dir)
      LogMsg("Critical: Can not create directory "+ Dir)
    Else
      LogMsg("Info: Directory " + Dir + " created")
    EndIf
  Else
    ProcedureReturn Dir + "/"
  EndIf
EndProcedure

;{ Initialisatie
*Record = AllocateMemory(32768)

; De verschillende directories
BaseDir.s = "/aiw/aiw1"
If FileSize(BaseDir) <> -2
  BaseDir.s = "."
EndIf
BaseDir + "/"

LogDir.s = CheckDirectory(BaseDir + "logs")

LockDir.s = CheckDirectory(BaseDir + "locks")

DocumentDir.s = CheckDirectory(BaseDir + "documents")

InputDir.s = CheckDirectory(DocumentDir + "afpinput")

TmpDir.s = CheckDirectory(InputDir + "tmp")

TodoDir.s = CheckDirectory(DocumentDir + "todo")

HeadersDir.s = CheckDirectory(DocumentDir + "headers")

LockFile.s = LockDir + #Prog + ".lock"
LockFileNr = CreateFile(0, LockFile)
If LockFileNr = 0 
  LogMsg("Critical: Unable to create " + LockFile + " Program already running?")
EndIf
;}

;{ Main loop
While FileSize(#Prog + ".stop") = -1 ; Zolang er geen SplitAFP.stop bestand is

  ;{ Verwerk alle AFP bestanden uit de input directory
  If ExamineDirectory(0, InputDir, "*.afp")
    
    While NextDirectoryEntry(0)
      
      If DirectoryEntryType(0) = #PB_DirectoryEntry_File
        InputFile.s = DirectoryEntryName(0)
        Gosub VerwerkFile
      EndIf
      
    Wend
    
    FinishDirectory(0)
  EndIf
  ;}
  
  LogMsg("") ; Om logfile te kunnen closen bij geen activiteit
  Delay(100) ; CPU besparing
  
Wend
;}
  
;{ Afsluiting
CloseFile(LockFileNr)
DeleteFile(LockFile)
End
;}

;{ VerwerkFile:
VerwerkFile:

  Error.s = ""
  LogMsg("Info: Processing " + InputDir + InputFile)

  p = FindString(InputFile, "_")
  If p <= 1
    Error.s = "Input file niet volgens formaat <stroom>_<iets>.afp"
    Goto VerwerkFileError:
  EndIf
  Stroom.s = Left(InputFile, p - 1)
  
  While Date() <= LastRun
    Delay(100)
  Wend
  LastRun = Date()
  
  TimeStamp.s = FormatDate("%yyyy%mm%dd%hh%ii%ss",Date())
  
  OutputBase.s = Stroom + "_" + TimeStamp
  
  TmpSubDir.s = TmpDir + OutputBase + "/"
  CheckDirectory(TmpSubDir)
  
  TodoSubDir.s = TodoDir + Stroom + "/"
  CheckDirectory(TodoSubDir)
  
  LogMsg("Info: Processing " + InputDir + InputFile)
 
  InputFileNr = ReadFile(#PB_Any, InputDir + InputFile)
  If InputFileNr = 0
    Error = "Error: InputFile can not be opened."
    Goto VerwerkFileError
  EndIf
  
  HeaderFile.s = OutputBase + "_header" + ".afp"
  HeaderFileNr = CreateFile(#PB_Any, TmpSubDir + HeaderFile)
  If HeaderFileNr = 0
    Error = "HeaderFile '" + TmpSubDir + HeaderFile + "' can not be opened."
    Goto VerwerkFileError
  EndIf
  
  NamedGroup = 0
  NamedGroupNr = 0
  Header = 1
  PreviousTriplet.s = ""
  
  ;{ Loop input records
  While Not Eof(InputFileNr)
    
    Skip = 0
    l0.c = ReadCharacter(InputFileNr)
    If l0 <> 90
      Error = InputDir + InputFile + " contains invalid AFP"
      Break
    EndIf
    l1.c = ReadCharacter(InputFileNr)
    l2.c = ReadCharacter(InputFileNr)
    
    RecordLength = l1 * 256 + l2 - 2
    ReadData(InputFileNr, *Record, RecordLength)
    RecordNr + 1
    
    Triplet.s = HexString(PeekS(*Record,3))
    
    If Triplet = "D3A8A8" ; BDT
      Header = 0
      CloseFile(HeaderFileNr)
    EndIf
    
    If Triplet = "D3A9A8" ; EDT
    EndIf
    
    If Triplet = "D3A8AD" ; BNG
      If PreviousTriplet <> Triplet 
        NamedGroup = 1
        NamedGroupNr + 1
        If Date() > LastRun + 60
          LastRun = Date()
          LogMsg("Info: " + Str(NamedGroupNr) + " Documents")
        EndIf
        OutputFile.s = OutputBase + "_0" + RSet(Str(NamedGroupNr), 6, "0") + ".afp"
        OutputFileNr = CreateFile(#PB_Any, TmpSubDir + OutputFile)
        If OutputFileNr = 0 
          Error = "Unable to create " + TmpSubDir + OutputFile
          Break
        EndIf
      Else
        Skip = 1
      EndIf
    EndIf
    
    If Header = 1
      WriteCharacter(HeaderFileNr, l0)
      WriteCharacter(HeaderFileNr, l1)
      WriteCharacter(HeaderFileNr, l2)
      WriteData(HeaderFileNr, *Record, RecordLength)
    EndIf
      
    If Header = 0 And NamedGroup = 1 And Skip = 0
      WriteCharacter(OutputFileNr, l0)
      WriteCharacter(OutputFileNr, l1)
      WriteCharacter(OutputFileNr, l2)
      WriteData(OutputFileNr, *Record, RecordLength)
    EndIf
    
    If Triplet = "D3A9AD" ; ENG
      NamedGroup = 0
      If PreviousTriplet <> Triplet
        CloseFile(OutputFileNr)
      EndIf
    EndIf
    
    PreviousTriplet.s = Triplet
  
  Wend
  ;}
  
  If Error <> ""
    Goto VerwerkFileError
  EndIf
  
  LogMsg("Info: " + Str(NamedGroupNr) + " Documents")
  
  If InputFileNr
    CloseFile(InputFileNr)
    InputFileNr = 0
  EndIf
  
  ; Move all files to final destinations
  
  If Not RenameFile(TmpSubDir + HeaderFile, HeadersDir + HeaderFile)
    LogMsg("Critical: Unable to move " + TmpSubDir + HeaderFile + " to " + HeadersDir + HeaderFile)
  EndIf
  
  For i = 1 To NamedGroupNr
    OutputFile.s = OutputBase + "_0" + RSet(Str(i), 6, "0") + ".afp"
    If Not RenameFile(TmpSubDir + OutputFile, TodoSubDir + OutpuFile)
        LogMsg("Critical: Unable to move " + TmpSubDir + OutputFile + " to " + TodoSubDir + OutputFile)
    EndIf

  Next i
  
Return
;}

;{ VerwerkFileError:
VerwerkFileError:

  If HeaderFileNr
    CloseFile(HeaderFileNr)
    HeaderFileNr = 0
  EndIf
  
  If InputFileNr
    CloseFile(InputFileNr)
    InputFileNr = 0
  EndIf
  
  LogMsg("Error: " + Error)
  LogMsg("Temporary files may be in " + TmpSubDir)
  
  If RenameFile(InputDir + InputFile, InputDir + InputFile + ".error")
    LogMsg("Inputfile renamed naar " + InputDir + InputFile + ".error")  
  Else
    Logmsg("Critical: Unable to rename " + InputDir + InputFile)
  EndIf
  
Return
;}
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 147
; FirstLine = 23
; Folding = AO8
; EnableXP
