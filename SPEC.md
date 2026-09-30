# C16 Flappy Bird -- technische Spezifikation

## Ziel

Ein eigenstaendiges Flappy-Bird-Spiel fuer einen serienmaessigen Commodore 16
mit 16 KiB RAM. Es wird mit ACME gebaut und in VICE (`xplus4`) als PRG
ausgefuehrt. Der Schwerpunkt liegt auf einer sofort reagierenden Steuerung,
pixelweichem horizontalem Scrolling und einer kleinen, ausdrucksstarken
Vogelanimation.

Der erste spielbare Build ist PAL-orientiert (50 Hz). NTSC-Unterstuetzung ist
kein Ziel des ersten Meilensteins.

## Spielerlebnis

- Eine Taste (`SPACE` oder `FIRE`) laesst den Vogel mit einem definierten
  Impuls aufsteigen; ohne Eingabe wirkt konstante Schwerkraft.
- Rohre laufen von rechts nach links. Die Luecke ist sicher erreichbar und
  ihre Position sowie der Abstand zwischen Rohren werden mit der Punktzahl
  schrittweise anspruchsvoller.
- Eine Beruehrung eines Rohrs, des Bodens oder der Decke beendet den Lauf.
  Der Bildschirm bleibt kurz stehen, zeigt Punktzahl und Bestwert und startet
  erst nach einer expliziten Eingabe neu.
- Der Vogel verwendet alle Animationsbilder aus der gelieferten GIF;
  die Fluegelbewegung laeuft auch beim Fallen weiter.

## Zielplattform und Werkzeugkette

| Bereich | Festlegung |
| --- | --- |
| Rechner | Commodore 16, 16 KiB RAM, PAL |
| CPU/Video | 8501 und TED |
| Assembler | ACME 0.97, Syntax in `.asm`-Quelldateien |
| Emulator | VICE `xplus4` mit PAL-C16-Konfiguration |
| Auslieferung | Ladefaehige `.prg`, optional ein `.d64` erst spaeter |
| Eingabe | Tastatur zuerst; Joystick-Port-Unterstuetzung nur, wenn sie ohne ROM-/RAM-Konflikte getestet ist |

Der Build darf keine KERNAL-Aufrufe innerhalb der Frame-Schleife ausfuehren.
Initialisierung, Laden und Debug-Ausgaben duerfen die KERNAL-Routinen nutzen.

## Grafik- und Bewegungsdesign

### Bildschirm

Die Spielansicht verwendet den TED-Textmodus mit einem eigenen Zeichensatz.
Die Matrix ist 40 x 25 Zeichen zu 8 x 8 Pixeln. Der TED zeigt 38 Spalten
(`$FF07` Bit 3 geloescht), damit der Rand die angeschnittene Scroll-Zelle
verdeckt. Spalten 0 und 39 bleiben Guard-Spalten. Ein fester HUD-Streifen
belegt die oberste Zeile; Spielfeld, Himmel und Boden belegen die restlichen
24 Reihen. Die Rohre bestehen aus wiederverwendbaren Kappen-, Koerper- und
Randzeichen. Das spart RAM und erlaubt unterschiedliche Hoehen allein durch
Umfuellen der Screen-Map.

Die genaue Lage von Screen-RAM, Color-RAM und Zeichensatz wird als symbolische
Memory-Map in `src/memory.inc` definiert. Vor der Implementierung wird sie
gegen die aktive TED-Speicherbank und die von ACME erzeugte PRG-Adresse
geprueft; keinerlei magische Adressen in der Spiellogik.

### Pixelweiches horizontales Scrolling

TED-Hardware-Feinscroll verschiebt die Zeichenanzeige in acht
Ein-Pixel-Schritten. Pro PAL-Frame sinkt der Offset um ein Pixel, von 7 nach
0. Die sichtbare Matrix wird dabei nicht an Ort und Stelle verschoben: diese
Kopie lief ueber das Textfenster hinaus, und die untere Bildhaelfte wurde
schon mit dem neuen Offset gezeichnet, waehrend die Zeilen noch halb auf der
alten Spalte standen.

Stattdessen gibt es zwei Textpuffer. Sichtbar starten Farbe `$0800` und
Screen `$0C00` (`$FF14` = `$0C`). Versteckt liegen Farbe `$1800` und Screen
`$1C00` (`$FF14` = `$18`). In den acht Frames bis zum Umbruch wandern die
variablen Spielfeldzeilen 1-21 (erst Zeichen, dann Farbe) in acht Stuecken
mit bis zu sechs Zeilen in den versteckten Puffer. Die letzte Stufe hat
sechs leere Eintraege und erzeugt stattdessen die neue rechte Spalte. HUD
und Boden bleiben gleich und werden einmal beim Start gespiegelt.
Im Frame vor dem Umbruch erhaelt Spalte 39 des versteckten Puffers die
naechste Weltspalte. Im unteren Rand (Raster `$F0`) schreibt der Umbruch nur
noch Scroll zurueck auf 7 und `$FF14` auf den fertigen Puffer. Acht Pixel
Matrix nach links und sieben Pixel Scroll nach rechts ergeben ein Pixel
nach links.

`$FF14` wird am Anfang einer Rasterzeile abgetastet. Ein Schreiben spaeter
in der Zeile bleibt haengen und verfaellt, sobald das Textfenster zu ist.
Der Vogel wird nur auf den Puffer gezeichnet, den der TED gerade zeigt, und
vor dem Kopieren geloescht, damit seine Glyphen nicht in die Rohrzeilen
rutschen. Bit 7 der Stueckliste waehlt Color-RAM. Der Test vergleicht das
Byte mit `$80`: das `inc` des Index zwischen Laden und Aufruf ueberschreibt
das Negative-Flag.

Die TED-Registerzugriffe bleiben in `src/video.asm`. Der Code endet vor
`$1800`, sonst ueberschreibt die erste Spiegelkopie das Programm. Eine
falsche Annahme zu TED-Registerbits darf nicht in die Spielmodule
durchsickern.

Die Standardgeschwindigkeit betraegt ein Pixel pro Frame. Damit ist die
Bewegung optisch kontinuierlich und die Spielsimulation bleibt einfach:
Weltpositionen werden in 8.8-Fixpunkt gespeichert, der sichtbare
Horizontalscroll wird daraus abgeleitet.

### Vogel und vertikale Pixelbewegung

Der Vogel ist ein 20 x 14 Pixel grosses Objekt und steht horizontal fest.
Seine physikalische Y-Position und Geschwindigkeit liegen in 8.8-Fixpunkt
vor. Fuer das Rendering enthaelt der Zeichensatz zwoelf dynamische Vogelzeichen,
vier Spalten mal drei Zeilen.

1. Die ganzzahlige Y-Position bestimmt die Bildschirmzeile.
2. Die unteren drei Bits bestimmen den vertikalen Pixelversatz.
3. Der Feinscroll schiebt jede Zelle mit. Damit der Vogel auf dem Schirm
   stehen bleibt, wird die Maske um `7 - Scroll` Pixel nach rechts in den
   Glyphen verschoben. Bei Scroll 7 faellt der Versatz auf 0 und die Maske
   belegt bis zu drei Spalten. Ab fuenf Pixeln Versatz kommt die vierte
   Spalte dazu. Vollstaendig leere Zellen werden nicht gezeichnet.
4. Aus dem 20 x 14-Frame wird so ein bis zu 32 x 24 Pixel grosser Block.
   Leere Bits zeigen die Hintergrundfarbe; eine Zelle hat nur eine
   Vordergrundfarbe.

Die Kollision beruecksichtigt nur nichtleere Vogelzeichen. Der Vogel bewegt
sich vertikal ohne Acht-Pixel-Spruenge und horizontal ohne den Sieben-Pixel-
Ruck des Feinscrolls. Die Animation uebernimmt alle Frames aus
`assets/flappy.gif` in Originalreihenfolge mit je fuenf PAL-Frames (100 ms),
auch beim Fallen. Das Kopieren bleibt auf den kleinen dynamischen
Zeichensatzbereich begrenzt und veraendert keine Rohr-Glyphen.

### Farben und Animation

Die erste Fassung nutzt ein kontrastreiches Himmel-/Rohr-/Boden-Schema mit
wenigen, bewusst gewaehlten TED-Farben. Zusatzeffekte duerfen das
Frame-Budget nicht gefaehrden:

- Bodenmuster scrollt mit derselben Weltgeschwindigkeit wie die Rohre.
- Der Vogel hat einen ein Pixel grossen dunklen Rand oder Schatten, wenn die
  gewaehlte Zeichen-/Farbkonfiguration dies zulaesst.
- Bei Kollision folgt ein kurzer Stillstand plus maximal acht Frames
  Flatter-/Fallanimation; kein teurer Full-Screen-Effekt im ersten Release.

## Simulation und Kollision

Die Simulation wird genau einmal je Video-Frame aktualisiert. Eingaben werden
vor der Physik gelesen; der Flap-Impuls ueberschreibt die Abwaertsgeschwindigkeit
nur bei einer neuen Tastendruckflanke. Schwerkraft, Impuls und
Maximalgeschwindigkeiten sind als benannte Konstanten in `src/constants.inc`
hinterlegt.

Die Rohrwelt liegt in einem Ringpuffer mit 64 Spalten bei `$3100`.
Jedes Byte enthaelt die erste Lueckenzeile eines Rohrs oder null fuer Himmel.
Die Initialisierung erzeugt 40 Spalten; danach entsteht genau eine neue
Weltspalte beim Nachfuellen des versteckten rechten Rands. Zeichnen und
Pufferwechsel selbst veraendern den Zufallszustand nicht. Die Maskierung
mit 63 bleibt auch beim Ueberlauf des 8-Bit-Weltzaehlers korrekt.

Rohre sind drei Zeichen breit und beginnen im Abstand von 24 Zeichen
(192 Pixeln). Die Luecke ist neun Zeichen (72 Pixel) hoch; ihre erste Zeile
liegt zwischen 4 und 10. Die erste Luecke beginnt wie bisher in Zeile 7.
Danach bestimmt ein nichtnulliger 8-Bit-LFSR mit Startwert `$5d` die Aenderung
um -2, -1, +1 oder +2 Zeilen, begrenzt auf den erlaubten Bereich. Der maximale
Hoehenwechsel betraegt damit 16 Pixel bei 168 Pixeln freiem Rohrabstand.
Ein Neustart setzt den Generator zurueck und wiederholt dieselbe Folge.
Punktwertung und steigende Schwierigkeit folgen separat.

Kollision prueft die sichtbaren Vogelpixel gegen die festen, am Zeichenraster
liegenden Rohrkanten, Decke und Boden. Dekorative Loecher in Rohrkappen und
Bodenmustern gehoeren zur festen Flaeche. Vollstaendig leere Vogelzeichen
werden weder als Treffer gewertet noch gezeichnet; ihre Bildschirmzeichen
und Farben bleiben erhalten. Dadurch ist direkter Kontakt ohne Grafikmischung
moeglich, obwohl der Vogel einen bis zu 32 x 24 Pixel grossen Zeichenblock hat.

Die Kandidatengrafik entsteht zuerst im Arbeits-RAM. Ist die Zielposition
mit neuer Pose und Scrollphase frei, wird sie direkt uebernommen. Nur bei
einem Treffer werden die Bewegungsachsen einzeln aufgeloest: Zuerst wird die
vertikale Bewegung bei aktueller Scrollposition geprueft. Trifft die
Zielposition ein Hindernis, wird sie pixelweise entgegen der Bewegungsrichtung
bis zum letzten freien Pixel korrigiert. Die maximale Bewegung bleibt unter
acht Pixeln, sodass ein acht Pixel dickes Hindernis nicht uebersprungen wird.
Erst danach wird der naechste horizontale Ein-Pixel-Schritt geprueft. Beim
Scrollumbruch werden dafuer die aktuellen Bildschirmspalten um eins versetzt
gelesen. Ein blockierter Schritt setzt Game-over und stoppt den Scroll.

Die korrigierte Kontaktposition wird noch gezeichnet und dann eingefroren.
Eine neue Leertastenflanke startet die Runde neu. Wuerde ein Wechsel der
Fluegelpose an der aktuellen Position ein Hindernis schneiden, bleibt die
bisherige Pose erhalten. Die transparente Oberkante der Maske darf ueber
Zeile null liegen; erst ein sichtbares Pixel ausserhalb des Feldes kollidiert.

Horizontal verschobene Maskenzeilen werden nach Pose und Scrollphase
zwischengespeichert, damit mehrere vertikale Proben keine erneuten Bitshifts
brauchen. Der folgende Feinscrollschritt verschiebt den Cache nur um ein Bit,
anstatt alle horizontalen Verschiebungen erneut auszufuehren. Die gesamte Berechnung erfolgt vor dem Warten auf den unteren Rand;
erst dort werden Bildschirm, Zeichensatz und Scrollregister aktualisiert.

## Laufzeitarchitektur

```text
reset/init
  -> video + eigener Zeichensatz + Eingabe initialisieren
  -> Spielfeld in beide Textpuffer spiegeln
  -> Titelbild
  -> neuer Lauf
  -> frame loop
       input
       physics (Kandidatenposition)
       collision -> bei Treffer bis zum letzten freien Pixel korrigieren
       frame-sync auf der aufsteigenden Flanke von Raster $F0
       bisheriges Vogelbild loeschen
       obstacle generation / scoring               (noch offen)
       $FF07 schreiben, beim Umbruch auch $FF14
       ein Teilstueck in den versteckten Puffer kopieren
       Vogel auf den sichtbaren Puffer zeichnen
  -> game-over
  -> Titelbild oder neuer Lauf
```

`frame-sync` wartet auf genau ein PAL-Frame-Ereignis am unteren Rand. Fuer den
Himmel setzt ein TED-Raster-IRQ an jeder Textzeilengrenze die naechste
Helligkeitsstufe des blauen Verlaufs. Der obere Rahmen bleibt auf Luminanz 0;
ab der ersten Bildschirmzeile steigt der Seitenrahmen gleichmaessig von
Luminanz 1 bis 7. Der untere Rahmen verwendet TED-Farbe 9 mit Luminanz 5. Der
Handler aktualisiert die Farben und den naechsten Rastervergleich;
Spielberechnung und Bildschirmaufbau bleiben ausserhalb des IRQ.

Vorgesehene Quelldateien:

| Datei | Verantwortung |
| --- | --- |
| `src/main.asm` | Einstieg, Zustandsmaschine, Build-Includes |
| `src/hardware.inc` | TED-, Eingabe- und ROM-Konstanten |
| `src/memory.inc` | symbolische Speicherbelegung und Puffer |
| `src/constants.inc` | Physik-, Spiel- und Kollisionskonstanten |
| `src/video.asm` | TED-Setup, Frame-Sync, Feinscroll, Screen-Spalten |
| `src/charset.asm` | statische Glyphen und dynamischer Vogelbereich |
| `src/input.asm` | Flankenerkennung fuer Tastatur/Joystick |
| `src/bird.asm` | Physik, Maskenkomposition und Vogelzeichnung |
| `src/collision.asm` | Pixelkontakt, sichere Pose und Bewegung |
| `src/render.asm` | Rohrspalten und Spielfeld |
| `src/obstacles.asm` | Reproduzierbare Rohrfolge und Spaltenringpuffer |

## RAM- und Performance-Budget

Die Implementierung muss auf 16 KiB funktionieren; eine 64-KiB-Konfiguration
darf nie vorausgesetzt werden. Die konkrete Byteaufstellung steht in
`src/memory.inc`. Sie umfasst Code, Daten, beide Textpuffer, Zeichensatz und
Stack. Der zweite Puffer belegt `$1800-$1FE7`. Ab `$3C00` bleiben 1 KiB
Reserve. Ein Bitmap-Doppelpuffer ist damit ausgeschlossen.

Die Frame-Schleife hat ein Budget von einem PAL-Frame. Die gewoehnliche
Ausfuehrung aktualisiert nur Eingabe, Physik, einen Scrollwert, gegebenenfalls
eine Randspalte und maximal zwoelf dynamische Vogelglyphen. Full-Screen-Loops,
ROM-Aufrufe, Diskettenzugriffe und zeitvariable Wartezeiten sind innerhalb der
Schleife verboten. Ein optionaler Rastermarker im Debug-Build macht die
Ausfuehrungszeit sichtbar.

## Qualitaetssicherung

1. Der ACME-Build muss ohne Warnungen ein PRG produzieren und die
   Speicheraufstellung auf Bereichsueberschneidungen pruefen.
2. In VICE wird der Build in PAL-C16/16-KiB-Konfiguration gestartet.
   Die Tests decken Kaltstart, Neustart, alle acht horizontalen und vertikalen
   Subpixel-Offsets, Rohrkanten, Boden/Decke, Punktvergabe und mindestens
   fuenf Minuten Dauerlauf ab.
3. Ein deterministischer Testmodus akzeptiert einen festen
   Hindernis-Zufallsstartwert. Damit lassen sich Kollisionen und schwierige
   Rohrfolgen reproduzieren, ohne die Release-Zufallsfolge einzuschraenken.
4. Debugcode und Rastermarker werden fuer den Release deaktiviert, ohne
   Spielcode oder Memory-Map umzubauen.

## Nicht im ersten Release

- Musik oder digitalisierte Effekte
- Mehrspielermodus
- Persistenter Bestwert auf Diskette/Kassette
- NTSC-spezifisches Timing
- Bitmap-Grafik oder ein Verschieben der ganzen Matrix im sichtbaren Frame.
  Der zweite Textpuffer ist der vorgesehene Scrollweg und gehoert dazu.
