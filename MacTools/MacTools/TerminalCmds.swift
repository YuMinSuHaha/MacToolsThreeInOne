//
//  TerminalCmds.swift
//  MacTools
//
//  Created by HahaSU on 2021/9/17.
//

import Foundation

class TerminalCmds {
    
    static func getUSBDeviceJson() -> Array<Any>? {
        let data = processIn(args: ["system_profiler", "-xml", "SPUSBDataType"])
        return XMLHandler().parseToArray(data: data)
    }
    
    static func processIn(args: [String]) -> Data {
        let outPipe = Pipe()
        let task = Process()
        
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        task.standardInput = Pipe()
        task.standardOutput = outPipe
        
        task.launch()
        task.waitUntilExit()
        
        return outPipe.fileHandleForReading.readDataToEndOfFile()
    }
    
    static func processInOut(argsIn: [String], argsOut: [String]) -> Data {
        let pipe = Pipe()

        let echo = Process()
        echo.launchPath = "/usr/bin/env"
        echo.arguments = argsIn
        echo.standardOutput = pipe

        let grep = Process()
        grep.launchPath = "/usr/bin/env"
        grep.arguments = argsOut
        grep.standardInput = pipe

        let out = Pipe()
        grep.standardOutput = out

        echo.launch()
        grep.launch()
        grep.waitUntilExit()
        
        return out.fileHandleForReading.readDataToEndOfFile()
    }
}
