import Foundation


public func test(describing description: String, action: () -> Void) {
    print("\n--- Test of: \(description) ---")
    action()
}

 
public func test2(describing description: String, action: () -> Void) {
    print("\n--- Test of: \(description) ---")
    action()
}
