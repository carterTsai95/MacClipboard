import XCTest
@testable import MacClipboard

final class ClipboardServiceTests: XCTestCase {
    var clipboardService: ClipboardService!
    let pasteboard = NSPasteboard.general
    
    override func setUp() {
        super.setUp()
        clipboardService = ClipboardService.shared
        pasteboard.clearContents()
    }
    
    override func tearDown() {
        pasteboard.clearContents()
        super.tearDown()
    }
    
    func testCopyAndGetTextContent() {
        // Given
        let testText = "Test clipboard text"
        let content = ClipboardContent.text(testText)
        
        // When
        clipboardService.copyToClipboard(content)
        let retrievedContent = clipboardService.getCurrentContent()
        
        // Then
        if case .text(let retrievedText) = retrievedContent {
            XCTAssertEqual(retrievedText, testText)
        } else {
            XCTFail("Retrieved content is not text or is nil")
        }
    }
    
    func testCopyAndGetImageContent() {
        // Given
        let testImage = NSImage(systemSymbolName: "clipboard", accessibilityDescription: nil)!
        let testImageData = testImage.tiffRepresentation!
        let content = ClipboardContent.image(testImageData)
        
        // When
        clipboardService.copyToClipboard(content)
        let retrievedContent = clipboardService.getCurrentContent()
        
        // Then
        if case .image(let retrievedData) = retrievedContent {
            XCTAssertEqual(retrievedData, testImageData)
        } else {
            XCTFail("Retrieved content is not image or is nil")
        }
    }
    
    func testGetContentFromEmptyClipboard() {
        // Given
        pasteboard.clearContents()
        
        // When
        let content = clipboardService.getCurrentContent()
        
        // Then
        XCTAssertNil(content)
    }
} 