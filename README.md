# BerlinCharge

iOS-Prototyp zur intelligenten Routenplanung mit AC- und DC-Ladestopps in Berlin.

BerlinCharge verbindet eine interaktive Ladestationskarte mit Fahrzeugprofilen und einer integrierten Routenplanung. Nutzer können direkt zu einer Ladestation navigieren oder eine Zieladresse eingeben und optional einen AC- oder DC-Ladestopp entlang der Route einplanen.

Die Anwendung entstand im Rahmen einer Bachelorarbeit im Studiengang Elektromobilität an der Berliner Hochschule für Technik.

## Projektziel

Ziel des Projekts ist es, die Suche nach einer geeigneten Ladestation und die anschließende Routenplanung in einer Anwendung zusammenzuführen.

Als konzeptionelle Grundlage dient die Vattenfall InCharge-App. BerlinCharge setzt den Schwerpunkt auf eine integrierte Routenanzeige und die Auswahl geeigneter Ladezwischenstopps im Berliner Stadtgebiet.

Das Projekt ist ein akademischer Prototyp und keine offizielle Vattenfall-Anwendung.

## Funktionen

### Ladestationskarte

- Darstellung der im Datensatz enthaltenen Berliner Ladestationen.
- Farblich unterschiedliche Marker für AC- und DC-Ladestationen.
- Anzeige des aktuellen Standorts nach erteilter Standortfreigabe.
- Detailansicht mit Stationsdaten wie Adresse, Ladeleistung und Stromart.
- Darstellung der Berliner Gebietsgrenzen anhand von GeoJSON-Daten.
- Verschieben, Drehen und Zoomen der Karte.

### Routenplanung

- Direkte Route vom aktuellen Standort zu einer Ladestation.
- Adresssuche und Routenberechnung zu einem ausgewählten Ziel.
- Optionale Routenplanung mit einem AC- oder DC-Ladezwischenstopp.
- Auswahl einer geeigneten Station anhand der berechneten Gesamtstrecke.
- Anzeige der Route als Polylinie auf der Karte.
- Anzeige von Fahrtstrecke und geschätzter Fahrzeit.
- Entfernen der angezeigten Route.

### Fahrzeugprofile

- Auswahl aus fünf hinterlegten Elektrofahrzeugprofilen.
- Detailansichten mit technischen Fahrzeugdaten.
- Nutzung des ausgewählten Profils für eine modellbasierte Prognose.
- Anzeige des prognostizierten Ladezustands und der Restreichweite nach der Fahrt.

### Stationsübersicht

- Listenansicht der hinterlegten Ladestationen.
- Suchfunktion zur Eingrenzung der Stationen.
- Detailansicht für einzelne Stationen.

## Technologien

| Technologie | Verwendung |
| --- | --- |
| Swift | Implementierung der Anwendungslogik |
| SwiftUI | Benutzeroberfläche und Zustandsverwaltung |
| MapKit | Karte, Adresssuche und Routenberechnung |
| CoreLocation | Ermittlung des Nutzerstandorts |
| Foundation | Datenverarbeitung und JSON-Dekodierung |
| Combine | Bestandteil der beschriebenen Architektur |
| JSON | Speicherung der Fahrzeug- und Stationsdaten |
| GeoJSON | Geografische Grenzen des Berliner Stadtgebiets |
| SF Symbols | Symbole der Benutzeroberfläche |
| Xcode | Entwicklungsumgebung |

## Aufbau der Anwendung

Die Anwendung ist in drei Hauptbereiche gegliedert:

| Komponente | Aufgabe |
| --- | --- |
| `InchargeView` | Verbindet die Hauptansichten über einen `TabView` |
| `HomeView` | Zeigt Fahrzeugprofile und verwaltet die Fahrzeugauswahl |
| `MapView` | Stellt Karte, Stationsmarker und Routen dar |
| `StationView` | Zeigt die durchsuchbare Stationsliste |

Die Architektur orientiert sich am Model-View-ViewModel-Prinzip (MVVM). Datenmodelle, Datenzugriff, Standortinformationen und Benutzeroberfläche sind in unterschiedliche Komponenten gegliedert.

Spezialisierte Loader lesen die lokalen Datensätze ein:

- `CarLoader` lädt Fahrzeugdaten aus `cars.json`.
- Stationsdaten werden aus einer lokalen JSON-Datei geladen.
- `GeoLoader` verarbeitet die geografischen Daten mithilfe von `MKGeoJSONDecoder`.

Die Fahrzeugauswahl wird in der zentralen Ansicht über `@State` gehalten und über `@Binding` an die betreffenden Ansichten weitergegeben.

## Funktionsweise der Routenplanung

### Direkte Route

1. Der aktuelle Standort wird ermittelt.
2. Als Ziel wird eine Ladestation oder ein Suchergebnis ausgewählt.
3. Über `MKDirections` wird eine Route für den Autoverkehr angefragt.
4. Die zurückgegebene Route wird auf der Karte dargestellt.

### Route mit Ladestopp

1. Zunächst wird die direkte Route zum gewünschten Ziel berechnet.
2. Die Stationen werden nach der gewählten Stromart AC oder DC gefiltert.
3. Berücksichtigt werden Stationen mit höchstens 2 km geometrischem Abstand zur ursprünglichen Routenpolylinie.
4. Für geeignete Kandidaten werden zwei Teilrouten berechnet:
   - aktueller Standort → Ladestation
   - Ladestation → Ziel
5. Die Kandidaten werden anhand der Summe ihrer Teilstrecken bewertet.
6. Die Station mit der geringsten berechneten Gesamtstrecke wird ausgewählt.
7. Die beiden Teilrouten werden zu einer gemeinsamen Polylinie zusammengefügt.

Der Abstand einer Station zur Route wird über den kleinsten Abstand zu den einzelnen Liniensegmenten der Routenpolylinie bestimmt.

Die Auswahl minimiert die Gesamtstrecke innerhalb der betrachteten Stationskandidaten. Sie ist keine globale Optimierung aller denkbaren Routen und Ladeoptionen.

## Datengrundlage

### Ladestationen

Die Stationsdaten basieren auf einem für die Bachelorarbeit aufbereiteten Export aus dem MyIncharge-Portal.

Für den Demonstrationsdatensatz wurden:

- nicht öffentlich zugängliche Standorte entfernt,
- als nicht verfügbar gekennzeichnete Stationen ausgeschlossen,
- mehrere Ladepunkte eines Standorts reduziert,
- bei Standorten mit AC- und DC-Lademöglichkeiten jeweils repräsentative Ladepunkte übernommen.

Die Arbeit beschreibt einen Datensatz mit über 80 gültigen Standorten in Berlin.

Die Stationsdaten werden lokal eingebunden und stellen eine Momentaufnahme dar. Sie werden nicht automatisch mit einem Betreiber-Backend synchronisiert.

### Fahrzeuge

Die Fahrzeugprofile basieren auf technischen Angaben der jeweiligen Hersteller. Sie enthalten unter anderem Informationen zu Batteriekapazität, Verbrauch, Reichweite und Motorleistung.

### Geografische Daten

Eine GeoJSON-Datei mit den Grenzen der Berliner Ortsteile dient zur geografischen Hervorhebung des Projektgebiets.

## Voraussetzungen

Zum Öffnen und Ausführen des Projekts werden benötigt:

- ein Mac mit einer zum Projekt passenden Xcode-Version,
- ein iOS-Simulator oder ein kompatibles iPhone,
- die im Projekt verwendeten JSON-, GeoJSON- und Bildressourcen,
- eine Standortfreigabe für standortbasierte Funktionen,
- eine Internetverbindung für die verwendeten Karten-, Such- und Routingdienste.

Die konkret erforderlichen Xcode-, Swift- und iOS-Versionen sind anhand der Projekteinstellungen zu ergänzen.

## Projekt starten

1. Repository herunterladen oder klonen.
2. Das enthaltene Xcode-Projekt öffnen.
3. Prüfen, ob die benötigten Daten und Assets dem App-Target zugeordnet sind.
4. Einen geeigneten Simulator oder ein angeschlossenes iPhone als Zielgerät auswählen.
5. Bei Ausführung auf einem iPhone die Signing-Einstellungen anpassen.
6. Die App in Xcode bauen und starten.
7. Beim ersten Zugriff auf die Standortfunktionen die Standortfreigabe erteilen.

Hinweis: Die Einrichtungsschritte müssen mit dem tatsächlichen Repository abgeglichen werden.

## Verwendung

1. Im Tab `Home` ein Fahrzeugprofil öffnen und auswählen.
2. Zum Tab `Map` wechseln.
3. Eine Ladestation auf der Karte auswählen oder nach einer Zieladresse suchen.
4. Eine Routenoption auswählen:
   - direkt zum Ziel,
   - mit AC-Ladestopp,
   - mit DC-Ladestopp.
5. Route, Fahrtzeit und Entfernung auf der Karte ansehen.
6. Bei ausgewähltem Fahrzeugprofil zusätzlich die prognostizierte Restreichweite und den Ladezustand prüfen.

Im Tab `Stations` lassen sich die hinterlegten Ladestationen unabhängig von der Kartenansicht durchsuchen.

## Einschränkungen

- Der Stationsdatensatz ist auf die im Projekt erfassten Berliner Standorte begrenzt.
- Die angezeigten Stationsdaten sind keine Echtzeitdaten.
- Eine angezeigte Verfügbarkeit garantiert keinen freien Ladepunkt.
- Im aufbereiteten Demonstrationsdatensatz wurden auch ursprünglich als `Charging` markierte Stationen als verfügbar dargestellt.
- Die Reichweiten- und Ladezustandsanzeige basiert auf hinterlegten Fahrzeugprofilen, nicht auf ausgelesenen Fahrzeugdaten.
- Die Stationsauswahl bewertet die Fahrstrecke; sie ist keine vollständige Optimierung aus Fahrzeit, Wartezeit, Ladezeit und Ladekosten.
- Routenanzeige und Routenplanung sind der Schwerpunkt des Prototyps. Eine vollständige Turn-by-Turn-Navigationslösung wird hier nicht zugesichert.
- Eine produktive Freischaltung oder Abrechnung von Ladevorgängen gehört nicht zum beschriebenen Projektumfang.

## Validierung

Die Bachelorarbeit dokumentiert die Überprüfung zentraler Anwendungsfälle anhand der Demo-App.

Dazu gehören:

- Fahrzeugauswahl und Anzeige der Fahrzeugdetails,
- Abfrage der Standortberechtigung,
- Darstellung von Stationsmarkern und Stationsdetails,
- Suche nach Zieladressen,
- direkte Routenberechnung,
- Routenberechnung mit AC- und DC-Ladestopp,
- Anzeige von Fahrtzeit, Entfernung und fahrzeugbezogenen Prognosen,
- Suche und Detailansichten in der Stationsliste.

Die Validierung beschreibt funktionale Tests des Prototyps. Angaben zu automatisierten Tests und deren Ausführung sind anhand des tatsächlichen Codeprojekts zu ergänzen.

## Mögliche Erweiterungen

- Anbindung einer API für aktuelle Stations- und Verfügbarkeitsdaten.
- Anzeige aktueller Ladepreise.
- Berücksichtigung von Störungen und Defekten.
- Bewertung der Zuverlässigkeit von Ladestationen.
- Erweiterung des Stationsgebiets auf ganz Deutschland.
- Anbindung realer Fahrzeug- und Batteriedaten.
- Weiterentwicklung der Ladeplanung unter Berücksichtigung zusätzlicher Einflussgrößen.

## Wissenschaftlicher Kontext

Titel der Bachelorarbeit:
„Entwicklung der smarten IOS-App BerlinCharge zur intelligenten Ladesäulen-Navigation“

Autor:
Tobias Gustav Hendrik Daiger

Hochschule:
Berliner Hochschule für Technik

Studiengang:
Elektromobilität, Bachelor of Engineering

## Lizenz und Drittinhalte

Die Lizenzierung des Quellcodes ist vor einer Veröffentlichung festzulegen und in einer `LICENSE`-Datei zu dokumentieren.

Für Stationsdaten, Fahrzeugbilder, geografische Daten und weitere Drittinhalte sind die jeweiligen Nutzungs- und Veröffentlichungsrechte gesondert zu prüfen. Eine Lizenz für den Quellcode umfasst diese Inhalte nicht automatisch.
