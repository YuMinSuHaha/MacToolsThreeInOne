//
//  USBWatcher.swift
//  MacTools
//
//  Created by HahaSU on 2021/9/22.
//

import Foundation

protocol USBWatcherDelegate: AnyObject {
    /// Called on the main thread when a device is connected.
    func deviceAdded(_ device: io_object_t)
    
    /// Called on the main thread when a device is disconnected.
    func deviceRemoved(_ device: io_object_t)
}

class USBWatcher {
    fileprivate weak var delegate: USBWatcherDelegate?
    fileprivate let notificationPort = IONotificationPortCreate(kIOMasterPortDefault)
    fileprivate var addedIterator: io_iterator_t = 0
    fileprivate var removedIterator: io_iterator_t = 0
    
    public init(delegate: USBWatcherDelegate) {
        self.delegate = delegate
        
        func handleNotification(_ instance: UnsafeMutableRawPointer?, _ iterator: io_iterator_t) {
            let watcher = Unmanaged<USBWatcher>.fromOpaque(instance!).takeUnretainedValue()
            let handler: ((io_iterator_t) -> Void)?
            switch iterator {
            case watcher.addedIterator:
                handler = watcher.delegate?.deviceAdded
            case watcher.removedIterator:
                handler = watcher.delegate?.deviceRemoved
            default: assertionFailure("received unexpected IOIterator"); return
            }
            while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
                handler?(device)
                IOObjectRelease(device)
            }
        }
        
        let query = IOServiceMatching(kIOUSBDeviceClassName)
        let opaqueSelf = Unmanaged.passUnretained(self).toOpaque()
        
        // Watch for connected devices.
        IOServiceAddMatchingNotification(
            notificationPort, kIOMatchedNotification, query,
            handleNotification, opaqueSelf, &addedIterator)
        
        handleNotification(opaqueSelf, addedIterator)
        
        // Watch for disconnected devices.
        IOServiceAddMatchingNotification(
            notificationPort, kIOTerminatedNotification, query,
            handleNotification, opaqueSelf, &removedIterator)
        
        handleNotification(opaqueSelf, removedIterator)
        
        // Add the notification to the main run loop to receive future updates.
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue(),
            .commonModes)
    }
    
    deinit {
        IOObjectRelease(addedIterator)
        IOObjectRelease(removedIterator)
        IONotificationPortDestroy(notificationPort)
    }
}

extension io_object_t {
    /// - Returns: The device's name.
    func name() -> String? {
        let buf = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        defer { buf.deallocate(capacity: 1) }
        return buf.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<io_name_t>.size) {
            if IORegistryEntryGetName(self, $0) == KERN_SUCCESS {
                return String(cString: $0)
            }
            return nil
        }
    }
}


