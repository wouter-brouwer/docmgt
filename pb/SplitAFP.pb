#Prog = "SplitAFP"

;{ Documentatie

; Dit programma splitst AFP bestanden naar losse documenten.
; De AFP headers (resources) worden apart opgeslagen.

; Input filenamen dienen te bestaan uit <stroom>_<iets unieks>.afp

; Bij de verwerking wordt een <timestamp> bepaald uit systeemdatum yyyymmddhhiiss
; als deze gelijk is aan de vorige wordt een seconde gewacht.

; De uitvoer bestanden heten <stroom>_<timestamp>_header.afp in /aiw/aiw1/documenten/headers
;  en <stroom>_<timestamp>_<sequencenr>_p<pages>.afp

;}

IncludeFile "Common.pbi"

IncludeFile "AFP.pbi"

Global ConfigDir.s

IncludeFile "StreamInfo.pbi"

;{ Initialisatie

NewList OutputFiles.s()

If Not OpenPreferences("openloop.ini")
  LogMsg("Critical: Unable to open openloop.ini")
EndIf

ConfigDir.s = CheckDirectory(ReadPreferenceString("ConfigDir",""))
TmpDir.s = CheckDirectory(ReadPreferenceString("TmpDir",""))
LogDir = CheckDirectory(ReadPreferenceString("LogsDir",""))
LockDir.s = CheckDirectory(ReadPreferenceString("LocksDir",""))
InputDir.s = CheckDirectory(ReadPreferenceString("InputAfpDir",""))
TodoDir.s = CheckDirectory(ReadPreferenceString("ToDoDir",""))
ResourcesDir.s = CheckDirectory(ReadPreferenceString("ResourcesDir",""))
ClosePreferences()

LockFile.s = LockDir + #Prog + ".lock"
LockFileNr = CreateFile(#PB_Any, LockFile)
If LockFileNr = 0 
  LogMsg("Critical: Unable to create " + LockFile + " Program already running?")
EndIf

; <<< T.b.v. Controle-D fout correctie
; ENG End Named Group
HexString.s = "D3A9EB 00 0000 FFFFFFFFFFFFFFFF" ; SFID + Flags + Reserved
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*ENG = AllocateMemory(HexLen(HexString) + 5)
ENGlen = PokeHexString(*ENG, HexString)
; <<< T.b.v. Controle-D fout correctie

LogMsg(#Prog + " started")
;}

;{ Main loop
; TEST
;While FileSize(#Prog + ".stop") = -1 ; Zolang er geen SplitAFP.stop bestand is

  ; Verwerk alle AFP bestanden uit de input directory
  If ExamineDirectory(0, InputDir, "*.afp")
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_File
        InputFile.s = DirectoryEntryName(0)
        If Right(InputFile, 5) <> ".done"
          Gosub VerwerkFile
        EndIf
      EndIf
    Wend
    FinishDirectory(0)
  EndIf
  
  LogMsg("") ; Om logfile te kunnen closen bij geen activiteit
  Delay(100) ; CPU besparing
  
; TEST
;Wend
;}
  
;{ Afsluiting
CloseFile(LockFileNr)
DeleteFile(LockFile)
End
;}

;{ VerwerkFile:
VerwerkFile:

  ;{ Initialisatie
  ClearList(OutputFiles())

  Error.s = ""
  LogMsg("Info: Processing " + InputDir + InputFile)

  p = FindString(InputFile, "_")
  If p <= 1
    Error.s = "Input file niet volgens formaat <stroom>_<iets>.afp"
    Goto VerwerkFileError:
  EndIf
  Stroom.s = Left(InputFile, p - 1)
  If LCase(StreamInfo(Stroom,"Stroom")) <> LCase(Stroom)
    Error.s = "Onbekende stroom " + Stroom
    Goto VerwerkFileError:
  EndIf
  
  CreateDirectory(ResourcesDir + Stroom)
  ResourcesSubDir.s = CheckDirectory(ResourcesDir + Stroom)
  
  While Date() <= LastRun
    Delay(100)
  Wend
  LastRun = Date()
  
  TimeStamp.s = FormatDate("%yyyy%mm%dd%hh%ii%ss",Date())
  
  OutputBase.s = Stroom + "_" + TimeStamp
  
  CreateDirectory(TmpDir + OutputBase)
  TmpSubDir.s = CheckDirectory(TmpDir + OutputBase)
  
  CreateDirectory(TodoDir + Stroom)
  TodoSubDir.s = CheckDirectory(TodoDir + Stroom)
  
  InputFileNr = ReadFile(#PB_Any, InputDir + InputFile)
  If InputFileNr = 0
    Error = "InputFile can not be opened."
    Gosub VerwerkFileError
    Return
  EndIf
  
  HeaderFile.s = OutputBase + "_header" + ".afp"
  HeaderFileNr = CreateFile(#PB_Any, TmpSubDir + HeaderFile)
  If HeaderFileNr = 0
    Error = "HeaderFile '" + TmpSubDir + HeaderFile + "' can not be opened."
    Gosub VerwerkFileError
    Return
  EndIf
  
  NamedGroupLevel = 0
  Documents = 0
  PreviousSFID.s = ""
  RecordNr = 0
  Header = 1
  
  ; <<< T.b.v. Control-D fout correctie
  NopRecord = 0
  
  ;}
  
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
    ReadData(InputFileNr, *AFPRecord, RecordLength)
    RecordNr + 1
    
    ; Structured Field Identifier
    SFID.s = HexString(PeekS(*AFPRecord,3))
    Debug SFID
    Select SFID
        
      Case NOP
        ; <<< T.b.v. Control-D fout correctie
        If HexString(PeekS(*AFPRecord + 6, 8))  = "FFFFFFFFFFFFFFFF"
          NopRecord = RecordNr
        EndIf
        ;
        
      Case BDT
        Debug "BDT"
        Header = 0
        CloseFile(HeaderFileNr)
        HeaderFileNr = 0
        Skip = 1
        
      Case BPG
        Debug "BPG"
        Pages + 1
        
      Case EPG
        ;Debug "EPG"
        ; <<< T.b.v. Control-D fout correctie
        LastEpgRecord = RecordNr
        ;
      Case EDT
        ;Debug "EDT"
        Gosub CloseOutputFile
        Skip = 1
        
      Case BNG
        ;Debug "BNG"
        ; <<< T.b.v. Control-D fout correctie
        If NopRecord = Record - 1 And LastEpgRecord = Record - 2 And NamedGroupLevel = 1
          WriteData(OutputFileNr, *ENG, ENGlen)
          LogMsg("ENG inserted for document " + Str(Documents))
          NamedGroupLevel - 1
        EndIf
        ;
        NamedGroupLevel + 1
        ;Debug Str(NamedGroupLevel)
        If NamedGroupLevel > 1
          Error = "Bestand bevat geneste Named Groups"
          Break
        EndIf
        Documents + 1
        Gosub CloseOutputFile
        ;{ Elke minuut wat voortgang tonen
        If Date() > LastRun + 60
          LastRun = Date()
          LogMsg("Info: " + Str(Documents) + " Documents")
        EndIf
        ;}
        ;{ Output bestand openen
        OutputFile.s = OutputBase + "_0" + RSet(Str(Documents), 6, "0") + ".afp"
        OutputFileNr = CreateFile(#PB_Any, TmpSubDir + OutputFile)
        If OutputFileNr = 0 
          Error = "Unable to create " + TmpSubDir + OutputFile
          Break
        EndIf
        ;}
        Pages = 0
    EndSelect
  
    ;{ Schrijf het record naar het betreffend uitvoerbestand
    If Skip = 0
      If Header = 1
        FileNr = HeaderFileNr
      Else
        If NamedGroupLevel > 0 Or Stroom = "83"
          FileNr = OutputFileNr
        Else
          FileNr = 0
        EndIf
      EndIf
      If FileNr > 0
        WriteCharacter(FileNr, l0)
        WriteCharacter(FileNr, l1)
        WriteCharacter(FileNr, l2)
        WriteData(FileNr, *AFPRecord, RecordLength)
      EndIf
    EndIf
    ;}
    
    If SFID = ENG
      ;Debug "ENG"
      NamedGroupLevel - 1
    EndIf
    
    PreviousSFID.s = SFID
  
  Wend
  ;}
  
  ;{ Afsluiting
  If Error <> ""
    Gosub VerwerkFileError
    Return
  EndIf
  
  LogMsg("Info: " + Str(Documents) + " Documents")
  
  If InputFileNr
    CloseFile(InputFileNr)
    InputFileNr = 0
  EndIf
  
  ; Move all files to final destinations
  
  If Not RenameFile(TmpSubDir + HeaderFile, ResourcesSubDir + HeaderFile)
    LogMsg("Critical: Unable to move " + TmpSubDir + HeaderFile + " to " + ResourcesSubDir + HeaderFile)
  EndIf
  
  ForEach OutputFiles()
    If Not RenameFile(TmpSubDir + OutputFiles(), TodoSubDir + OutputFiles())
        LogMsg("Critical: Unable to move " + TmpSubDir + OutputFiles() + " to " + TodoSubDir)
    EndIf
  Next
  
  DeleteDirectory(TmpSubDir, "")
  ;} 
  
Return ; <--- TEST
  
  If RenameFile(InputDir + InputFile, InputDir + InputFile + ".done")
    LogMsg(InputDir + InputFile + " moved to " + ProcessedDir)  
  Else
    Logmsg("Critical: Unable move " + InputDir + InputFile + " to " + ProcessedDir)
  EndIf
 
Return
;}

;{ CloseOutputFile:
CloseOutputFile:
  If OutputFileNr > 0
    CloseFile(OutputFileNr)
    OutputFileNr = 0
    AddElement(OutputFiles())
    ; Aantal pagina's toevoegen aan bestandsnaam
    OutputFiles() = ReplaceString(OutputFile.s, ".", "_P" + Str(Pages) + ".")
    RenameFile(TmpSubDir + OutputFile, TmpSubDir + OutputFiles()) 
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
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 216
; FirstLine = 161
; Folding = yJ+
; EnableXP