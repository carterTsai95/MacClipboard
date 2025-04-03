import XCTest
@testable import MacClipboard

final class ClipboardManagerTests: XCTestCase {
    var clipboardManager: ClipboardManager!
    let pasteboard = NSPasteboard.general
    
    override func setUp() {
        super.setUp()
        clipboardManager = ClipboardManager(maxItems: 5)
        pasteboard.clearContents()
    }
    
    override func tearDown() {
        pasteboard.clearContents()
        super.tearDown()
    }
    
    func testAddNewItem() {
        // Given
        let testText = "Test text"
        pasteboard.clearContents()
        pasteboard.setString(testText, forType: .string)
        
        // When
        let expectation = XCTestExpectation(description: "Wait for clipboard monitoring")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Then
            XCTAssertEqual(self.clipboardManager.clipboardItems.count, 1)
            if case .text(let text) = self.clipboardManager.clipboardItems.first?.content {
                XCTAssertEqual(text, testText)
            } else {
                XCTFail("First item is not text or doesn't exist")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testMaxItemsLimit() {
        // Given
        let maxItems = 5
        clipboardManager = ClipboardManager(maxItems: maxItems)
        let expectation = XCTestExpectation(description: "Wait for all items")
        
        // When
        func addItem(index: Int) {
            guard index < 10 else {
                // All items added, now check the result
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    XCTAssertEqual(self.clipboardManager.clipboardItems.count, maxItems)
                    
                    // Verify the last 5 items are present (items 5-9)
                    let expectedTexts = (5...9).map { "Test text \($0)" }.reversed()
                    let actualTexts = self.clipboardManager.clipboardItems.compactMap { item -> String? in
                        if case .text(let text) = item.content {
                            return text
                        }
                        return nil
                    }
                    
                    XCTAssertEqual(actualTexts, Array(expectedTexts))
                    expectation.fulfill()
                }
                return
            }
            
            let testText = "Test text \(index)"
            self.pasteboard.clearContents()
            self.pasteboard.setString(testText, forType: .string)
            
            // Add next item after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                addItem(index: index + 1)
            }
        }
        
        // Start adding items
        addItem(index: 0)
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testCopyToClipboard() {
        // Given
        let testText = "Test text"
        let item = ClipboardItem(content: .text(testText))
        
        // When
        clipboardManager.copyToClipboard(item)
        
        // Then
        XCTAssertEqual(pasteboard.string(forType: .string), testText)
    }
    
    func testDeleteItem() {
        // Given
        let testText = "Test text"
        pasteboard.clearContents()
        pasteboard.setString(testText, forType: .string)
        
        let expectation = XCTestExpectation(description: "Wait for item to be added")
        
        // When
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let item = self.clipboardManager.clipboardItems.first else {
                XCTFail("No item was added")
                return
            }
            
            // Then
            self.clipboardManager.deleteItem(item)
            XCTAssertFalse(self.clipboardManager.clipboardItems.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testClearHistory() {
        // Given
        let expectation = XCTestExpectation(description: "Wait for items to be added")
        
        func addItems(index: Int) {
            guard index < 3 else {
                // All items added, now test clearing
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.clipboardManager.clearHistory()
                    XCTAssertEqual(self.clipboardManager.clipboardItems.count, 1)
                    expectation.fulfill()
                }
                return
            }
            
            let testText = "Test text \(index)"
            self.pasteboard.clearContents()
            self.pasteboard.setString(testText, forType: .string)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                addItems(index: index + 1)
            }
        }
        
        // Start adding items
        addItems(index: 0)
        
        wait(for: [expectation], timeout: 5.0)
    }
} 
