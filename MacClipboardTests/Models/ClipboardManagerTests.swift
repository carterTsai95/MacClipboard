import XCTest
@testable import MacClipboard

final class ClipboardManagerTests: XCTestCase {
    // MARK: - Properties
    private var clipboardManager: ClipboardManager!
    private var mockPasteboard: MockPasteboard!
    
    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()
        mockPasteboard = MockPasteboard()
        clipboardManager = ClipboardManager(maxItems: 5, 
                                         pasteboard: mockPasteboard,
                                         monitoringInterval: 0.1) // Faster monitoring for tests
    }
    
    override func tearDown() {
        mockPasteboard = nil
        clipboardManager = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    func testAddNewItem() {
        // Given
        let testText = "Test text"
        mockPasteboard.clearContents()
        mockPasteboard.setString(testText, forType: .string)
        
        // When
        let expectation = XCTestExpectation(description: "Wait for clipboard monitoring")
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.clipboardManager.clipboardItems.count, 1)
            guard let firstItem = self.clipboardManager.clipboardItems.first else {
                XCTFail("First item should exist")
                return
            }
            
            guard case .text(let text) = firstItem.content else {
                XCTFail("First item should be text")
                return
            }
            
            XCTAssertEqual(text, testText)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMaxItemsLimit() {
        // Given
        let maxItems = 5
        clipboardManager = ClipboardManager(maxItems: maxItems, 
                                         pasteboard: mockPasteboard,
                                         monitoringInterval: 0.1)
        let expectation = XCTestExpectation(description: "Wait for all items")
        
        // When
        func addItem(index: Int) {
            guard index < 10 else {
                // All items added, now check the result
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    XCTAssertEqual(self.clipboardManager.clipboardItems.count, maxItems)
                    
                    // Verify the last 5 items are present (items 5-9)
                    let expectedTexts = (5...9).map { "Test text \($0)" }.reversed()
                    let actualTexts = self.clipboardManager.clipboardItems.compactMap { item -> String? in
                        guard case .text(let text) = item.content else { return nil }
                        return text
                    }
                    
                    XCTAssertEqual(actualTexts, Array(expectedTexts))
                    expectation.fulfill()
                }
                return
            }
            
            let testText = "Test text \(index)"
            self.mockPasteboard.clearContents()
            self.mockPasteboard.setString(testText, forType: .string)
            
            // Force check for changes immediately
            self.clipboardManager.forceCheckForChanges()
            
            // Add next item after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                addItem(index: index + 1)
            }
        }
        
        // Start adding items
        addItem(index: 0)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCopyToClipboard() {
        // Given
        let testText = "Test text"
        let item = ClipboardItem(content: .text(testText))
        
        // When
        clipboardManager.copyToClipboard(item)
        
        // Then
        XCTAssertEqual(mockPasteboard.string(forType: .string), testText)
    }
    
    func testDeleteItem() {
        // Given
        let testText = "Test text"
        mockPasteboard.clearContents()
        mockPasteboard.setString(testText, forType: .string)
        
        let expectation = XCTestExpectation(description: "Wait for item to be added and deleted")
        
        // When
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let item = self.clipboardManager.clipboardItems.first else {
                XCTFail("No item was added")
                expectation.fulfill()
                return
            }
            
            // Then
            self.clipboardManager.deleteItem(item)
            
            // Wait for the delete operation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                XCTAssertTrue(self.clipboardManager.clipboardItems.isEmpty)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testClearHistory() {
        // Given
        let expectation = XCTestExpectation(description: "Wait for items to be added and cleared")
        
        func addItems(index: Int) {
            guard index < 3 else {
                // All items added, now test clearing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.clipboardManager.clearHistory()
                    
                    // Wait for the clear operation to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        XCTAssertEqual(self.clipboardManager.clipboardItems.count, 1)
                        expectation.fulfill()
                    }
                }
                return
            }
            
            let testText = "Test text \(index)"
            self.mockPasteboard.clearContents()
            self.mockPasteboard.setString(testText, forType: .string)
            
            // Force check for changes immediately
            self.clipboardManager.forceCheckForChanges()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                addItems(index: index + 1)
            }
        }
        
        // Start adding items
        addItems(index: 0)
        
        wait(for: [expectation], timeout: 3.0)
    }
} 
