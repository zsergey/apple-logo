import UIKit

public class Window: UIWindow {
	
	private var invisibleInkViews: [UIView] = []
	
	public override func sendEvent(_ event: UIEvent) {
		
		super.sendEvent(event)
		
		guard let touches = event.allTouches, 
				let touch = touches.first else {
			return
		}
		
		let firstResponders: [UIView] = childHitTest(point: touch.location(in: self), with: event) ?? [self]
		
		switch touch.phase {
		case .began:
			firstResponders.forEach { $0.touchesBegan(touches, with: event) }
			startTexturePlayer(firstResponders)
		case .moved:
			firstResponders.forEach { $0.touchesMoved(touches, with: event) }
		case .ended:
			firstResponders.forEach { $0.touchesEnded(touches, with: event) }
			invisibleInkViews.forEach { $0.touchesEnded(touches, with: event) }
			stopTexturePlayer(firstResponders)
		default:
			break
		}
	}
	
	private func startTexturePlayer(_ firstResponders: [UIView]) {
		if let view = firstResponders.first,
		   type(of: view) == NSClassFromString("CKInvisibleInkImageEffectView"),
		   let appleLogoView = firstResponders.first?.superview as? AppleLogoView {
			appleLogoView.updateTexturePlayer?(true)
		}
	}
	
	private func stopTexturePlayer(_ firstResponders: [UIView]) {
		(firstResponders.first?.superview as? AppleLogoView)?.updateTexturePlayer?(false)
	}
	
	private func childHitTest(point: CGPoint, with event: UIEvent?) -> [UIView]? {
		
		if self.isHidden || !self.isUserInteractionEnabled ||
			self.alpha <= 0.01 {
			return nil
		}
		
		var responders: [UIView] = []
		
		for subview in subviews {
			
			if subview.frame.contains(point) {
				let nextPoint = subview.layer.convert(point, to: layer)
				
				/// В цикле до тех пор пока респонедом является класс `CKInvisibleInkImageEffectView` от Apple
				/// добавляю каждый такой экземпляр в массив и ему ставлю `isUserInteractionEnabled = false`
				/// чтобы на следующей итерации цикла получить следующий респондер с типом `CKInvisibleInkImageEffectView`
				while let responder = subview.hitTest(nextPoint, with: event),
					  type(of: responder) == NSClassFromString("CKInvisibleInkImageEffectView") {
					responders.append(responder)
					responder.isUserInteractionEnabled = false
				}
				
				if responders.count == 0 {
					if let responder = subview.hitTest(nextPoint, with: event) {
						responders.append(responder)
					}
				} else {
					/// Запоминаем всех респондеров с типом `CKInvisibleInkImageEffectView`, требуется чтобы в дальнейшем завершить тач.
					invisibleInkViews = responders
				}
			}
		}
		
		/// Возвращаем всем респондерам значение свойства `isUserInteractionEnabled`
		responders.forEach { $0.isUserInteractionEnabled = true }
		
		return responders
	}
}
