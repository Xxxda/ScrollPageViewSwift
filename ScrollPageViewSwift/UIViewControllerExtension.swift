import UIKit

let logger: Logger = {
    let logger = Logger()
    return logger
}()

struct Logger {
    public func print<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {
        #if DEBUG
        print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
        #endif
    }
}

extension UIViewController {
    
    public weak var zj_scrollPageController: UIViewController? {
        get {
            var superVc = self.parent
            while superVc != nil {
                if superVc! is ScrollContentViewDelegate  {
                    break
                }
                superVc = superVc!.parent
            }
            return superVc
        }
    }
}
