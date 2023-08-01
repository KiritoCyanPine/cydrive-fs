//
//  FileProviderConnection.swift
//  ipfsFileProvider
//
//  Created by Debasish Nandi on 02/06/23.
//

import Foundation
import FileProvider
import os

class ProviderConnection{
    var  fileProviderManager: NSFileProviderManager
    let domain:NSFileProviderDomain
    
    init(domain: NSFileProviderDomain) {
        self.domain = domain
        fileProviderManager = NSFileProviderManager(for: self.domain)!
    }
    
    func resume() {
        let fileManager = FileManager.default
        
        fileProviderManager.getUserVisibleURL(for: NSFileProviderItemIdentifier.rootContainer) { url, error in
            guard error == nil else {
                os_log(.error, "An error occurred on user visible URL retrieval!")
                return
            }
            
            guard let url = url else {
                return
            }
            
            do{
                try fileManager.setAttributes([.posixPermissions: 0o444],ofItemAtPath: url.absoluteString)
            } catch {
                print("Error : ", error)
            }
            
            os_log("resume was called--- 2")
            
            fileManager.getFileProviderServicesForItem(at: url) { list, error in
                guard let services = list else {
                    os_log(.error, "No file provider service list provided by file manager for \(url)")
                    return
                }
                
                os_log("Received count of file provider services: \(services.count)")
                
                for (_, service) in services {
                    
                    os_log("Found service with name related to desired provider.")
                    
                    service.getFileProviderConnection { connection, error in
                        guard error == nil else {
                            os_log(.error, "Failed to get file provider connection: \(error!.localizedDescription)")
                            return
                        }
                        
                        guard let connection = connection else {
                            os_log(.error, "getFileProviderConnection did not provide any connection!")
                            return
                        }
                        
                        connection.resume()
                    }
                }
            }
        }
    }
    
    func evictionFolder(filepath:String) {
        Task {
            do {
                print("evicting Item", filepath)
                try await fileProviderManager.evictItem(identifier: NSFileProviderItemIdentifier(filepath))
            }catch {
                print ("Error: ",error)
            }
        }
    }
    
    func refreshFolder(filepath:String) {
        // try await fileProviderManager.reimportItems(below: NSFileProviderItemIdentifier(filepath))
        fileProviderManager.signalEnumerator(for: .workingSet,completionHandler: { ourError in
            if let ourError = ourError {
                print("notifyCallback: mount / unmount failed re-enumeration: \(ourError)")
            } else {
                print("notifyCallback: mount / unmount signalled re-enumeration; pending")
            }
        })
        
        print("maybe it was Evicted")
        
    }
    
}
