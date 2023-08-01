//
//  FileExplorerIPFSApp.swift
//  FileExplorerIPFS
//
//  Created by Debasish Nandi on 07/06/23.
//

import SwiftUI
import os
import FileProvider


class FileProvide {
    var identifier: NSFileProviderDomainIdentifier!
    var domain: NSFileProviderDomain!
    var providerConnection: ProviderConnection!
    
    init() {
        identifier = NSFileProviderDomainIdentifier(rawValue: "somevalueforipfsexplorer")
        domain = NSFileProviderDomain(identifier: identifier, displayName: "IPFS")
    }
    
    func endCydrive () {
        NSFileProviderManager.remove(domain) {error in
            print("Error : \(String(describing: error))")
            guard let error = error else {
                return
            }

            NSLog(error.localizedDescription)
        }
    }
    
    func applicationDidFinishLaunching() {
        os_log("application Started for FileProvider IPFS")
        NSFileProviderManager.add(domain) { error in
            print("Error : \(String(describing: error))")
            guard let error = error else {
                return
            }

            NSLog(error.localizedDescription)
        }
        
        providerConnection = ProviderConnection(domain: domain)
        providerConnection.resume()
    }
    
    func evictRoot(filepath:String) {
        print("CALLINGGG~~~ ", filepath)
        ProviderConnection(domain: domain).evictionFolder(filepath: filepath)
    }
    
    func RefreshRoot(filepath:String) {
//        endCydrive()
//        applicationDidFinishLaunching()
        print("CALLINGGG~~~ ", filepath)
        ProviderConnection(domain: domain).refreshFolder(filepath: filepath)
    }
}


@main
struct FileExplorerIPFSApp:App {
//    static func main() {
//        // Your code logic here, without the UI
//        // For example, you can call functions or start background tasks
//        var _: () = FileProvide().endCydrive()
//    }
    
    var body: some Scene {

        WindowGroup {
            ContentView()
        }
    }
}
