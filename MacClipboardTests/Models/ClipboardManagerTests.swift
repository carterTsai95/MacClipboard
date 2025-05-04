import XCTest
@testable import MacClipboard

// Mock storage for testing
class MockClipboardItemStorage: ClipboardItemStorage {
    private var items: [ClipboardItem] = []
    
    override init() {
        super.init()
    }
    
    override func saveItems(_ items: [ClipboardItem]) {
        self.items = items
    }
    
    override func loadItems() -> [ClipboardItem] {
        return items
    }
}

// Test-specific subclass of ClipboardManager
class TestableClipboardManager: ClipboardManager {
    func forceCheckForChanges(completion: (() -> Void)? = nil) {
        checkForChanges(completion: completion)
    }
}

final class ClipboardManagerTests: XCTestCase {
    // MARK: - Properties
    private var clipboardManager: TestableClipboardManager!
    private var mockPasteboard: MockPasteboard!
    private var mockStorage: MockClipboardItemStorage!
    
    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()
        mockPasteboard = MockPasteboard()
        mockStorage = MockClipboardItemStorage()
        // Replace the shared storage with our mock
        ClipboardItemStorage.shared = mockStorage
        clipboardManager = TestableClipboardManager(maxItems: 5, 
                                                 pasteboard: mockPasteboard,
                                                 monitoringInterval: 0.1) // Faster monitoring for tests
    }
    
    override func tearDown() {
        mockPasteboard = nil
        clipboardManager = nil
        mockStorage = nil
        // Restore the original shared storage
        ClipboardItemStorage.shared = ClipboardItemStorage()
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
        clipboardManager.forceCheckForChanges {
            XCTAssertEqual(self.clipboardManager.clipboardItems.count, 1)
            guard let firstItem = self.clipboardManager.clipboardItems.first else {
                XCTFail("First item should exist")
                expectation.fulfill()
                return
            }
            
            guard case .text(let text) = firstItem.content else {
                XCTFail("First item should be text")
                expectation.fulfill()
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
        clipboardManager = TestableClipboardManager(maxItems: maxItems, 
                                                 pasteboard: mockPasteboard,
                                                 monitoringInterval: 0.1)
        let expectation = XCTestExpectation(description: "Wait for all items")
        
        // When
        func addItem(index: Int) {
            guard index < 10 else {
                // All items added, now check the result
                XCTAssertEqual(self.clipboardManager.clipboardItems.count, maxItems)
                
                // Verify the last 5 items are present (items 5-9)
                let expectedTexts = (5...9).map { "Test text \($0)" }.reversed()
                let actualTexts = self.clipboardManager.clipboardItems.compactMap { item -> String? in
                    guard case .text(let text) = item.content else { return nil }
                    return text
                }
                
                XCTAssertEqual(actualTexts, Array(expectedTexts))
                expectation.fulfill()
                return
            }
            
            let testText = "Test text \(index)"
            self.mockPasteboard.clearContents()
            self.mockPasteboard.setString(testText, forType: .string)
            
            // Force check for changes immediately
            self.clipboardManager.forceCheckForChanges {
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
        let expectation = XCTestExpectation(description: "Wait for copy to complete")
        clipboardManager.copyToClipboard(item) {
            // Then
            XCTAssertEqual(self.mockPasteboard.string(forType: .string), testText)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteItem() {
        // Given
        let testText = "Test text"
        mockPasteboard.clearContents()
        mockPasteboard.setString(testText, forType: .string)
        
        let expectation = XCTestExpectation(description: "Wait for item to be added and deleted")
        
        // When
        clipboardManager.forceCheckForChanges {
            guard let item = self.clipboardManager.clipboardItems.first else {
                XCTFail("No item was added")
                expectation.fulfill()
                return
            }
            
            // Then
            self.clipboardManager.deleteItem(item) {
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
            guard index < 5 else {
                // All items added, now mark some as favorites and add to groups
                let items = self.clipboardManager.clipboardItems
                
                // Mark second item as favorite
                self.clipboardManager.toggleFavorite(items[1])
                
                // Create a custom group and add third item to it
                self.clipboardManager.createCustomGroup(name: "Test Group") { group in
                    self.clipboardManager.addItemToGroup(items[2], group: group)
                    
                    // Now test clearing
                    self.clipboardManager.clearHistory {
                        // Should keep:
                        // 1. First item (most recent)
                        // 2. Second item (favorite)
                        // 3. Third item (in custom group)
                        XCTAssertEqual(self.clipboardManager.clipboardItems.count, 3)
                        
                        // Verify the items are in the correct order
                        XCTAssertEqual(self.clipboardManager.clipboardItems[0].id, items[0].id)
                        XCTAssertEqual(self.clipboardManager.clipboardItems[1].id, items[1].id)
                        XCTAssertEqual(self.clipboardManager.clipboardItems[2].id, items[2].id)
                        
                        expectation.fulfill()
                    }
                }
                return
            }
            
            let testText = "Test text \(index)"
            self.mockPasteboard.clearContents()
            self.mockPasteboard.setString(testText, forType: .string)
            
            // Force check for changes immediately
            self.clipboardManager.forceCheckForChanges {
                addItems(index: index + 1)
            }
        }
        
        // Start adding items
        addItems(index: 0)
        
        wait(for: [expectation], timeout: 5.0)
    }
} 
