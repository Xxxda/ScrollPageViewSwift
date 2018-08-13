import UIKit

public class ScrollPageView: UIView {
    
    private let cellId = "cellId"
    
    private var segmentStyle = SegmentStyle()
    
    public var extraBtnOnClick: ((_ extraBtn: UIButton) -> Void)? {
        didSet {
            segView.extraBtnOnClick = extraBtnOnClick
        }
    }
    
    private(set) var segView: ScrollSegmentView!
    private(set) var contentView: ScrollContentView!
    private var titlesArray: [String] = []
    private var childVcs: [UIViewController] = []
    private weak var parentViewController: UIViewController?
    
    init(frame:CGRect,
                segmentStyle: SegmentStyle,
                titles: [String],
                childVcs:[UIViewController],
                parentViewController: UIViewController) {
        
        self.parentViewController = parentViewController
        self.childVcs = childVcs
        self.titlesArray = titles
        self.segmentStyle = segmentStyle
        assert(childVcs.count == titles.count, "标题的个数必须和子控制器的个数相同")
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        backgroundColor = UIColor.white
        segView = ScrollSegmentView(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: 44), segmentStyle: segmentStyle, titles: titlesArray)
        
        guard let parentVc = parentViewController else { return }
        
        contentView = ScrollContentView(frame: CGRect(x: 0,
                                                y: (segView.frame.origin.y + segView.frame.height),
                                                width: bounds.size.width,
                                                height: bounds.size.height - 44),
                                  childVcs: childVcs,
                                  parentViewController: parentVc)
        contentView.delegate = self
        
        addSubview(segView)
        addSubview(contentView)
        segView.titleBtnOnClick = {[unowned self] (label: UILabel, index: Int) in
            self.contentView.setContentOffSet(offSet: CGPoint(x: self.contentView.bounds.size.width * CGFloat(index), y: 0),
                                              animated: self.segmentStyle.changeContentAnimated)
        }
    }
    
    deinit {
        parentViewController = nil
        logger.print("...")
    }
}

extension ScrollPageView {
    
    public func selectedIndex(selectedIndex: Int, animated: Bool) {
        segView.selectedIndex(selectedIndex: selectedIndex, animated: animated)
    }
    
    public func reloadChildVcsWithNewTitles(titles: [String], andNewChildVcs newChildVcs: [UIViewController]) {
        self.childVcs = newChildVcs
        self.titlesArray = titles
        segView.reloadTitlesWithNewTitles(titles: titlesArray)
        contentView.reloadAllViewsWithNewChildVcs(newChildVcs: childVcs)
    }
}

extension ScrollPageView: ScrollContentViewDelegate {
    
    public var segmentView: ScrollSegmentView {
        return segView
    }
}
