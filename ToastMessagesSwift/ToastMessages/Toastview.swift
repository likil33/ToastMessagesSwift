
//  Created by santhosh
//  Copyright © 2020 Nextbrain. All rights reserved.
//




import Foundation
import UIKit



let KEY_WINDOW = UIWindow.key


class DisplayToastView: NSObject {
    static let shared = DisplayToastView()
    //Initializer access level change now
    private override init(){}
    
    // calling from viewcontroller for toastMessage
    func toast(_ message : String) {
        DispatchQueue.main.async {
            KEY_WINDOW? .makeToast(message) // self.view .makeToast(message)
        }
    }
    
}

public extension UIView {
    
    private struct ToastKeys {
        static var timer        = "timer"
        static var duration     = "duration"
        static var point        = "point"
        static var completion   = "completion"
        static var activeToast  = "activeToast"
        static var activityView = "activityView"
        static var queue        = "queue"
        static var toastTag     = 887
        
    }
    
    
    private class ToastCompletionWrapper {
        var completion: ((Bool) -> Void)?
        init(_ completion: ((Bool) -> Void)?) {
            self.completion = completion
        }
    }
    private enum ToastError: Error {
        case insufficientData
    }
    
    private var queue: NSMutableArray {
        get {
            if let queue = objc_getAssociatedObject(self, &ToastKeys.queue) as? NSMutableArray {
                return queue
            } else {
                let queue = NSMutableArray()
                objc_setAssociatedObject(self, &ToastKeys.queue, queue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return queue
            }
        }
    }
    
    // MARK: - Make Toast Methods
    func makeToast(_ message: String?, duration: TimeInterval = ToastManager.shared.duration, position: ToastPosition = ToastManager.shared.position, title: String? = nil, image: UIImage? = nil, style: ToastStyle = ToastManager.shared.style, completion: ((_ didTap: Bool) -> Void)? = nil) {
        do {
            let toast = try toastViewForMessage(message, title: title, image: image, style: style)
            
            if SupportDefaults.getToastStatus() == false {
                SupportDefaults.setToastStatus(flag: true)
                showToast(toast, duration: duration, position: position, completion: completion)
            }
        } catch ToastError.insufficientData {
            print("Error: message, title, and image are all nil")
        } catch {}
    }
    
    func makeToast(_ message: String?, duration: TimeInterval = ToastManager.shared.duration, point: CGPoint, title: String?, image: UIImage?, style: ToastStyle = ToastManager.shared.style, completion: ((_ didTap: Bool) -> Void)?) {
        do {
            let toast = try toastViewForMessage(message, title: title, image: image, style: style)
            showToast(toast, duration: duration, point: point, completion: completion)
        } catch ToastError.insufficientData {
            print("Error: message, title, and image cannot all be nil")
        } catch {}
    }
    
    // MARK: - Show Toast Methods
    func showToast(_ toast: UIView, duration: TimeInterval = ToastManager.shared.duration, position: ToastPosition = ToastManager.shared.position, completion: ((_ didTap: Bool) -> Void)? = nil) {
        let point = position.centerPoint(forToast: toast, inSuperview: self)
        showToast(toast, duration: duration, point: point, completion: completion)
    }
    
    func showToast(_ toast: UIView, duration: TimeInterval = ToastManager.shared.duration, point: CGPoint, completion: ((_ didTap: Bool) -> Void)? = nil) {
        objc_setAssociatedObject(toast, &ToastKeys.completion, ToastCompletionWrapper(completion), .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if let _ = objc_getAssociatedObject(self, &ToastKeys.activeToast) as? UIView, ToastManager.shared.isQueueEnabled {
            objc_setAssociatedObject(toast, &ToastKeys.duration, NSNumber(value: duration), .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(toast, &ToastKeys.point, NSValue(cgPoint: point), .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            queue.add(toast)
        } else {
            showToast(toast, duration: duration, point: point)
        }
    }
    
    // MARK: - Hide Toast Methods
    func hideAllToasts() {
        queue.removeAllObjects()
        
        if let activeToast = objc_getAssociatedObject(self, &ToastKeys.activeToast) as? UIView {
            hideToast(activeToast)
        }
    }
    
    // MARK: - Activity Methods
    func makeToastActivity(_ position: ToastPosition) {
        // sanity
        guard let _ = objc_getAssociatedObject(self, &ToastKeys.activityView) as? UIView else { return }
        
        let toast = createToastActivityView()
        let point = position.centerPoint(forToast: toast, inSuperview: self)
        makeToastActivity(toast, point: point)
    }
    func makeToastActivity(_ point: CGPoint) {
        // sanity
        guard let _ = objc_getAssociatedObject(self, &ToastKeys.activityView) as? UIView else { return }
        
        let toast = createToastActivityView()
        makeToastActivity(toast, point: point)
    }
    func hideToastActivity() {
        if let toast = objc_getAssociatedObject(self, &ToastKeys.activityView) as? UIView {
            UIView.animate(withDuration: ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                toast.alpha = 0.0
            }) { _ in
                toast.removeFromSuperview()
                objc_setAssociatedObject(self, &ToastKeys.activityView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                SupportDefaults.setToastStatus(flag: false)
            }
        }
    }
    
    // MARK: - Private Activity Methods
    private func makeToastActivity(_ toast: UIView, point: CGPoint) {
        toast.alpha = 0.0
        toast.center = point
        
        objc_setAssociatedObject(self, &ToastKeys.activityView, toast, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        self.addSubview(toast)
        
        UIView.animate(withDuration: ToastManager.shared.style.fadeDuration, delay: 0.0, options: .curveEaseOut, animations: {
            toast.alpha = 1.0
        })
    }
    
    private func createToastActivityView() -> UIView {
        let style = ToastManager.shared.style
        
        let activityView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: style.activitySize.width, height: style.activitySize.height))
        activityView.backgroundColor = style.backgroundColor
        activityView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        activityView.layer.cornerRadius = style.cornerRadius
        
        if style.displayShadow {
            activityView.layer.shadowColor = style.shadowColor.cgColor
            activityView.layer.shadowOpacity = style.shadowOpacity
            activityView.layer.shadowRadius = style.shadowRadius
            activityView.layer.shadowOffset = style.shadowOffset
        }
        
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.center = CGPoint(x: activityView.bounds.size.width / 2.0, y: activityView.bounds.size.height / 2.0)
        activityView.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
        
        return activityView
    }
    
    // MARK: - Private Show/Hide Methods
    private func showToast(_ toast: UIView, duration: TimeInterval, point: CGPoint) {
        toast.center = point
        toast.alpha = 0.0
        
        if ToastManager.shared.isTapToDismissEnabled {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(UIView.handleToastTapped(_:)))
            toast.addGestureRecognizer(recognizer)
            toast.isUserInteractionEnabled = true
            toast.isExclusiveTouch = true
        }
        
        objc_setAssociatedObject(self, &ToastKeys.activeToast, toast, .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.addSubview(toast)
        
        UIView.animate(withDuration: ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            toast.alpha = 1.0
        }) { _ in
            let timer = Timer(timeInterval: duration, target: self, selector: #selector(UIView.toastTimerDidFinish(_:)), userInfo: toast, repeats: false)
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
            objc_setAssociatedObject(toast, &ToastKeys.timer, timer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private func hideToast(_ toast: UIView) {
        hideToast(toast, fromTap: false)
    }
    
    private func hideToast(_ toast: UIView, fromTap: Bool) {
        
        UIView.animate(withDuration: ToastManager.shared.style.fadeDuration, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
            toast.alpha = 0.0
        }) { _ in
            toast.removeFromSuperview()
            SupportDefaults.setToastStatus(flag: false)
            objc_setAssociatedObject(self, &ToastKeys.activeToast, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            if let wrapper = objc_getAssociatedObject(toast, &ToastKeys.completion) as? ToastCompletionWrapper, let completion = wrapper.completion {
                completion(fromTap)
            }
            
            if let nextToast = self.queue.firstObject as? UIView, let duration = objc_getAssociatedObject(nextToast, &ToastKeys.duration) as? NSNumber, let point = objc_getAssociatedObject(nextToast, &ToastKeys.point) as? NSValue {
                self.queue.removeObject(at: 0)
                self.showToast(nextToast, duration: duration.doubleValue, point: point.cgPointValue)
            }
        }
    }
    
    // MARK: - Events
    @objc func handleToastTapped(_ recognizer: UITapGestureRecognizer) {
        guard let toast = recognizer.view, let timer = objc_getAssociatedObject(toast, &ToastKeys.timer) as? Timer else { return }
        timer.invalidate()
        hideToast(toast, fromTap: true)
    }
    
    @objc func toastTimerDidFinish(_ timer: Timer) {
        guard let toast = timer.userInfo as? UIView else { return }
        hideToast(toast)
        SupportDefaults.setToastStatus(flag: false)
    }
    
    // MARK: - Toast Construction
    func toastViewForMessage(_ message: String?, title: String?, image: UIImage?, style: ToastStyle) throws -> UIView {
        // sanity
        guard message != nil || title != nil || image != nil else {
            throw ToastError.insufficientData
        }
        
        var messageLabel: UILabel?
        var titleLabel: UILabel?
        var imageView: UIImageView?
        
        let wrapperView = UIView()
        wrapperView.backgroundColor = style.backgroundColor
        wrapperView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        wrapperView.layer.cornerRadius = style.cornerRadius
        
        
        if style.displayShadow {
            wrapperView.layer.shadowColor = UIColor.black.cgColor
            wrapperView.layer.shadowOpacity = style.shadowOpacity
            wrapperView.layer.shadowRadius = style.shadowRadius
            wrapperView.layer.shadowOffset = style.shadowOffset
        }
        
        if let image = image {
            imageView = UIImageView(image: image)
            imageView?.contentMode = .scaleAspectFit
            imageView?.frame = CGRect(x: style.horizontalPadding, y: style.verticalPadding, width: style.imageSize.width, height: style.imageSize.height)
        }
        
        var imageRect = CGRect.zero
        
        if let imageView = imageView {
            imageRect.origin.x = style.horizontalPadding
            imageRect.origin.y = style.verticalPadding
            imageRect.size.width = imageView.bounds.size.width
            imageRect.size.height = imageView.bounds.size.height
        }
        
        if let title = title {
            titleLabel = UILabel()
            titleLabel?.numberOfLines = style.titleNumberOfLines
            titleLabel?.font = style.titleFont
            titleLabel?.textAlignment = style.titleAlignment
            titleLabel?.lineBreakMode = .byWordWrapping
            titleLabel?.textColor = style.titleColor
            titleLabel?.backgroundColor = UIColor.clear
            titleLabel?.text = title;
            
            let maxTitleSize = CGSize(width: (self.bounds.size.width * style.maxWidthPercentage) - imageRect.size.width, height: self.bounds.size.height * style.maxHeightPercentage)
            let titleSize = titleLabel?.sizeThatFits(maxTitleSize)
            if let titleSize = titleSize {
                titleLabel?.frame = CGRect(x: 0.0, y: 0.0, width: titleSize.width, height: titleSize.height)
            }
        }
        
        if let message = message {
            messageLabel = UILabel()
            messageLabel?.text = message
            messageLabel?.numberOfLines = style.messageNumberOfLines
            messageLabel?.font = style.messageFont
            messageLabel?.textAlignment = style.messageAlignment
            messageLabel?.lineBreakMode = .byTruncatingTail;
            messageLabel?.textColor = style.messageColor
            messageLabel?.backgroundColor = UIColor.clear
            
            let maxMessageSize = CGSize(width: (self.bounds.size.width * style.maxWidthPercentage) - imageRect.size.width, height: self.bounds.size.height * style.maxHeightPercentage)
            let messageSize = messageLabel?.sizeThatFits(maxMessageSize)
            if let messageSize = messageSize {
                let actualWidth = min(messageSize.width, maxMessageSize.width)
                let actualHeight = min(messageSize.height, maxMessageSize.height)
                messageLabel?.frame = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
            }
        }
        
        var titleRect = CGRect.zero
        if let titleLabel = titleLabel {
            titleRect.origin.x = imageRect.origin.x + imageRect.size.width + style.horizontalPadding
            titleRect.origin.y = style.verticalPadding
            titleRect.size.width = titleLabel.bounds.size.width
            titleRect.size.height = titleLabel.bounds.size.height
        }
        
        var messageRect = CGRect.zero
        if let messageLabel = messageLabel {
            messageRect.origin.x = imageRect.origin.x + imageRect.size.width + style.horizontalPadding
            messageRect.origin.y = titleRect.origin.y + titleRect.size.height + style.verticalPadding
            messageRect.size.width = messageLabel.bounds.size.width
            messageRect.size.height = messageLabel.bounds.size.height
        }
        
        let longerWidth = max(titleRect.size.width, messageRect.size.width)
        let longerX = max(titleRect.origin.x, messageRect.origin.x)
        let wrapperWidth = max((imageRect.size.width + (style.horizontalPadding * 2.0)), (longerX + longerWidth + style.horizontalPadding))
        let wrapperHeight = max((messageRect.origin.y + messageRect.size.height + style.verticalPadding), (imageRect.size.height + (style.verticalPadding * 2.0)))
        wrapperView.frame = CGRect(x: 0.0, y: 0.0, width: wrapperWidth, height: wrapperHeight)
        
        if let titleLabel = titleLabel {
            titleLabel.frame = titleRect
            wrapperView.addSubview(titleLabel)
        }
        if let messageLabel = messageLabel {
            messageLabel.frame = messageRect
            wrapperView.addSubview(messageLabel)
        }
        if let imageView = imageView {
            wrapperView.addSubview(imageView)
        }
        return wrapperView
        
    }
    
}

// MARK: - Toast Style

public struct ToastStyle {
    
    public init() {}
    public var backgroundColor = UIColor.black.withAlphaComponent(0.8)
    public var titleColor = UIColor.white
    public var messageColor = UIColor.white
    public var maxWidthPercentage: CGFloat = 0.8 {
        didSet {
            maxWidthPercentage = max(min(maxWidthPercentage, 1.0), 0.0)
        }
    }
    
    public var maxHeightPercentage: CGFloat = 0.8 {
        didSet {
            maxHeightPercentage = max(min(maxHeightPercentage, 1.0), 0.0)
        }
    }
    
    public var horizontalPadding: CGFloat = 10.0
    public var verticalPadding: CGFloat = 10.0
    public var cornerRadius: CGFloat = 10.0;
    public var titleFont = UIFont.boldSystemFont(ofSize: 16.0)
    public var messageFont = UIFont.systemFont(ofSize: 16.0)
    public var titleAlignment = NSTextAlignment.left
    public var messageAlignment = NSTextAlignment.left
    public var titleNumberOfLines = 0
    public var messageNumberOfLines = 0
    public var displayShadow = false
    public var shadowColor = UIColor.black
    public var shadowOpacity: Float = 0.8 {
        didSet {
            shadowOpacity = max(min(shadowOpacity, 1.0), 0.0)
        }
    }
    public var shadowRadius: CGFloat = 6.0
    public var shadowOffset = CGSize(width: 4.0, height: 4.0)
    public var imageSize = CGSize(width: 80.0, height: 80.0)
    public var activitySize = CGSize(width: 100.0, height: 100.0)
    public var fadeDuration: TimeInterval = 0.2
}

// MARK: - Toast Manager
public class ToastManager {
    public static let shared = ToastManager()
    public var style = ToastStyle()
    public var isTapToDismissEnabled = true
    public var isQueueEnabled = true
    public var duration: TimeInterval = 3.0
    public var position = ToastPosition.bottom
}

// MARK: - ToastPosition
public enum ToastPosition {
    case top
    case center
    case bottom
    
    fileprivate func centerPoint(forToast toast: UIView, inSuperview superview: UIView) -> CGPoint {
        let padding: CGFloat = ToastManager.shared.style.verticalPadding
        
        switch self {
        case .top:
            return CGPoint(x: superview.bounds.size.width / 2.0, y: (toast.frame.size.height / 2.0) + padding)
        case .center:
            return CGPoint(x: superview.bounds.size.width / 2.0, y: superview.bounds.size.height / 2.0)
        case .bottom:
            return CGPoint(x: superview.bounds.size.width / 2.0, y: (superview.bounds.size.height - (toast.frame.size.height / 2.0)) - padding)
        }
    }
}




class SupportDefaults: NSObject {
    
       class func setToastStatus(flag: Bool) -> Void{
           UserDefaults.standard.set(flag, forKey: "toastStatus")
           UserDefaults.standard.synchronize()
       }
       class func getToastStatus() -> Bool {
           return UserDefaults.standard.bool(forKey: "toastStatus")
       }
    
}



//extension UIViewController {
//
//    // toastMessage
//    func displayToast(_ message : String) {
//        DispatchQueue.main.async {
//           //constant .add//KEY_WINDOW
//            if let KEY_WINDOW = UIWindow.key {
//                KEY_WINDOW.makeToast(message)
//            }
//        }
//    }
//
//}

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
