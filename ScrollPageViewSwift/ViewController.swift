import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var style = SegmentStyle()
        style.showLine = true
        style.scrollTitle = false
        style.gradualChangeTitleColor = true
        style.scrollLineColor = UIColor.black
        
        let titles = setChildVcs().map { $0.title! }
        let scroll = ScrollPageView(frame: CGRect(x: 0,
                                                  y: 64,
                                                  width: view.bounds.size.width,
                                                  height: view.bounds.size.height - 64),
                                    segmentStyle: style,
                                    titles: titles,
                                    childVcs: setChildVcs(),
                                    parentViewController: self)
        view.addSubview(scroll)
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

