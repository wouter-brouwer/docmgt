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

InputDir.s = "split/"
OutputDir.s = "merged/"

*BDT = AllocateMemory(17)
PokeHexString(*BDT, "5a0010d3a8a8000000ffffffffffffffff")
*EDT = AllocateMemory(17)
PokeHexString(*EDT, "5a0010d3a9a8000000ffffffffffffffff")

;}

;{ Loop input bestanden

If ExamineDirectory(0, InputDir, "*_0*")
  While NextDirectoryEntry(0)
    If DirectoryEntryType(0) = #PB_DirectoryEntry_File
      InputFileName.s = DirectoryEntryName(0)
      Gosub VerwerkFile
    EndIf
  Wend
  FinishDirectory(0)
EndIf

If OutputFileNr > 0
  WriteData(OutputFileNr, *EDT, 17)
  CloseFile(OutputFileNr)
  OutputFileNr = 0
  LogMsg("Info: " + Str(Documents) + " documents")
EndIf

;}

End

;{ VerwerkFile:
VerwerkFile:

  OutputFile.s = StringField(InputFileName, 1, "_0")
  
  If OutputFile <> PreviousOutputFile.s
    If OutputFileNr > 0
      WriteData(OutputFileNr, *EDT, 17)
      CloseFile(OutputFileNr)
      OutputFileNr = 0
      LogMsg("Info: " + Str(Documents) + " documents")
    EndIf
    ; Read Header
    HeaderFile.s = OutputFile + "_header"
    HeaderFileNr = ReadFile(#PB_Any, InputDir + HeaderFile)
    If HeaderFileNr = 0 
      LogMsg("Error: ???")
      End
    EndIf  
    HeaderLength = Lof(HeaderFileNr)
    *HeaderBuffer = AllocateMemory(HeaderLength)
    ReadData(HeaderFileNr, *HeaderBuffer, HeaderLength)
    CloseFile(HeaderFileNr)
    ; Create OutputFile
    OutputFileNr = CreateFile(#PB_Any, OutputDir + OutputFile)
    LogMsg("Info: Creating " + OutputFile)
    If OutputFileNr = 0
      LogMsg("Error: ???")
      End
    EndIf
    Documents = 0
    ; Write Header
    WriteData(OutputFileNr, *HeaderBuffer, HeaderLength)
    WriteData(OutputFileNr, *BDT, 17)
    PreviousOutputFile = OutputFile
  EndIf
  
  InputFileNr = ReadFile(#PB_Any, InputDir + InputFileName)
  If InputFileNr = 0 
    LogMsg("Error: ???")
    End
  EndIf  
  
  InputFileLength = Lof(InputFileNr)
  *Buffer = AllocateMemory(InputFileLength)
  ReadData(InputFileNr, *Buffer, InputFileLength)
  CloseFile(InputFileNr)
  WriteData(OutputFileNr, *Buffer, InputFileLength)
  Documents + 1

Return
;}
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 148
; FirstLine = 22
; Folding = A+
; EnableXP