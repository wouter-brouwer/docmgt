Procedure.s MaterialInfo(MaterialCode.s, Keyword.s)
  
  ; Deze procedure levert stroom attributen
  
  Static LastRead
  Static NewList Lines.s()
  Static Keywords.s
  Static KeywordCount
  Static Separator.s = ";"

  If Date() > LastRun + 300 ; elke 5 minuten    
    FileName.s = ConfigDir + "materialinfo.csv"
    FileNr = ReadFile(#PB_Any, FileName)
    If FileNr > 0
      Keywords = ""
      While Not Eof(FileNr)
        Line.s = ReadString(FileNr)
        If Left(Line, 1) <> "#"
          If Keywords = ""
            Keywords = LCase(Line)
            If LCase(StringField(Keywords, 1, Separator)) <> "code"
              LogMsg("Critical: The first column in " + FileName + " must be 'Code'")
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
      LogMsg("Critical: Unable to read " + FileName)
    EndIf
    LastRead = Date()
  EndIf  
  
  For Index = 1 To KeywordCount
    If Trim(StringField(Keywords, Index, Separator)) = LCase(Keyword)
      Break
    EndIf
  Next Index
  If Index > KeywordCount
    LogMsg("Error: Unable to find MatrialInfo Keyword " + Keyword)
    ProcedureReturn "error"
  EndIf  
  
  Found = 0
  ForEach Lines()
    If Trim(LCase(StringField(Lines(), 1, Separator))) = LCase(MaterialCode)
      ProcedureReturn Trim(StringField(Lines(), Index, Separator))
    EndIf
  Next
  
  LogMsg("Error: Unable to find MaterialCode " + MaterialCode)
  ProcedureReturn "error"

EndProcedure

; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 24
; Folding = -
; EnableXP