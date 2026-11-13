import SwiftUI
import PDFKit

struct PDFDatei: Identifiable, Hashable {
    let url: URL
    var id: URL { url }
}

struct ContentView: View {
    @State private var jahrText = String(Calendar.current.component(.year, from: .now) + 1)
    @State private var land: Bundesland = .bayern
    @State private var pdf: PDFDatei?
    @State private var fehler: String?

    private var jahr: Int? {
        guard let j = Int(jahrText.trimmingCharacters(in: .whitespaces)), Feiertage.jahre.contains(j) else { return nil }
        return j
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Eingaben") {
                    HStack {
                        Text("Jahr")
                        Spacer()
                        TextField("z. B. 2027", text: $jahrText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                    Picker("Bundesland", selection: $land) {
                        ForEach(Bundesland.allCases) { bl in
                            Text(bl.name).tag(bl)
                        }
                    }
                }

                Section {
                    Button {
                        erstellePDF()
                    } label: {
                        Label("PDF erstellen", systemImage: "doc.richtext")
                    }
                    .disabled(jahr == nil)
                } footer: {
                    if jahr == nil {
                        Text(verbatim: "Bitte ein Jahr zwischen \(Feiertage.jahre.lowerBound) und \(Feiertage.jahre.upperBound) eingeben.")
                            .foregroundStyle(.red)
                    }
                }

                if let fehler {
                    Section { Text(fehler).foregroundStyle(.red) }
                }

                if let jahr {
                    Section {
                        ForEach(Feiertage.berechne(jahr: jahr, land: land)) { f in
                            HStack(alignment: .firstTextBaseline) {
                                Text(Self.datumsFormat.string(from: Kalender.datum(f.tag)))
                                    .monospacedDigit()
                                    .foregroundStyle(f.regional ? .orange : .red)
                                    .frame(width: 90, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(f.name)
                                    if let h = f.hinweis {
                                        Text(h).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(verbatim: "Feiertage \(jahr) – \(land.name)")
                    }
                }
            }
            .navigationTitle("Jahreskalender")
            .navigationDestination(item: $pdf) { datei in
                PDFVorschau(url: datei.url)
            }
        }
    }

    private static let datumsFormat: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Kalender.gregorianisch
        f.timeZone = Kalender.gregorianisch.timeZone
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EE dd.MM."
        return f
    }()

    private func erstellePDF() {
        guard let jahr else { return }
        fehler = nil
        let daten = KalenderPDF.erzeuge(jahr: jahr, land: land)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Jahreskalender_\(jahr)_\(land.kuerzel).pdf")
        do {
            try daten.write(to: url, options: .atomic)
            pdf = PDFDatei(url: url)
        } catch {
            fehler = "PDF konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }
}

struct PDFVorschau: View {
    let url: URL

    var body: some View {
        PDFKitAnsicht(url: url)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(url.deletingPathExtension().lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: url) {
                        Label("Teilen", systemImage: "square.and.arrow.up")
                    }
                }
            }
    }
}

struct PDFKitAnsicht: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePage
        v.backgroundColor = .secondarySystemBackground
        v.document = PDFDocument(url: url)
        return v
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}

#Preview {
    ContentView()
}
