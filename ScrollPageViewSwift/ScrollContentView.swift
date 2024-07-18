import UIKit

public class CustomGestureCollectionView: UICollectionView {
    
    var panGestureShouldBeginClosure: ((_ panGesture: UIPanGestureRecognizer, _ collectionView: CustomGestureCollectionView) -> Bool)?
    
    func setupPanGestureShouldBeginClosure(closure: @escaping (_ panGesture: UIPanGestureRecognizer, _ collectionView: CustomGestureCollectionView) -> Bool) {
        panGestureShouldBeginClosure = closure
    }
    
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureShouldBeginClosure = panGestureShouldBeginClosure, let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            return panGestureShouldBeginClosure(panGesture, self)
        } else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
    }
}

public class ScrollContentView: UIView {
    
    private let cellId = "cellId"
    
    private var childVcs: [UIViewController] = []
    /// 用来判断是否是点击了title, 点击了就不要调用scrollview的代理来进行相关的计算
    private var forbidTouchToAdjustPosition = false
    private var beginOffSetX: CGFloat = 0.0
    private var oldIndex = 0
    private var currentIndex = 1
    private weak var parentViewController: UIViewController?
    weak var delegate: ScrollContentViewDelegate?
    
    private(set) lazy var collectionView: CustomGestureCollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        let collection = CustomGestureCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        flowLayout.itemSize = self.bounds.size
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        collection.scrollsToTop = false
        collection.bounces = false
        collection.showsHorizontalScrollIndicator = false
        collection.frame = self.bounds
        collection.collectionViewLayout = flowLayout
        collection.isPagingEnabled = true
        collection.delegate = self
        collection.dataSource = self
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        return collection
    }()
    
    public init(frame:CGRect, childVcs:[UIViewController], parentViewController: UIViewController) {
        self.parentViewController = parentViewController
        self.childVcs = childVcs
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("不要使用storyboard中的view为contentView")
    }
    
    private func commonInit() {
        // 不要添加navigationController包装后的子控制器
        for childVc in childVcs {
            if childVc.isKind(of: UINavigationController.self) {
                fatalError("不要添加UINavigationController包装后的子控制器")
            }
            parentViewController?.addChildViewController(childVc)
        }
        collectionView.backgroundColor = UIColor.clear
        collectionView.frame = bounds
        
        // 在这里调用了懒加载的collectionView, 那么之前设置的self.frame将会用于collectionView,如果在layoutsubviews()里面没有相关的处理frame的操作, 那么将导致内容显示不正常
        addSubview(collectionView)
        
        // 设置naviVVc手势代理, 处理pop手势 只在第一个页面的时候执行系统的滑动返回手势
        if let naviParentViewController = self.parentViewController?.parent as? UINavigationController {
            if naviParentViewController.viewControllers.count == 1 { return }
            collectionView.setupPanGestureShouldBeginClosure(closure: { [weak self] (panGesture, collectionView) -> Bool in
                
                let strongSelf = self
                guard let `self` = strongSelf else { return false}
                
                let transionX = panGesture.velocity(in: panGesture.view).x
                
                if collectionView.contentOffset.x == 0 && transionX > 0 {
                    naviParentViewController.interactivePopGestureRecognizer?.isEnabled = true
                } else {
                    naviParentViewController.interactivePopGestureRecognizer?.isEnabled = false
                }
                return self.delegate?.contentViewShouldBeginPanGesture(panGesture: panGesture, collectionView: collectionView) ?? true
            })
        }
    }
    
    // 发布通知
    private func addCurrentShowIndexNotification(index: Int) {
        NotificationCenter.default.post(name: NSNotification.Name(ScrollPageViewDidShowThePageNotification),
                                        object: nil,
                                        userInfo: ["currentIndex": index])
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
        let  vc = childVcs[currentIndex]
        vc.view.frame = bounds
    }
    
    deinit {
        parentViewController = nil
        logger.print("...")
    }
}

extension ScrollContentView {
    
    // 给外界可以设置ContentOffSet的方法(public method to set contentOffSet)
    public func setContentOffSet(offSet: CGPoint , animated: Bool) {
        // 不要执行collectionView的scrollView的滚动代理方法
        self.forbidTouchToAdjustPosition = true
        delegate?.contentViewDidBeginMove(scrollView: collectionView)
        self.collectionView.setContentOffset(offSet, animated: animated)
    }
    
    public func reloadAllViewsWithNewChildVcs(newChildVcs: [UIViewController] ) {
        childVcs.forEach { (childVc) in
            childVc.willMove(toParentViewController: nil)
            childVc.view.removeFromSuperview()
            childVc.removeFromParentViewController()
        }
        childVcs.removeAll()
        childVcs = newChildVcs
        
        // don't add the childVc that wrapped by the navigationController
        // 不要添加navigationController包装后的子控制器
        for childVc in childVcs {
            if childVc.isKind(of: UINavigationController.self) {
                fatalError("不要添加UINavigationController包装后的子控制器")
            }
            parentViewController?.addChildViewController(childVc)
        }
        collectionView.reloadData()
    }
}

extension ScrollContentView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return childVcs.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        let  vc = childVcs[indexPath.row]
        vc.view.frame = bounds
        cell.contentView.addSubview(vc.view)
        vc.didMove(toParentViewController: parentViewController)
        addCurrentShowIndexNotification(index: indexPath.row)
        return cell
    }
}

extension ScrollContentView: UIScrollViewDelegate {
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentIndex = Int(floor(scrollView.contentOffset.x / bounds.size.width))
        
        delegate?.contentViewDidEndDisPlay(scrollView: collectionView)
        // 保证如果滚动没有到下一页就返回了上一页
        // 通过这种方式再次正确设置 index(still at oldPage )
        delegate?.contentViewDidEndMoveToIndex(fromIndex: self.currentIndex, toIndex: currentIndex)
    }
    
    // 代码调整contentOffSet但是没有动画的时候不会调用这个
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.contentViewDidEndDisPlay(scrollView: collectionView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let currentIndex = Int(floor(scrollView.contentOffset.x / bounds.size.width))
        if let naviParentViewController = self.parentViewController?.parent as? UINavigationController {
            naviParentViewController.interactivePopGestureRecognizer?.isEnabled = true
            
        }
        delegate?.contentViewDidEndDrag(scrollView: scrollView)
        print(scrollView.contentOffset.x)
        //快速滚动的时候第一页和最后一页(scroll too fast will not call 'scrollViewDidEndDecelerating')
        if scrollView.contentOffset.x == 0 || scrollView.contentOffset.x == scrollView.contentSize.width - scrollView.bounds.width{
            if self.currentIndex != currentIndex {
                delegate?.contentViewDidEndMoveToIndex(fromIndex: self.currentIndex, toIndex: currentIndex)
            }
        }
    }
    
    // 手指开始拖的时候, 记录此时的offSetX, 并且表示不是点击title切换的内容(remenber the begin offsetX)
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        /// 用来判断方向
        beginOffSetX = scrollView.contentOffset.x
        delegate?.contentViewDidBeginMove(scrollView: collectionView)
        
        forbidTouchToAdjustPosition = false
    }
    
    // 需要实时更新滚动的进度和移动的方向及下标 以便于外部使用 (compute the index and progress)
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offSetX = scrollView.contentOffset.x
        // 如果是点击了title, 就不要计算了, 直接在点击相应的方法里就已经处理了滚动
        if forbidTouchToAdjustPosition {
            return
        }
        
        let temp = offSetX / bounds.size.width
        // 滚动的进度 -- 取小数位
        var progress = temp - floor(temp)
        // 根据滚动的方向
        if offSetX - beginOffSetX >= 0 {// 手指左滑, 滑块右移
            oldIndex = Int(floor(offSetX / bounds.size.width))
            currentIndex = oldIndex + 1
            if currentIndex >= childVcs.count {
                currentIndex = oldIndex - 1
            }
            if offSetX - beginOffSetX == scrollView.bounds.size.width {// 滚动完成
                progress = 1.0;
                currentIndex = oldIndex;
            }
        } else {
            // 手指右滑, 滑块左移
            currentIndex = Int(floor(offSetX / bounds.size.width))
            oldIndex = currentIndex + 1
            progress = 1.0 - progress
        }
        delegate?.contentViewMoveToIndex(fromIndex: oldIndex, toIndex: currentIndex, progress: progress)
    }
}

public protocol ScrollContentViewDelegate: class {
    /// 有默认实现, 不推荐重写(override is not recommoned)
    func contentViewMoveToIndex(fromIndex: Int, toIndex: Int, progress: CGFloat)
    /// 有默认实现, 不推荐重写(override is not recommoned)
    func contentViewDidEndMoveToIndex(fromIndex: Int , toIndex: Int)
    func contentViewShouldBeginPanGesture(panGesture: UIPanGestureRecognizer , collectionView: CustomGestureCollectionView) -> Bool;
    func contentViewDidBeginMove(scrollView: UIScrollView)
    func contentViewIsScrolling(scrollView: UIScrollView)
    func contentViewDidEndDisPlay(scrollView: UIScrollView)
    func contentViewDidEndDrag(scrollView: UIScrollView)
}

// 由于每个遵守这个协议的都需要执行些相同的操作, 所以直接使用协议扩展统一完成,协议遵守者只需要提供segmentView即可
extension ScrollContentViewDelegate {
    
    public func contentViewDidEndDrag(scrollView: UIScrollView) {
        
    }
    
    public func contentViewDidEndDisPlay(scrollView: UIScrollView) {
        
    }
    
    public func contentViewIsScrolling(scrollView: UIScrollView) {
        
    }
    
    public func contentViewDidBeginMove(scrollView: UIScrollView) {
        
    }
    
    public func contentViewShouldBeginPanGesture(panGesture: UIPanGestureRecognizer, collectionView: CustomGestureCollectionView) -> Bool {
        return true
    }
    
    // 内容每次滚动完成时调用, 确定title和其他的控件的位置
    public func contentViewDidEndMoveToIndex(fromIndex: Int , toIndex: Int) {
    }

    // 内容正在滚动的时候,同步滚动滑块的控件
    public func contentViewMoveToIndex(fromIndex: Int, toIndex: Int, progress: CGFloat) {
    }
}

