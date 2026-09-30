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
- Der Vogel hat mindestens drei Flugphasen (Fluegel hoch, mitte, runter);
  beim Fallen kippt bzw. veraendert er sichtbar seine Haltung.

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
beiden Rohrbaender (je sechs Zeilen, erst Zeichen, dann Farbe) in acht
Stuecken zu je drei Zeilen in den versteckten Puffer. Himmel, Luecke und
Boden sind in jeder Spalte gleich und werden einmal beim Start gespiegelt.
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

Der Vogel ist ein 16 x 16 Pixel grosses Objekt und steht horizontal fest.
Seine physikalische Y-Position und Geschwindigkeit liegen in 8.8-Fixpunkt
vor. Fuer das Rendering enthaelt der Zeichensatz neun dynamische Vogelzeichen,
drei Spalten mal drei Zeilen.

1. Die ganzzahlige Y-Position bestimmt die Bildschirmzeile.
2. Die unteren drei Bits bestimmen den vertikalen Pixelversatz.
3. Der Feinscroll schiebt jede Zelle mit. Damit der Vogel auf dem Schirm
   stehen bleibt, wird die Maske um `7 - Scroll` Pixel nach rechts in den
   Glyphen verschoben. Bei Scroll 7 faellt der Versatz auf 0 und die Maske
   belegt genau zwei Spalten. Ab einem Pixel Versatz kommt die dritte
   Spalte dazu. Eine leere dritte Spalte wird nicht auf den Schirm gelegt.
4. Aus dem 16 x 16-Frame wird so ein bis zu 24 x 24 Pixel grosser Block.
   Leere Bits zeigen die Hintergrundfarbe; eine Zelle hat nur eine
   Vordergrundfarbe.

So bleibt die Kollisionsbox unabhaengig vom Zeichenraster. Der Vogel bewegt
sich vertikal ohne Acht-Pixel-Spruenge und horizontal ohne den Sieben-Pixel-
Ruck des Feinscrolls. Die Fluegelanimation wechselt zeitbasiert zwischen drei
Quellmasken; Fallgeschwindigkeit waehlt zusaetzlich eine aufgerichtete oder
abwaerts gerichtete Pose. Das Kopieren bleibt auf den kleinen dynamischen
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

Die Rohrwelt wird als Ringpuffer von Hindernissen gespeichert, nicht als
vollstaendige Tilemap. Jedes Hindernis umfasst mindestens:

- Welt-X-Koordinate in 8.8-Fixpunkt,
- obere und untere Kante der Luecke in Pixeln,
- einmalig vergebene Punktwertung.

Kollision verwendet die physikalische, achsenparallele Vogelbox gegen die
Rohrrechtecke in Pixelkoordinaten. Grafikzeichen sind nie die
Kollisionswahrheit. Die Trefferbox ist bewusst etwas kleiner als die
Vogelmaske und wird mit Konstanten dokumentiert, damit das Spiel fair bleibt.

## Laufzeitarchitektur

```text
reset/init
  -> video + eigener Zeichensatz + Eingabe initialisieren
  -> Spielfeld in beide Textpuffer spiegeln
  -> Titelbild
  -> neuer Lauf
  -> frame loop
       frame-sync auf der aufsteigenden Flanke von Raster $F0
       input
       bisheriges Vogelbild loeschen
       physics
       obstacle generation / scoring / collision   (ab Meilenstein 3)
       $FF07 schreiben, beim Umbruch auch $FF14
       ein Teilstueck in den versteckten Puffer kopieren
       Vogel auf den sichtbaren Puffer zeichnen
  -> game-over
  -> Titelbild oder neuer Lauf
```

`frame-sync` wartet auf genau ein PAL-Frame-Ereignis. Die erste Version darf
einen sicheren Rasterpoll verwenden; wenn dessen Timing nicht stabil genug
ist, wird auf eine einzelne TED-Raster-IRQ mit minimalem Handler umgestellt.
Die Spielberechnung selbst laeuft ausserhalb des IRQ. Das verhindert
KERNAL-abhhaengige Wartezeiten und macht das Frame-Budget messbar.

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
| `src/game.asm` | Physik, Rohrringpuffer, Kollision, Punkte |
| `src/render.asm` | Rohrspalten, HUD und Vogel-Glyphenkomposition |

## RAM- und Performance-Budget

Die Implementierung muss auf 16 KiB funktionieren; eine 64-KiB-Konfiguration
darf nie vorausgesetzt werden. Die konkrete Byteaufstellung steht in
`src/memory.inc`. Sie umfasst Code, Daten, beide Textpuffer, Zeichensatz und
Stack. Der zweite Puffer belegt `$1800-$1FE7`. Ab `$3C00` bleiben 1 KiB
Reserve. Ein Bitmap-Doppelpuffer ist damit ausgeschlossen.

Die Frame-Schleife hat ein Budget von einem PAL-Frame. Die gewoehnliche
Ausfuehrung aktualisiert nur Eingabe, Physik, einen Scrollwert, gegebenenfalls
eine Randspalte und maximal sechs dynamische Vogelglyphen. Full-Screen-Loops,
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
