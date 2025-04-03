import XCTest
@testable import MacClipboard

final class ClipboardServiceTests: XCTestCase {
    // MARK: - Properties
    private var clipboardService: ClipboardService!
    private var mockPasteboard: MockPasteboard!
    
    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()
        mockPasteboard = MockPasteboard()
        clipboardService = ClipboardService(pasteboard: mockPasteboard)
    }
    
    override func tearDown() {
        mockPasteboard = nil
        clipboardService = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    func testCopyAndGetTextContent() {
        // Given
        let testText = "Test clipboard text"
        let content = ClipboardContent.text(testText)
        
        // When
        clipboardService.copyToClipboard(content)
        let retrievedContent = clipboardService.getCurrentContent()
        
        // Then
        XCTAssertNotNil(retrievedContent, "Retrieved content should not be nil")
        guard case .text(let retrievedText) = retrievedContent else {
            XCTFail("Retrieved content should be text")
            return
        }
        XCTAssertEqual(retrievedText, testText)
        XCTAssertEqual(mockPasteboard.string(forType: .string), testText)
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
        XCTAssertNotNil(retrievedContent, "Retrieved content should not be nil")
        guard case .image(let retrievedData) = retrievedContent else {
            XCTFail("Retrieved content should be image")
            return
        }
        XCTAssertEqual(retrievedData, testImageData)
        XCTAssertEqual(mockPasteboard.data(forType: .tiff), testImageData)
    }
    
    func testGetContentFromEmptyClipboard() {
        // Given
        mockPasteboard.clearContents()
        
        // When
        let content = clipboardService.getCurrentContent()
        
        // Then
        XCTAssertNil(content, "Content should be nil for empty clipboard")
    }
} 