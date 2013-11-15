; neem de header en alle files en plak ze aan elkaar

Procedure LogMsg(Msg.s)
  TimeStamp.s = FormatDate("%dd-%mm-%yyyy %hh:%ii:%ss", Date())
  Regel.s = TimeStamp + " - " + Msg
  Debug Regel
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

;{ Initialisatie

JobsDir.s = "./documents/jobs/"
HeaderDir.s = "./documents/headers/"
OutputDir.s = "./System/hf/afp/"

*BDT = AllocateMemory(17)
PokeHexString(*BDT, "5a0010d3a8a8000000ffffffffffffffff")
*EDT = AllocateMemory(17)
PokeHexString(*EDT, "5a0010d3a9a8000000ffffffffffffffff")
NewList FileNames.s()
;}

;{ Loop door de jobs
If ExamineDirectory(0, JobsDir, "*.*")
  While NextDirectoryEntry(0)
    If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
      JobName.s = DirectoryEntryName(0)
      JobDir.s = JobsDir + JobName + "/"
      Gosub VerwerkJob
    EndIf
  Wend
  FinishDirectory(0)
EndIf
;}

End

;{ VerwerkJob:
VerwerkJob:

ClearList(FileNames())
If ExamineDirectory(1, JobDir, "*.afp")
  While NextDirectoryEntry(1)
    If DirectoryEntryType(1) = #PB_DirectoryEntry_File
      AddElement(FileNames())
      FileNames() = DirectoryEntryName(1)
    EndIf
  Wend
  FinishDirectory(1)
EndIf

SortList(FileNames(), #PB_Sort_Ascending)

ForEach FileNames()
  InputFile.s = FileNames()
  Gosub VerwerkFile
Next

If OutputFileNr > 0
  WriteData(OutputFileNr, *EDT, 17)
  CloseFile(OutputFileNr)
  OutputFileNr = 0
  LogMsg("Info: " + Str(Documents) + " documents")
  RenameFile(OutputDir + OutputFile.s, OutputDir + ReplaceString(OutputFile, ".tmp", ".afp"))
EndIf
Return
;}


;{ VerwerkFile:
VerwerkFile:

  OutputFile.s = StringField(InputFile, 1, "_0") + ".tmp"
  
  If OutputFile <> PreviousOutputFile.s
    If OutputFileNr > 0
      WriteData(OutputFileNr, *EDT, 17)
      CloseFile(OutputFileNr)
      OutputFileNr = 0
      LogMsg("Info: " + Str(Documents) + " documents")
    EndIf
    ; Read Header
    HeaderFile.s = ReplaceString(OutputFile, ".", "_header.")
    HeaderFile.s = ReplaceString(HeaderFile, ".tmp", ".afp")
    HeaderFileNr = ReadFile(#PB_Any, HeaderDir + HeaderFile)
    If HeaderFileNr = 0 
      LogMsg("Critical: Can not read " + HeaderDir + HeaderFile)
    EndIf  
    HeaderLength = Lof(HeaderFileNr)
    *HeaderBuffer = AllocateMemory(HeaderLength)
    ReadData(HeaderFileNr, *HeaderBuffer, HeaderLength)
    CloseFile(HeaderFileNr)
    ; Create OutputFile
    OutputFileNr = CreateFile(#PB_Any, OutputDir + OutputFile)
    If OutputFileNr = 0
      LogMsg("Critical: Unable to create " + OutputDir + OutputFile)
    EndIf
    LogMsg("Info: Creating " + OutputFile)
    Documents = 0
    ; Write Header
    WriteData(OutputFileNr, *HeaderBuffer, HeaderLength)
    WriteData(OutputFileNr, *BDT, 17)
    PreviousOutputFile = OutputFile
  EndIf
  
  InputFileNr = ReadFile(#PB_Any, JobDir + InputFile)
  If InputFileNr = 0 
    LogMsg("Critical: Unable to read " + JobDir + InputFile)
  EndIf  
  
  InputFileLength = Lof(InputFileNr)
  *Buffer = AllocateMemory(InputFileLength)
  ReadData(InputFileNr, *Buffer, InputFileLength)
  CloseFile(InputFileNr)
  WriteData(OutputFileNr, *Buffer, InputFileLength)
  Documents + 1

Return
;}

; IDE Options = PureBasic 5.20 LTS (Linux - x64)
; CursorPosition = 166
; FirstLine = 163
; Folding = --
; EnableXP