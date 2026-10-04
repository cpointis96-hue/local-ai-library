import Foundation

public enum ByteCountFormatter {
    private static let units = ["B", "KB", "MB", "GB", "TB", "PB"]

    public static func string(from bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }

        let value = Double(bytes)
        let exponent = min(
            Int(log(value) / log(1024)),
            units.count - 1
        )
        let scaled = value / pow(1024, Double(exponent))
        if exponent == 0 || scaled >= 10 || scaled.rounded() == scaled {
            return "\(Int(scaled.rounded())) \(units[exponent])"
        }
        return String(
            format: "%.1f %@",
            locale: Locale(identifier: "en_US_POSIX"),
            scaled,
            units[exponent]
        )
    }
}
