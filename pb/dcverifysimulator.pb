#Prog = "dcverifysimulator" ; DC Verivy Simulator
#Versie = "0.1"

; Dit programma leest de MRDF file en maakt een resultfile zoals DC Verify dat zou doen

Procedure Usage(Message.s)
  OpenConsole()
  ConsoleError(Message)
  If Message <> "" 
    ExitCode = 1
  EndIf
  PrintN(#Prog + " version " + #Versie + " by Wouter Brouwer")
  PrintN("A program to process MRDF files to resultfiles")
  PrintN("Usage: "+#Prog+" <inputdirectory> <outputdirectory> [-d]")
  PrintN("-d to run endless (deamon)")
  End ExitCode
EndProcedure

;{ Init

Test = #True

If Test
  If FileSize("/aiw/aiw1/System/icf") = -2
    InputDirectory.s = "/aiw/aiw1/System/icf/PB_in"
    OutputDirectory.s = "/aiw/aiw1/System/icf/PB_out"    
  ElseIf FileSize("c:\") = -2
    InputDirectory = "input"
    OutputDirectory = "output"
  EndIf
Else
  If CountProgramParameters() < 2
    Usage("")
  EndIf
  InputDirectory.s = ProgramParameter()
  OutputDirectory.s = ProgramParameter()
  Option.s = LCase(ProgramParameter())
EndIf

If FileSize(InputDirectory) <> -2
  Usage("InputDirectory " + InputDirectory + " not found")
  End
EndIf

If FileSize(OutputDirectory) <> -2
  Usage("OutputDirectory " + OutputDirectory + " not found")
  End
EndIf

If Option <> "" And Option <> "-d"
  Usage("Invalid option " + Option)
EndIf
;}

;{ Main loop
Repeat 
  If ExamineDirectory(0, InputDirectory, "*.inp")  
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_File
        InputFile.s = InputDirectory + "/" + DirectoryEntryName(0)
        TmpFile.s = OutputDirectory + "/" + StringField(DirectoryEntryName(0), 1, ".") + ".tmp"
        OutputFile.s = OutputDirectory + "/" + StringField(DirectoryEntryName(0), 1, ".") + ".out"
        Gosub VerwerkFile
      EndIf
    Wend
    FinishDirectory(0)
  EndIf
  If Option <> "-d"
    Break
  EndIf
  Delay(5000) ; Poll every 5 seconds
ForEver
End
;}

;{ VerwerkFile:
VerwerkFile:
  If ReadFile(1, InputFile)
    InputLine.s = ReadString(1) ; Header
    CreateFile(2, TmpFile)
    While Not Eof(1)
      InputLine.s = ReadString(1)
      
;{    Parse InputLine
      JobID_Filler.s = Mid(InputLine, 1, 2)
      JobID.s = Mid(InputLine, 3, 8)
      PieceID.s = Mid(InputLine, 11, 6)
      JobType.s = Mid(InputLine, 17, 32)
      SelPages01.s = Mid(InputLine, 81, 5)
      SelPages02.s = Mid(InputLine, 86, 5)
      SelPages03.s = Mid(InputLine, 91, 5)
      SelPages04.s = Mid(InputLine, 96, 5)
      AccountPull.s = Mid(InputLine, 162, 1)
      QualityAudit.s = Mid(InputLine, 163, 1)
      AlertClear.s = Mid(InputLine, 164, 1)
      VS1.s = Mid(InputLine, 166, 1)
      VS2.s = Mid(InputLine, 167, 1)
      VS3.s = Mid(InputLine, 168, 1)
      VS4.s = Mid(InputLine, 169, 1)
      VS5.s = Mid(InputLine, 170, 1)
      VS6.s = Mid(InputLine, 171, 1)
      Name.s = Mid(InputLine, 332, 40)
      Address1.s = Mid(InputLine, 372, 40)
      Address2.s = Mid(InputLine, 412, 40)
      Address3.s = Mid(InputLine, 452, 40)
      Address4.s = Mid(InputLine, 492, 40)
      Address5.s = Mid(InputLine, 532, 40)
      Address6.s = Mid(InputLine, 572, 40)
      PostCode.s = LSet(Mid(InputLine, 612, 16),40)
      ReprintIndex.s = Mid(InputLine, 844, 30)
;}   

;{    Determine Inserter result
      Operator.s = LSet("Operator", 15)
      Inserter.s = LSet("Inserter", 15)
      ;Delay(30)
      TimeStampInserter.s = LSet(FormatDate("%mm/%dd/%yyyy%hh:%ii:%ss", Date()),18)
      x = Random(100,1)
      If x <= 1 ; 1% uitval
        Disposition.s = "06"
        DispositionText.s = LSet("Unprocessed", 30)
      ElseIf x <= 2 ; 1% handmatig gecorrigeerd
        Disposition.s = "08"
        DispositionText.s = LSet("ManuallyRepaired", 30)
      Else
        Disposition.s = "05"
        DispositionText.s = LSet("SuccessfullyRendered", 30)
      EndIf
 ;}
      
;{    Build OuputLine
      OutputLine.s = JobID_Filler
      OutputLine + JobID.s
      OutputLine + PieceID.s
      OutputLine + JobType
      OutputLine + SelPages01
      OutputLine + SelPages02
      OutputLine + SelPages03
      OutputLine + SelPages04
      OutputLine + "0" ; ActFeeder01
      OutputLine + "0" ; ActFeeder02
      OutputLine + "0" ; ActFeeder03
      OutputLine + "0" ; ActFeeder04
      OutputLine + "0" ; ActFeeder05
      OutputLine + "0" ; ActFeeder06
      OutputLine + "0" ; ActFeeder07
      OutputLine + "0" ; ActFeeder08
      OutputLine + AccountPull
      OutputLine + QualityAudit
      OutputLine + AlertClear
      OutputLine + VS1
      OutputLine + VS2
      OutputLine + VS3
      OutputLine + VS4
      OutputLine + Name
      OutputLine + Address1
      OutputLine + Address2
      OutputLine + Address3
      OutputLine + Address4
      OutputLine + Address5
      OutputLine + Address6
      OutputLine + PostCode
      OutputLine + TimeStampInserter
      OutputLine + Operator
      OutputLine + Inserter
      OutputLine + Disposition
      OutputLine + DispositionText
      OutputLine + ReprintIndex
;}

      WriteStringN(2, OutputLine)
    Wend
    CloseFile(2)
    RenameFile(TmpFile, OutputFile)
    CloseFile(1)
    CopyFile(InputFile, InputFile + ".done")
    DeleteFile(InputFile)
  EndIf
Return
;}
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 75
; FirstLine = 2
; Folding = s+
; EnableXP