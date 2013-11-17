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

;{ Maak Barcode records

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
; IDE Options = PureBasic 5.20 LTS (Linux - x64)
; Folding = Ag
; EnableXP