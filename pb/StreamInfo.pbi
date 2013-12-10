Procedure.s StreamInfo(StreamCode.s, Keyword.s)
  
  ; Deze procedure levert stroom attributen
  
  Static LastRead
  Static NewList Lines.s()
  Static Keywords.s
  Static KeywordCount
  Static Separator.s = ";"

  If Date() > LastRun + 300 ; elke 5 minuten    
    FileName.s = ConfigDir + "streaminfo.csv"
    FileNr = ReadFile(#PB_Any, FileName)
    If FileNr > 0
      Keywords = ""
      While Not Eof(FileNr)
        Line.s = ReadString(FileNr)
        If Left(Line, 1) <> "#"
          If Keywords = ""
            Keywords = LCase(Line)
            If LCase(StringField(Keywords, 1, Separator)) <> "code"
              ProcedureReturn "Critical: The first column in " + FileName + " must be 'Code'"
            EndIf
            KeywordCount = CountString(Keywords, Separator) + 1
          Else
            AddElement(Lines())
            Lines() = Line
          EndIf
        EndIf        
      Wend
      CloseFile(FileNr)
    Else
      ProcedureReturn "Critical: Unable to read " + FileName
    EndIf
    LastRead = Date()
  EndIf  
  
  For Index = 1 To KeywordCount
    If Trim(StringField(Keywords, Index, Separator)) = LCase(Keyword)
      Break
    EndIf
  Next Index
  If Index > KeywordCount
    ProcedureReturn "Error: Unable to find Keyword " + Keyword
  EndIf  
  
  Found = 0
  ForEach Lines()
    If Trim(LCase(StringField(Lines(), 1, Separator))) = LCase(StreamCode)
      ProcedureReturn Trim(StringField(Lines(), Index, Separator))
    EndIf
  Next
  
  ProcedureReturn "Error: Unable to find StreamCode " + StreamCode

EndProcedure

; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 21
; Folding = -
; EnableXP