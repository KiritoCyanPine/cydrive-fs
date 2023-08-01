//
//  PathOperations.swift
//  FileExplorerIPFS
//
//  Created by Debasish Nandi on 24/07/23.
//

import Foundation


extension URL {
    public static func toItemIdentifier(path:String) -> String {
        let splitPath = path.split(separator: "/")

        return splitPath.joined(separator: "/")
    }
    
    public static func toIPFSPath(path:String) -> String {
        let splitPath = path.split(separator: "/")

        return "/"+splitPath.joined(separator: "/")
    }
}
