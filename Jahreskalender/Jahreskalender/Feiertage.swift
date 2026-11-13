import Foundation

/// Ein Tag ohne Uhrzeit/Zeitzone.
struct Tag: Hashable, Comparable {
    let jahr: Int
    let monat: Int
    let tag: Int

    static func < (a: Tag, b: Tag) -> Bool {
        (a.jahr, a.monat, a.tag) < (b.jahr, b.monat, b.tag)
    }
}

struct Feiertag: Identifiable, Hashable {
    let tag: Tag
    let name: String
    /// true = gilt nur in Teilen des Bundeslandes
    let regional: Bool
    let hinweis: String?

    var id: String { "\(tag.jahr)-\(tag.monat)-\(tag.tag)-\(name)" }
}

enum Kalender {
    /// Gregorianischer Kalender, ISO-Wochen (Montag, min. 4 Tage), UTC – vermeidet Sommerzeit-Effekte.
    static let gregorianisch: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.locale = Locale(identifier: "de_DE")
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }()

    static func datum(_ t: Tag) -> Date {
        gregorianisch.date(from: DateComponents(year: t.jahr, month: t.monat, day: t.tag))!
    }

    static func tag(_ d: Date) -> Tag {
        let k = gregorianisch.dateComponents([.year, .month, .day], from: d)
        return Tag(jahr: k.year!, monat: k.month!, tag: k.day!)
    }

    static func plus(_ t: Tag, tage: Int) -> Tag {
        tag(gregorianisch.date(byAdding: .day, value: tage, to: datum(t))!)
    }

    /// 0 = Montag … 6 = Sonntag
    static func wochentagIndex(_ t: Tag) -> Int {
        (gregorianisch.component(.weekday, from: datum(t)) + 5) % 7
    }

    static func kalenderwoche(_ t: Tag) -> Int {
        gregorianisch.component(.weekOfYear, from: datum(t))
    }

    static func tageImMonat(jahr: Int, monat: Int) -> Int {
        let d = datum(Tag(jahr: jahr, monat: monat, tag: 1))
        return gregorianisch.range(of: .day, in: .month, for: d)!.count
    }

    static let monatsnamen = ["Januar", "Februar", "März", "April", "Mai", "Juni",
                              "Juli", "August", "September", "Oktober", "November", "Dezember"]
    static let wochentageKurz = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
}

enum Feiertage {
    /// Unterstützter Zeitraum. Vor 1995 galten andere Regeln (z. B. Buß- und Bettag bundesweit).
    static let jahre = 1995...2100

    /// Ostersonntag nach der Gaußschen Osterformel (anonymer gregorianischer Algorithmus).
    static func ostersonntag(_ jahr: Int) -> Tag {
        let a = jahr % 19
        let b = jahr / 100
        let c = jahr % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let monat = (h + l - 7 * m + 114) / 31
        let tag = ((h + l - 7 * m + 114) % 31) + 1
        return Tag(jahr: jahr, monat: monat, tag: tag)
    }

    /// Buß- und Bettag: Mittwoch vor dem 23. November.
    static func bussUndBettag(_ jahr: Int) -> Tag {
        let t22 = Tag(jahr: jahr, monat: 11, tag: 22)
        let abstand = (Kalender.wochentagIndex(t22) - 2 + 7) % 7 // 2 = Mittwoch
        return Kalender.plus(t22, tage: -abstand)
    }

    static func berechne(jahr: Int, land: Bundesland) -> [Feiertag] {
        let ostern = ostersonntag(jahr)
        var liste: [Feiertag] = []

        func add(_ m: Int, _ d: Int, _ name: String, regional: Bool = false, hinweis: String? = nil) {
            liste.append(Feiertag(tag: Tag(jahr: jahr, monat: m, tag: d), name: name, regional: regional, hinweis: hinweis))
        }
        func addOstern(_ offset: Int, _ name: String, regional: Bool = false, hinweis: String? = nil) {
            liste.append(Feiertag(tag: Kalender.plus(ostern, tage: offset), name: name, regional: regional, hinweis: hinweis))
        }

        // Bundesweit
        add(1, 1, "Neujahr")
        addOstern(-2, "Karfreitag")
        addOstern(1, "Ostermontag")
        add(5, 1, "Tag der Arbeit")
        addOstern(39, "Christi Himmelfahrt")
        addOstern(50, "Pfingstmontag")
        add(10, 3, "Tag der Deutschen Einheit")
        add(12, 25, "1. Weihnachtstag")
        add(12, 26, "2. Weihnachtstag")

        // Heilige Drei Könige
        if [.badenWuerttemberg, .bayern, .sachsenAnhalt].contains(land) {
            add(1, 6, "Heilige Drei Könige")
        }

        // Internationaler Frauentag
        if (land == .berlin && jahr >= 2019) || (land == .mecklenburgVorpommern && jahr >= 2023) {
            add(3, 8, "Internationaler Frauentag")
        }

        // Ostersonntag / Pfingstsonntag (gesetzlich in BB und HE)
        if [.brandenburg, .hessen].contains(land) {
            addOstern(0, "Ostersonntag")
            addOstern(49, "Pfingstsonntag")
        }

        // Tag der Befreiung (Berlin, einmalig)
        if land == .berlin && (jahr == 2020 || jahr == 2025) {
            add(5, 8, "Tag der Befreiung")
        }

        // Fronleichnam
        if [.badenWuerttemberg, .bayern, .hessen, .nordrheinWestfalen, .rheinlandPfalz, .saarland].contains(land) {
            addOstern(60, "Fronleichnam")
        } else if land == .sachsen {
            addOstern(60, "Fronleichnam", regional: true, hinweis: "nur in einigen Gemeinden im Landkreis Bautzen")
        } else if land == .thueringen {
            addOstern(60, "Fronleichnam", regional: true, hinweis: "nur in Gemeinden mit überwiegend katholischer Bevölkerung (Eichsfeld u. a.)")
        }

        // Augsburger Friedensfest
        if land == .bayern {
            add(8, 8, "Augsburger Friedensfest", regional: true, hinweis: "nur im Stadtgebiet Augsburg")
        }

        // Mariä Himmelfahrt
        if land == .saarland {
            add(8, 15, "Mariä Himmelfahrt")
        } else if land == .bayern {
            add(8, 15, "Mariä Himmelfahrt", regional: true, hinweis: "nur in Gemeinden mit überwiegend katholischer Bevölkerung")
        }

        // Weltkindertag
        if land == .thueringen && jahr >= 2019 {
            add(9, 20, "Weltkindertag")
        }

        // Reformationstag
        let reformationSeitJeher: [Bundesland] = [.brandenburg, .mecklenburgVorpommern, .sachsen, .sachsenAnhalt, .thueringen]
        let reformationSeit2018: [Bundesland] = [.bremen, .hamburg, .niedersachsen, .schleswigHolstein]
        if reformationSeitJeher.contains(land)
            || (reformationSeit2018.contains(land) && jahr >= 2018)
            || jahr == 2017 {
            add(10, 31, jahr == 2017 ? "Reformationstag (500 Jahre)" : "Reformationstag")
        }

        // Allerheiligen
        if [.badenWuerttemberg, .bayern, .nordrheinWestfalen, .rheinlandPfalz, .saarland].contains(land) {
            add(11, 1, "Allerheiligen")
        }

        // Buß- und Bettag
        if land == .sachsen {
            liste.append(Feiertag(tag: bussUndBettag(jahr), name: "Buß- und Bettag", regional: false, hinweis: nil))
        }

        return liste.sorted { $0.tag < $1.tag }
    }
}
