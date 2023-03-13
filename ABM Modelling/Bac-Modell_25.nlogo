;Unterschied zur Vorversion: Behübschen
;
;Einfügung von NetLogo-Erweiterungen
extensions [nw] ;NetworkPackage zur Erstellung von Netzwerken

;Definition der Agentenklassen
breed[fossps fossp] ;Fossil Supplier = Produzenten des Konsumgutes, welches auf fossilien Rohstoffen beruht.
breed[biosps biosp] ;Bio Supplier = Produzenten des Konsumgutes, welches auf biologischen/erneuerbaren Rohstoffen beruht.
breed[custms custm] ;Kunden = Kaufen Konsumgut foscom
breed [biocustms biocustm]; Kunden = Kaufen Konsumgut biocom

;Definition globaler Variablen
globals [foscom biocom oilprice oildev difprob validation] ;foscom = Marktpreis des Guts (Commodity) mit fossiler Rohstoffbasis; biocom = Marktpreis des Guts mit erneuerbarer Rohstoffbasis (spielt aktuel noch kein Rolle)
                                                 ;oilprice = Ölpreis; oildev = Veränderungsrate Ölpreis;  difprob = Diffusion probability [%]... Erwartungswert der WK der biowtp-Beeinflussung durch Nachbarn bei n Versuchen.
                                                 ;validation = Variable zur Überprüfung der Logik der Simulationsstartbedingungen

;Definition agentenspezifischer Variablen
fossps-own [uc check mshare];uc = Unit Cost = Stückkosten; check = für Stückkostenzuteilung; mshare = Marktanteil

custms-own [biowtpm custmshare check]; biowptm = Willingness to Pay More für Bio-Produkt; concustmshare = Marktanteil eines Kunden; check = für biowtp-Zuteilung

biosps-own [uc mshare]

biocustms-own[biowtpm custmshare start] ; start = restliche Tickanzahl bis Simulationsende zur Berechnung der Diffusionswahrscheinlichkeiten

links-own [c impact]  ;c = "Check"-Variable zur Links-Abfrage bei Diffusionsprozess; impact = zeigt an, ob Veränderung der Linkfarbe die biowtpm eines custm bereits verändert hat


to setup ;Simulationsvorbereitung
  clear-all
  reset-ticks
  creation    ;Agentenerstellung
  marketshare ;Zuteilung der mshares der FOSSPS
  unit_costs  ;Zuteilung der uc der FOSSPS

  set oilprice 68
  ;Implementation der drei Entwicklungsszenarios des Ölpreises -> ANNAHME: Lineare Entwicklug des Ölpreises; Szenarien enden 2040, Anstieg pro Monat => jeder dritter Tick
  if Oil-Scenario = "Current Policies"[ set oildev 1.00773809578038]
  if Oil-Scenario = "Stated Policies"[ set oildev 1.00472953736261]
  if Oil-Scenario = "Sustainable Development"[ set oildev 0.998387939288562]

  biowtpm_allocation         ;Zuteilung der biowtpms der CUSTMS
  diffusionprobability      ;Legt global "difprob" für gesamten Simulationsdurchgang fest.

end


to go ;Iterationsvorgang
  ;if count fossps = 1 [stop]

  if ticks = 0 [valid?] ;Überprüfung der Angaben nur bei erstem Durchgang
  if validation = FALSE [stop] ;Validierung muss für Simulationsstart positiv sein
  if ticks = 88 * 3 [ ;Ölpreis verändert sich nur alle 3 Ticks => 1 Tick = 1 Monat
    ending
   stop];Ende der Simulation, weil Entwicklung des Ölpreises danach ungewiss
  if count fossps = 0 [ ;Ende der Simulation, wenn nur mehr Biosps am Markt
    ending
    stop
  ]

  oil                  ;Veränderung des Ölpreises
  priceupdate          ;Veränderung der fossps [uc]
  substitution         ;Ersetzung der fossps durch biosps
  diffusion            ;Diffusionprozess
  biowtpm-adaptation    ;Veränderung der custms [biowtpm]

  tick
end

to valid? ;Überprüfung ob Angaben logisch sind
  ;Überprüfung ob Angabe des total-market-share = 1 ist
  if precision (total-Market-Share-large-Companies + total-Market-Share-medium-Companies + total-Market-Share-small-Companies) 4 != 1[;precision rundet den Wert auf 4 Nachkommastellen
  print "total Market-Share-Error: Please adjust total market-shares"
  set validation FALSE
  ]
  ;Überprüfung ob für mshare der einzelnen Agenten gilt L > M > S
  ifelse (total-Market-Share-large-Companies / Number-of-large-Companies) > (total-Market-Share-medium-Companies / Number-of-medium-Companies) and (total-Market-Share-medium-Companies / Number-of-medium-Companies) > (total-Market-Share-small-Companies / Number-of-small-Companies)[
  ];es passiert nichts - Anforderungen erfüllt
  [; else : wenn Anforderung nicht erfüllt
   print "relative Market-Share-Error: Please adjust relative market-shares"
   set validation FALSE
    ]
  ;Überprüfung ob Max-WTPM > Min-WTPM
  if Max-WTPM < Min-WTPM[
    print "WTPM-Error: Please adjust Max- or Min-WTPM"
    set validation FALSE
  ]

end

to ending ;Endanzeige
  write "------------------------------------------" print ""
  write "FINAL REPORT" print ""
  write "End of Simulation after " write ticks print " ticks"
  write "Number of Biosps = " print count biosps
  write "Number of Biocustms = " print count biocustms

end


to creation ;Agentenerstellung

  ;Modellierung Kunden - Small World Network
  let number Number-of-Customers / 2
  nw:generate-small-world custms links number 2  2 false [
    set shape "person"
    set color orange
    setxy random-xcor random-ycor
  ]
  repeat 3000 [ layout-spring turtles links 0.5 5 2 ] ;Netzwerk sortieren ---- damit setup schneller wird kann repeat ZAHL reduziert werden

  ;Zuteilung des Market-Shares => ANNAHME: Jeder Kunde hat gleichen Martkanteil
  ask custms[
    set custmshare ( 1 / Number-of-Customers)
  ]

  ;Modellierung Fossil Supplier
  let cor -16
  create-fossps (Number-of-large-Companies + Number-of-medium-Companies + Number-of-small-Companies)[
    setxy random-xcor random-ycor
    set shape "factory"
    set color blue
  ]

end


to marketshare ;betifft NUR FOSSPS! Bestimmung der Marktanteile eines jeden einzelnen FOSSP

  ;LARGE companies
  ask n-of ( Number-of-large-Companies ) fossps with [check = 0][
    set mshare (total-Market-Share-large-Companies / Number-of-large-Companies)
    set label "L"
    set check 1
  ]

  ;SMALL companies
  ask n-of ( Number-of-small-Companies ) fossps with [check = 0][
    set mshare (total-Market-Share-small-Companies / Number-of-small-Companies)
    set label "S"
    set check 1
  ]

  ;MEDIUM companies
  ask n-of ( Number-of-medium-Companies) fossps with [check = 0][
    set mshare (total-Market-Share-medium-Companies / Number-of-medium-Companies)
    set label "M"
    set check 1
  ]

end

to unit_costs ;betrifft NUR FOSSPS
              ;Zuteilung der Stückkosten - ANNAHME: Economies of Scale => je größer ein Unternehmen, desto geringer die Stückkosten => je größer mshare, desto geringer uc
              ;Methode: Berechnung der individuellen Stückkosten (uc) abgeleitet von den Stückkosten eines hypothetischen Monopolisten mit Marktanteil 100%
  ask fossps[
    let factor (7000 + random 1001) / 10000 ;Zufällige Auswahl des Faktor zur Auswirkung der Economies of Scale [0.7;0.8]
    ;print factor
    ;Berechnung von k0 und potenz durch factor => Ergebnis ist Formel zur Berechnung der Stückkosten aller Marktanteile, mit Monopol-Stückkosten iHv 100.
    let k0 (100.000000000547 * factor ^ -6.643856189758)
    let potenz (-1.442695048400 * ln(factor) - 0.000000002946) * -1
    ;print  k0
    ;print potenz
    ;Umwandlung von k0 und auf gewünschte Monopol-Stückkosten => Ergebnis ist Formel zur Berechnung der Stückkosten aller Martkanteile, mit Monopol-Stückkosten iHv Monopoly-Unit-Cost-foscom.
    let k1 (Monopoly-Unit-Cost-foscom / 100 * k0)
    ;print k1
    ;Berechnung der agentenspezifischen UnitCosts abhängig vom Marktanteil (mshare)
    set uc (k1 * (mshare * 100) ^ potenz)
    ;print uc
  ]

  ;Implementation foscom (Preis des Gutes der fossps)
  set foscom ( max [uc] of fossps) ;ANNAHME: Preis des Gutes = höchste Stückkosten am Markt. Logik: Preis kann nicht niedriger sein, da Unternehmen ansonsten nicht profitabel wäre.

end

to oil ;Veränderung des Ölpreises
  if ticks / 3  = int ( ticks / 3)[ ;Ölpreis ändert sich nur alle 3 Ticks
    set oilprice oilprice * oildev
    ;Auswirkung des veränderten Ölpreises auf agentenspezifische Unit Costs -> ANNAHME: Oil-Price-Dependency für alle Fossps gleich!
    ask fossps[ ;ANNAHME: Ölpreisveränderung betrifft nur Stückkosten der FOSSPS
      set uc uc * (((oildev - 1) * Oil-Price-Dependency / 100) + 1)
    ]
  ]
end


to biowtpm_allocation ;betrifft NUR CUSTMS; Einstellung der custms-variable biowtpm abhängig von Innovationsgruppe
;ANNAHME: Immer 5 gleiche Gruppen die IMMER gleich groß sind
;ANNAHME: WTPM ist "gleichverteilt" => die ersten 2.5% der Custms besitzen die höchsten 2.5% der WTPM ( = Max-WTPM * 0.975)

  ;maxwtpm... Maximal mögliche BioWTPM einer Gruppe (oberes Limit)
  ;minwtpm... Minimal mögliche BioWTPM einer Gruppe (unteres Limit)

  ;"Innovators"
  ask n-of (Number-of-Customers * 0.025 ) custms with [check = 0][ ;ANNAHME: immer 2.5% aller Custms ------------------- Problem: Bei zu geringer Custm-Anzahl gibt es keinen Innovator
    let maxwtpm Max-WTPM                                                                           ;Alle Angaben in %
    let minwtpm (Min-WTPM + (Max-WTPM - Min-WTPM) * 0.975)  ;ANNAHME: Fixe Limits

    ;print maxwtpm
    ;print minwtpm

    let interval ((maxwtpm - minwtpm) * 1000) ;Berechnung des Intervalls, in dem biowtpm des custsm liegen kann; * 1000 weil random Befehl nur mit integern funktioniert
    let var (minwtpm + random (interval) / 1000) ;+1 damit auch oberes Limit mit random erreichbar

    ;write  "Interval" print interval
    ;write "Biowtpm" print var


    set biowtpm ( 1 + var / 100 ) ;Umrechnung von % in Zahl
    set label "I" ;für Innovator
    set check 1

    ;write "biowtpm" print biowtpm

  ]


   ;"Early Followers"
  ask n-of (Number-of-Customers * 0.135) custms with [check = 0][ ;ANNAHME: immer 13.5% aller Custms
    let maxwtpm  (Min-WTPM + (Max-WTPM - Min-WTPM) * 0.975) ;Oberes Limit ist unteres Limit der Vordergruppe                      ;Alle Angaben in %!!
    let minwtpm (Min-WTPM + (Max-WTPM - Min-WTPM) * 0.84)  ;ANNAHME: Fixe Limits

    let interval ((maxwtpm - minwtpm) * 1000) ;Berechnung des Intervalls, in dem biowtpm des custsm liegen kann; * 1000 weil random Befehl nur mit integern funktioniert
    let var (minwtpm + random (interval) / 1000) ;+1 damit auch oberes Limit mit random erreichbar

    set biowtpm ( 1 + var / 100 ) ;Umrechnung von % in Zahl
    set label "EF" ;für Innovator
    set check 1
  ]


  ;"Early Majority"
  ask n-of (Number-of-Customers * 0.34) custms with [check = 0][ ;ANNAHME: immer 34% aller Custms
    let maxwtpm (Min-WTPM + (Max-WTPM - Min-WTPM) * 0.84)  ;Oberes Limit ist unteres Limit der Vordergruppe                      ;Alle Angaben in %!!
    let minwtpm (Min-WTPM + (Max-WTPM - Min-WTPM) * 0.5)  ;ANNAHME: Fixe Limits

    let interval ((maxwtpm - minwtpm) * 1000) ;Berechnung des Intervalls, in dem biowtpm des custsm liegen kann; * 1000 weil random Befehl nur mit integern funktioniert
    let var (minwtpm + random (interval) / 1000) ;+1 damit auch oberes Limit mit random erreichbar

    set biowtpm ( 1 + var / 100 ) ;Umrechnung von % in Zahl
    set label "EM" ;für Innovator
    set check 1
  ]


  ;"Late Majority"
  ask n-of (Number-of-Customers * 0.34) custms with [check = 0][ ;ANNAHME: immer 34% aller Custms
    let maxwtpm (Min-WTPM + (Max-WTPM - Min-WTPM) * 0.5)  ;Oberes Limit ist unteres Limit der Vordergruppe                      ;Alle Angaben in %!!
    let minwtpm (Min-WTPM + (Max-WTPM - Min-WTPM) * 0.16)  ;ANNAHME: Fixe Limits

    let interval ((maxwtpm - minwtpm) * 1000) ;Berechnung des Intervalls, in dem biowtpm des custsm liegen kann; * 1000 weil random Befehl nur mit integern funktioniert
    let var (minwtpm + random (interval) / 1000) ;+1 damit auch oberes Limit mit random erreichbar

    set biowtpm ( 1 + var / 100 ) ;Umrechnung von % in Zahl
    set label "LM" ;für Innovator
    set check 1
  ]


  ;"Laggards"
  ask custms with [check = 0][ ;ANNAHME: immer 16% aller Custms -> Auswahl der restlichen Custms
    let maxwtpm  (Min-WTPM + (Max-WTPM - Min-WTPM) * 0.16) ;Oberes Limit ist unteres Limit der Vordergruppe                      ;Alle Angaben in %!!
    let minwtpm Min-WTPM  ;ANNAHME: Fixe Limits

    let interval ((maxwtpm - minwtpm) * 1000) ;Berechnung des Intervalls, in dem biowtpm des custsm liegen kann; * 1000 weil random Befehl nur mit integern funktioniert
    let var (minwtpm + random (interval) / 1000) ;+1 damit auch oberes Limit mit random erreichbar

    set biowtpm ( 1 + var / 100 ) ;Umrechnung von % in Zahl
    set label "L" ;für Innovator
    set check 1
  ]

end

to priceupdate ;Betrifft nur FOSSPS; Foscom wird den höchsten fossp [uc] gleichgesetzt.
  if any? fossps [set foscom ( max [uc] of fossps)]
end


to substitution ;Mechanismus zur Ersetzung von fossps durch biosps
                ;die Ersetzung eines fossp' durch eine biosp findet statt wenn: Stückkosten fossp(Marktanteil = share) * decisionwtp > Stückkosten biosps(Marktanteil = share)
                ;wobei BIOWTPM folgendermaßen berechnet wird: 1) reihe custms absteigen nach individueller biowtpm in Liste0
                ;                                            2) wähle, von Listenanfang beginnend, so viele custms, dass die Summe ihrer [costmshare] = share ist und füge diese in neue Liste Liste1
                ;                                            3) wähle von Liste1 jenen custms mit niedrigster biowtpm (= jener custm, der zuletzt hinzugefügt wurde).
                ;                                            4) setze decisionwtp gleich jener niedrigster biowtpm
                ;Logik: Biosp tritt nur in Markt ein, wenn er gleichen Marktanteil stückkostendeckend übernehmen kann => letzter Kunde muss min bereit sein, genau Stückkostenpreis zu zahlen

  let maxuc 0     ;nimmt anschließend den Wert der höchsten fossp[uc] an.
  let share 0     ;nimmt anschließend den Wert der mshare des fossp mit den höchsten uc an.

  ;Berechnung der Entscheidungsvariablen maxuc & share
  ask fossps with-max [uc][
    ;show who
    set maxuc uc    ;Setze maxuc den höchsten fossp [uc] in Simulation -> muss der gleiche Wert wie Foscom sein!
    set share mshare ;Setze share den mshare des fossp mit den höchsten uc
                     ;show maxuc
  ]
  ;write "maxuc" print maxuc
  ;write "share" print share


  ;Wieviele Konsumenten braucht man zur Erreichung eines Marktanteils von share? ; Marktanteil eines custm = custmshare des Agenten
  let conneed 0 ;conneed = Zahl die angibgt, wieviele Konsumenten für die Erreichung eines Marktanteils von share notwendig sind.
                ;VERÄNDERUNG 1 zu V.22; wenn es sich hierbei um letzten Fossp handelt, dann muss conneed abgerundet werden! => Sonst Error bei Umstellung zu Biocustms!
  ifelse count fossps = 1 [
    set conneed floor (share / (1 / (count custms + count biocustms) ))
    ;write "conneed" print conneed
  ]

  [
    set conneed ceiling (share / (1 / (count custms + count biocustms) )) ;
                                                                          ;ceiling...Aufrunden der Zahl auf Intenger; Ausdruck (1 / count custms) = Marktanteil eines jeden Custms = custmshare
                                                                          ;WICHTIG: Fehlerquelle: (count custms + count biocusmts)! ansonsten Relationen falsch!!
                                                                          ;write "Number von Costms needed" print conneed
  ]

  ; Erstelle einer Liste der Konsumenten mit der höchsten bioWTP; Es sollen so viele Konsumenten in der Liste sein, dass die Summe ihrer custmshare >= share ist
  let liste0 []
  set liste0 sort-on [(- biowtpm)] custms ;Erstelle Liste aller Custms, sortiert nach biowptm, wobei Agent mit höchster biowtpm am Anfang [beinhaltet Agenten!]

  let liste1 []
  let combine []

  set liste1 sort [biowtpm] of custms ; Erstelle Liste aller biowtpms, sortiert nach Größe, kleineste biowtpm zuerst [beinhaltet Eigenschafter der Agenten!]
  set liste1 reverse liste1 ;Jetzt größte biowtpm zuerst => Übereinstimmung der Reihenfolge der biowtpms in liste1 mit custms in liste

  ; While Schleife hört auf, wenn die Anzahl der Listenitems = conneed
  let x 0
  while [x < conneed] [
    set combine lput item x  liste1 combine    ; Begonnen wird damit, die höchste biowtpm ans Listenende zu setzen => Am Loopende: Minimum der biowtpms der Liste ist am Ende.
    set x x + 1
    ;if x > 200 [stop] ;Sicherung While-Schleife
  ]

  ;Überprüfungsmöglichkeit
  ;write "Custm-List" print liste0
  ;write "biowtpm-List" print liste1
  ;write "Combine" print combine

  ;Wähle die niedrigste biowtpm, also die letzte Zahl der Liste combine; Nur wenn combine nicht empty ist - ansonsten Fehlermeldung!
  let decisionwtp 0
  if not empty? combine[
    set decisionwtp  (min combine)
    ;write "Decisionwtp" print decisionwtp
  ]

  ;Berechnung der biouc(share) => 1:1 gleiche Formel wie bei fossps
  let biouc 0
  let factor (7000 + random 1001) / 10000 ;Zufällige Auswahl des Faktor zur Auswirkung der Economies of Scale [0.7;0.8]
  ;Berechnung von k0 und potenz durch factor => Ergebnis ist Formel zur Berechnung der Stückkosten aller Marktanteile, ausgehend von Mono-Stückkosten von 100
  let k0 (100.000000000547 * factor ^ -6.643856189758)
  let potenz (-1.442695048400 * ln(factor) - 0.000000002946) * -1
  ;Umwandlung von k0 und auf gewünschte Mono-Stückkosten => Ergebnis ist Formel zur Berechnung der Stückkosten aller Martkanteile, ausgehend von Monopoly-Unit-Cost-foscom
  let k1 (Monopoly-Unit-Cost-biocom / 100 * k0)
  ;Berechnung der agentenspezifischen UnitCosts abhängig vom Marktanteil
  set biouc (k1 * (share * 100) ^ potenz)
  ;print  "BIOUC" print biouc

  ;ANMERKUNG: Bei Gleichsetzung beider Monopoly-Unit-Cost-foscom/biocom ist biouc immer niedriger als fosspuc - trotz gleicher Formel! Begründung: je mehr (S) fossps, desto ungünstiger ist des Faktor des betroffenen fossps bei Berechnung der Uc

  ;Entscheidung der Ersetzung: Biosp ersetzt fossp wenn : foscom * decisionwtp >= biouc(mit Marktanteil share)
  let sub? 0 ;sub? wird 1 wenn eine Substitution erfolgt ist
  if foscom * decisionwtp > biouc[
    let dif 0 ;----------------VERÄNDERUNG 2 zu V.22; dif gibt die Änderung von mshare zu newshare an.
    ask fossps with [uc = maxuc][ ;Wenn Bedingung erfüllt: ersetze fossp durch biosp
      set breed biosps
      set color green
      set shape "factory"
      set uc biouc

      let newshare (conneed * (1 / Number-of-Customers)) ; --------VERÄNDERUNG 3 zu V.22; der neue Marktanteil ist abhängig von der Anzahl an Kunden, die zu Biocustms werden.
      set dif newshare - mshare                         ; newshare ist immer größer als mshare, weil bei conneed-Berechnung aufgerundet wird. dif speichert Differenz
      set mshare newshare                               ; Überschreibung des alten mshare mit newshare

      ;write "Dif" print dif

      set sub? 1
    ]
    ;VERÄNDERUNG 4 zu V.22; Verlust von Marktanteil aller FOSSPS; ANNAHME: Gleichmäßige Aufteilung des Verlusts auf alle Fossps
    ask fossps[
        set mshare (mshare - (dif / (count fossps)) ) ;:Marktanteils-Verlust wird gleichmäßig auf alle Fossps aufgeteilt
      ]
  ]

  ;Konsumenten, deren biowtp zum Umstieg relevant war, werden grün. Ziel: Alle Custms der biowtpms in der Liste "combine" waren, werden grün => werden biocustms
  if sub? = 1 [
    ; While Schleife hört auf, Variable x gleich groß wie die erforderliche conneed ist.
    set x 0
    while [x < conneed][
      ask (item x liste0) [ ; mit x = 0: item x liste0 => liefert costm mit höchster biowptm
                            ;Speicherung der alten Eigenschaften
        let a custmshare
        let b biowtpm
        ;Umwandlung in biocustm mit gleichen Eigenschaften => Vereinfacht die folgenden Iterationsdruchgänge.
        set breed biocustms
        set color green
        set shape "person"
        set custmshare a
        set biowtpm b
        set start (264 - ticks) ;check gibt somit die Anzahl an Ticks bis Simulationsende an = die Anzahl an Versuchen, um die eigenen Links grün werden zu lassen.
      ]
      set x x + 1
      ;if x > 200 [stop] ;Sicherung While-Schleife
    ]


    set sub? 0
  ]

end


to diffusionprobability ;Festlegung von difprob = Die fixe Wahrscheinlichkeit, dass Link innerhalb eines Ticks grün wird.
                        ;ANNAHME: difprob bleibt für gesamte Simulation unverändert.
                        ;ANNAHME: alle 6 Attribute sind gleichgewichtet
  set difprob ( 100 / 4 * ( Relative_Advantage + Observability + Trialability + Compatibility + Complexity + Perceived_Risk) ) ;Gibt die WK für 1 Ziehung an
  ;print "DiffProb= "write difprob
end


to diffusion ;Nachbarn von Biocustms erfahren mit gewisser Wahrscheinlichkeit von Biocom. ANNAHME: die biowtpm eines custms steigt, wenn er bemerkt, dass sein Nachbar ein Biocustm. (Neighbor-Effect)
             ;ANNAHME: Wahrscheinlichkeit des Verbreitung von den Biocom-Attributen abhängig

  ;jeder Link eines Biocustms werden mit WK von p pro tick grün
  ask biocustms[
    while[count my-links with [c = 0] > 0][ ;while-Schleife läuft bis jeder Link einmal abgefragt wurde; die Variable c ist 1, wenn Link bereits grün
      ask one-of my-links with [c = 0][ ;nur nicht-grüne Links sollen gefragt werden
        if random-float 1 <= (difprob / 100) [set color green] ;random-float 1 liefert float aus interval [0;1]; ANNAHME: Konstante WK pro Tick für jeden Link eines Biocustm
        set c 1 ; c wird 1 gesetzt, unabhängig davon, ob Link grün wurde oder nicht, um doppelten Aufruf zu verhindern.
      ]
    ]
    ask my-links with [color != green][set c 0] ;Alle Links die nicht grün sind, erhalten wieder einen c-Wert von 0 und werden somit bei nächstem tick wieder abgefragt
  ]

end

to biowtpm-adaptation ;ANNAHME: Existenz des Neighbor-Effect: Die biowtpm eines custms erhöht sich um einen Faktor, wenn er Vorteile des Biocom beim Nachbar feststellt (=> Link wird grün)
                      ;ANNAHME: Betrifft nur CUSTMS => Biocustms haben unveränderliche Biowtp

  ask custms[
    if any? my-links with [c = 1 and impact = 0][ ;wenn Links des Agenten grün und noch keine Auswirkung auf biowtpm hatten
      let number count (my-links with [c = 1 and impact = 0 ]) ;zähle betroffene Links
      set biowtpm biowtpm + ( (Neighbor-Effect / 100) * number) ;ANNAHME: Pro grünem Link erhöht sich biowtpm um den KONSTANTEN (nicht relativen) Wert Neighbor-Effect.

      ask my-links with [c = 1 and impact = 0][set impact 1] ;ANNAHME:Links können nur einmal eine Auswirkung auf custm[biowtpm] haben.
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
3
17
515
530
-1
-1
15.3
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
524
23
587
56
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
523
67
586
100
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
748
111
903
171
Number-of-Customers
200.0
1
0
Number

INPUTBOX
970
60
1125
120
Monopoly-Unit-Cost-foscom
0.15
1
0
Number

TEXTBOX
695
85
740
103
Market
14
0.0
1

SLIDER
970
175
1125
208
Oil-Price-Dependency
Oil-Price-Dependency
0
200
110.0
10
1
%
HORIZONTAL

TEXTBOX
990
25
1105
56
Fossil Commodity (Foscom)
14
0.0
1

MONITOR
970
210
1125
255
Actual-Oil-Price [$ per barrel]
oilprice
3
1
11

CHOOSER
970
125
1125
170
Oil-Scenario
Oil-Scenario
"Current Policies" "Stated Policies" "Sustainable Development"
1

SLIDER
520
375
785
408
total-Market-Share-large-Companies
total-Market-Share-large-Companies
0
1
0.5
0.01
1
NIL
HORIZONTAL

TEXTBOX
625
355
710
386
Market-Share\n
14
0.0
1

SLIDER
521
455
786
488
total-Market-Share-small-Companies
total-Market-Share-small-Companies
0
1
0.21
0.01
1
NIL
HORIZONTAL

INPUTBOX
520
110
686
170
Number-of-large-Companies
4.0
1
0
Number

INPUTBOX
520
175
687
235
Number-of-medium-Companies
6.0
1
0
Number

INPUTBOX
520
240
687
300
Number-of-small-Companies
10.0
1
0
Number

MONITOR
520
305
677
350
Number of Fossil Suppliers
Number-of-large-Companies + Number-of-medium-Companies + Number-of-small-Companies
17
1
11

SLIDER
520
415
785
448
total-Market-Share-medium-Companies
total-Market-Share-medium-Companies
0
1
0.29
0.01
1
NIL
HORIZONTAL

MONITOR
815
360
865
405
L [%]
( total-Market-Share-large-Companies / Number-of-large-Companies) * 100
2
1
11

MONITOR
815
406
865
451
M [%]
( total-Market-Share-medium-Companies / Number-of-medium-Companies) * 100
2
1
11

MONITOR
815
451
865
496
S [%]
( total-Market-Share-small-Companies / Number-of-small-Companies) * 100
2
1
11

TEXTBOX
780
330
930
358
Market-Share of one Agent of Company-class
11
0.0
1

MONITOR
815
500
865
545
Total
total-Market-Share-large-Companies + total-Market-Share-medium-Companies + total-Market-Share-small-Companies
2
1
11

MONITOR
970
255
1125
300
Actual Market Price Foscom
foscom
2
1
11

INPUTBOX
1150
60
1305
120
Monopoly-Unit-Cost-biocom
0.5
1
0
Number

TEXTBOX
1170
25
1320
56
Biological Commodity\n(Biocom)
14
0.0
1

TEXTBOX
755
190
905
231
Customers Willingness to Pay More for Biocom [percentage]
11
0.0
1

SLIDER
745
220
920
253
Max-WTPM
Max-WTPM
0
300
90.0
1
1
%
HORIZONTAL

SLIDER
745
255
920
288
Min-WTPM
Min-WTPM
0
300
27.0
1
1
%
HORIZONTAL

SLIDER
1145
360
1285
393
Relative_Advantage
Relative_Advantage
0
1
0.4
0.1
1
NIL
HORIZONTAL

SLIDER
1145
392
1285
425
Observability
Observability
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
1145
425
1285
458
Trialability
Trialability
0
1
0.4
0.1
1
NIL
HORIZONTAL

SLIDER
1145
456
1285
489
Compatibility
Compatibility
0
1
0.6
0.1
1
NIL
HORIZONTAL

SLIDER
980
360
1120
393
Complexity
Complexity
-1
0
-0.3
0.1
1
NIL
HORIZONTAL

SLIDER
980
395
1120
428
Perceived_Risk
Perceived_Risk
-1
0
-0.7
0.1
1
NIL
HORIZONTAL

TEXTBOX
985
335
1135
353
Attributes of Biocom
14
0.0
1

SLIDER
745
290
920
323
Neighbor-Effect
Neighbor-Effect
0
100
16.0
1
1
%
HORIZONTAL

MONITOR
980
440
1120
485
Probability of Diffusion
difprob
17
1
11

PLOT
525
495
780
678
Überprüfung der Marktanteile
Zeit
Marktanteil
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"Biosps" 1.0 0 -10899396 true "" "plot sum [mshare] of biosps"
"Fossps" 1.0 0 -13345367 true "" "plot sum [mshare] of fossps"
"Biocustms" 1.0 0 -14333415 true "" "plot sum [custmshare] of biocustms"
"Custms" 1.0 0 -15390905 true "" "plot sum [custmshare] of custms"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
