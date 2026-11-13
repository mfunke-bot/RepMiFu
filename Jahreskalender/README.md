# Jahreskalender (iOS)

SwiftUI-App, die einen Jahreskalender als PDF (A4 quer, eine Seite) erzeugt.
Eingabe: Jahr (1995–2100) und Bundesland. Gesetzliche Feiertage des Bundeslandes
werden im Kalender markiert und unten mit Datum aufgelistet.

## Öffnen & Starten
- Xcode 16 oder neuer, iOS 17+
- `Jahreskalender.xcodeproj` öffnen, unter *Signing & Capabilities* ein Team wählen
  (ggf. Bundle-ID `de.example.Jahreskalender` anpassen), Run.

## Darstellung im PDF
- 12 Monate im Raster 4 × 3, mit Kalenderwochen (ISO 8601)
- Wochenenden grau hinterlegt, Sonntage rot
- Landesweite Feiertage: rot gefüllt
- Nur regional geltende Feiertage: orange umrandet, mit Hinweis
  (Mariä Himmelfahrt und Augsburger Friedensfest in BY, Fronleichnam in Teilen von SN und TH)
- PDF-Vorschau in der App, Teilen/Sichern über das Teilen-Menü

## Feiertagsregeln
Bundesweit: Neujahr, Karfreitag, Ostermontag, 1. Mai, Christi Himmelfahrt,
Pfingstmontag, Tag der Deutschen Einheit, 1./2. Weihnachtstag.
Länderspezifisch: Heilige Drei Könige, Frauentag (BE ab 2019, MV ab 2023),
Oster-/Pfingstsonntag (BB, HE), Tag der Befreiung (BE 2020, 2025), Fronleichnam,
Mariä Himmelfahrt, Weltkindertag (TH ab 2019), Reformationstag (HB/HH/NI/SH ab 2018,
bundesweit 2017), Allerheiligen, Buß- und Bettag (SN).
Künftige Gesetzesänderungen sind nicht berücksichtigt.

## App-Icon
`Jahreskalender/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (1024 × 1024, ohne Transparenz).
Neu erzeugen: `python3 Tools/erzeuge_app_icon.py Jahreskalender/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (benötigt Pillow).
