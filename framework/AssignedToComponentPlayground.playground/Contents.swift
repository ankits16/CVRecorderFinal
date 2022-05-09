//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport



class VynAssignedToCollection: UIView{
    
}






class MyViewController : UIViewController {
    
    private let captureLinkViewHeight: CGFloat = 30
    private let spacing: CGFloat = 5
    private let captureLinkCollectionRowHeight: CGFloat = 80
    
    private func getCaptureLinkViewRow() -> UIStackView {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fillEqually
//        verticalStackView.alignment = .center
//        verticalStackView.spacing = spacing * 2
//        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
//        verticalStackView.backgroundColor = .clear
//        verticalStackView.heightAnchor.constraint(equalToConstant: captureLinkViewHeight + spacing).isActive = true
//        verticalStackView.widthAnchor.constraint(equalToConstant: view.frame.width - 20).isActive = true
        verticalStackView.backgroundColor = .orange
        return verticalStackView
    }
    
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let label = UILabel()
        label.frame = CGRect(x: 150, y: 200, width: 200, height: 20)
        label.text = "Hello World!"
        label.textColor = .black
        
        view.addSubview(label)
        
        let vStack = getCaptureLinkViewRow()
        vStack.backgroundColor = .yellow
        
        vStack.frame =  CGRect(
            x: 0, y: 100,
            width: UIScreen.main.bounds.width - 100,
            height: 100)
        
        
//        first component
        let assignedToview = VynAssignedToCollection(frame: CGRect(
            x: 0, y: 0,
            width: UIScreen.main.bounds.width - 120,
            height: 50))
        assignedToview.backgroundColor = .green
        vStack.addArrangedSubview(assignedToview)
        
//        second component
        let assignedToview2 = VynAssignedToCollection(frame: CGRect(
            x: 0, y: 0,
            width: UIScreen.main.bounds.width - 120,
            height: 50))
        assignedToview2.backgroundColor = .blue
        vStack.addArrangedSubview(assignedToview2)
        
        view.addSubview(vStack)
        
        self.view = view
    }
    
    
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
