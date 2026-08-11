import CoreGraphics
import CoreText
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct SurveyReportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    static var writableContentTypes: [UTType] { [.pdf] }

    let data: Data

    init(project: SurveyProject, records: [DetectionRecord]) {
        data = SurveyReportRenderer.render(project: project, records: records)
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum SurveyReportRenderer {
    fileprivate static let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    fileprivate static let margin: CGFloat = 48

    static func render(project: SurveyProject, records: [DetectionRecord]) -> Data {
        let mutableData = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutableData as CFMutableData) else { return Data() }
        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return Data() }

        let wifiRecords = records.filter { $0.transport == "Wi-Fi" }
        let bleRecords = records.filter { $0.transport != "Wi-Fi" }
        let locatedRecords = records.filter(\.hasLocation)
        let samples = WiFiChannelAnalyzer.samples(from: records)
        let stats = WiFiChannelAnalyzer.statistics(samples: samples)

        var page = PDFPage(context: context)
        page.start()
        page.text("OmniPulse", size: 25, bold: true, color: CGColor(red: 0.25, green: 0.25, blue: 0.80, alpha: 1))
        page.text("Informe de levantamiento inalámbrico", size: 16, bold: true)
        page.space(10)
        page.text("Proyecto: \(project.name)", size: 13, bold: true)
        page.text("Generado: \(Date().formatted(date: .long, time: .shortened))", size: 10, color: CGColor(gray: 0.35, alpha: 1))
        if !project.notes.isEmpty {
            page.text("Notas: \(project.notes)", size: 10)
        }
        page.rule()
        page.text("Resumen", size: 15, bold: true)
        page.text("\(records.count) observaciones · \(wifiRecords.count) Wi-Fi · \(bleRecords.count) BLE · \(locatedRecords.count) con ubicación", size: 11)
        page.text("Sensores: \(Set(records.compactMap(\.sensorIdentifier)).count) · Canales observados: \(Set(wifiRecords.compactMap(\.wifiChannel)).count)", size: 11)

        page.space(8)
        page.text("Recomendaciones de canal", size: 15, bold: true)
        for band in WiFiBand.allCases {
            if let recommendation = WiFiChannelAnalyzer.recommendation(for: band, samples: samples) {
                page.text("\(band.rawValue): canal \(recommendation.channel). \(recommendation.explanation)", size: 11)
            } else {
                page.text("\(band.rawValue): sin muestras suficientes.", size: 11, color: CGColor(gray: 0.45, alpha: 1))
            }
        }

        page.space(8)
        page.text("Ocupación de canales", size: 15, bold: true)
        if stats.isEmpty {
            page.text("No hay observaciones Wi-Fi con canal.", size: 11)
        } else {
            for stat in stats.prefix(18) {
                page.ensureSpace(18)
                page.text(
                    "\(stat.band.rawValue) · canal \(stat.channel): \(stat.networkCount) redes, promedio \(Int(stat.averageRSSI.rounded())) dBm, máximo \(stat.strongestRSSI) dBm",
                    size: 10
                )
            }
        }

        page.space(8)
        page.text("Observaciones recientes", size: 15, bold: true)
        for record in records.sorted(by: { $0.seenAt > $1.seenAt }).prefix(40) {
            page.ensureSpace(18)
            let channel = record.wifiChannel.map { " · canal \($0)" } ?? ""
            page.text("\(record.displayName) · \(record.transport) · \(record.rssi) dBm\(channel)", size: 9.5)
        }

        page.finish()
        context.closePDF()
        return mutableData as Data
    }
}

private struct PDFPage {
    let context: CGContext
    var cursorY: CGFloat = SurveyReportRenderer.pageRect.maxY - SurveyReportRenderer.margin

    mutating func start() {
        context.beginPDFPage(nil)
        cursorY = SurveyReportRenderer.pageRect.maxY - SurveyReportRenderer.margin
    }

    mutating func finish() {
        context.endPDFPage()
    }

    mutating func ensureSpace(_ height: CGFloat) {
        if cursorY - height < SurveyReportRenderer.margin {
            finish()
            start()
        }
    }

    mutating func text(_ value: String, size: CGFloat, bold: Bool = false, color: CGColor = CGColor(gray: 0.08, alpha: 1)) {
        let lineHeight = size * 1.45
        ensureSpace(lineHeight)
        let font = CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, size, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: value, attributes: attributes))
        context.textPosition = CGPoint(x: SurveyReportRenderer.margin, y: cursorY - size)
        CTLineDraw(line, context)
        cursorY -= lineHeight
    }

    mutating func space(_ value: CGFloat) {
        cursorY -= value
    }

    mutating func rule() {
        ensureSpace(20)
        cursorY -= 9
        context.setStrokeColor(CGColor(gray: 0.82, alpha: 1))
        context.setLineWidth(0.7)
        context.move(to: CGPoint(x: SurveyReportRenderer.margin, y: cursorY))
        context.addLine(to: CGPoint(x: SurveyReportRenderer.pageRect.maxX - SurveyReportRenderer.margin, y: cursorY))
        context.strokePath()
        cursorY -= 11
    }
}
