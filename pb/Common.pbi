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
  
  ; De boodschap met datum en tijd naar de log schrijven
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

Procedure HexLen(String.s)
  String = ReplaceString(String, " ", "")
  ProcedureReturn Len(String) / 2
EndProcedure

Procedure.s Hex2(Number, Len)
  ProcedureReturn RSet(Hex(Number, #PB_Long), Len, "0")
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

Procedure PokeUU(*Buffer, Value.u)
  ; Zet een 2bytes unsigned waarde in het geheugen met de high order byte eerst
  l1.c = Value / 256
  l2.c = Value % 256
  PokeC(*Buffer, l1)
  PokeC(*Buffer + 1, l2)
EndProcedure

Procedure.u PeekUU(*Buffer)
  ; Haalt een 2 byte unsigned waarde uit het geheugen met de high order byte eerst 
  l1.c = PeekC(*Buffer)
  l2.c = PeekC(*Buffer + 1)
  ProcedureReturn l1 * 256 + l2
EndProcedure

Procedure.u ReadUU(FileNr)
  l1.c = ReadCharacter(FileNr)
  l2.c = ReadCharacter(FileNr)
  ProcedureReturn l1 * 256 + l2
EndProcedure

Procedure WriteUU(FileNr, Value.u)
  l1.c = Value / 256
  l2.c = Value % 256
  WriteCharacter(Filenr, l1)
  WriteCharacter(FileNr, l2)

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

Procedure.s CheckDirectory(Dir.s)
  rc = FileSize(Dir)
  If rc <> -2
    LogMsg("Critical: Missing directory "+ Dir)
  Else
    ProcedureReturn Dir + "/"
  EndIf
EndProcedure
; IDE Options = PureBasic 5.20 LTS (Linux - x64)
; CursorPosition = 117
; FirstLine = 4
; Folding = AN9
; EnableXP