# C16 Flappy Bird -- Umsetzungsplan

## Akzeptanzkriterien

Der erste Release ist fertig, wenn er in VICE als PAL-C16 mit 16 KiB startet,
eine Steuerung hat, Rohre mit Ein-Pixel-Feinscroll bewegt, den Vogel mindestens
auf Pixelzeilen vertikal bewegt, Kollision/Punkte/Game-Over korrekt behandelt
und mindestens fuenf Minuten ohne sichtbares Frame-Stottern laeuft.

## Meilenstein 0 -- Technische Basis

- [x] Projektstruktur `src/`, `build/`, `assets/` und `tests/` anlegen; alle
  generierten Dateien unter `build/` halten.
- [x] Reproduzierbaren ACME-Build mit Debug-Symbolen erstellen, der
  `build/flappy.prg` erzeugt.
- [x] VICE-Startkommando fuer PAL-C16/16-KiB dokumentieren und ausfuehrbar
  machen.
- [x] `hardware.inc` aus verifizierten TED- und C16-Registeradressen
  erstellen; Scrollregister, Bildschirmmodus und Rasterstatus separat
  kennzeichnen.
- [x] Konkrete Memory-Map aufzeichnen: PRG/Code, Screen, Color-RAM, eigener
  Zeichensatz, dynamische Glyphen, Spielstatus, Ringpuffer und Stack.
- [x] Startstub und Initialisierung schreiben: Interrupt-Status, TED-Video,
  Screen- und Farbspeicher sowie eigener Zeichensatz.
- [x] Test-PRG erstellen, das Rahmenfarbe oder eine Bildschirmzelle pro Frame
  aendert, um Build, Laden und 50-Hz-Frame-Sync zu bestaetigen.

**Abnahme:** Das Test-PRG startet aus VICE, zeigt den eigenen Zeichensatz und
zaehlt exakt sichtbar mit PAL-Frame-Tempo.

## Meilenstein 1 -- Feinscroll-Prototyp

- [x] Einen Spielbereich mit Himmel und Rohren ueber Zeilen 0-23 rendern;
  Zeile 24 bleibt fuer Boden und HUD fest.
  Sichtbar sind 38 Spalten; die Matrix bleibt 40 Byte breit, Spalten 0 und
  39 liegen unter dem Rand.
- [x] Einen konfigurierbaren senkrechten Helligkeitsverlauf, abgestuften Seitenrahmen und festen
  unteren Rahmen mit Raster-IRQ setzen.
- [x] TED-Horizontalfeinscroll fuer alle acht Ein-Pixel-Offsets isoliert
  implementieren und Richtung/Maskierung mit einem sichtbaren Marker pruefen.
- [x] Die naechste Spalte im versteckten Textpuffer vorbereiten und `$FF14`
  erst im unteren Rand kippen. Acht Teilstuecke pro Umbruch, keine
  Vollbild-Redraws im Frame.
- [x] Rohre bis zur oberen Spielfeldkante ziehen; Zeilen 0-23 scrollen,
  Zeile 24 als feste Boden-/HUD-Zeile darstellen.
- [x] Obere Rasterfarbkante mit Rohranfang bei PAL-Zeile `$34` ausrichten;
  eigenen Handler vor dem ersten Zeichenfetch verwenden.
- [x] Einen Messrahmen oder Debugzaehler einbauen, um fehlende/doppelte
  Nachfuellvorgaenge aufzudecken.

**Abnahme:** Die Rohre bewegen sich mindestens 30 Sekunden
ohne Acht-Pixel-Sprung, ohne Riss in der unteren Bildhaelfte und ohne
Spaltenluecke durch den sichtbaren Bereich. In VICE bleibt die Rohrkante
ueber zwei Umbrueche bei einem Pixel pro Frame, oben und unten gleich.

## Meilenstein 2 -- Vogel mit Pixelbewegung

- [x] Vogelmasken aus `assets/flappy.gif` als 20 x 14-Bitbilder
  in den Zeichensatz-/Assetbereich aufnehmen.
- [x] Dynamische Vogelglyphen und die erforderlichen Bildschirmzellen
  reservieren.
- [x] 8.8-Fixpunkt-Y-Position, Geschwindigkeit, Schwerkraft, Flap-Impuls und
  Geschwindigkeitsgrenzen implementieren.
- [x] Maskenzeilen mit den unteren drei Y-Bits in die dynamischen Glyphen
  verschieben; Ueberlauf in die dritte Zeichenzeile korrekt behandeln.
- [x] Sechs GIF-Frames in Originalreihenfolge mit je 100 ms abspielen,
  auch beim Fallen; keine zusaetzliche Fallpose.
- [x] Frueheres Vogelbild loeschen, neues Bild setzen und Kanten an oberen
  sowie unteren Spielfeldgrenzen pruefen.

**Abnahme:** Der Vogel folgt jeder Eingabe ohne merkliche Latenz, steigt und
faellt in Ein-Pixel-Schritten und bleibt bei allen acht Subpixel-Offsets
vollstaendig dargestellt.

## Meilenstein 3 -- Spielregeln

- [x] Deterministischen Hindernis-Ringpuffer mit Startwert fuer den Zufall
  implementieren.
- [x] Lueckenhoehe, Rohrabstand und minimale Sicherheitsmargen als Konstanten
  definieren.
- [x] Neue Rohre nur beim Nachfuellen der rechten Weltspalte einplanen und
  daraus die sichtbaren Rohrzeichen erzeugen.
- [x] Kollision vor dem Zeichnen gegen Rohre und die Spielfeldkanten bei 0/192 Pixeln pruefen;
  nur sichtbare Vogelpixel beruecksichtigen, leere Vogelzeichen auslassen.
- [x] Bei Kollision bis zum letzten freien Pixel zuruecksetzen und einfrieren;
  Neustart durch erneuten Tastendruck.
- [x] Punkte beim einmaligen Passieren eines Rohrs vergeben; HUD ohne
  Full-Screen-Redraw aktualisieren.
- [ ] Start-, Spiel-, Kollisions- und Game-over-Zustaende implementieren,
  inklusive explizitem Neustart per Eingabe.

**Abnahme:** Treffende und nicht treffende Randfaelle an Rohrkante und den
Spielfeldgrenzen verhalten sich reproduzierbar; pro passiertem Rohr wird genau ein Punkt
vergeben.

## Meilenstein 4 -- Feinschliff und Stabilitaet

- [x] Dreifarbige Multicolor-Rohre nach `assets/pipe.png` mit acht Pixel
  hohen Abschlusskappen; Hires-Vogel und Rasterhimmel beibehalten.
- [ ] Farben und Vogelposen fuer klare Lesbarkeit
  abstimmen.
- [ ] Schwierigkeit langsam an Punktzahl koppeln, ohne unmoegliche
  Rohrfolgen zu erzeugen.
- [x] Frame-Budget per VICE-Registertrace messen und die teuersten
  Routinen optimieren, falls ein Frame die Rastergrenze ueberschreitet.
- [ ] Den aktuellen Stand erneut mindestens 5 Minuten in VICE ohne Grafikreste,
  Speicherueberlauf oder Frame-Aussetzer ausfuehren.
- [ ] Kaltstart, Neustart, lange Punktzahl und wiederholte Kollisionen
  pruefen.
- [x] Build-/Startanleitung im `README.md` ergaenzen und die finale PRG
  erzeugen.

**Abnahme:** Der Release-Build laeuft auf der PAL-C16-Konfiguration aus VICE
fuenf Minuten stabil und erfuellt alle Akzeptanzkriterien.

## Aktueller Pruefstand und offene Regressionen

- [x] 1.024 Pufferwechsel und 3.000 automatische Spielframes mit fester HUD-Zeile.
- [x] 119.808 Pixelkollisions- und 4.616 Render-/Restore-Faelle bestanden.
- [x] Untere Spielfeldkante bei 192 Pixeln fuer alle sechs getesteten
  Posen und alle acht Scrollphasen verifiziert. Die Bodenzeile ist Kollision.
- [x] IRQ-Register, Stack, Vektorwechsel, Neustart und 9-Bit-Rasterfolge geprueft.
- [x] 3.874 Farbzugriffe der Multicolor-Fassung mit buendiger Oberkante in VICE im erlaubten Zeitfenster.
- [x] Kollisionsorakel und Kadenztest auf alle sechs GIF-Frames erweitern;
  Kontakt-, Freeze- und Neustarttests bestehen.
- [ ] Neuen VICE-Rastertrace fuer aktuelle Farben, Abstaende und HUD-Timing aufzeichnen.
- [ ] Neue Rasterroutine auf echter PAL-C16-Hardware pruefen.
- [x] HUD: HIGH mit Sitzungsbestwert links, TEDDY BIRD mittig, SCORE rechts;
  vierstellige Zahlen mit fuehrenden Nullen (fuenf Stellen oberhalb 9999).
- [x] PRESS SPACE blinkt mittig bei Game-over; Bestwert ueberlebt Rundenneustart.
- [x] Toten Vogel mit TED_BIRD_DEAD_COLOR zeichnen; normale Farbe beim Neustart.
- [x] HUD-Ausgabe nach Scroll-/Vogel-Ausgabe verschieben, damit Punkteereignisse
  den zeitkritischen Pufferwechsel nicht verzoegern.
- [x] Bei Punkten nur die seitlichen Score-Felder mit direkten Pufferadressen
  aktualisieren; kein Loeschen/Neuzeichnen des mittleren Textes.

- [x] Konfiguration in constants.inc zentralisieren und veraltete Kommentare bereinigen.
- [x] Beim Blinken nur die Mitte zeichnen; Vogelfarbe einmal pro Zeichenvorgang waehlen.

- [x] Vogel-Ausgabe bei oberer Position per VICE-Trace messen und auf `$CC`
  vorziehen; 77 Ausgaben enden vor dem sichtbaren Bildbeginn.

## Technische Risiken und Entscheidungen

| Risiko | Gegenmassnahme |
| --- | --- |
| TED-Feinscrollregister oder sichtbare Randraender sind anders als erwartet | Zuerst isolierter Meilenstein-1-Test mit sichtbaren Offsets; Register bleiben in `video.asm` gekapselt. |
| Dynamische Vogelglyphen zerstoeren benachbarte Grafik | Separaten, festen Zeichensatzbereich reservieren; nur dessen Bytes im Frame beschreiben. |
| 16-KiB-RAM reicht nicht fuer Komfortpuffer | Der Text-Doppelpuffer ist der Scrollweg und endet vor `$2000`. Kein Bitmap-Doppelpuffer und keine Tilemap; Rohre bleiben Ringpuffer plus generierte Randspalte. |
| Framebudget wird von Glyphen-Kopien ueberschritten | Nur geaenderte Vogelpose/Position neu zusammensetzen, Quellmasken kompakt halten und mit Rastermarker messen. |
| Vogelzeichen ueberschreiben Umgebung | Kandidaten im Arbeits-RAM pruefen, bei Kontakt pixelweise zuruecksetzen und leere Vogelzeichen nicht zeichnen. |

## Reihenfolge

Meilenstein 0 und 1 muessen vor der Spielmechanik abgeschlossen sein. Meilenstein
2 kann parallel zur grafischen Ausgestaltung, aber nicht vor der verifizierten
Memory-Map beginnen. Erst nach Meilenstein 3 werden Farben, Schwierigkeit und
optionale Effekte optimiert.
