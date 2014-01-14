#Prog = "RemoveTLEs"

;{ Documentatie

; PDS Streamweaver produceert AFP met heel veel TLE's

; Dit programma verwijdert de overtollige TLE's waardoor de uitvoer veel compacter wordt 
; en daardoor ook veel sneller in Eddoc Weaver verwerkt kan worden.

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
;InputFile.s = "C:\tmp\DepersAFP\Output\AS640014.afp"
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
  
  Skip = 0
  Select SFID
      
      
    Case NOP
      Skip = 1
      
        s.s = EbcdicToAscii(PeekS(*AFPRecord + 6, RecordLength - 6))
  
        ; NOP content moet "Job.<property name>=<property value>" zijn
        If Left(s, 4) = "Job." And FindString(s, "=")
          Skip = 0
        EndIf  
      
    Case TLE
      skip = 1
      ln.c = PeekC(*AFPRecord + 6)
      TagName.s = EbcdicToAscii(PeekS(*AFPRecord + 6 + 4, ln - 4))
      lv.c = PeekC(*AFPRecord + 6 + ln)
      TagValue.s = EbcdicToAscii(PeekS(*AFPRecord + 6 + 4 + ln, lv - 4))
      Select TagName
        Case "ADF_IP_PIECEID"
          skip = 0
        Case "ADF_IP_INSERTERSTATIONS"
          skip = 0
        Case "ADF_IP_EDGEMARKER"
          skip = 0
        Case "ADF_IP_QUALITYCHECK"
          skip = 0
        Case "ADF_IP_NEXTCHANNEL"
          skip = 0
      EndSelect
      
  EndSelect 
      
  If Skip = 0
    WriteCharacter(OutputFileNr, l0) ; Separator
    WriteCharacter(OutputFileNr, l1) ; Lengte 1
    WriteCharacter(OutputFileNr, l2) ; Lengte 2
    WriteData(OutputFileNr, *AFPRecord, RecordLength)
  EndIf

Wend
;}
  
;{ Afsluiting  

CloseFile(InputFileNr)
CloseFile(OutputFileNr)

End  

;}
; IDE Options = PureBasic 5.11 (Linux - x86)
; CursorPosition = 35
; Folding = 4
; EnableXP
; Executable = removeTLEs