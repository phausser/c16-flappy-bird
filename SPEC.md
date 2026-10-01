# C16 Flappy Bird -- technische Spezifikation

## Ziel

Ein eigenstaendiges Flappy-Bird-Spiel fuer einen serienmaessigen Commodore 16
mit 16 KiB RAM. Es wird mit ACME gebaut und in VICE (`xplus4`) als PRG
ausgefuehrt. Der Schwerpunkt liegt auf einer sofort reagierenden Steuerung,
pixelweichem horizontalem Scrolling und einer kleinen, ausdrucksstarken
Vogelanimation.

Der erste spielbare Build ist PAL-orientiert (50 Hz). NTSC-Unterstuetzung ist
kein Ziel des ersten Meilensteins.

## Spielerlebnis (Zielbild)

- Eine Taste (`SPACE` oder `FIRE`) laesst den Vogel mit einem definierten
  Impuls aufsteigen; ohne Eingabe wirkt konstante Schwerkraft.
- Rohre laufen von rechts nach links. Die Luecke ist sicher erreichbar und
  ihre Position sowie der Abstand zwischen Rohren werden mit der Punktzahl
  schrittweise anspruchsvoller.
- Eine Beruehrung eines Rohrs oder der oberen/unteren Spielfeldkante beendet den Lauf.
  Der Bildschirm bleibt kurz stehen, zeigt Punktzahl und Bestwert und startet
  erst nach einer expliziten Eingabe neu.
- Der Vogel verwendet alle Animationsbilder aus der gelieferten GIF;
  die Fluegelbewegung laeuft auch beim Fallen weiter.

Aktuell umgesetzt sind SPACE-Steuerung, Scrollen, Rohrfolge, Pixelkollision,
Einfrieren, Neustart und ein Punkt pro geschafftem Rohr in der festen
Bodenzeile, Sitzungsbestwert und blinkender Neustarthinweis. FIRE, Titelbild
und steigende Schwierigkeit sind noch
offen; siehe `TODO.md`.

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
verdeckt. Spalten 0 und 39 bleiben Guard-Spalten. Die Zeilen 0-23 sind das Spielfeld:
Rohre reichen dort oben und unten bis an den Rand der Zeichenmatrix. Zeile 24 ist der feste Boden
und die Punkteanzeige. Sie scrollt nicht mit, weder im Feinscroll noch beim Spaltenschub.
Die Rohre bestehen aus drei wiederverwendbaren Multicolor-Zeichen
fuer linken Streifen, Mitte und rechten Streifen, vorerst ohne Abschluss. Das spart RAM und erlaubt unterschiedliche Hoehen allein durch
Umfuellen der Screen-Map.

Die genaue Lage von Screen-RAM, Color-RAM und Zeichensatz wird als symbolische
Memory-Map in `src/memory.inc` definiert. Vor der Implementierung wird sie
gegen die aktive TED-Speicherbank und die von ACME erzeugte PRG-Adresse
geprueft; keinerlei magische Adressen in der Spiellogik.

### Dreifarbige Rohre

`assets/pipe.png` ist die 24 x 24 Pixel grosse Referenz. Die oberen acht
Pixel bilden den Abschluss an beiden Seiten der Durchflugluecke; beim
oberen Rohr wird er vertikal gespiegelt. Die restlichen Zeilen enthalten
dieselben zwoelf Doppelpixel. Die drei Rohrglyphen 1-3 wiederholen
die Bytes `$DD`, `$7F` und `$BA` jeweils achtmal. Von links nach rechts lautet
die Farbfolge: Gruen, Gelb, Gruen, Gelb / Gelb, Gruen, Gruen, Gruen /
Dunkelgruen, Gruen, Dunkelgruen, Dunkelgruen. Oben und unten bleiben die
Rohrkoerper gerade; drei separate Kappenglyphen folgen den Ziffernglyphen.

`$FF07` Bit 4 aktiviert gemischten Multicolor-Text. Nur Rohrzellen tragen
Color-RAM-Bit 3 (`$5D`): Pixelpaar 01 nutzt `$FF16 = $77` (Gelb), 10 nutzt
`$FF17 = $25` (Dunkelgruen), 11 nutzt die Zellfarbe `$55` (Gruen).
Kein Rohrpixel nutzt 00, sodass der Rasterhimmel die Rohre nicht umfaerbt.
Vogelzellen behalten Attribut `$00` und damit Hires-Aufloesung. Der Renderer
bestimmt den Rohrstreifen aus den vorherigen Ringpuffer-Spalten; das
Lueckenformat und die volle 24-Pixel-Kollisionsbreite bleiben erhalten.

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
Spielfeldzeilen 0-23 (erst Zeichen, dann Farbe) in acht Stuecken
mit bis zu sieben Zeilen in den versteckten Puffer. Zeile 24 fehlt in dieser Liste.
Acht der 56 Plaetze bleiben leer; die neue rechte Spalte entsteht, wenn das achte Stueck fertig ist.
Im Frame vor dem Umbruch erhaelt Spalte 39 des versteckten Puffers die
naechste Weltspalte. Im unteren Rand (Raster `$FC`) schreibt der Umbruch nur
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

Video- und Scrollregister liegen in `src/video.asm`, Farb- und IRQ-Register
in `src/gradient.asm`, die Tastaturabfrage in `src/input.asm`. Der Code unter
dem BASIC-Stub endet vor `$1800`, sonst ueberschreibt die erste Spiegelkopie
das Programm. Die Punktanzeige liegt ab `$2000`, noch vor den Vogelmasken. Eine
falsche Annahme zu TED-Registerbits darf nicht in die Spielmodule
durchsickern.

Die Standardgeschwindigkeit betraegt ein Pixel pro Frame. Damit ist die
Bewegung optisch kontinuierlich und die Spielsimulation bleibt einfach:
Ein 8-Bit-Weltspaltenzaehler und ein Feinscrollwert von 7 bis 0 bestimmen
die horizontale Position; nur die Vogelphysik verwendet 8.8-Fixpunkt.

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

Die aktuelle Fassung nutzt einen konfigurierbaren Helligkeitsverlauf, gruene Rohre
und einen konfigurierbaren Vogel. Seine aktuelle Farbe kommt aus
TED_BIRD_COLOR in src/hardware.inc. Folgende optionale Effekte sind noch offen.
Das Himmel-/Rohr-Schema arbeitet mit
wenigen, bewusst gewaehlten TED-Farben. Zusatzeffekte duerfen das
Frame-Budget nicht gefaehrden:

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

Rohre sind drei Zeichen breit und beginnen im Abstand von 12 Zeichen
(96 Pixeln). Die Luecke ist neun Zeichen (72 Pixel) hoch; ihre erste Zeile
liegt zwischen 4 und 10. Die erste Luecke beginnt wie bisher in Zeile 7.
Danach bestimmt ein nichtnulliger 8-Bit-LFSR mit Startwert `$5d` die Aenderung
um -2, -1, +1 oder +2 Zeilen, begrenzt auf den erlaubten Bereich. Der maximale
Hoehenwechsel betraegt damit 16 Pixel bei 168 Pixeln freiem Lueckenbereich.
Ein Neustart setzt den Generator zurueck und wiederholt dieselbe Folge.
Jedes geschaffte Rohr gibt genau einen Punkt, geprueft in `swap_buffers` direkt
nach dem Weltspalten-Inkrement. Die gerade verlassene Spalte unter dem Vogel
ist `(WORLD_COLUMN + 11) & 63`. Steht dort eine Luecke und in der naechsten
Ringzelle Himmel, war das die rechte der drei Rohrspalten. Der Zaehler ist
16 Bit. Angezeigt werden bis zu fuenf Stellen ohne fuehrende Nullen, zentriert
in den sichtbaren Spalten 1-38 (`start = 1 + (38 - stellen) / 2`). Der Umbruch
schreibt die Zeile nur bei einer Aenderung neu, in beide Puffer, ohne das
Spielfeld zu verschieben. Ein Rohr, an dem der Lauf endet, gibt keinen Punkt,
weil der Kontakt den Scroll vor dem Umbruch stoppt. Neustart setzt auf 0.
Steigende Schwierigkeit folgt separat.

Kollision prueft die sichtbaren Vogelpixel gegen die festen, am Zeichenraster
liegenden Rohrkanten sowie die obere Spielfeldkante bei 0 und die Bodenzeile
ab Pixel 192. Alle drei Rohrstreifen sind vollstaendig solide. Vollstaendig leere Vogelzeichen
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
  -> neuer Lauf
  -> frame loop
       input
       physics (Kandidatenposition)
       collision -> bei Treffer bis zum letzten freien Pixel korrigieren
       frame-sync auf der aufsteigenden Flanke von Raster $FC
       bisheriges Vogelbild loeschen
       neue Rohrspalte bei Bedarf erzeugen
       $FF07 schreiben, beim Umbruch auch $FF14
       ein Teilstueck in den versteckten Puffer kopieren
       Vogel auf den sichtbaren Puffer zeichnen
       vorgemerkte Score-Felder direkt in beide Puffer schreiben; Titel unveraendert
  -> game-over
  -> neuer Lauf bei erneuter SPACE-Flanke
```

`frame-sync` wartet auf genau ein PAL-Frame-Ereignis am unteren Rand.
Sieben Rasterbaender teilen den aktiven Bildschirm mit konfigurierbarer Grundfarbe in die
Luminanzen 1 bis 7. Hintergrund und Seitenrahmen wechseln bei jedem Schritt
auf derselben Rasterzeile. Der obere Rahmen bleibt bis zum Bildschirmbeginn
auf Luminanz 0; am Beginn des unteren Rahmens wechseln Hintergrund und Rahmen
auf TED-Farbe 9 mit Luminanz 6. Spielberechnung und Bildschirmaufbau bleiben
ausserhalb des IRQ.

### Raster-IRQ und buendige Oberkante

Der eigene Hardware-IRQ nutzt `$FFFE/$FFFF`; auf dem 16-KiB-C16 liegen diese
Bytes gespiegelt bei `$3FFE/$3FFF`. ROM wird ueber `$FF3F` ausgeblendet.
A/X werden gesichert, Y bleibt unveraendert; Rueckkehr erfolgt mit `RTI`.
Es gibt keinen Ruecksprung in den KERNAL. `$FF09` wird am Eintritt quittiert,
Farbe, naechste IRQ-Adresse und kompletter 9-Bit-Vergleich werden im vorigen
IRQ vorbereitet. `$FF0A` aktiviert nur den Raster-IRQ samt Vergleichsbit 8.

Die Rastervergleichswerte stehen in `background_gradient_rasters`: erste
Zeile minus zwei, sechs Vielfache von `BACKGROUND_GRADIENT_DISTANCE`
(aktuell 28), Boden minus zwei und oberer Rand minus eins. Die Farben kommen
aus `background_gradient_colors`, auch fuer Oberkante und Boden. Die erste Grenze entspricht
PAL-Bildzeile `$34` und der ersten Rohrzeile. Der obere Rahmen behaelt bis
dorthin Luminanz 0. Ab `$C4`, der ersten Rasterzeile von Zeichenzeile 24,
tragen Hintergrund und Rahmen die Bodenfarbe. Dieselbe IRQ setzt `$FF07`
auf Scroll 0, nur fuer diese Zeile. Die Spielschleife schreibt den
Spiel-Scroll im unteren Rand (`$FC`) zurueck, auch wenn der Lauf steht.

Normale Baender starten den IRQ eine Zeile vorher und synchronisieren ueber
`$FF1E` auf die horizontale Austastluecke. Die erste Grenze benoetigt einen
eigenen Handler: IRQ auf TED-Zeile `$02`, Warten ueber deren rechten Rand,
dann Farbzugriffe nach dem Zeichenfetch in Zeile `$03`. So liegen beide
Schreibzugriffe vor dem sichtbaren Beginn von Zeile `$04`. Getrennte
horizontale Schwellwerte (`$B0` beim Eintritt, `$BC` nach dem Fetch)
verhindern, dass ein spaeter Lesezyklus eine ganze Zeile ueberspringt. Bei geaenderten Rasterabstaenden muessen Zeichenfetch-Paare und sichtbare
Zeitfenster erneut in VICE geprueft werden. Voraussetzung ist PAL mit
Vertikalscroll 3 und normaler TED-Taktumschaltung. Kein Warten auf `$FF1D`
im IRQ; die Spielschleife bleibt ausserhalb des Handlers.

Quelldateien:

| Datei | Verantwortung |
| --- | --- |
| `src/main.asm` | Einstieg, Zustandsmaschine, Build-Includes |
| `src/hardware.inc` | TED-, Eingabe- und ROM-Konstanten |
| `src/memory.inc` | symbolische Speicherbelegung und Puffer |
| `src/constants.inc` | Physik-, Spiel- und Kollisionskonstanten |
| `src/video.asm` | TED-Setup, Frame-Sync, Feinscroll, Screen-Spalten |
| `src/gradient.asm` | Rasterfarben, Hardware-IRQ und horizontale Synchronisierung |
| `src/bird_masks.inc` | importierte Vogelmasken fuer die dynamische Animation |
| `src/font.inc` | Zeichensatz: Ziffern, Buchstaben, Rohrglyphen; ein binaeres Byte pro Zeile |
| `src/input.asm` | Flankenerkennung fuer SPACE |
| `src/bird.asm` | Physik, Maskenkomposition und Vogelzeichnung |
| `src/collision.asm` | Pixelkontakt, sichere Pose und Bewegung |
| `src/render.asm` | Rohrspalten und Spielfeld |
| `src/score.asm` | Punkte und Sitzungsbestwert, HUD-Text, Blinken, beide Puffer schreiben |
| `src/obstacles.asm` | Reproduzierbare Rohrfolge und Spaltenringpuffer |

## RAM- und Performance-Budget

Die Implementierung muss auf 16 KiB funktionieren; eine 64-KiB-Konfiguration
darf nie vorausgesetzt werden. Die konkrete Byteaufstellung steht in
`src/memory.inc`. Sie umfasst Code, Daten, beide Textpuffer, Zeichensatz und
Stack. Der zweite Puffer belegt `$1800-$1FE7`. `$3C00-$3FFD` bleibt Reserve; `$3FFE/$3FFF` ist der Hardware-IRQ-Vektor. Ein Bitmap-Doppelpuffer ist damit ausgeschlossen.

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
   Die Release-Abnahme soll Kaltstart, Neustart, alle acht horizontalen und vertikalen
   Subpixel-Offsets, Rohrkanten, untere/obere Spielfeldkante, Punktvergabe und mindestens
   fuenf Minuten Dauerlauf abdecken.
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

## Aktueller Pruefstand

Build und Lint bestehen. Die CPU-Tests bestanden 1.024 Pufferwechsel,
3.000 automatische Spielframes, 119.808 Pixelkollisions- und 4.616
Render-/Restore-Faelle fuer alle sechs Posen. Kontakt, Freeze, Neustart,
Animationskadenz und IRQ-Zustand sind geprueft. HUD-Tests pruefen Ausrichtung,
Sitzungsbestwert, Blinken und das Verschieben der HUD-Ausgabe hinter den
zeitkritischen Pufferwechsel.

Die untere Zeile zeigt links HIGH mit Bestwert, mittig TEDDY BIRD und
rechts SCORE mit aktuellem Punktestand. Zahlen haben mindestens vier Stellen
mit fuehrenden Nullen; oberhalb 9999 bleiben alle fuenf Stellen sichtbar.
Bei Game-over blinkt mittig PRESS SPACE mit
25 PAL-Frames pro Phase. Der Bestwert bleibt bei Rundenneustart bestehen
und wird beim Programmstart geloescht. Buchstaben verwenden die gleiche
Fuenf-Pixel-Hoehe und Zwei-Pixel-Strichstaerke wie die Ziffern. Der tote Vogel
verwendet TED-Farbe 2 mit Luminanz 6; Neustart stellt TED_BIRD_COLOR wieder her.

Eine fruehere Multicolor-Fassung bestand 3.874 Farbzugriffe in VICE. Ein
neuer Rastertrace und Fuenf-Minuten-Dauerlauf des aktuellen Stands sowie
echte C16-Hardwaretests stehen aus. Testbefehle stehen in `TECH.md`.
