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

- [x] Einen 40-Spalten-Spielbereich mit Himmel, Bodenmuster und
  Rohr-Testspalten rendern.
- [x] TED-Horizontalfeinscroll fuer alle acht Ein-Pixel-Offsets isoliert
  implementieren und Richtung/Maskierung mit einem sichtbaren Marker pruefen.
- [x] Beim Offset-Ueberlauf genau eine vorbereitete Spalte am rechten Rand
  nachfuellen; keine Vollbild-Redraws im Frame.
- [x] Boden- und Rohrmuster an die gleiche logische Weltkoordinate binden.
- [x] Einen Messrahmen oder Debugzaehler einbauen, um fehlende/doppelte
  Nachfuellvorgaenge aufzudecken.

**Abnahme (offen):** Ein Rohr und das Bodenmuster bewegen sich mindestens 30
Sekunden ohne Acht-Pixel-Sprung oder Spaltenluecke durch den sichtbaren
Bereich.

## Meilenstein 2 -- Vogel mit Pixelbewegung

- [ ] Vogelmasken fuer mindestens drei Fluegelstellungen als 16 x 16-Bitdaten
  in den Zeichensatz-/Assetbereich aufnehmen.
- [ ] Dynamische Vogelglyphen und die erforderlichen Bildschirmzellen
  reservieren.
- [ ] 8.8-Fixpunkt-Y-Position, Geschwindigkeit, Schwerkraft, Flap-Impuls und
  Geschwindigkeitsgrenzen implementieren.
- [ ] Maskenzeilen mit den unteren drei Y-Bits in die dynamischen Glyphen
  verschieben; Ueberlauf in die dritte Zeichenzeile korrekt behandeln.
- [ ] Fluegelphase und Fallpose aus Flugzustand/Geschwindigkeit waehlen.
- [ ] Frueheres Vogelbild loeschen, neues Bild setzen und Kanten an oberen
  sowie unteren Spielfeldgrenzen pruefen.

**Abnahme:** Der Vogel folgt jeder Eingabe ohne merkliche Latenz, steigt und
faellt in Ein-Pixel-Schritten und bleibt bei allen acht Subpixel-Offsets
vollstaendig dargestellt.

## Meilenstein 3 -- Spielregeln

- [ ] Deterministischen Hindernis-Ringpuffer mit Startwert fuer den Zufall
  implementieren.
- [ ] Lueckenhoehe, Rohrabstand und minimale Sicherheitsmargen als Konstanten
  definieren.
- [ ] Neue Rohre nur beim Nachfuellen der rechten Weltspalte einplanen und
  daraus die sichtbaren Rohrzeichen erzeugen.
- [ ] Pixelgenaue Rechteckkollision zwischen Vogelbox, Rohrkoerpern, Decke
  und Boden implementieren.
- [ ] Punkte beim einmaligen Passieren eines Rohrs vergeben; HUD ohne
  Full-Screen-Redraw aktualisieren.
- [ ] Start-, Spiel-, Kollisions- und Game-over-Zustaende implementieren,
  inklusive explizitem Neustart per Eingabe.

**Abnahme:** Treffende und nicht treffende Randfaelle an Rohrkante, Boden und
Decke verhalten sich reproduzierbar; pro passiertem Rohr wird genau ein Punkt
vergeben.

## Meilenstein 4 -- Feinschliff und Stabilitaet

- [ ] Farben, Rohrkappen, Bodenmuster und Vogelposen fuer klare Lesbarkeit
  abstimmen.
- [ ] Schwierigkeit langsam an Punktzahl koppeln, ohne unmoegliche
  Rohrfolgen zu erzeugen.
- [ ] Frame-Budget mit sichtbarem Debugmarker messen und die teuersten
  Routinen optimieren, falls ein Frame die Rastergrenze ueberschreitet.
- [ ] Mindestens 5 Minuten Autoplay/Manuelltest in VICE ohne Grafikreste,
  Speicherueberlauf oder Frame-Aussetzer ausfuehren.
- [ ] Kaltstart, Neustart, lange Punktzahl und wiederholte Kollisionen
  pruefen.
- [ ] Build-/Startanleitung im `README.md` ergaenzen und die finale PRG
  erzeugen.

**Abnahme:** Der Release-Build laeuft auf der PAL-C16-Konfiguration aus VICE
fuenf Minuten stabil und erfuellt alle Akzeptanzkriterien.

## Technische Risiken und Entscheidungen

| Risiko | Gegenmassnahme |
| --- | --- |
| TED-Feinscrollregister oder sichtbare Randraender sind anders als erwartet | Zuerst isolierter Meilenstein-1-Test mit sichtbaren Offsets; Register bleiben in `video.asm` gekapselt. |
| Dynamische Vogelglyphen zerstoeren benachbarte Grafik | Separaten, festen Zeichensatzbereich reservieren; nur dessen Bytes im Frame beschreiben. |
| 16-KiB-RAM reicht nicht fuer Komfortpuffer | Keine Vollbild-Doppelbuffer und keine Tilemap; Ringpuffer plus generierte Randspalte einsetzen. |
| Framebudget wird von Glyphen-Kopien ueberschritten | Nur geaenderte Vogelpose/Position neu zusammensetzen, Quellmasken kompakt halten und mit Rastermarker messen. |
| Unfaire Kollisionen durch Zeichenraster | Ausschliesslich Fixpunkt-/Pixelboxen fuer die Spielregel nutzen, nicht Screenzeichen. |

## Reihenfolge

Meilenstein 0 und 1 muessen vor der Spielmechanik abgeschlossen sein. Meilenstein
2 kann parallel zur grafischen Ausgestaltung, aber nicht vor der verifizierten
Memory-Map beginnen. Erst nach Meilenstein 3 werden Farben, Schwierigkeit und
optionale Effekte optimiert.
