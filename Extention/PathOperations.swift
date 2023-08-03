//
//  PathOperations.swift
//  FileExplorerIPFS
//
//  Created by Debasish Nandi on 24/07/23.
//

import Foundation


extension URL {
    public static func toItemIdentifier(string:String) -> String {
//        var path = toPathWithoutEmail(path: string)
        
        let splitPath = string.split(separator: "/")

        return "/"+splitPath.joined(separator: "/")
    }
    
    public static func toIPFSPath(path:String) -> String {
        let splitPath = path.split(separator: "/")

        return "/"+splitPath.joined(separator: "/")
    }
    
    public static func toIPFSPathForOprations(path:String) -> String {
        let splitPath = path.split(separator: "/")
        
        if splitPath.count == 0 {
            return "/"
        }
        
        if URL.isValidEmailAddress(String(splitPath[0])) {
            return "/"+splitPath.joined(separator: "/")
        }

        return "/debasish.nandi-intl@cylogic.com/"+splitPath.joined(separator: "/")
    }
    
    public static func toPathWithoutEmail(path:String) -> String {
        let splitPath = path.split(separator: "/")

        if splitPath.count != 0 && URL.isValidEmailAddress(String(splitPath[0])) {
            var pwomail = splitPath.dropFirst()
            return "/"+pwomail.joined(separator: "/")
        }
        
        return "/"+splitPath.joined(separator: "/")
    }
    
    
    public static func isValidEmailAddress(_ emailpath: String) -> Bool {
        let splitPath = emailpath.split(separator: "/")
        
        if splitPath.count != 1 {
            return false
        }
        
        let pathWithEmail = String(splitPath[0])
        
        var returnValue = true
        let emailRegEx = "[A-Z0-9a-z.-_]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
        
        do {
            let regex = try NSRegularExpression(pattern: emailRegEx)
            let nsString = pathWithEmail as NSString
            let results = regex.matches(in: pathWithEmail, range: NSRange(location: 0, length: nsString.length))
            
            if results.count == 0
            {
                returnValue = false
            }
            
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            returnValue = false
        }
        
        return  returnValue
    }
}
