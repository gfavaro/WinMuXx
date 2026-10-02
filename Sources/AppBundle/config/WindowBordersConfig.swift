import AppKit
import Common
import TOMLKit

enum WindowBorderOrder: String { case below, above }

struct WindowBordersConfig: ConvenienceCopyable, Equatable {
    var enabled = true
    var width = 4.0
    var activeColor = "#E1E3E4"
    var inactiveColor = "#494D64"
    var order = WindowBorderOrder.below
    var excludeApps: [String] = []
}

private let borderParsers: [String: any ParserProtocol<WindowBordersConfig>] = [
    "enabled": Parser(\.enabled, parseBool),
    "width": Parser(\.width) { raw, trace in
        let value = raw.double ?? raw.int.map(Double.init)
        return value.orFailure(.semantic(trace, "Must be a finite, nonnegative number"))
            .filter(.semantic(trace, "Must be a finite, nonnegative number")) { $0.isFinite && $0 >= 0 }
    },
    "order": Parser(\.order) { raw, trace in
        parseString(raw, trace).flatMap { WindowBorderOrder(rawValue: $0).orFailure(.semantic(trace, "Must be 'below' or 'above'")) }
    },
    "exclude-apps": Parser(\.excludeApps, parseArrayOfStrings),
    "active-color": Parser(\.activeColor, parseBorderColor),
    "inactive-color": Parser(\.inactiveColor, parseBorderColor),
]

private func parseBorderColor(_ raw: TOMLValueConvertible, _ trace: TomlBacktrace) -> ParsedToml<String> {
    parseString(raw, trace).flatMap {
        normalizedWindowBorderColor($0).orFailure(.semantic(trace, "Use #RRGGBB or #RRGGBBAA"))
    }
}

func normalizedWindowBorderColor(_ raw: String) -> String? {
    guard raw.hasPrefix("#"), [7, 9].contains(raw.count), UInt32(raw.dropFirst(), radix: 16) != nil else { return nil }
    return raw.uppercased()
}

func parseWindowBorders(_ raw: TOMLValueConvertible, _ trace: TomlBacktrace, _ errors: inout [TomlParseError]) -> WindowBordersConfig {
    parseTable(raw, WindowBordersConfig(), borderParsers, trace, &errors)
}
