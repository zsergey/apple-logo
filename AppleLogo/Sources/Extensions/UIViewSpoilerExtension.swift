import UIKit

extension UIView {
	
	func addAppleLogoSpiler(path: UIBezierPath, size: CGSize) {
		
		for _ in 1...10 {
			let maskLayer = CAShapeLayer()
			maskLayer.path = path.cgPath
			maskLayer.strokeColor = UIColor.clear.cgColor
			maskLayer.fillColor = UIColor.white.cgColor
			
			if let invisibleInk = getInvisibleInkEffectView() {
				invisibleInk.layer.mask = maskLayer
				addSubview(invisibleInk)
				invisibleInk.center(in: self)
				invisibleInk.height(size.height)
				invisibleInk.width(size.width)
				
				invisibleInk.backgroundColor = .clear
				invisibleInk.layer.masksToBounds = true
			}
		}
	}
	
	private func getInvisibleInkEffectView() -> UIView? {
		dlopen("/System/Library/PrivateFrameworks/ChatKit.framework/ChatKit", RTLD_NOW)
		let invisibleInkView = NSClassFromString("CKInvisibleInkImageEffectView") as? UIView.Type
		let view = invisibleInkView?.init()
		return view
	}
}
