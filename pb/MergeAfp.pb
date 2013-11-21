#Prog = "MergeAFP"

;{ Documentatie

; neem de header en alle files en plak ze aan elkaar
; Voeg 2D Matrix codes toe
; Schrijf MRDF

;}

IncludeFile "Common.pbi"

IncludeFile "AFP.pbi"

Global ConfigDir.s

IncludeFile "StreamInfo.pbi"

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
HexString = OBD + "00 0000" ; SFID + Flags + Reserved
HexString + "03 43 01" ; Descriptor Position
HexString + "08 4B 00 00 0960 0960" ; Measurement Units
HexString + "09 4C 02 0007C0 00057B" ; Object Area Size
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*OBD = AllocateMemory(HexLen(HexString))
OBDlen = PokeHexString(*OBD, HexString)

; OBP Object Area Position
HexString = OBP + "00 0000" ; SFID + Flags + Reserved
HexString + "01" ; Position ID
HexString + "17" ; Len
;HexString + "000060 000F00" ; X Y-as origin
HexString + "000000 000000" ; X Y-as origin
HexString + "0000 2D00" ; X Y rotation
HexString + "00" ; Reserved
HexString + "000000 000000" ; X Y origin object content
HexString + "0000 2D00 00" 
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*OBP = AllocateMemory(HexLen(HexString))
OBPlen = PokeHexString(*OBP, HexString)

; MBC Map Barcode Object
HexString = MBC + "00 0000" ; SFID + Flags + Reserved
HexString + "00 05 03 04 00"
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*MBC = AllocateMemory(HexLen(HexString))
MBClen = PokeHexString(*MBC, HexString)

  ; BDD Barcode Data Descriptor
HexString = BDD + "00 0000" ; SFID + Flags + Reserved
; BSD Barcode Symbol Descriptor
HexString + "00" ; Unit Base 00 = 10" 01 = 10cm
HexString + "00" ; Reserved
HexString + "0960" ; Units per unitbase X
HexString + "0960" ; Units per unitbase Y
HexString + "07C0" ; Width presentationspace
HexString + "057B" ; Length presentationspace
HexString + "0000" ; Desired symbol width
HexString + "1C 00"; Data Matrix
HexString + "FF"   ; Font
HexString + "0000" ; Color
HexString + "FF"   ; ModuleWidth in mils
HexString + "FFFF" ; ElementHeight
HexString + "01"   ; Height Multiplier
HexString + "FFFF" ;WideNarrow ratio
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
HexString + "0025 0295"; x + y Coordinates
HexString + "C0" ; Control flags
HexString + "0010" ; Row size
HexString + "0010" ; Number of rows
HexString + "01" ; Sequence indicator
HexString + "07" ; Total symbols
HexString + "FE" ; FileID byte 1
HexString + "FE" ; FileID byte 2
HexString + "40" ; Special function flags
BDA_HeaderA5.s = HexString

; BDA Barcode Data
HexString = "D3EEEB 00 0000" ; SFID + Flags + Reserved
; BSA Barcode Symbol Data
HexString + "00" ; Barcode flags
HexString + "0025 0811"; x + y Coordinates
HexString + "C0" ; Control flags
HexString + "0010" ; Row size
HexString + "0010" ; Number of rows
HexString + "01" ; Sequence indicator
HexString + "07" ; Total symbols
HexString + "FE" ; FileID byte 1
HexString + "FE" ; FileID byte 2
HexString + "40" ; Special function flags
BDA_HeaderA4.s = HexString

; EBC End Barcode Object
HexString.s = "D3A9EB 00 0000" ; SFID + Flags + Reserved
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*EBC = AllocateMemory(HexLen(HexString) + 5)
EBClen = PokeHexString(*EBC, HexString)

;}

;{ Initialisatie

;InstelHoekjeA4Len = ?EndInstelHoekjeA4 - ?InstelHoekjeA4
;*InstelHoekjeA4 = ?InstelHoekjeA4

InstelHoekjeA5Len = ?EndInstelHoekjeA5 - ?InstelHoekjeA5
*InstelHoekjeA5 = ?InstelHoekjeA5

If Not OpenPreferences("openloop.ini")
  LogMsg("Critical: Unable to open openloop.ini")
EndIf

ConfigDir.s = CheckDirectory(ReadPreferenceString("ConfigDir",""))
TmpDir.s = CheckDirectory(ReadPreferenceString("TmpDir",""))
LogDir = CheckDirectory(ReadPreferenceString("LogsDir",""))
LockDir.s = CheckDirectory(ReadPreferenceString("LocksDir",""))
JobsDir.s = CheckDirectory(ReadPreferenceString("JobsDir",""))
OutputDir.s = CheckDirectory(ReadPreferenceString("OutputAfpDir",""))
ResourcesDir.s = CheckDirectory(ReadPreferenceString("ResourcesDir",""))
ClosePreferences()

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

;Repeat
;{ Loop door de jobs
If ExamineDirectory(0, JobsDir, "*.*")
  While NextDirectoryEntry(0)
    If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
      JobName.s = DirectoryEntryName(0)
      If Left(JobName, 1) <> "." And Right(JobName, 5) <> ".busy" And Right(JobName, 5) <> ".done"
        JobDir.s = JobsDir + JobName + "/"
        Gosub VerwerkJob
      EndIf
    EndIf
  Wend
  FinishDirectory(0)
EndIf
;}
Delay(1000)
;ForEver
End

;{ VerwerkJob:
VerwerkJob:

  LogMsg("Processing job " + JobName)

  Stroom.s = StringField(JobName, 1, "_")
  
  ResourcesSubDir.s = CheckDirectory(ResourcesDir + Stroom)

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
      HeaderFileNr = ReadFile(#PB_Any, ResourcesSubDir + HeaderFile)
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
          ; <<< TEST
          PageFormat.s = UCase(StreamInfo(Stroom, "PaginaFormaat"))
          If 1 = 1
            ; 2D Matrix
            WriteData(OutputFileNr, *BBC, BBClen)          
            WriteData(OutputFileNr, *BOG, BOGlen)
            WriteData(OutputFileNr, *OBD, OBDlen)
            WriteData(OutputFileNr, *OBP, OBPlen)
            WriteData(OutputFileNr, *MBC, MBClen)
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
            Barcode = AsciiToEbcdic(Barcode)
            If PageFormat = "A4"
              Hexstring.s = BDA_HeaderA4 + HexString(Barcode)
            Else
              Hexstring.s = BDA_HeaderA5 + HexString(Barcode)
            EndIf              
            HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
            *BDA = AllocateMemory(HexLen(HexString) + 5)
            BDAlen = PokeHexString(*BDA, HexString)
        
            WriteData(OutputFileNr, *BDA, BDAlen)
            WriteData(OutputFileNr, *EBC, EBClen)
          EndIf
          
          
          ; of op basis van de page descriptor
          If UCase(StreamInfo(Stroom, "PaginaFormaat")) = "A5"
            ; PageHeight - 16
            WriteData(OutputFileNr, *InstelHoekjeA5, InstelHoekjeA5Len)
          EndIf
          
 ;         If UCase(StreamInfo(Stroom, "PaginaFormaat")) = "A4"
 ;           WriteData(OutputFileNr, *InstelHoekjeA4, InstelHoekjeA5Len)
 ;         EndIf
    
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
    ; << TEST
    ;RenameFile(OutputDir + OutputFile.s, OutputDir + ReplaceString(OutputFile, ".tmp", ".afp"))
    CopyFile(OutputDir + OutputFile.s, OutputDir + ReplaceString(OutputFile, ".tmp", ".afp"))
    LogMsg("Info: " + JobName + ".afp created with " + Str(Documents) + " documents")
    ;}
  EndIf
  
  Done.s = JobDir + ".done"
  Done = ReplaceString(Done, "/.", ".")
  
  ; TEST
  ;RenameFile(JobDir, Done)
Return
;}

DataSection
  
  ;InstelHoekjeA4:
  ;  IncludeBinary "instelhoekje.A4.afp"
  ;EndInstelHoekjeA4:
    
  InstelHoekjeA5:
    IncludeBinary "instelhoekje.A5.afp"
  EndInstelHoekjeA5:
  
EndDataSection 

; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 290
; FirstLine = 235
; Folding = e-
; EnableXP