#Prog = "SplitAFP"

;{ Documentatie

; Dit programma splitst AFP bestanden naar losse documenten.
; De AFP header wordt apart opgeslagen.

; Input filenamen dienen te bestaan uit <stroom>_<iets unieks>.afp

; Bij de verwerking wordt een <timestamp> bepaald uit systeemdatum yyyymmddhhiiss
; als deze gelijk is aan de vorige wordt een seconde gewacht.

; De uitvoer bestanden heten <stroom>_yyyymmdduuiiss_header.afp in /aiw/aiw1/documenten/headers
;  en <stroom>_<timestamp>_<sequencenr>_p<pages>.afp

;}

Procedure.s HexString(String.s)

  For i = 1 To Len(String)
    HexString.s + Right("0" + Hex(Asc(Mid(String,i,1))),2)
  Next i
  
  ProcedureReturn HexString

EndProcedure

;{ Maak Barcode records

Procedure HexLen(String.s)
  String = ReplaceString(String, " ", "")
  ProcedureReturn Len(String) / 2
EndProcedure

Procedure.s Hex2(Number, Len)
  ProcedureReturn RSet(Hex(Number, #PB_Long), Len, "0")
EndProcedure

Procedure PokeHexString(*Buffer, String.s)
  String = ReplaceString(String, " ", "")
  ;Debug String
  Len = Len(String) / 2
  OffSet = 0
  For i = 1 To Len(String) Step 2
    ;Debug Str(i)
    If i = 17 
      ;CallDebugger
    EndIf
    ;Debug Mid(String, i, 1)
    h = Asc(Mid(String,i,1))
    h - 48
    If h > 10
      h - 7
    EndIf
    ;Debug Mid(String, i+1, 1)
    l = Asc(Mid(String,i+1,1))
    l - 48
    If l > 10
      l - 7
    EndIf
    PokeC(*Buffer + OffSet, h * 16 + l)
    OffSet + 1
  Next i
  ProcedureReturn Len
EndProcedure

; BBC Begin Barcode Object
HexString.s = "D3A8EB 00 0000" ; SFID + Flags + Reserved
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*BBC = AllocateMemory(HexLen(HexString))
BBClen = PokeHexString(*BBC, HexString)


; BOG Begin Object Environment Group
HexString = "D3A8C7 00 0000" ; SFID + Flags + Reserved
HexString + "F0F0F0F0F0F0F1" ; (OEG Name)
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*BOG = AllocateMemory(HexLen(HexString))
BOGlen = PokeHexString(*BOG, HexString)

; OBD Object Area Descriptor
HexString = "D3A66B 00 0000" ; SFID + Flags + Reserved
HexString + "03 43 01" ; Descriptor Position
HexString + "08 4B 00 00 0960 0960" ; Measurement Units
HexString + "09 4C 02 000000 000000" ; Object Area Size
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*OBD = AllocateMemory(HexLen(HexString))
OBDlen = PokeHexString(*OBD, HexString)

; OBP Object Area Position
HexString = "D3AC6B 00 0000" ; SFID + Flags + Reserved
HexString + "01" ; Position ID
HexString + "17" ; Len
HexString + "000060 000F00" ; X Y-as origin
HexString + "0000 0000" ; X Y rotation
HexString + "00" ; Reserved
HexString + "000000 000000" ; X Y origin object content
HexString + "0000 2D00 00" 
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*OBP = AllocateMemory(HexLen(HexString))
OBPlen = PokeHexString(*OBP, HexString)

; BDD Barcode Data Descriptor
HexString = "D3A6EB 00 0000" ; SFID + Flags + Reserved
; BSD Barcode Symbol Descriptor
HexString + "00" ; Unit Base 00 = 10" 01 = 10cm
HexString + "00" ; Reserved
HexString + "0960" ; Units per unitbase X
HexString + "0960" ; Units per unitbase Y
HexString + "0000" ; Width presentationspace
HexString + "0000" ; Length presentationspace
HexString + "0000" ; Desired symbol width
HexString + "1C 00"; Data Matrix
HexString + "FF"   ; Font
HexString + "FFFF" ; Color
HexString + "10"   ; ModuleWidth in mils
HexString + "0000" ; ElementHeight
HexString + "00"   ; Height Multiplier
HexString + "0000" ;WideNarrow ratio
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*BDD = AllocateMemory(HexLen(HexString) + 5)
BDDlen = PokeHexString(*BDD, HexString)

; EOG End Object Environment Group
HexString = "D3A9C7 00 0000" ; SFID + Flags + Reserved
HexString + "F0F0F0F0F0F0F1" ; (OEG Name)
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*EOG = AllocateMemory(HexLen(HexString) + 5)
EOGlen = PokeHexString(*EOG, HexString)

; BDA Barcode Data
HexString = "D3EEEB 00 0000" ; SFID + Flags + Reserved
; BSA Barcode Symbol Data
HexString + "00" ; Barcode flags
HexString + "0000 0000"; x + y Coordinates
HexString + "00" ; Control flags
HexString + "0010" ; Row size
HexString + "0010" ; Number of rows
HexString + "00" ; Sequence indicator
HexString + "00" ; Total symbols
HexString + "01" ; FileID byte 1
HexString + "01" ; FileID byte 2
HexString + "01" ; Special function flags
Hexstring + HexString("123456001234560000100002000000111") ; Data
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*BDA = AllocateMemory(HexLen(HexString) + 5)
BDAlen = PokeHexString(*BDA, HexString)

; EBC End Barcode Object
HexString.s = "D3A9EB 00 0000" ; SFID + Flags + Reserved
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*EBC = AllocateMemory(HexLen(HexString) + 5)
EBClen = PokeHexString(*EBC, HexString)



;}

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

Procedure xPokeHexString(*Pointer,String.s)
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

NewList OutputFiles.s()

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

ProcessedDir.s = CheckDirectory(InputDir + "processed")

TmpDir.s = CheckDirectory(InputDir + "tmp")

TodoDir.s = CheckDirectory(DocumentDir + "todo")

HeadersDir.s = CheckDirectory(DocumentDir + "headers")

LockFile.s = LockDir + #Prog + ".lock"
LockFileNr = CreateFile(#PB_Any, LockFile)
If LockFileNr = 0 
  LogMsg("Critical: Unable to create " + LockFile + " Program already running?")
EndIf
LogMsg(#Prog + " started")
;}

;{ Main loop
;While FileSize(#Prog + ".stop") = -1 ; Zolang er geen SplitAFP.stop bestand is

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
  
;Wend
;}
  
;{ Afsluiting
CloseFile(LockFileNr)
DeleteFile(LockFile)
End
;}

;{ VerwerkFile:
VerwerkFile:

ClearList(OutputFiles())

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
      HeaderFileNr = 0
      Skip = 1
    EndIf
    
    If Header = 0
      ;Debug Triplet
    EndIf
  
    
    If Triplet = "D3EEEE" ; NOP
    EndIf
    
    If Triplet = "D3A8AF" ; BPG
      Pages + 1
    EndIf
    
    If Triplet = "D3A9AF" ; EPG
      
      WriteData(OutputFileNr, *BBC, BBClen)
      WriteData(OutputFileNr, *BOG, BOGlen)
      WriteData(OutputFileNr, *OBD, OBDlen)
      WriteData(OutputFileNr, *OBP, OBPlen)
      WriteData(OutputFileNr, *BDD, BDDlen)
      WriteData(OutputFileNr, *EOG, EOGlen)
      WriteData(OutputFileNr, *BDA, BDAlen)
      WriteData(OutputFileNr, *EBC, EBClen)
     
    EndIf
    
    If Triplet = "D3A9A8" ; EDT
      If OutputFileNr > 0
        CloseFile(OutputFileNr)
        OutputFileNr = 0
        AddElement(OutputFiles())
        OutputFiles() = ReplaceString(OutputFile.s, ".", "_P" + Str(Pages) + ".")
        RenameFile(TmpSubDir + OutputFile, TmpSubDir + OutputFiles()) 
      EndIf
      Skip = 1
    EndIf
    
    If Triplet = "D3A8AD" ; BNG
      If OutputFileNr > 0
        CloseFile(OutputFileNr)
        OutputFileNr = 0
        AddElement(OutputFiles())
        OutputFiles() = ReplaceString(OutputFile.s, ".", "_P" + Str(Pages) + ".")
        RenameFile(TmpSubDir + OutputFile, TmpSubDir + OutputFiles()) 
      EndIf
      NamedGroupLevel + 1
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
      Pages = 0
    EndIf
    
    If Header = 1
      WriteCharacter(HeaderFileNr, l0)
      WriteCharacter(HeaderFileNr, l1)
      WriteCharacter(HeaderFileNr, l2)
      WriteData(HeaderFileNr, *Record, RecordLength)
    EndIf
      
    If Header = 0 And Skip = 0
      WriteCharacter(OutputFileNr, l0)
      WriteCharacter(OutputFileNr, l1)
      WriteCharacter(OutputFileNr, l2)
      WriteData(OutputFileNr, *Record, RecordLength)
    EndIf
    
    If Triplet = "D3A9AD" ; ENG
      NamedGroupLevel - 1
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
  
  ForEach OutputFiles()
    If Not RenameFile(TmpSubDir + OutputFiles(), TodoSubDir + OutputFiles())
        LogMsg("Critical: Unable to move " + TmpSubDir + OutputFiles() + " to " + TodoSubDir)
    EndIf
  Next
  
  DeleteDirectory(TmpSubDir, "")
  
Return
  
  If RenameFile(InputDir + InputFile, ProcessedDir + InputFile)
    LogMsg(InputDir + InputFile + " moved to " + ProcessedDir)  
  Else
    Logmsg("Critical: Unable move " + InputDir + InputFile + " to " + ProcessedDir)
  EndIf
 
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
; IDE Options = PureBasic 5.20 LTS (Linux - x64)
; CursorPosition = 93
; FirstLine = 38
; Folding = FAs0
; EnableXP