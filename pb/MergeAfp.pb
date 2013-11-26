#Prog = "MergeAFP"

;{ Documentatie

; neem de header en alle files en plak ze aan elkaar
; Voeg 2D Matrix codes toe
; Schrijf MRDF

;}

NewList MrdfLines.s()

IncludeFile "Common.pbi"

IncludeFile "AFP.pbi"

Global ConfigDir.s
Global RunControlDir.s

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

If Not OpenPreferences("openloop.ini")
  LogMsg("Critical: Unable to open openloop.ini")
EndIf

ConfigDir.s = CheckDirectory(ReadPreferenceString("ConfigDir",""))
TmpDir.s = CheckDirectory(ReadPreferenceString("TmpDir",""))
LogDir = CheckDirectory(ReadPreferenceString("LogsDir",""))
JobsDir.s = CheckDirectory(ReadPreferenceString("JobsDir",""))
OutputDir.s = CheckDirectory(ReadPreferenceString("OutputAfpDir",""))
OutputMrdfDir.s = CheckDirectory(ReadPreferenceString("OutputMrdfDir",""))
ResourcesDir.s = CheckDirectory(ReadPreferenceString("ResourcesDir",""))
RunControlDir.s = CheckDirectory(ReadPreferenceString("RunControlDir",""))
ClosePreferences()

IncludeFile "RunControl.pbi"

HexString = BDT + "00 0000 FFFFFFFF FFFFFFFF"
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*BDT = AllocateMemory(HexLen(HexString))
BDTlen = PokeHexString(*BDT, HexString)

HexString = EDT + "00 0000 FFFFFFFF FFFFFFFF"
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*EDT = AllocateMemory(HexLen(HexString))
EDTlen = PokeHexString(*EDT, HexString)

HexString = BPT + "00 0000 FFFF 0000 0000 0000"
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*BPT = AllocateMemory(HexLen(HexString))
BPTlen = PokeHexString(*BPT, HexString)

HexString = EPT + "00 0000 FFFF 0000 0000 0000"
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*EPT = AllocateMemory(HexLen(HexString))
EPTlen = PokeHexString(*EPT, HexString)

HexString = BRG + "00 0000"
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*BRG = AllocateMemory(HexLen(HexString))
BRGlen = PokeHexString(*BRG, HexString)

HexString = ERG + "00 0000"
HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
*ERG = AllocateMemory(HexLen(HexString))
ERGlen = PokeHexString(*ERG, HexString)

NewList FileNames.s()
NewList JobDirs.s()

LogMsg(#Prog + " started")
;}

;{ Main loop
Quit = 0
Repeat
  
  Quit = Bool(FileSize(StopFile) = 0)

  If FileSize(PauseFile) < 0 And Not Quit

    ;{ Loop door de jobs
    GetDirSorted(JobDirs(), JobsDir, "*.todo", #PB_DirectoryEntry_Directory)

    ForEach JobDirs()
      JobName.s = ReplaceString(JobDirs(), ".todo", "")
      Gosub VerwerkJob
    Next
    ;}
  
  EndIf
  
  LogMsg("")
  HeartBeat()
  Delay(1000)
  
  ; TEST
  ;Quit = 1
  
Until Quit
;}

;{ Afsluiting
LogMsg(#Prog + " ended")
DeleteFile(StopFile)
End
;}

;{ VerwerkJob:
VerwerkJob:

  LogMsg("Processing job " + JobName)

  JobDir.s = JobsDir + JobName
  Stroom.s = StringField(JobName, 1, "_")
  JobNr.s = StringField(JobName, 2, "_")
  Dim Stations(6) 
  ResourcesSubDir.s = CheckDirectory(ResourcesDir + Stroom)

  ; Zet de filenamen in een list om ze gesorteerd te kunnen verwerken
  GetDirSorted(FileNames(), JobDir + ".todo", "*.afp", #PB_DirectoryEntry_File)
  
  ClearList(MrdfLines())
  
  ForEach FileNames()
    InputFile.s = FileNames()    
    ;{ VerwerkFile    
    If OutputFileNr = 0      
      ;{ OpenOutputFile
      
      ; Create OutputFile
      OutputFile.s = JobName + ".tmp"
      OutputFileNr = CreateFile(#PB_Any, OutputDir + OutputFile)
      If OutputFileNr = 0
        LogMsg("Critical: Unable to create " + OutputDir + OutputFile)
      EndIf
      Documents = 0
;       
;       ; Write Header
;       WriteData(OutputFileNr, *HeaderBuffer, HeaderLength)
      
       WriteData(OutputFileNr, *BRG, BRGlen)          
       If ExamineDirectory(1, ResourcesSubDir, "*.res")
         While NextDirectoryEntry(1)
           If DirectoryEntryType(1) = #PB_DirectoryEntry_File
             ResName.s = DirectoryEntryName(1)
             ReadFile(0, ResourcesSubDir + ResName)
             ResourceBufferLen = Lof(0)
             *ResourceBuffer = AllocateMemory(ResourceBufferLen)
             ReadData(0, *ResourceBuffer, ResourceBufferLen)
             CloseFile(0)
             WriteData(OutputFileNr, *ResourceBuffer, ResourceBufferLen)
           EndIf
         Wend
         FinishDirectory(1)
       EndIf
       WriteData(OutputFileNr, *ERG, ERGlen)
     
      WriteData(OutputFileNr, *BDT, BDTlen)
    
      ;}
    EndIf
    InputFileNr = ReadFile(#PB_Any, JobDir + ".todo/" + InputFile)
    If InputFileNr = 0 
      LogMsg("Critical: Unable to read " + JobDir + ".todo/" + InputFile)
    EndIf    
    Documents + 1
    PageNr = 0
    p = FindString(InputFile, "_P")
    e = FindString(InputFile, ".")
    Pages = Val(Mid(InputFile, p + 2, e - p))
    
    InserterStations.s = "000000"
    QualityCheck.s = "0"
    EdgeMarker.s = "0"
    NextChannel.s = "0"
    
    While Not Eof(InputFileNr)
      
      
      l0.c = ReadCharacter(InputFileNr)
      If l0 <> 90
        LogMsg("Critical: " + JobDir + InputFile + " contains invalid AFP")
      EndIf
      ;l1.c = ReadCharacter(InputFileNr)
      ;l2.c = ReadCharacter(InputFileNr)
      ;RecordLength = l1 * 256 + l2 - 2
      RecordLength.u = ReadUU(InputFileNr) - 2
      
      ReadData(InputFileNr, *AFPRecord, RecordLength)
      RecordNr + 1
      
      ; Structured Field Identifier
      SFID.s = HexString(PeekS(*AFPRecord,3))

      Select SFID
          
        Case PGD ; Page Descriptor
          ;D3 A6 AF 00 00 00
          ;00 X Base 10 inch
          ;00 Y Base 10 inch
          ;00 00 pixels per base X
          pp10ix.u = PeekUU(*AFPRecord + 8)
          ;00 00 pixels per base y
          pp10iy.u = PeekUU(*AFPRecord + 10)
          ;00 00 PageWidth
          PageWith.u = PeekUU(*AFPRecord + 13)
          ;00 00 PageHeight
          PageHeight.u = PeekUU(*AFPRecord + 16)
          ;CallDebugger
          
        Case TLE
          ln.c = PeekC(*AFPRecord + 6)
          TagName.s = EbcdicToAscii(PeekS(*AFPRecord + 6 + 4, ln - 4))
          lv.c = PeekC(*AFPRecord + 6 + ln)
          TagValue.s = EbcdicToAscii(PeekS(*AFPRecord + 6 + 4 + ln, lv - 4))
          Select TagName
            Case "ADF-IP-INSERTERSTATIONS"
              InserterStations = TagValue
            Case "ADF-IP-EDGEMARKER"
              EdgeMarker = TagValue
            Case "ADF-IP-QUALITYCHECK"
              QualityCheck = TagValue
            Case "ADF-IP-NEXTCHANNEL"
              NextChannel = TagValue
          EndSelect
          
        Case BPG
          PageNr + 1
          
        Case EPG
          ; <<< TEST
          PageSize.s = UCase(StreamInfo(Stroom, "PageSize"))
          If 1 = 1
            ;{ Plaats 2D Matrix
            WriteData(OutputFileNr, *BBC, BBClen)          
            WriteData(OutputFileNr, *BOG, BOGlen)
            WriteData(OutputFileNr, *OBD, OBDlen)
            WriteData(OutputFileNr, *OBP, OBPlen)
            WriteData(OutputFileNr, *MBC, MBClen)
            WriteData(OutputFileNr, *BDD, BDDlen)
            WriteData(OutputFileNr, *EOG, EOGlen)
            
            Barcode.s = JobNr
            Barcode + RSet(Str(Documents),6,"0")
            Barcode + RSet(Str(PageNr),5,"0")
            Barcode + RSet(Str(Pages),5,"0")
            Barcode + Inserterstations
            Barcode + NextChannel
            Barcode + EdgeMarker
            Barcode + QualityCheck
            Barcode = AsciiToEbcdic(Barcode)
            If PageSize = "A4"
              Hexstring.s = BDA_HeaderA4 + HexString(Barcode)
            Else
              Hexstring.s = BDA_HeaderA5 + HexString(Barcode)
            EndIf              
            HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
            *BDA = AllocateMemory(HexLen(HexString) + 5)
            BDAlen = PokeHexString(*BDA, HexString)
        
            WriteData(OutputFileNr, *BDA, BDAlen)
            WriteData(OutputFileNr, *EBC, EBClen)
            ;}
          EndIf
          
          If 1 = 1
            ;{ Scrijf het instelhoekje
            WriteData(OutputFileNr, *BPT, BPTlen)
            
            ; PTX Presentation Text
            HexString = PTX + "00 0000" ; SFID + Flags + Reserved
            HexString + "2B D3"
            HexString + "05 75 00 08 01" ; STC Black
            HexString + "06 F7 00 00 2D 00" ; STO 90
            HexString + "05 75 00 08 01 " ; STC Black
            HexString + "04 C7 00 00" ; AMI X 0
            HexString + "04 D3"  + RSet(Hex(PageHeight - 600), 4, "0")  ; AMB Y 7752 x'1E48' pageheight - 600
            ;Debug RSet(Hex(PageHeight - 600), 4, "0")
            HexString + "07 E7" ; DBR Line Down
            HexString + "02 4E" ; Length 590
            HexString + "00 14" ; Width 20
            HexString + "00 "
            HexString + "04 C7 00 14" ; AMI X 20
            HexString + "04 D3" + RSet(Hex(PageHeight - 16), 4, "0") ; AMB Y 8336 x'2090' pageheight - 16
            ;Debug RSet(Hex(PageHeight - 16), 4, "0")
            HexString + "07 E5" ; DIR Line Right
            HexString + "02 4E" ; Length 590
            HexString + "00 14" ; Width 20
            HexString + "00 "
            HexString + "02 F8" ; ???
            HexString = "5A" + Hex2(HexLen(HexString) + 2, 4) + HexString
            *PTX = AllocateMemory(HexLen(HexString))
            PTXlen = PokeHexString(*PTX, HexString)
            WriteData(OutputFileNr, *PTX, PTXlen)

            WriteData(OutputFileNr, *EPT, EPTlen)
;           Else 
;             WriteData(OutputFileNr, *InstelHoekjeA5, InstelHoekjeA5Len)
            ;}
          EndIf
           
      EndSelect

      WriteCharacter(OutputFileNr, l0)
      WriteUU(OutputFileNr, RecordLength + 2)
      WriteData(OutputFileNr, *AFPRecord, RecordLength)
    Wend
    
    CloseFile(InputFileNr)
    ;{ Build MRDF record
    MrdfRecord.s = Space(2)
    MrdfRecord + RSet(JobNr,8,"0")
    MrdfRecord + RSet(Str(Documents),6,"0")
    MrdfRecord + Space(64)
    MrdfRecord + RSet(Str(Pages),5,"0")
    MrdfRecord + Zero(55)
    MrdfRecord + "0.000"
    MrdfRecord + InserterStations
    For i = 1 To 6
      If Mid(InserterStations, i, 1) = "1"
        Stations(i) + 1
      EndIf
    Next i
    MrdfRecord + Zero(11)
    MrdfRecord + QualityCheck
    MrdfRecord + Zero(1)
    MrdfRecord + EdgeMarker
    MrdfRecord + Zero(6)
    MrdfRecord + Space(672)
    MrdfRecord + LSet(StringField(InputFile, 1, "_P"), 30)
    MrdfRecord + Zero(12)
    MrdfRecord + Space(88)
    MrdfRecord + Zero(4)
    MrdfRecord + Space(112)
    ;Debug MrdfRecord
    AddElement(MrdfLines())
    MrdfLines() = MrdfRecord
    ;} 
  
    ;}
  Next
  
  If OutputFileNr > 0
    ;{ Close OuputFile
    WriteData(OutputFileNr, *EDT, EDTlen)
    CloseFile(OutputFileNr)
    OutputFileNr = 0
    ; << TEST
    DeleteFile(OutputDir + ReplaceString(OutputFile, ".tmp", ".afp"))
    RenameFile(OutputDir + OutputFile.s, OutputDir + ReplaceString(OutputFile, ".tmp", ".afp"))
    
    LogMsg("Info: " + JobName + ".afp created with " + Str(Documents) + " documents")
    ;}
    MrdfFile.s = OutputMrdfDir + JobNr
    MrdfFilenr = CreateFile(#PB_Any, MrdfFile + ".tmp")
    If Not MrdfFilenr
      LogMsg("Critical: Unable to create " + MrdfFile)
    EndIf
    ;{ Build Mrdf header
    MrdfRecord.s = Space(2)
    MrdfRecord + RSet(JobNr,8,"0")
    MrdfRecord + Space(203)
    MrdfRecord + Zero(5)
    MrdfRecord + Space(19)
    MrdfRecord + Zero(5)
    MrdfRecord + "2"    
    MrdfRecord + RSet(Str(Documents),6,"0")
    MrdfRecord + RSet(Str(TotalPages),10,"0")
    MrdfRecord + Space(132)
    For i = 1 To 6
      If Stations(i) > 0
        MrdfRecord + "2" 
      Else
        MrdfRecord + "1"
      EndIf
    Next i
    MrdfRecord + String("1", 10)
    MrdfRecord + Space(328)
    MrdfRecord + Zero(16*6)
    MrdfRecord + LSet(OutputFile, 60)
    MrdfRecord + Space(138)
    WriteStringN(MrdfFileNr, MrdfRecord)
    ;}
    ForEach MrdfLines()
      WriteStringN(MrdfFileNr, MrdfLines())
    Next
    CloseFile(MrdfFileNr)
    RenameFile(MrdfFile + ".tmp", MrdfFile + ".inp")
  EndIf
  
  RenameFile(JobDir + ".todo", JobDir + ".busy")
Return
;}
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 207
; FirstLine = 47
; Folding = 9G9
; EnableXP
; Executable = \aiw\aiw1\openloop\bin\mergeafp