import Foundation
import UIKit
import ComponentFlow

final class CameraButton: Component {
    let content: AnyComponent<Empty>
    let minSize: CGSize?
    let tag: AnyObject?
    let isEnabled: Bool
    let action: () -> Void

    init(
        content: AnyComponent<Empty>,
        minSize: CGSize? = nil,
        tag: AnyObject? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.content = content
        self.minSize = minSize
        self.tag = tag
        self.isEnabled = isEnabled
        self.action = action
    }
    
    func tagged(_ tag: AnyObject) -> CameraButton {
        return CameraButton(
            content: self.content,
            minSize: self.minSize,
            tag: tag,
            isEnabled: self.isEnabled,
            action: self.action
        )
    }
    
    static func ==(lhs: CameraButton, rhs: CameraButton) -> Bool {
        if lhs.content != rhs.content {
            return false
        }
        if lhs.minSize != rhs.minSize {
            return false
        }
        if lhs.tag !== rhs.tag {
            return false
        }
        if lhs.isEnabled != rhs.isEnabled {
            return false
        }
        return true
    }
    
    final class View: UIButton, ComponentTaggedView {
        private let contentView: ComponentHostView<Empty>
        
        private var component: CameraButton?
        private var currentIsHighlighted: Bool = false {
            didSet {
                if self.currentIsHighlighted != oldValue {
                    self.updateScale(transition: .easeInOut(duration: 0.3))
                }
            }
        }
        
        private func updateScale(transition: Transition) {
            guard let component = self.component else {
                return
            }
            let scale: CGFloat
            if component.isEnabled {
                scale = self.currentIsHighlighted ? 0.8 : 1.0
            } else {
                scale = 1.0
            }
            transition.setScale(view: self, scale: scale)
        }
    
        override init(frame: CGRect) {
            self.contentView = ComponentHostView<Empty>()
            self.contentView.isUserInteractionEnabled = false
            self.contentView.layer.allowsGroupOpacity = true
            
            super.init(frame: frame)
            
            self.addSubview(self.contentView)
            
            self.addTarget(self, action: #selector(self.pressed), for: .touchUpInside)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public func matches(tag: Any) -> Bool {
            if let component = self.component, let componentTag = component.tag {
                let tag = tag as AnyObject
                if componentTag === tag {
                    return true
                }
            }
            return false
        }
        
        @objc private func pressed() {
            self.component?.action()
        }
        
        override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            self.currentIsHighlighted = true
            
            return super.beginTracking(touch, with: event)
        }
    
        override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
            self.currentIsHighlighted = false
            
            super.endTracking(touch, with: event)
        }
        
        override func cancelTracking(with event: UIEvent?) {
            self.currentIsHighlighted = false
            
            super.cancelTracking(with: event)
        }
        
        func update(component: CameraButton, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: Transition) -> CGSize {
            let contentSize = self.contentView.update(
                transition: transition,
                component: component.content,
                environment: {},
                containerSize: availableSize
            )
            
            var size = contentSize
            if let minSize = component.minSize {
                size.width = max(size.width, minSize.width)
                size.height = max(size.height, minSize.height)
            }
            
            self.component = component
            
            self.updateScale(transition: transition)
            self.isEnabled = component.isEnabled
            
            transition.setFrame(view: self.contentView, frame: CGRect(origin: CGPoint(x: floor((size.width - contentSize.width) / 2.0), y: floor((size.height - contentSize.height) / 2.0)), size: contentSize), completion: nil)
            
            return size
        }
    }
    
    func makeView() -> View {
        return View(frame: CGRect())
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: Transition) -> CGSize {
        view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
