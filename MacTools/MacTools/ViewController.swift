//
//  ViewController.swift
//  MacTools
//
//  Created by HahaSU on 2021/9/17.
//

import Cocoa
import IOKit
import IOKit.usb

class ViewController: NSViewController {
    
    private var usbWatcher: USBWatcher?
    @IBOutlet var textView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        usbWatcher = USBWatcher(delegate: self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
}

extension ViewController: USBWatcherDelegate {
    func deviceAdded(_ device: io_object_t) {
        if let array = TerminalCmds.getUSBDeviceJson() as? [[String:Any]] {
            textView.string = array.description
        }
    }
    
    func deviceRemoved(_ device: io_object_t) {
        if let array = TerminalCmds.getUSBDeviceJson() as? [[String:Any]] {
            textView.string = array.description
        }
    }
}
