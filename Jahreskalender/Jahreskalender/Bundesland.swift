import Foundation

enum Bundesland: String, CaseIterable, Identifiable {
    case badenWuerttemberg = "BW"
    case bayern = "BY"
    case berlin = "BE"
    case brandenburg = "BB"
    case bremen = "HB"
    case hamburg = "HH"
    case hessen = "HE"
    case mecklenburgVorpommern = "MV"
    case niedersachsen = "NI"
    case nordrheinWestfalen = "NW"
    case rheinlandPfalz = "RP"
    case saarland = "SL"
    case sachsen = "SN"
    case sachsenAnhalt = "ST"
    case schleswigHolstein = "SH"
    case thueringen = "TH"

    var id: String { rawValue }
    var kuerzel: String { rawValue }

    var name: String {
        switch self {
        case .badenWuerttemberg: return "Baden-Württemberg"
        case .bayern: return "Bayern"
        case .berlin: return "Berlin"
        case .brandenburg: return "Brandenburg"
        case .bremen: return "Bremen"
        case .hamburg: return "Hamburg"
        case .hessen: return "Hessen"
        case .mecklenburgVorpommern: return "Mecklenburg-Vorpommern"
        case .niedersachsen: return "Niedersachsen"
        case .nordrheinWestfalen: return "Nordrhein-Westfalen"
        case .rheinlandPfalz: return "Rheinland-Pfalz"
        case .saarland: return "Saarland"
        case .sachsen: return "Sachsen"
        case .sachsenAnhalt: return "Sachsen-Anhalt"
        case .schleswigHolstein: return "Schleswig-Holstein"
        case .thueringen: return "Thüringen"
        }
    }
}
