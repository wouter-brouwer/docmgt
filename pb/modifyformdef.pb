#Prog = "SplitAFP"

;{ Documentatie

; Dit programma splitst AFP bestanden naar losse documenten.
; De AFP headers (resources) worden apart opgeslagen.

; Input filenamen dienen te bestaan uit <stroom>_<iets unieks>.afp

; Bij de verwerking wordt een <timestamp> bepaald uit systeemdatum yyyymmddhhiiss
; als deze gelijk is aan de vorige wordt een seconde gewacht.

; De uitvoer bestanden heten <stroom>_<timestamp>_<sequencenr>_p<pages>.afp

;}

IncludeFile "Common.pbi"

IncludeFile "AFP.pbi"

Global ConfigDir.s
Global RunControlDir.s

IncludeFile "StreamInfo.pbi"

;{ Initialisatie

; <<< T.b.v. Controle-D fout correctie
; PGP Page Position
HexString.s = "D3B1AF 00 0000 01" ; SFID + Flags + Reserved
HexString + "0C 000000 000000 0000 20 00 FF"
HexString + "0C 000000 000000 0000 10 00 FF"
HexString + "0C 000000 000000 0000 40 00 FF"
HexString + "0C 000000 000000 0000 30 00 FF"
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*PGP = AllocateMemory(HexLen(HexString) + 5)
PGPlen = PokeHexString(*PGP, HexString)
; <<< T.b.v. Controle-D fout correctie

InputFileNr = OpenFile(#PB_Any, "F1A54UPD")

OutputFileNr = CreateFile(#PB_Any, "F1A54UPX")
   
  ;}
  
  ;{ Loop input records
  While Not Eof(InputFileNr)
    skip = 0
    
    l0.c = ReadCharacter(InputFileNr)
    If l0 <> 90
      CallDebugger
      End
    EndIf
    RecordLength.u = ReadUU(InputFileNr) - 2
    
    ReadData(InputFileNr, *AFPRecord, RecordLength)
    RecordNr + 1
    
   
    ; Structured Field Identifier
    SFID.s = HexString(PeekS(*AFPRecord,3))
    
    If SFID = PGP
      WriteData(OutputFileNr, *PGP, PGPlen)
      skip = 1
    EndIf        
        
        
  
    ;{ Schrijf het record naar het betreffend uitvoerbestand
    If Skip = 0
      WriteCharacter(OutputFileNr, l0)
      WriteUU(OutputFileNr, RecordLength + 2)
      WriteData(OutputFileNr, *AFPRecord, RecordLength)
    EndIf
    ;}
    
  
  
  Wend
  ;}
  
  ;{ Afsluiting

  

    CloseFile(InputFileNr)

    CloseFile(OutputFileNr)


  
  End
  
  ;{
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 29
; FirstLine = 11
; Folding = +-
; EnableXP
; Executable = SplitAFP