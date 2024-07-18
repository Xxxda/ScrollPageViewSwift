import UIKit

class ViewController: UIViewController, ScrollContentViewDelegate {
    func contentViewMoveToIndex(fromIndex: Int, toIndex: Int, progress: CGFloat) {
        segmentView?.adjustUIWithProgress(progress, fromIndex, toIndex)
    }
    
    func contentViewDidEndMoveToIndex(fromIndex: Int, toIndex: Int) {
        segmentView?.adjustTitleOffSetToCurrentIndex(toIndex)
    }
    

    var segmentView: ScrollSegmentView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var style = SegmentStyle()
        style.showLine = true
        style.scrollTitle = false
        style.gradualChangeTitleColor = true
        style.scrollLineColor = UIColor.black
        
        let titles = setChildVcs().map { $0.title! }

        let segmentView = ScrollSegmentView(frame: CGRect(x: 0, y: 64, width: view.bounds.size.width, height: 44), segmentStyle: SegmentStyle(), titles: titles)


        let scroll = ScrollPageView(frame: CGRect(x: 0,
                                                  y: 64 + 44,
                                                  width: view.bounds.size.width,
                                                  height: view.bounds.size.height - 64),
                                    childVcs: setChildVcs(),
                                    parentViewController: self)
        scroll.delegate = self
        view.addSubview(scroll)
        view.addSubview(segmentView)

        segmentView.titleBtnOnClick = {
            scroll.scrollToIndex($1, animated: true)
        }
        self.segmentView = segmentView
    }
    
    func setChildVcs() -> [UIViewController] {
       
        let vc1 = UIViewController()
        vc1.view.backgroundColor = UIColor.blue
        vc1.title = "热点"
        
        let vc2 = UIViewController()
        vc2.view.backgroundColor = UIColor.green
        vc2.title = "国际要闻"
        
        let vc3 = UIViewController()
        vc3.view.backgroundColor = UIColor.red
        vc3.title = "趣事"
        
        let vc4 = UIViewController()
        vc4.view.backgroundColor = UIColor.yellow
        vc4.title = "囧图"
        
        return [vc1, vc2, vc3, vc4]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
 
    }
}

