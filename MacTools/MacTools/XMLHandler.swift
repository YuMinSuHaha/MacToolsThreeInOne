//
//  XMLParser.swift
//  MacTools
//
//  Created by HahaSU on 2021/9/17.
//

import Foundation

class XMLHandler: NSObject  {
    static let shared = XMLHandler()
    
    var stackList:[Any] = []
    var tempKey: String?
    var tempValue: String?
    var tempArray:[Any] = []
    var tempDic:[String:Any] = [:]
    
    func parseToArray(data: Data) -> [[String:Any]] {
        reset()
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return stackList.first as? [[String:Any]] ?? []
    }
    
    func parseToDict(data: Data) -> [String:Any] {
        reset()
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return stackList.first as? [String:Any] ?? [:]
    }
    
    private func reset() {
        stackList.removeAll()
    }
    
}

extension XMLHandler: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "dict" {
            tempDic.removeAll()
            stackList.append([String:Any]())
        } else if elementName == "array" {
            tempArray.removeAll()
            stackList.append([Any]())
        } else if elementName == "key" {
            tempKey = "key"
            stackList.append(tempKey)
        } else if elementName != "plist" {
            stackList.append(elementName)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let element = elementName.trimmingCharacters(in: .whitespacesAndNewlines)
        if element == "dict" {
            let dictionary = stackList.popLast() as? [String:Any] ?? [:]
            if (stackList.last as? String) != nil {
                let key = stackList.popLast() as? String ?? "key"
                var dic = stackList.popLast() as? [String:Any] ?? [:]
                dic[key] = dictionary
                stackList.append(dic)
            } else if (stackList.last as? [Any]) != nil {
                var arr = stackList.popLast() as? [Any] ?? []
                arr.append(dictionary)
                stackList.append(arr)
            } else if stackList.count == 0 {
                stackList.append(dictionary)
            }
        } else if element == "array" {
            let array = stackList.popLast() as? [Any] ?? []
            if (stackList.last as? String) != nil {
                let key = stackList.popLast() as? String ?? "key"
                var dic = stackList.popLast() as? [String:Any] ?? [:]
                dic[key] = array
                stackList.append(dic)
            } else if (stackList.last as? [Any]) != nil {
                var arr = stackList.popLast() as? [Any] ?? []
                arr.append(array)
                stackList.append(arr)
            } else if stackList.count == 0  {
                stackList.append(array)
            }
        } else if element == "key" {
            var key = stackList.popLast() as? String
            key = tempValue
            stackList.append(key ?? "key")
        } else if element != "plist" && element.count > 0 {
            let _ = stackList.popLast()
            if (stackList.last as? String) != nil {
                let key = stackList.popLast() as? String ?? "key"
                var dic = stackList.popLast() as? [String:Any] ?? [:]
                dic[key] = tempValue
                stackList.append(dic)
            } else if (stackList.last as? [Any]) != nil {
                var arr = stackList.popLast() as? [Any] ?? []
                arr.append(tempValue ?? "")
                stackList.append(arr)
            }
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("XML parser error : \(parseError)")
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        tempValue = string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}
