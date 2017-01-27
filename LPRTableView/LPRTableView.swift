//
//  LPRTableView.swift
//  LPRTableView
//
//  Objective-C code Copyright (c) 2013 Ben Vogelzang. All rights reserved.
//  Swift adaptation Copyright (c) 2014 Nicolas Gomollon. All rights reserved.
//

import UIKit

open class LPRTableView: UITableView {
    /// The object that acts as the delegate of the receiving table view.
    open weak var longPressReorderDelegate: LPRTableViewDelegate?
    fileprivate let longPressGestureRecognizer = UILongPressGestureRecognizer()
    fileprivate var initialIndexPath: IndexPath?
    fileprivate var currentLocationIndexPath: IndexPath?
    fileprivate var draggingView: UIImageView?
    fileprivate var scrollRate = 0.0
    fileprivate let animationDuration = TimeInterval(0.3)
    fileprivate var scrollDisplayLink: CADisplayLink?
    
    /**
    A Bool property that indicates whether long press to reorder is enabled.
    */
    open var longPressReorderEnabled: Bool {
        get {
            return longPressGestureRecognizer.isEnabled
        }
        set {
            longPressGestureRecognizer.isEnabled = newValue
        }
    }
    
    public convenience init()  {
        self.init(frame: CGRect.zero)
    }
    
    public override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        longPressGestureRecognizer.addTarget(self, action: #selector(LPRTableView.longPressGestureRecognized(_:)))
        addGestureRecognizer(longPressGestureRecognizer)
    }
}

extension LPRTableView {
    
    private func canMoveRowAtIndexPath(_ indexPath: IndexPath) -> Bool {
        return dataSource?.tableView?(self, canMoveRowAt: indexPath) ?? true
    }
    
    private func shouldMoveRowAtIndexPath(_ indexPath: IndexPath, forGestureRecognizer gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
        return longPressReorderDelegate?.tableView(self, shouldMoveRowAtIndexPath: indexPath, forGestureRecognizer: gestureRecognizer) ?? true
    }
    
    private func cancelGesture() {
        longPressGestureRecognizer.isEnabled = false
        longPressGestureRecognizer.isEnabled = true
    }
    
    internal func longPressGestureRecognized(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        let indexPath = indexPathForRow(at: location)
        
        guard isValidMovement(indexPath, gestureRecognizer: gestureRecognizer) else {
            cancelGesture()
            return
        }
        
        switch gestureRecognizer.state {
        case .began:
            // Started.
            longPressBegan(gestureRecognizer)
        case .changed:
            // Dragging.
            longPressChanged(gestureRecognizer)
            break
        case .ended:
            longPressEnded(gestureRecognizer)
            break
        default:
            break
        }
    }
    
    private func longPressBegan(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        guard let indexPath = indexPathForRow(at: location) else {
            return
        }
        guard var cell = cellForRow(at: indexPath) else {
            return
        }
        cell.setSelected(false, animated: false)
        cell.setHighlighted(false, animated: false)
        
        if draggingView == nil {
            // Create the view that will be dragged around the screen.
            if let draggingCell = longPressReorderDelegate?.tableView(self, draggingCell: cell, atIndexPath: indexPath) {
                cell = draggingCell
            }
            
            // Make an image from the pressed table view cell.
            UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, UIScreen.main.scale)
            cell.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            draggingView = UIImageView(image: image)
            
            guard let draggingView = draggingView else {
                // cannot come here
                return
            }
            
            addSubview(draggingView)
            let rect = rectForRow(at: indexPath)
            draggingView.frame = draggingView.bounds.offsetBy(dx: rect.origin.x, dy: rect.origin.y)
            
            longPressReorderDelegate?.tableView(self, willAppearDraggingView: draggingView, atIndexPath: indexPath)
            UIView.animate(withDuration: animationDuration, animations: { [unowned self] in
                // Add drop shadow to image and lower opacity.
                draggingView.layer.masksToBounds = false
                draggingView.layer.shadowColor = UIColor.black.cgColor
                draggingView.layer.shadowOffset = CGSize.zero
                draggingView.layer.shadowRadius = 4.0
                draggingView.layer.shadowOpacity = 0.7
                draggingView.layer.opacity = 0.85
                draggingView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                draggingView.center = CGPoint(x: self.center.x, y: location.y)
            }) 
        }
        
        cell.isHidden = true
        currentLocationIndexPath = indexPath
        initialIndexPath = indexPath
        
        // Enable scrolling for cell.
        scrollDisplayLink = CADisplayLink(target: self, selector: #selector(LPRTableView.scrollTableView(_:)))
        scrollDisplayLink?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    private func longPressChanged(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        if let draggingView = draggingView {
            // Update position of the drag view, but don't let it go past the top or the bottom too far.
            if location.y >= 0 && location.y <= contentSize.height + 50 {
                draggingView.center = CGPoint(x: center.x, y: location.y)
            }
        }
        var rect = bounds
        // Adjust rect for content inset, as we will use it below for calculating scroll zones.
        rect.size.height -= contentInset.top
        
        updateCurrentLocation(gestureRecognizer)
        
        // Tell us if we should scroll, and in which direction.
        let scrollZoneHeight = rect.size.height / 6.0
        let topScrollBeginning = contentOffset.y + contentInset.top  + scrollZoneHeight
        let bottomScrollBeginning = contentOffset.y + contentInset.top + rect.size.height - scrollZoneHeight
        
        if location.y >= bottomScrollBeginning {
            // We're in the bottom zone.
            scrollRate = Double(location.y - bottomScrollBeginning) / Double(scrollZoneHeight)
        } else if location.y <= topScrollBeginning {
            // We're in the top zone.
            scrollRate = Double(location.y - topScrollBeginning) / Double(scrollZoneHeight)
        } else {
            scrollRate = 0.0
        }
    }
    
    private func longPressEnded(_ gestureRecognizer: UILongPressGestureRecognizer) {
        // Remove scrolling CADisplayLink.
        scrollDisplayLink?.invalidate()
        scrollDisplayLink = nil
        scrollRate = 0.0
        
        guard let draggingView = draggingView, let currentLocationIndexPath = currentLocationIndexPath else {
            return
        }
        
        // Animate the drag view to the newly hovered cell.
        longPressReorderDelegate?.tableView(self, willDisappearDraggingView: draggingView, atIndexPath: currentLocationIndexPath)
        UIView.animate(withDuration: animationDuration,
            animations: { [unowned self] in
                let rect = self.rectForRow(at: currentLocationIndexPath)
                draggingView.transform = CGAffineTransform.identity
                draggingView.frame = draggingView.bounds.offsetBy(dx: rect.origin.x, dy: rect.origin.y)
            },
            completion: { [unowned self] _ in
                self.draggingView?.removeFromSuperview()
                if let indexPathsForVisibleRows = self.indexPathsForVisibleRows {
                    self.reloadRows(at: indexPathsForVisibleRows, with: .none)
                }
                self.currentLocationIndexPath = nil
                self.draggingView = nil
        })
    }
    
    private func isValidMovement(_ indexPath: IndexPath?, gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
        // Get out of here if the long press was not on a valid row or our table is empty or the dataSource tableView:canMoveRowAtIndexPath: doesn't allow moving the row.
        let numberOfRows = (0..<numberOfSections).reduce(0) { $0 + self.numberOfRows(inSection: $1) }
        guard numberOfRows > 0 else {
            // Table is empty
            return false
        }
        switch gestureRecognizer.state {
        case .began:
            if indexPath == nil || // Invalid row
                !canMoveRowAtIndexPath(indexPath!) || // Datasource decision
                !shouldMoveRowAtIndexPath(indexPath!, forGestureRecognizer: gestureRecognizer) { // For gesture value
                    return false
            }
        case .ended:
            if currentLocationIndexPath == nil {
                return false
            }
        default:
            break
        }
        return true
    }
    
    private func updateCurrentLocation(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        guard var indexPath = indexPathForRow(at: location) else {
            return
        }
        if let initialIndexPath = initialIndexPath {
            if let targetIndexPath = delegate?.tableView?(self, targetIndexPathForMoveFromRowAt: initialIndexPath, toProposedIndexPath: indexPath) {
                indexPath = targetIndexPath
            }
        }
        if let currentLocationIndexPath = currentLocationIndexPath {
            let oldHeight = rectForRow(at: currentLocationIndexPath).size.height
            let newHeight = rectForRow(at: indexPath).size.height
            
            
            let cell = cellForRow(at: indexPath)
            if indexPath != currentLocationIndexPath && gestureRecognizer.location(in: cell).y > (newHeight - oldHeight) && canMoveRowAtIndexPath(indexPath) {
                beginUpdates()
                moveRow(at: currentLocationIndexPath, to: indexPath)
                dataSource?.tableView?(self, moveRowAt: currentLocationIndexPath, to: indexPath)
                self.currentLocationIndexPath = indexPath
                endUpdates()
            }
        }
    }
    
    internal func scrollTableView(_ sender: CADisplayLink) {
        let location = longPressGestureRecognizer.location(in: self)
        guard location.x.isNaN || location.y.isNaN else {
            // Explicitly check for out-of-bound touch
            return
        }
        let offsetY = Double(contentOffset.y) + scrollRate * 10.0
        var newOffset = CGPoint(x: contentOffset.x, y: CGFloat(offsetY))
        
        if newOffset.y < -contentInset.top {
            newOffset.y = -contentInset.top
        } else if (contentSize.height + contentInset.bottom) < frame.size.height {
            newOffset = contentOffset
        } else if newOffset.y > (contentSize.height + contentInset.bottom - frame.size.height) {
            newOffset.y = contentSize.height + contentInset.bottom - frame.size.height
        }
        contentOffset = newOffset
        
        if let draggingView = draggingView {
            if location.y >= 0 && location.y <= (contentSize.height + 50) {
                draggingView.center = CGPoint(x: center.x, y: location.y)
            }
        }
        
        updateCurrentLocation(longPressGestureRecognizer)
    }
}
