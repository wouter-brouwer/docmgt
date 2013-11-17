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

Global LogDir.s
NewList FileNames.s()

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
    If FileSize(LogDir + #Prog + ".log") > 1024 * 1024 ; 1 MB
      RenameFile(LogDir + #Prog + ".log", LogDir + #Prog + FormatDate("_%yyyy-%mm-%dd", Date()) + ".log")
    EndIf
    LogFileNr = OpenFile(#PB_Any, LogDir + #Prog + ".log")
    FileSeek(LogFileNr, Lof(LogFileNr))
  EndIf
  
  ; De boodschap met tijd naar de log schrijven
  TimeStamp.s = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  Regel.s = TimeStamp + " - " + Msg
  Debug Regel
  WriteStringN(LogFileNr, Regel)
  
  ; Stoppen bij ernstige fout
  If FindString(LCase(Msg), "critical") = 1
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

Procedure.s CheckDirectory(Dir.s)
  If FileSize(Dir) <> -2
    If Not CreateDirectory(Dir)
      LogMsg("Critical: Can not create directory "+ Dir)
    Else
      LogMsg("Info: Directory " + Dir + " created")
    EndIf
  Else
    ProcedureReturn Dir + "/"
  EndIf
EndProcedure

;{ Init

; De verschillende directories
BaseDir.s = "/aiw/aiw1"
If FileSize(BaseDir) <> -2
  BaseDir.s = "."
EndIf
BaseDir + "/"

LogDir.s = CheckDirectory(BaseDir + "logs")

LockDir.s = CheckDirectory(BaseDir + "locks")

ConfigDir.s = CheckDirectory(BaseDir + "config")

DocumentDir.s = CheckDirectory(BaseDir + "documents")

TodoDir.s = CheckDirectory(DocumentDir + "todo")

JobsDir.s = CheckDirectory(DocumentDir + "jobs")

LockFile.s = LockDir + #Prog + ".lock"
LockFileNr = CreateFile(#PB_Any, LockFile)
If LockFileNr = 0 
  LogMsg("Critical: Unable to create " + LockFile + " Program already running?")
EndIf
LogMsg(#Prog + " started")

If ReadFile(0, ConfigDir + "JobNr.txt")
  JobNr = Val(ReadString(0))
  CloseFile(0)
EndIf

TimeFileNr = ReadFile(#PB_Any, "xTimeFile.txt")
;}

;{ Main loop
While FileSize(#Prog + ".stop") = -1 ; Zolang er geen MakeJobs.stop bestand is
  
;{ Bepaal datum en tijd
  ; Voor testdoeleinden uit een bestandje halen
  If TimeFileNr
    If Not Eof(TimeFileNr)
      Line.s = ReadString(TimeFileNr)
      Datum.s = StringField(Line, 1, " ")
      Tijd.s = StringField(Line, 2, " ")
    Else
      Break
    EndIf
  Else
    ; Voor werkelijkheid de systeemdatum en tijd nemen
    Datum.s = FormatDate("%dd-%mm-%yyyy", Date())
    Tijd.s = FormatDate("%hh:%ii:%ss", Date())
  EndIf  
;}
  
;{ Bepaal de datum kenmerken
  If Datum <> VorigeDatum.s
    Weekdag = DayOfWeek(ParseDate("%dd-%mm-%yyyy", Datum))
    If Weekdag = 0
      Weekdag = 7
    EndIf
    Feestdag = 0
    ; lees feestdagen bestand
    If ReadFile(1, ConfigDir + "feestdagen.txt")
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
      LogMsg("Critical: Feestdagen bestand kan niet geopend worden")
    EndIf
    VorigeDatum = Datum
  EndIf
  ;}

  If Tijd <> VorigeTijd.s; Nieuwe minuut
    
    Debug "Verwerking: " + Datum + " " + Tijd
    
    ;{ Verwerk alle regels
    If Not ReadFile(1, ConfigDir + "makejobsregels.txt")
      LogMsg("Critical: Regel bestand kan niet worden geopend")
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
      MinPages = 0
      MaxPages = 0
      ;}
      
      ;{ Parse de regel
      Line = Trim(ReplaceString(ReadString(1), Chr(9), " ")) + " "
      If Left(Line,1) = "#" ; Commentaar overslaan
        Continue
      EndIf
      Line = ReplaceString(Line, ",", " ")
      Line = ReplaceString(Line, ";", " ")
      Line = ReplaceString(Line, "  ", " ")
      ;LogMsg("Regel: "+ Line)
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
        If Woord = "min-documenten"
          KeyWord.s = "MinimaalDocumenten"
          Continue
        EndIf
        If Woord = "max-documenten"
          KeyWord.s = "MaximaalDocumenten"
          Continue
        EndIf
        If Woord = "min-paginas"
          KeyWord.s = "MinimaalPaginas"
          Continue
        EndIf
        If Woord = "max-paginas"
          KeyWord.s = "MaximaalPaginas"
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
              LogMsg("Error: Ongeldige dag " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "Tijden"
            If IsTijd(Woord)
              Tijden + Woord + ";"
            Else
              LogMsg("Error: Ongeldige tijd " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "Van"
            If IsTijd(Woord)
              Periodes + Woord + "-"
            Else
              LogMsg("Error: Ongeldige tijd " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "Tot"
            If IsTijd(Woord)
              Periodes + Woord + ";"
            Else
              LogMsg("Error: Ongeldige tijd " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "Ouder"
            If IsTijd(Woord)
              Ouder = ParseDate("%hh:%ii", Woord)
            Else
              LogMsg("Error: Ongeldige tijd " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "NietJonger"
            If IsTijd(Woord)
              NietJonger = ParseDate("%hh:%ii", Woord)
            Else
              LogMsg("Error: Ongeldige tijd " + Woord + " in regel " + Line)
              Line = ""
              Break
            EndIf
          Case "MinimaalDocumenten"
            MinDocs= Val(Woord)
          Case "MaximaalDocumenten"
            MaxDocs = Val(Woord)
          Case "MinimaalPaginas"
            MinPages = Val(Woord)
          Case "MaximaalPaginas"
            MaxPages = Val(Woord)
          Default
            LogMsg("Error: Onverwacht woord " + Woord)
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
          If ExamineDirectory(0, TodoDir + StringField(Stromen, i, ";"), StringField(Stromen, i, ";") + "*.*")
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
      If NietJonger >= 0
        Match = 0
        Peil = ParseDate("%dd-%mm-%yyyy %hh:%ii:%ss", Datum + " " + Tijd) - 1          
        For i = 1 To CountString(Stromen, ";")
          If ExamineDirectory(0, TodoDir + StringField(Stromen, i, ";"), StringField(Stromen, i, ";") + "*.*")
            While NextDirectoryEntry(0)
              If DirectoryEntryType(0) = #PB_DirectoryEntry_File
                If DirectoryEntryDate(0, #PB_Date_Modified) >= Peil
                  Match + 1
                  Break 2
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
      AantalDocs = 0
      For i = 1 To CountString(Stromen, ";")
        If ExamineDirectory(0, TodoDir + StringField(Stromen, i, ";"), StringField(Stromen, i, ";") + "*.*")
          While NextDirectoryEntry(0)
            If DirectoryEntryType(0) = #PB_DirectoryEntry_File
              AantalDocs + 1
              If AantalDocs >= MinDocs
                Break
              EndIf
            EndIf
          Wend
          FinishDirectory(0)
        EndIf
      Next i
      If AantalDocs = 0 Or AantalDocs < MinDocs
        Continue
      EndIf
      ;}
             
      ;{ Check of er voldoende pagina's zijn
      AantalPages = 0
      For i = 1 To CountString(Stromen, ";")
        If ExamineDirectory(0, TodoDir + StringField(Stromen, i, ";"), StringField(Stromen, i, ";") + "*.*")
          While NextDirectoryEntry(0)
            If DirectoryEntryType(0) = #PB_DirectoryEntry_File
              FileName.s = DirectoryEntryName(0)
              p = FindString(FileName, "_P")
              e = FindString(FileName, ".")
              Pages = Val(Mid(FileName, p + 2, e - p))
              AantalPages + Pages
              If AantalPages >= MinPages
                Break
              EndIf
            EndIf
          Wend
          FinishDirectory(0)
        EndIf
      Next i
      If AantalPages = 0 Or AantalPages < MinPages
        Continue
      EndIf
      ;}
             
      LogMsg("Match OK")
      
      ;{ Maak job
      
      AantalDocs = 0
      AantalPages = 0
      For i = 1 To CountString(Stromen, ";")
        Stroom.s = StringField(Stromen, i, ";")
        TodoStroomDir.s = TodoDir + Stroom + "/"
        ClearList(FileNames())
        If ExamineDirectory(0, TodoStroomDir, Stroom + "*.*")
          While NextDirectoryEntry(0)
            If DirectoryEntryType(0) = #PB_DirectoryEntry_File
              AddElement(FileNames())
              FileNames() = DirectoryEntryName(0)
            EndIf
          Wend
          FinishDirectory(0)
          SortList(FileNames(), #PB_Sort_Ascending)
          ForEach FileNames()
            FileName = FileNames()
            Gosub VerwerkFile
          Next
        EndIf
      Next i
      If AantalDocs > 0
        LogMsg(JobName.s + " created with " + Str(AantalDocs) + " documents and " + Str(AantalPages) + " pages")
      EndIf
    
      ;}
      
    Wend
    CloseFile(1) ; Regels
    ;}
      
    VorigeTijd = Tijd
    
  EndIf
  
  LogMsg("") ; Geef LogMsg gelegenheid om logfile te sluiten
  
  Delay(100) ; CPU besparing
  
Wend
;}

;{ Afsluiting
If LockFileNr
  CloseFile(LockFileNr)
EndIf

If TimeFileNr
  CloseFile(TimeFileNr)
EndIf

End
;}

;{ VerwerkFile:
VerwerkFile:

  p = FindString(FileName, "_P")
  e = FindString(FileName, ".")
  Pages = Val(Mid(FileName, p + 2, e - p))
  
  If (MaxDocs > 0 And AantalDocs = MaxDocs) Or
     (MaxPages > 0 And AantalPages >= MaxPages)
    LogMsg(JobName.s + " created with " + Str(AantalDocs) + " documents and " + Str(AantalPages) + " pages")
    AantalDocs = 0
    AantalPages = 0
  EndIf
  
  AantalDocs + 1
  AantalPages + Pages
  If AantalDocs = 1
    JobNr + 1        
    JobName.s = ReplaceString(Stromen, ";", "_") + RSet(Str(JobNr), 8, "0")
    JobDir.s = JobsDir + JobName + "/"
    If Not CreateDirectory(JobDir)
      LogMsg("Critical: Unable to create " + JobDir)
    EndIf 
     ;{ Opslaan laatst gebruikte JobNr
    If CreateFile(0, ConfigDir + "JobNr.txt")
      WriteStringN(0, Str(JobNr))
      CloseFile(0)
    Else
      LogMsg("Critical: Laatst gebruikte JobNr kan niet worden opgeslagen")
    EndIf
    ;}            
  EndIf
  
  If Not RenameFile(TodoStroomDir + FileName, JobDir + FileName) 
    LogMsg("Critical: Unable move " + TodoStroomDir + FileName + " to " + JobDir)
  EndIf

Return
;}
; IDE Options = PureBasic 5.20 LTS (Linux - x64)
; CursorPosition = 494
; FirstLine = 169
; Folding = AWhk-
; EnableUnicode
; EnableXP