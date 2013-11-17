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

;{ Initialisatie

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
; TEST
;While FileSize(#Prog + ".stop") = -1 ; Zolang er geen SplitAFP.stop bestand is

  ; Verwerk alle AFP bestanden uit de input directory
  If ExamineDirectory(0, InputDir, "*.afp")
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_File
        InputFile.s = DirectoryEntryName(0)
        Gosub VerwerkFile
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
    
    Select SFID
      Case BDT
        Header = 0
        CloseFile(HeaderFileNr)
        HeaderFileNr = 0
        Skip = 1
      Case BPG
        Pages + 1
      Case EDT
        Gosub CloseOutputFile
        Skip = 1
      Case BNG
        NamedGroupLevel + 1
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
        FileNr = OutputFileNr
      EndIf
      WriteCharacter(FileNr, l0)
      WriteCharacter(FileNr, l1)
      WriteCharacter(FileNr, l2)
      WriteData(FileNr, *AFPRecord, RecordLength)
    EndIf
    ;}
    
    If SFID = ENG
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
  
  If Not RenameFile(TmpSubDir + HeaderFile, HeadersDir + HeaderFile)
    LogMsg("Critical: Unable to move " + TmpSubDir + HeaderFile + " to " + HeadersDir + HeaderFile)
  EndIf
  
  ForEach OutputFiles()
    If Not RenameFile(TmpSubDir + OutputFiles(), TodoSubDir + OutputFiles())
        LogMsg("Critical: Unable to move " + TmpSubDir + OutputFiles() + " to " + TodoSubDir)
    EndIf
  Next
  
  DeleteDirectory(TmpSubDir, "")
  ;} 
  
Return ; <--- TEST
  
  If RenameFile(InputDir + InputFile, ProcessedDir + InputFile)
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
; IDE Options = PureBasic 5.20 LTS (Linux - x64)
; CursorPosition = 169
; Folding = Q-+
; EnableXP