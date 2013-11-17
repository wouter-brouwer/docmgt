#Prog = "MergeAFP"

;{ Documentatie

; neem de header en alle files en plak ze aan elkaar
; Voeg 2D Matrix codes toe
; Schrijf MRDF

;}

IncludeFile "Common.pbi"

IncludeFile "AFP.pbi"

;{ Maak Barcode records

; BBC Begin Barcode Object
HexString.s = BBC + "00 0000" ; SFID + Flags + Reserved
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*BBC = AllocateMemory(HexLen(HexString))
BBClen = PokeHexString(*BBC, HexString)


; BOG Begin Object Environment Group
HexString = BOG + "00 0000" ; SFID + Flags + Reserved
HexString + HexString(AsciiToEBCDIC("2DMATRIX")) ; (OEG Name)
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
HexString + HexString(AsciiToEBCDIC("2DMATRIX")) ; (OEG Name)
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
BDA_Header.s = HexString

; EBC End Barcode Object
HexString.s = "D3A9EB 00 0000" ; SFID + Flags + Reserved
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*EBC = AllocateMemory(HexLen(HexString) + 5)
EBClen = PokeHexString(*EBC, HexString)



;}

;{ Initialisatie

JobsDir.s = "./documents/jobs/"
HeaderDir.s = "./documents/headers/"
OutputDir.s = "./System/hf/afp/"

HexString = BDT + "00 0000 FFFFFFFF FFFFFFFF"
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*BDT = AllocateMemory(HexLen(HexString))
BDTlen = PokeHexString(*BDT, HexString)

HexString = EDT + "00 0000 FFFFFFFF FFFFFFFF"
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*EDT = AllocateMemory(HexLen(HexString))
EDTlen = PokeHexString(*EDT, HexString)

NewList FileNames.s()
;}

Repeat
;{ Loop door de jobs
If ExamineDirectory(0, JobsDir, "*.*")
  While NextDirectoryEntry(0)
    If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
      JobName.s = DirectoryEntryName(0)
      If Left(JobName, 1) <> "." And Right(JobName, 5) <> ".done"
        JobDir.s = JobsDir + JobName + "/"
        Gosub VerwerkJob
      EndIf
    EndIf
  Wend
  FinishDirectory(0)
EndIf
;}
Delay(1000)
ForEver
End

;{ VerwerkJob:
VerwerkJob:

  LogMsg("Processing job " + JobName)

  ;{ Zet de filenamen in een list om ze gesorteerd te kunnen verwerken
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
  ;}
  
  SortList(FileNames(), #PB_Sort_Ascending)
  
  ForEach FileNames()
    InputFile.s = FileNames()    
    ;{ VerwerkFile    
    If OutputFileNr = 0      
      ;{ OpenOutputFile
      
      ; Read Header
      HeaderFile.s = StringField(InputFile, 1, "_0") + "_header.afp"
      HeaderFileNr = ReadFile(#PB_Any, HeaderDir + HeaderFile)
      If HeaderFileNr = 0 
        LogMsg("Critical: Can not read " + HeaderDir + HeaderFile)
      EndIf  
      HeaderLength = Lof(HeaderFileNr)
      *HeaderBuffer = AllocateMemory(HeaderLength)
      ReadData(HeaderFileNr, *HeaderBuffer, HeaderLength)
      CloseFile(HeaderFileNr)
      
      ; Create OutputFile
      OutputFile.s = JobName + ".tmp"
      OutputFileNr = CreateFile(#PB_Any, OutputDir + OutputFile)
      If OutputFileNr = 0
        LogMsg("Critical: Unable to create " + OutputDir + OutputFile)
      EndIf
      Documents = 0
      
      ; Write Header
      WriteData(OutputFileNr, *HeaderBuffer, HeaderLength)
      WriteData(OutputFileNr, *BDT, BDTlen)
    
      ;}
    EndIf
    InputFileNr = ReadFile(#PB_Any, JobDir + InputFile)
    If InputFileNr = 0 
      LogMsg("Critical: Unable to read " + JobDir + InputFile)
    EndIf    
    Documents + 1
    PageNr = 0
    p = FindString(InputFile, "_P")
    e = FindString(InputFile, ".")
    Pages = Val(Mid(InputFile, p + 2, e - p))
    
    While Not Eof(InputFileNr)
      
      
      l0.c = ReadCharacter(InputFileNr)
      If l0 <> 90
        LogMsg("Critical: " + JobDir + InputFile + " contains invalid AFP")
      EndIf
      l1.c = ReadCharacter(InputFileNr)
      l2.c = ReadCharacter(InputFileNr)
      
      RecordLength = l1 * 256 + l2 - 2
      ReadData(InputFileNr, *AFPRecord, RecordLength)
      RecordNr + 1
      
      ; Structured Field Identifier
      SFID.s = HexString(PeekS(*AFPRecord,3))

      Select SFID
        Case BPG
          PageNr + 1
        Case EPG
          WriteData(OutputFileNr, *BBC, BBClen)
          WriteData(OutputFileNr, *BOG, BOGlen)
          WriteData(OutputFileNr, *OBD, OBDlen)
          WriteData(OutputFileNr, *OBP, OBPlen)
          WriteData(OutputFileNr, *BDD, BDDlen)
          WriteData(OutputFileNr, *EOG, EOGlen)
          
          Barcode.s = StringField(JobName,2,"_")
          Barcode + RSet(Str(Documents),6,"0")
          Barcode + RSet(Str(PageNr),5,"0")
          Barcode + RSet(Str(Pages),5,"0")
          Barcode + "000000" ; Inserterstations
          Barcode + "0" ; Quality Check
          Barcode + "0" ; Edge Mark
          Barcode + "0" ; Next Channel          
          Hexstring.s = BDA_Header + HexString(Barcode)
          HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
          *BDA = AllocateMemory(HexLen(HexString) + 5)
          BDAlen = PokeHexString(*BDA, HexString)
      
          WriteData(OutputFileNr, *BDA, BDAlen)
          WriteData(OutputFileNr, *EBC, EBClen)
      EndSelect

      WriteCharacter(OutputFileNr, l0)
      WriteCharacter(OutputFileNr, l1)
      WriteCharacter(OutputFileNr, l2)
      WriteData(OutputFileNr, *AFPRecord, RecordLength)
    Wend
    
    CloseFile(InputFileNr)
  
    ;}
  Next
  
  If OutputFileNr > 0
    ;{ Close OuputFile
    WriteData(OutputFileNr, *EDT, EDTlen)
    CloseFile(OutputFileNr)
    OutputFileNr = 0
; TEST
    RenameFile(OutputDir + OutputFile.s, "/c/Temp/" + ReplaceString(OutputFile, ".tmp", ".afp"))
    LogMsg("Info: " + JobName + ".afp created with " + Str(Documents) + " documents")
    ;}
  EndIf
  
  Done.s = JobDir + ".done"
  Done = ReplaceString(Done, "/.", ".")
RenameFile(JobDir, Done)
Return
;}
; IDE Options = PureBasic 5.20 LTS (Linux - x64)
; CursorPosition = 93
; FirstLine = 48
; Folding = e0
; EnableXP