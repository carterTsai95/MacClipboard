import AppKit

protocol PasteboardProtocol {
    func clearContents()
    func setString(_ string: String, forType type: NSPasteboard.PasteboardType)
    func setData(_ data: Data, forType type: NSPasteboard.PasteboardType)
    func string(forType type: NSPasteboard.PasteboardType) -> String?
    func data(forType type: NSPasteboard.PasteboardType) -> Data?
    var changeCount: Int { get }
} 