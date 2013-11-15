#Prog = "MakeJobs"

;{ Documentatie

; Dit programma selecteert documenten uit de verzameling op basis van regels

; De documenten staan als afzonderlijke bestanden in een directory structuur
; documenten/<soort>/<status>/<soort>_<volgnummer>.<extensie>

; De status kan zijn: new, job en ready
; In "new" komen ze voor selectie in aanmerking
; Als ze geselecteerd zijn worden ze naar "job" gezet
; Als ze klaar zijn worden ze naar "ready" gezet 

; Die regels bepalen welke documenten wanneer tot een job gevormd worden

; Dat wanneer kan ingesteld worden op datum en tijd gebeurtenissen

; Er kan ook een maximum aantal documenten aangegeven worden die bij elkaar een job vormen.

; Voor de job vorming worden ze bij elkaar in een hotfolder gezet met een list file erbij

; Er moet een document type tabel zijn met alle kenmerken
; Type Form UP Paper Code   Plex    Env Code   Insert Prod    CustType    Country   
; 32   A5   4  CF    257761 Simplex C5  125466 Auto   Paymens Particulier Domestic etc

;}

Procedure LogMsg(Msg.s)
  
  Static LogFileNr, LastRun
  
  ; Logfile sluiten als er 10 seconden geen echte logging geweest is
  If LCase(Msg) = ""
    If LogFileNr > 0 And Date() > LastRun + 10
      CloseFile(LogFileNr)
      LogFileNr = 0
    EndIf
    ProcedureReturn
  EndIf  
  LastRun = Date()
  
  ; Indien nodig de logfile openen
  If LogFileNr = 0
    ; Als hij te groot is aan een nieuwe beginnen
    If FileSize(#Prog + ".log") > 1024 * 1024 ; 1 MB
      RenameFile(#Prog + ".log", #Prog + FormatDate("_%yyyy-%mm-%dd", Date()) + ".log")
    EndIf
    LogFileNr = OpenFile(#PB_Any, #Prog + ".log")
    FileSeek(LogFileNr, Lof(LogFileNr))
  EndIf
  
  ; De boodschap met tijd naar de log schrijven
  TimeStamp.s = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  Regel.s = TimeStamp + " - " + Msg
  Debug Regel
  WriteStringN(LogFileNr, Regel)
  
  ; Stoppen bij ernstige fout
  If FindString(LCase(Msg), "error") = 1 Or 
     FindString(LCase(Msg), "critical") = 1
    End
  EndIf
  
EndProcedure

Procedure IsTijd(Woord.s)
  If ParseDate("%hh:%ii", Woord) >= 0
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure IsDag(Woord.s)
  If ParseDate("%dd-%mm-%yyyy", Woord) > 0
    ProcedureReturn #True
  EndIf
  If ParseDate("%dd-%mm", Woord) >= 0
    ProcedureReturn #True
  EndIf
  If ParseDate("%dd", Woord) >= 0
    ProcedureReturn #True
  EndIf
  If Woord = "maandag" Or Woord = "ma"
    ProcedureReturn #True
  EndIf
  If Woord = "dinsdag" Or Woord = "di"
    ProcedureReturn #True
  EndIf
  If Woord = "woensdag" Or Woord = "wo"
    ProcedureReturn #True
  EndIf
  If Woord = "donderdag" Or Woord = "do"
    ProcedureReturn #True
  EndIf
  If Woord = "vrijdag" Or Woord = "vr"
    ProcedureReturn #True
  EndIf
  If Woord = "zaterdag" Or Woord = "za"
    ProcedureReturn #True
  EndIf
  If Woord = "zondag" Or Woord = "zo"
    ProcedureReturn #True
  EndIf
  If Woord = "weekdagen"
    ProcedureReturn #True
  EndIf
  If Woord = "weekend"
    ProcedureReturn #True
  EndIf
  If Woord = "werkdagen"
    ProcedureReturn #True
  EndIf
  If Woord = "feestdag"
    ProcedureReturn #True
  EndIf
EndProcedure

Procedure DatumMatch(Datum.s, Weekdag, Feestdag, Dag.s)
  
  If ParseDate("%dd", Dag) > 0 And ParseDate("%dd-%mm-%yyyy", Dag + Mid(Datum, 3)) = ParseDate("%dd-%mm-%yyyy", Datum)
    ProcedureReturn #True
  EndIf
  
  If ParseDate("%dd-%mm", Dag) > 0 And ParseDate("%dd-%mm-%yyyy", Dag + Mid(Datum, 6)) = ParseDate("%dd-%mm-%yyyy", Datum)
    ProcedureReturn #True
  EndIf
  
  If ParseDate("%dd-%mm-%yyyy", Dag) > 0 And ParseDate("%dd-%mm-%yyyy", Dag) = ParseDate("%dd-%mm-%yyyy", Datum)
    ProcedureReturn #True
  EndIf
  
  If Dag = "weekdagen" And Weekdag <= 5  
    ProcedureReturn #True
  EndIf
  
  If Dag = "weekend" And Weekdag >= 6  
    ProcedureReturn #True
  EndIf
  
  If Dag = "feestdag" And Feestdag = 1
    ProcedureReturn #True
  EndIf
  
  If Dag = "werkdagen" And Weekdag <= 5 And Feestdag = 0
    ProcedureReturn #True
  EndIf
  
  If StringField("maandag,dinsdag,woensdag,donderdag,vrijdag,zaterdag,zondag", Weekdag, ",") = Dag Or
     StringField("ma,di,wo,do,vr,za,zo", Weekdag, ",") = Dag
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
    
EndProcedure

;{ Init
LogMsg(#Prog + " Gestart")
; ; Stop de hele directory structuur in een Linked List
; ; zodat makkelijk 
; If ExamineDirectory(0, "documenten/" + Stroom, "*.*")
;   While NextDirectoryEntry(0)
;     If DirectoryEntryType(0) = #PB_DirectoryEntry_File
;       FileName.s = DirectoryEntryName(0)
;       FileDate= DirectoryEntryDate(0, #PB_Date_Modified)
;       Aantal + 1
;     EndIf
;   Wend
;   FinishDirectory(0)
; EndIf
; LogMsg("Filescan ready " + Str(Aantal))

If ReadFile(0, "JobNr.txt")
  JobNr = Val(ReadString(0))
  CloseFile(0)
EndIf

TimeFile = ReadFile(#PB_Any, "xTimeFile.txt")
;}

;{ Main loop
Repeat
  
;{ Bepaal datum en tijd
  ; Voor testdoeleinden uit een bestandje halen
  If TimeFile
    If Not Eof(TimeFile)
      Line.s = ReadString(TimeFile)
      Datum.s = StringField(Line, 1, " ")
      Tijd.s = StringField(Line, 2, " ")
    Else
      Break
    EndIf
  Else
    ; Voor werkelijkheid de systeemdatum en tijd nemen
    Datum.s = FormatDate("%dd-%mm-%yyyy", Date())
    Tijd.s = FormatDate("%hh:%ii", Date())
  EndIf  
;}
  
;{ Bepaal de datum kenmerken
  If Datum <> VorigeDatum.s
    Weekdag = DayOfWeek(Date(ParseDate("%dd-%mm-%yyyy", Datum)))
    If Weekdag = 0
      Weekdag = 7
    EndIf
    Feestdag = 0
    ; lees feestdagen bestand
    If ReadFile(1,"feestdagen.txt")
      NieuwsteFeestdag.s = "01-01-1970"
      While Not Eof(1)
        Dag.s = FormatDate("%dd-%mm-%yyyy", ParseDate("%dd-%mm-%yyyy", ReadString(1)))
        If Datum = Dag
          Feestdag = 1
        EndIf
        If ParseDate("%dd-%mm-%yyyy", Dag) > ParseDate("%dd-%mm-%yyyy", NieuwsteFeestdag)
          NieuwsteFeestdag = Dag
        EndIf
      Wend
      CloseFile(1)
      If ParseDate("%dd-%mm-%yyyy", NieuwsteFeestdag) < ParseDate("%dd-%mm-%yyyy", Datum)
        LogMsg("Error: Feestdagen bestand is niet meer actueel")
      EndIf
      If ParseDate("%dd-%mm-%yyyy", NieuwsteFeestdag) < AddDate(Date(),#PB_Date_Year,1)
        LogMsg("Warning: Feestdagen moet uitgebreid worden voor het komende jaar")
      EndIf        
    Else        
      LogMsg("Error: Feestdagen bestand kan niet geopend worden")
    EndIf
    VorigeDatum = Datum
  EndIf
  ;}

  If Tijd <> VorigeTijd.s ; Nieuwe minuut
    
    Debug "Verwerking: " + Datum + " " + Tijd
    
    ;{ Verwerk alle regels
    If Not ReadFile(1,"regels.txt")
      LogMsg("Error: Regel bestand kan niet worden geopend")
    EndIf

    While Not Eof(1)
        
      ;{ Initialisaties
      Stromen.s = ""
      Dagen.s = ""
      Tijden.s = ""
      Periodes.s = ""
      Ouder = 0
      NietJonger = 0
      MinDocs = 0
      MaxDocs = 0
      ;}
      
      ;{ Parse de regel
      Line = Trim(ReplaceString(ReadString(1), Chr(9), " ")) + " "
      If Left(Line,1) = "#" ; Commentaar overslaan
        Continue
      EndIf
      Line = ReplaceString(Line, ",", " ")
      Line = ReplaceString(Line, ";", " ")
      Line = ReplaceString(Line, "  ", " ")
      LogMsg("Regel: "+ Line)
      For i = 1 To CountString(Line, " ")
        Woord.s = StringField(Line, i, " ")
        If Woord = "stroom"
          KeyWord.s = "Stroom"
          Continue
        EndIf
        If Woord = "op"
          KeyWord.s = "Dagen"
          Continue
        EndIf
        If Woord = "om"
          KeyWord.s = "Tijden"
          Continue
        EndIf
        If Woord = "van"
          KeyWord.s = "Van"
          Continue
        EndIf
        If Woord = "tot"
          KeyWord.s = "Tot"
          Continue
        EndIf
        If Woord = "bij-ouder-dan"
          KeyWord.s = "Ouder"
          Continue
        EndIf
        If Woord = "bij-niet-jonger-dan"
          KeyWord.s = "NietJonger"
          Continue
        EndIf
        If Woord = "minimaal"
          KeyWord.s = "Minimaal"
          Continue
        EndIf
        If Woord = "maximaal"
          KeyWord.s = "Maximaal"
          Continue
        EndIf
        If Woord = "en"
          Continue
        EndIf
        Select KeyWord
          Case "Stroom"
            Stromen + Woord + ";"
          Case "Dagen"
            If IsDag(Woord)
              Dagen + Woord + ";"
            Else
              LogMsg("warning Ongeldige dag " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "Tijden"
            If IsTijd(Woord)
              Tijden + Woord + ";"
            Else
              LogMsg("warning Ongeldige tijd " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "Van"
            If IsTijd(Woord)
              Periodes + Woord + "-"
            Else
              LogMsg("warning Ongeldige tijd " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "Tot"
            If IsTijd(Woord)
              Periodes + Woord + ";"
            Else
              LogMsg("warning Ongeldige tijd " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "Ouder"
            If IsTijd(Woord)
              Ouder = ParseDate("%hh:%ii", Woord)
            Else
              LogMsg("warning Ongeldige tijd " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "NietJonger"
            If IsTijd(Woord)
              NietJonger = ParseDate("%hh:%ii", Woord)
            Else
              LogMsg("warning Ongeldige tijd " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "Minimaal"
            MinDocs= Val(Woord)
          Case "Maximaal"
            MaxDocs = Val(Woord)
          Default
            LogMsg("warning Onverwacht woord " + Woord)
            Line = ""
            Break
        EndSelect 
      Next i
      If Line = ""
        Continue
      EndIf
      ;}
      
      ;{ Check of de dagen kloppen
      If Dagen <> ""
        Match = 0
        For i = 1 To CountString(Dagen, ";")
          If DatumMatch(Datum, Weekdag, Feestdag, StringField(Dagen, i, ";"))
            Match + 1
            Break
          EndIf
        Next i  
        If Not Match
          Continue
        EndIf
      EndIf
      ;}
      
      ;{ Check of de tijden kloppen
      If Tijden <> ""
        Match = 0
        For i = 1 To CountString(Tijden, ";")
          If Tijd = StringField(Tijden, i, ";")
            Match + 1
            Break
          EndIf
        Next i  
        If Not Match
          Continue
        EndIf
      EndIf
      ;}
      
      ;{ Check of de periodes kloppen
      If Periodes <> ""
        Match = 0
        For i = 1 To CountString(Periodes, ";")
          Periode.s = StringField(Periodes, i, ";")
          Van = ParseDate("%hh:%ii", StringField(Periode,1,"-"))
          Tot = ParseDate("%hh:%ii", StringField(Periode,2,"-"))
          Nu = ParseDate("%hh:%ii", Tijd)
          If Nu >= Van And Nu <= Tot
            Match + 1
            Break
          EndIf
        Next i  
        If Not Match
          Continue
        EndIf
      EndIf
      ;}
      
      ;{ Check of er al oude bestanden zijn
      If Ouder > 0
        Match = 0
        Peil = ParseDate("%dd-%mm-%yyyy %hh:%ii", Datum + " " + Tijd) - Ouder          
        For i = 1 To CountString(Stromen, ";")
          If ExamineDirectory(0, "documenten", StringField(Stromen, i, ";") + "*.*")
            While NextDirectoryEntry(0)
              If DirectoryEntryType(0) = #PB_DirectoryEntry_File
                FileDate = DirectoryEntryDate(0, #PB_Date_Modified)
                If FileDate <= Peil
                  Match + 1
                EndIf
              EndIf
            Wend
            FinishDirectory(0)
          EndIf
        Next i
        If Not Match
          Continue
        EndIf
      EndIf
      ;}
      
      ;{ Check of er niet nog nieuwe bestanden zijn
      If NietJonger > 0
        Match = 0
        Peil = ParseDate("%dd-%mm-%yyyy %hh:%ii", Datum + " " + Tijd) - Ouder          
        For i = 1 To CountString(Stromen, ";")
          If ExamineDirectory(0, "documenten", StringField(Stromen, i, ";") + "*.*")
            While NextDirectoryEntry(0)
              If DirectoryEntryType(0) = #PB_DirectoryEntry_File
                If DirectoryEntryDate(0, #PB_Date_Modified) >= Peil
                  Match + 1
                EndIf
              EndIf
            Wend
            FinishDirectory(0)
          EndIf
        Next i
        If Match
          Continue
        EndIf
      EndIf
      ;}
        
      ;{ Check of er voldoende documenten zijn
      Aantal = 0
      For i = 1 To CountString(Stromen, ";")
        If ExamineDirectory(0, "documenten", StringField(Stromen, i, ";") + "*.*")
          While NextDirectoryEntry(0)
            If DirectoryEntryType(0) = #PB_DirectoryEntry_File
              Aantal + 1
            EndIf
          Wend
          FinishDirectory(0)
        EndIf
      Next i
      If Aantal =0 Or Aantal < MinDocs
        Continue
      EndIf
      ;}
             
      LogMsg("Match OK")
      
      ;{ Maak job
      
      Aantal = 0
      For i = 1 To CountString(Stromen, ";")
        If ExamineDirectory(0, "documenten", StringField(Stromen, i, ";") + "*.*")
          While NextDirectoryEntry(0)
            If DirectoryEntryType(0) = #PB_DirectoryEntry_File
              FileName.s = DirectoryEntryName(0)
              If Aantal = MaxDocs
                LogMsg(JobName.s + " gemaakt met " + Aantal + " documenten")
                Aantal = 0
              EndIf
              Aantal + 1
              If Aantal = 1
                JobNr + 1        
                JobName.s = ReplaceString(Stromen, ";", "_") + RSet(Str(JobNr), 8, "0")
                CreateDirectory("jobs/" + JobName)
              EndIf
              RenameFile("documenten/" + FileName, "jobs/" + JobName + "/" + FileName) 
            EndIf
          Wend
          FinishDirectory(0)
        EndIf
      Next i
      If Aantal > 0
        LogMsg(JobName + " gemaakt met " + Aantal + " documenten")
      EndIf
    
      ;}
      
    Wend
    CloseFile(1) ; Regels
    ;}
      
    ;{ Opslaan laatst gebruikte JobNr
    If CreateFile(0, "JobNr.txt")
      WriteStringN(0, Str(JobNr))
      CloseFile(0)
    Else
      LogMsg("Error: Laatst gebruikte JobNr kan niet worden opgeslagen")
    EndIf
    ;}

    VorigeTijd = Tijd
    
  EndIf
  
  LogMsg("") ; Geef LogMsg gelegenheid om logfile te sluiten
  
  Delay(100) ; CPU besparing
  
ForEver
;}

;{ Afsluiting
If TimeFile
  CloseFile(TimeFile)
EndIf

End
;}
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 479
; FirstLine = 321
; Folding = Zv66
; EnableUnicode
; EnableXP