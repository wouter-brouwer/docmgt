Procedure.s StreamInfo(Stream.s, Keyword.s)
  
  ; Deze procedure levert stroom attributen
  
  Static LastRead
  Static NewList Regels.s()
  Static Keywords.s
  Static Separator.s = ";"

  If Date() > LastRun + 300 ; elke 5 minuten
    
    FileName.s = ConfigDir + "stromen.csv"
    FileNr = ReadFile(#PB_Any, FileName)
    If FileNr > 0
      Keywords = ""
      While Not Eof(FileNr)
        Line.s = ReadString(FileNr)
        If Left(Line, 1) <> "#"
          If Keywords = ""
            Keywords = LCase(Line)
          Else
            AddElement(Regels())
            Regels() = Line
          EndIf
        EndIf        
      Wend
      CloseFile(FileNr)
    Else
      LogMsg("Critical: Unable to read " + FileName)
    EndIf
    LastRead = Date()
  EndIf  
  
  
  AantalKeywords = CountString(Keywords, Separator) + 1
  For Index = 1 To AantalKeywords
    If Trim(StringField(Keywords, Index, Separator)) = LCase(Keyword)
      Break
    EndIf
  Next Index
  If Index > AantalKeywords
    LogMsg("Error: Unable to find Keyword " + Keyword)
    ProcedureReturn "error"
  EndIf  
  
  Found = 0
  ForEach Regels()
    If Trim(LCase(StringField(Regels(), 1, Separator))) = LCase(Stream)
      ProcedureReturn Trim(StringField(Regels(), Index, Separator))
    EndIf
  Next
  
  LogMsg("Error: Unable to find Stream " + Stream)
  ProcedureReturn "error"

EndProcedure

; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 12
; Folding = -
; EnableXP