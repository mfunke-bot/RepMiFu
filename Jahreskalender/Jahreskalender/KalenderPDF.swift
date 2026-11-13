import UIKit

/// Erzeugt einen Jahreskalender als einseitiges PDF (A4 quer).
enum KalenderPDF {
    private static let seite = CGRect(x: 0, y: 0, width: 841.89, height: 595.28) // A4 quer in pt
    private static let rand: CGFloat = 24

    private static let farbeFeiertag = UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1)
    private static let farbeRegional = UIColor(red: 0.95, green: 0.55, blue: 0.10, alpha: 1)
    private static let farbeWochenende = UIColor(white: 0.92, alpha: 1)
    private static let farbeSonntagText = UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1)
    private static let farbeKW = UIColor(white: 0.55, alpha: 1)

    static func erzeuge(jahr: Int, land: Bundesland) -> Data {
        let feiertage = Feiertage.berechne(jahr: jahr, land: land)
        var feiertagNachTag: [Tag: Feiertag] = [:]
        for f in feiertage where feiertagNachTag[f.tag] == nil || feiertagNachTag[f.tag]!.regional {
            feiertagNachTag[f.tag] = f
        }

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Jahreskalender \(jahr) – \(land.name)",
            kCGPDFContextCreator as String: "Jahreskalender",
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: seite, format: format)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            let inhalt = seite.insetBy(dx: rand, dy: rand)

            // Titel
            let titelHoehe: CGFloat = 30
            zeichne("Jahreskalender \(jahr)", in: CGRect(x: inhalt.minX, y: inhalt.minY, width: inhalt.width, height: titelHoehe),
                    font: .systemFont(ofSize: 22, weight: .bold), farbe: .black, ausrichtung: .left)
            zeichne(land.name, in: CGRect(x: inhalt.minX, y: inhalt.minY, width: inhalt.width, height: titelHoehe),
                    font: .systemFont(ofSize: 16, weight: .semibold), farbe: .darkGray, ausrichtung: .right)

            // Legende / Feiertagsliste unten
            let spalten = 4
            let zeilen = Int(ceil(Double(feiertage.count) / Double(spalten)))
            let zeilenHoehe: CGFloat = 10
            let hinweise = feiertage.filter { $0.regional }
            let legendeHoehe = 14 + CGFloat(zeilen) * zeilenHoehe + CGFloat(hinweise.count) * 9 + 4
            let legende = CGRect(x: inhalt.minX, y: inhalt.maxY - legendeHoehe, width: inhalt.width, height: legendeHoehe)
            zeichneLegende(feiertage: feiertage, hinweise: hinweise, in: legende, spalten: spalten, zeilenHoehe: zeilenHoehe)

            // Monatsraster 4 × 3
            let raster = CGRect(x: inhalt.minX, y: inhalt.minY + titelHoehe + 8,
                                width: inhalt.width, height: legende.minY - inhalt.minY - titelHoehe - 16)
            let mSpalten = 4, mZeilen = 3
            let abstand: CGFloat = 14
            let mBreite = (raster.width - abstand * CGFloat(mSpalten - 1)) / CGFloat(mSpalten)
            let mHoehe = (raster.height - abstand * CGFloat(mZeilen - 1)) / CGFloat(mZeilen)

            for monat in 1...12 {
                let s = (monat - 1) % mSpalten
                let z = (monat - 1) / mSpalten
                let r = CGRect(x: raster.minX + CGFloat(s) * (mBreite + abstand),
                               y: raster.minY + CGFloat(z) * (mHoehe + abstand),
                               width: mBreite, height: mHoehe)
                zeichneMonat(jahr: jahr, monat: monat, in: r, feiertage: feiertagNachTag)
            }
        }
    }

    // MARK: - Monat

    private static func zeichneMonat(jahr: Int, monat: Int, in r: CGRect, feiertage: [Tag: Feiertag]) {
        guard let g = UIGraphicsGetCurrentContext() else { return }

        let kopfHoehe: CGFloat = 16
        zeichne(Kalender.monatsnamen[monat - 1], in: CGRect(x: r.minX, y: r.minY, width: r.width, height: kopfHoehe),
                font: .systemFont(ofSize: 11, weight: .bold), farbe: .black, ausrichtung: .left)

        let spalten = 8 // KW + Mo…So
        let zellB = r.width / CGFloat(spalten)
        let wtHoehe: CGFloat = 11
        let wtY = r.minY + kopfHoehe
        zeichne("KW", in: CGRect(x: r.minX, y: wtY, width: zellB, height: wtHoehe),
                font: .systemFont(ofSize: 6.5), farbe: farbeKW)
        for (i, wt) in Kalender.wochentageKurz.enumerated() {
            zeichne(wt, in: CGRect(x: r.minX + CGFloat(i + 1) * zellB, y: wtY, width: zellB, height: wtHoehe),
                    font: .systemFont(ofSize: 7, weight: .semibold), farbe: i == 6 ? farbeSonntagText : .darkGray)
        }

        g.setStrokeColor(UIColor(white: 0.7, alpha: 1).cgColor)
        g.setLineWidth(0.5)
        g.move(to: CGPoint(x: r.minX, y: wtY + wtHoehe))
        g.addLine(to: CGPoint(x: r.maxX, y: wtY + wtHoehe))
        g.strokePath()

        let rasterY = wtY + wtHoehe + 1
        let zellH = (r.maxY - rasterY) / 6
        let ersterIndex = Kalender.wochentagIndex(Tag(jahr: jahr, monat: monat, tag: 1))
        let anzahl = Kalender.tageImMonat(jahr: jahr, monat: monat)

        var letzteZeile = -1
        for d in 1...anzahl {
            let t = Tag(jahr: jahr, monat: monat, tag: d)
            let pos = ersterIndex + d - 1
            let zeile = pos / 7
            let spalte = pos % 7
            let zelle = CGRect(x: r.minX + CGFloat(spalte + 1) * zellB, y: rasterY + CGFloat(zeile) * zellH,
                               width: zellB, height: zellH)

            if zeile != letzteZeile {
                letzteZeile = zeile
                zeichne("\(Kalender.kalenderwoche(t))", in: CGRect(x: r.minX, y: zelle.minY, width: zellB, height: zellH),
                        font: .systemFont(ofSize: 6.5), farbe: farbeKW)
            }

            let markierung = zelle.insetBy(dx: 1, dy: 1)
            var textFarbe = UIColor.black
            var font = UIFont.systemFont(ofSize: 8)

            if spalte >= 5 {
                g.setFillColor(farbeWochenende.cgColor)
                g.fill(markierung)
                if spalte == 6 { textFarbe = farbeSonntagText }
            }

            if let f = feiertage[t] {
                let pfad = UIBezierPath(roundedRect: markierung, cornerRadius: 2.5)
                if f.regional {
                    g.setStrokeColor(farbeRegional.cgColor)
                    g.setLineWidth(1.2)
                    pfad.lineWidth = 1.2
                    pfad.stroke()
                    textFarbe = farbeRegional
                    font = .systemFont(ofSize: 8, weight: .bold)
                } else {
                    g.setFillColor(farbeFeiertag.cgColor)
                    pfad.fill()
                    textFarbe = .white
                    font = .systemFont(ofSize: 8, weight: .bold)
                }
            }

            zeichne("\(d)", in: zelle, font: font, farbe: textFarbe)
        }
    }

    // MARK: - Legende

    private static func zeichneLegende(feiertage: [Feiertag], hinweise: [Feiertag], in r: CGRect,
                                       spalten: Int, zeilenHoehe: CGFloat) {
        guard let g = UIGraphicsGetCurrentContext() else { return }

        g.setStrokeColor(UIColor(white: 0.7, alpha: 1).cgColor)
        g.setLineWidth(0.5)
        g.move(to: CGPoint(x: r.minX, y: r.minY))
        g.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        g.strokePath()

        // Symbolerklärung
        let y0 = r.minY + 3
        var x = r.minX
        zeichne("Feiertage:", in: CGRect(x: x, y: y0, width: 60, height: 10),
                font: .systemFont(ofSize: 8, weight: .bold), farbe: .black, ausrichtung: .left)
        x = r.maxX - 260
        let symbol = CGRect(x: x, y: y0 + 1, width: 12, height: 8)
        g.setFillColor(farbeFeiertag.cgColor)
        UIBezierPath(roundedRect: symbol, cornerRadius: 2).fill()
        zeichne("gesetzlicher Feiertag", in: CGRect(x: x + 16, y: y0, width: 100, height: 10),
                font: .systemFont(ofSize: 7), farbe: .black, ausrichtung: .left)
        x += 120
        let symbol2 = CGRect(x: x, y: y0 + 1, width: 12, height: 8)
        g.setStrokeColor(farbeRegional.cgColor)
        let p2 = UIBezierPath(roundedRect: symbol2, cornerRadius: 2)
        p2.lineWidth = 1.2
        p2.stroke()
        zeichne("nur regional (*)", in: CGRect(x: x + 16, y: y0, width: 120, height: 10),
                font: .systemFont(ofSize: 7), farbe: .black, ausrichtung: .left)

        // Liste spaltenweise
        let fmt = DateFormatter()
        fmt.calendar = Kalender.gregorianisch
        fmt.timeZone = Kalender.gregorianisch.timeZone
        fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "EE dd.MM."

        let zeilen = Int(ceil(Double(feiertage.count) / Double(spalten)))
        let spaltenB = r.width / CGFloat(spalten)
        let listeY = r.minY + 14
        for (i, f) in feiertage.enumerated() {
            let s = i / max(zeilen, 1)
            let z = i % max(zeilen, 1)
            let zr = CGRect(x: r.minX + CGFloat(s) * spaltenB, y: listeY + CGFloat(z) * zeilenHoehe,
                            width: spaltenB, height: zeilenHoehe)
            let datum = fmt.string(from: Kalender.datum(f.tag))
            zeichne(datum, in: CGRect(x: zr.minX, y: zr.minY, width: 52, height: zr.height),
                    font: .monospacedDigitSystemFont(ofSize: 7.5, weight: .regular),
                    farbe: f.regional ? farbeRegional : farbeFeiertag, ausrichtung: .left)
            zeichne(f.name + (f.regional ? " *" : ""), in: CGRect(x: zr.minX + 54, y: zr.minY, width: zr.width - 56, height: zr.height),
                    font: .systemFont(ofSize: 7.5), farbe: .black, ausrichtung: .left)
        }

        // Hinweise zu regionalen Feiertagen
        var hy = listeY + CGFloat(zeilen) * zeilenHoehe + 2
        for f in hinweise {
            let text = "* \(f.name): \(f.hinweis ?? "nur regional")"
            zeichne(text, in: CGRect(x: r.minX, y: hy, width: r.width, height: 9),
                    font: .italicSystemFont(ofSize: 6.5), farbe: .darkGray, ausrichtung: .left)
            hy += 9
        }
    }

    // MARK: - Text

    private static func zeichne(_ text: String, in rect: CGRect, font: UIFont, farbe: UIColor,
                                ausrichtung: NSTextAlignment = .center) {
        let absatz = NSMutableParagraphStyle()
        absatz.alignment = ausrichtung
        absatz.lineBreakMode = .byTruncatingTail
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: farbe, .paragraphStyle: absatz]
        let groesse = (text as NSString).size(withAttributes: attr)
        let r = CGRect(x: rect.minX, y: rect.midY - groesse.height / 2, width: rect.width, height: groesse.height)
        (text as NSString).draw(in: r, withAttributes: attr)
    }
}
