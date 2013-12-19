#Prog = "RepairAFP"

;{ Documentatie

; Eddoc Weaver produceert soms AFP uitvoer waarbij het default character van de codepage
; niet bestaat.

; Dit programma repareert dat door hiervoor het eerste character van de codepage index te gebruiken.

; Daarnaast repareert hij ook de fout met de puntgrootte nul van een font 

;}

IncludeFile "Common.pbi"

IncludeFile "AFP.pbi"

;{ Initialisatie

OpenConsole() ; om naar Sysout te kunnen schrijven

If CountProgramParameters() <> 2
  PrintN("Usage: repairafp <inputfile> <outputfile>")
  End 1
EndIf


InputFile.s = ProgramParameter()
;InputFile.s = "c:\tmp\10113072.print_range.afp"
InputFileNr = ReadFile(#PB_Any, InputFile)
If InputFileNr = 0 
  PrintN("Unable to read " + InputFile)
  End 1
EndIf
  
OutputFile.s = ProgramParameter()
;OutputFile = InputFile + ".repaired"
OutputFileNr = CreateFile(#PB_Any, OutputFile)
If OutputFileNr = 0 
  PrintN("Unable to create " + OutputFile)
  End 1
EndIf

RecordNr = 0

;}

;{ Loop input records
While Not Eof(InputFileNr)
  
  Position = Loc(InputFileNr)
  
  l0.c = ReadCharacter(InputFileNr)
  If l0 <> 90
    Print (InputFile + " contains invalid AFP")
    End 1
  EndIf
  l1.c = ReadCharacter(InputFileNr)
  l2.c = ReadCharacter(InputFileNr)
  
  RecordLength = l1 * 256 + l2 - 2
  ReadData(InputFileNr, *AFPRecord, RecordLength)
  RecordNr + 1
  
  ; Structured Field Identifier
  SFID.s = HexString(PeekS(*AFPRecord,3))
  
  Select SFID
      
    Case FND ; Font Description
      Debug PeekHexString(*AFPRecord + 40, 6)
      If PeekHexString(*AFPRecord + 40, 6) = "000000000000"
        PokeHexString(*AFPRecord + 40, "006C006C006C")
        PrintN(InputFile + " contains invalid FND at record " + Str(RecordNr))        
      EndIf        
      
    Case CPC ; Code Page Control
      DefaultChar.s = EbcdicToAscii(PeekS(*AFPRecord + 6, 8))
      DefaultCharLoc = Position + 9 ; Bewaar de positie
      
    Case CPI ; Code Page Index
      Lijst.s = "" ; Initieer het lijstje
      Offset = 6 ; Initiele offset
      While Offset + 8 < RecordLength ; Zolang je nog in het record zit
        Lijst + EbcdicToAscii(PeekS(*AFPRecord + Offset, 8)) + ";" ; Voeg toe aan het lijstje
        Offset + 10 ; volgende
      Wend
      Debug Lijst
      If FindString(Lijst, DefaultChar) = 0 ; Staat het defaultchar in het lijstje
        PrintN(InputFile + " contains invalid Default character " + DefaultChar +" at record " + Str(RecordNr))
        FileSeek(OutputFileNr, DefaultCharLoc)
        WriteString(OutputFileNr, AsciiToEbcdic(StringField(Lijst, 1, ";")))
        FileSeek(OutputFileNr, Lof(OutputFileNr))
      EndIf
      
  EndSelect 
      
  WriteCharacter(OutputFileNr, l0) ; Separator
  WriteCharacter(OutputFileNr, l1) ; Lengte 1
  WriteCharacter(OutputFileNr, l2) ; Lengte 2
  WriteData(OutputFileNr, *AFPRecord, RecordLength)
  
Wend
;}
  
;{ Afsluiting  

CloseFile(InputFileNr)
CloseFile(OutputFileNr)

End  

;}
; IDE Options = PureBasic 5.11 (Linux - x86)
; CursorPosition = 73
; Folding = 4
; EnableXP
; Executable = RepairAFP