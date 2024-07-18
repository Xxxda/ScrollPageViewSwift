import UIKit

public class ScrollPageView: UIView {
    
    weak var delegate: ScrollContentViewDelegate?

    private let cellId = "cellId"

    public var extraBtnOnClick: ((_ extraBtn: UIButton) -> Void)? {
        didSet {
        }
    }
    
    private(set) var contentView: ScrollContentView!
    private var titlesArray: [String] = []
    private var childVcs: [UIViewController] = []
    private weak var parentViewController: UIViewController?
    
    init(frame:CGRect,
         childVcs:[UIViewController],
         parentViewController: UIViewController) {
        
        self.parentViewController = parentViewController
        self.childVcs = childVcs

        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        backgroundColor = UIColor.white

        
        guard let parentVc = parentViewController else { return }
        
        contentView = ScrollContentView(frame: CGRect(x: 0,
                                                y: 0,
                                                width: bounds.size.width,
                                                height: bounds.size.height),
                                  childVcs: childVcs,
                                  parentViewController: parentVc)
        contentView.delegate = self
        
        addSubview(contentView)

    }

    func scrollToIndex(_ index: Int, animated: Bool) {
        self.contentView.setContentOffSet(offSet: CGPoint(x: self.contentView.bounds.size.width * CGFloat(index), y: 0),
                                          animated: animated)
    }

    deinit {
        parentViewController = nil
        logger.print("...")
    }
}

extension ScrollPageView {
    
    public func selectedIndex(selectedIndex: Int, animated: Bool) {
    }
    
    public func reloadChildVcsWithNewTitles(andNewChildVcs newChildVcs: [UIViewController]) {
        self.childVcs = newChildVcs
        contentView.reloadAllViewsWithNewChildVcs(newChildVcs: childVcs)
    }
}

extension ScrollPageView: ScrollContentViewDelegate {

    // 内容每次滚动完成时调用, 确定title和其他的控件的位置
    public func contentViewDidEndMoveToIndex(fromIndex: Int , toIndex: Int) {
        delegate?.contentViewDidEndMoveToIndex(fromIndex: fromIndex, toIndex: toIndex)
    }

    // 内容正在滚动的时候,同步滚动滑块的控件
    public func contentViewMoveToIndex(fromIndex: Int, toIndex: Int, progress: CGFloat) {
        delegate?.contentViewMoveToIndex(fromIndex: fromIndex, toIndex: toIndex, progress: progress)
    }
}
