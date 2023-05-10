import Foundation
import UIKit
import Display
import ComponentFlow
import AppBundle
import ChatTextInputMediaRecordingButton
import AccountContext
import TelegramPresentationData
import ChatPresentationInterfaceState

public final class MessageInputActionButtonComponent: Component {
    public enum Mode {
        case none
        case send
        case apply
        case voiceInput
        case videoInput
    }
    
    public enum Action {
        case down
        case up
    }

    public let mode: Mode
    public let action: (Mode, Action, Bool) -> Void
    public let switchMediaInputMode: () -> Void
    public let updateMediaCancelFraction: (CGFloat) -> Void
    public let context: AccountContext
    public let theme: PresentationTheme
    public let strings: PresentationStrings
    public let presentController: (ViewController) -> Void
    public let audioRecorder: ManagedAudioRecorder?
    public let videoRecordingStatus: InstantVideoControllerRecordingStatus?
    
    public init(
        mode: Mode,
        action: @escaping (Mode, Action, Bool) -> Void,
        switchMediaInputMode: @escaping () -> Void,
        updateMediaCancelFraction: @escaping (CGFloat) -> Void,
        context: AccountContext,
        theme: PresentationTheme,
        strings: PresentationStrings,
        presentController: @escaping (ViewController) -> Void,
        audioRecorder: ManagedAudioRecorder?,
        videoRecordingStatus: InstantVideoControllerRecordingStatus?
    ) {
        self.mode = mode
        self.action = action
        self.switchMediaInputMode = switchMediaInputMode
        self.updateMediaCancelFraction = updateMediaCancelFraction
        self.context = context
        self.theme = theme
        self.strings = strings
        self.presentController = presentController
        self.audioRecorder = audioRecorder
        self.videoRecordingStatus = videoRecordingStatus
    }
    
    public static func ==(lhs: MessageInputActionButtonComponent, rhs: MessageInputActionButtonComponent) -> Bool {
        if lhs.mode != rhs.mode {
            return false
        }
        if lhs.context !== rhs.context {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        if lhs.audioRecorder !== rhs.audioRecorder {
            return false
        }
        if lhs.videoRecordingStatus !== rhs.videoRecordingStatus {
            return false
        }
        return true
    }
    
    public final class View: HighlightTrackingButton {
        private var micButton: ChatTextInputMediaRecordingButton?
        private let sendIconView: UIImageView
        
        private var component: MessageInputActionButtonComponent?
        private weak var componentState: EmptyComponentState?
        
        override init(frame: CGRect) {
            self.sendIconView = UIImageView()
            
            super.init(frame: frame)
            
            self.isMultipleTouchEnabled = false
            
            self.addSubview(self.sendIconView)
            
            self.highligthedChanged = { [weak self] highlighted in
                guard let self else {
                    return
                }
                
                let scale: CGFloat = highlighted ? 0.6 : 1.0
                
                let transition = Transition(animation: .curve(duration: highlighted ? 0.5 : 0.3, curve: .spring))
                transition.setSublayerTransform(view: self, transform: CATransform3DMakeScale(scale, scale, 1.0))
            }
            
            self.addTarget(self, action: #selector(self.touchDown), for: .touchDown)
            self.addTarget(self, action: #selector(self.pressed), for: .touchUpInside)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func touchDown() {
            guard let component = self.component else {
                return
            }
            component.action(component.mode, .down, false)
        }
        
        @objc private func pressed() {
            guard let component = self.component else {
                return
            }
            component.action(component.mode, .up, false)
        }
        
        override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            return super.continueTracking(touch, with: event)
        }
        
        func update(component: MessageInputActionButtonComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: Transition) -> CGSize {
            let previousComponent = self.component
            self.component = component
            self.componentState = state
            
            let themeUpdated = previousComponent?.theme !== component.theme
            
            if self.micButton == nil {
                let micButton = ChatTextInputMediaRecordingButton(
                    context: component.context,
                    theme: component.theme,
                    useDarkTheme: true,
                    strings: component.strings,
                    presentController: component.presentController
                )
                self.micButton = micButton
                micButton.statusBarHost = component.context.sharedContext.mainWindow?.statusBarHost
                self.addSubview(micButton)
                
                micButton.beginRecording = { [weak self] in
                    guard let self, let component = self.component else {
                        return
                    }
                    switch component.mode {
                    case .voiceInput, .videoInput:
                        component.action(component.mode, .down, false)
                    default:
                        break
                    }
                }
                micButton.endRecording = { [weak self] sendMedia in
                    guard let self, let component = self.component else {
                        return
                    }
                    switch component.mode {
                    case .voiceInput, .videoInput:
                        component.action(component.mode, .up, sendMedia)
                    default:
                        break
                    }
                }
                micButton.switchMode = { [weak self] in
                    guard let self, let component = self.component else {
                        return
                    }
                    component.switchMediaInputMode()
                }
                micButton.updateCancelTranslation = { [weak self] in
                    guard let self, let micButton = self.micButton, let component = self.component else {
                        return
                    }
                    component.updateMediaCancelFraction(micButton.cancelTranslation)
                }
            }
            
            if self.sendIconView.image == nil {
                self.sendIconView.image = generateImage(CGSize(width: 33.0, height: 33.0), rotatedContext: { size, context in
                    context.clear(CGRect(origin: CGPoint(), size: size))
                    context.setFillColor(UIColor.white.cgColor)
                    context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
                    context.setBlendMode(.copy)
                    context.setStrokeColor(UIColor.clear.cgColor)
                    context.setLineWidth(2.0)
                    context.setLineCap(.round)
                    context.setLineJoin(.round)
                    
                    context.translateBy(x: 5.45, y: 4.0)
                    
                    context.saveGState()
                    context.translateBy(x: 4.0, y: 4.0)
                    let _ = try? drawSvgPath(context, path: "M1,7 L7,1 L13,7 S ")
                    context.restoreGState()
                    
                    context.saveGState()
                    context.translateBy(x: 10.0, y: 4.0)
                    let _ = try? drawSvgPath(context, path: "M1,16 V1 S ")
                    context.restoreGState()
                })
            }
            
            var sendAlpha: CGFloat = 0.0
            var microphoneAlpha: CGFloat = 0.0
            
            switch component.mode {
            case .none:
                break
            case .send, .apply:
                sendAlpha = 1.0
            case .videoInput, .voiceInput:
                microphoneAlpha = 1.0
            }
            
            transition.setAlpha(view: self.sendIconView, alpha: sendAlpha)
            transition.setScale(view: self.sendIconView, scale: sendAlpha == 0.0 ? 0.01 : 1.0)
            
            if let image = self.sendIconView.image {
                let iconFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((availableSize.width - image.size.width) * 0.5), y: floorToScreenPixels((availableSize.height - image.size.height) * 0.5)), size: image.size)
                transition.setPosition(view: self.sendIconView, position: iconFrame.center)
                transition.setBounds(view: self.sendIconView, bounds: CGRect(origin: CGPoint(), size: iconFrame.size))
            }
            
            if let micButton = self.micButton {
                if themeUpdated {
                    micButton.updateTheme(theme: component.theme)
                }
                
                let micButtonFrame = CGRect(origin: CGPoint(), size: availableSize)
                let shouldLayoutMicButton = micButton.bounds.size != micButtonFrame.size
                transition.setPosition(layer: micButton.layer, position: micButtonFrame.center)
                transition.setBounds(layer: micButton.layer, bounds: CGRect(origin: CGPoint(), size: micButtonFrame.size))
                if shouldLayoutMicButton {
                    micButton.layoutItems()
                }
                
                if previousComponent?.mode != component.mode {
                    switch component.mode {
                    case .none, .send, .apply, .voiceInput:
                        micButton.updateMode(mode: .audio, animated: !transition.animation.isImmediate)
                    case .videoInput:
                        micButton.updateMode(mode: .video, animated: !transition.animation.isImmediate)
                    }
                }
                
                DispatchQueue.main.async { [weak self, weak micButton] in
                    guard let self, let component = self.component, let micButton else {
                        return
                    }
                    micButton.audioRecorder = component.audioRecorder
                    micButton.videoRecordingStatus = component.videoRecordingStatus
                }
                
                transition.setAlpha(view: micButton, alpha: microphoneAlpha)
                transition.setScale(view: micButton, scale: microphoneAlpha == 0.0 ? 0.01 : 1.0)
            }
            
            return availableSize
        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
