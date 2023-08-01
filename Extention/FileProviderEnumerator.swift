//
//  FileProviderEnumerator.swift
//  Extention
//
//  Created by Debasish Nandi on 07/06/23.
//

import FileProvider
import ipfs_api
import os

class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    private let enumeratedItemIdentifier: NSFileProviderItemIdentifier
    private let anchor = NSFileProviderSyncAnchor("an anchor".data(using: .utf8)!)
    private var retrys: UInt8 = 0
    
    init(enumeratedItemIdentifier: NSFileProviderItemIdentifier) {
        self.enumeratedItemIdentifier = enumeratedItemIdentifier
        super.init()
    }
    

#warning("implement this to update invalidation of enumerated changes")
    func invalidate() {
    }
    
    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        /* TODO:
         - inspect the page to determine whether this is an initial or a follow-up request
         
         If this is an enumerator for a directory, the root container or all directories:
         - perform a server request to fetch directory contents
         If this is an enumerator for the active set:
         - perform a server request to update your local database
         - fetch the active set from your local database
         
         - inform the observer about the items returned by the server (possibly multiple times)
         - inform the observer that you are finished with this page
         */
        
        
        Task{
            do {
                var filepath:String = ""
                var items: [Item] = []
                
                if enumeratedItemIdentifier != .rootContainer && enumeratedItemIdentifier != .trashContainer && enumeratedItemIdentifier != .workingSet{
                    filepath = enumeratedItemIdentifier.rawValue
                }
                
                filepath = URL.toIPFSPath(path: filepath)
                
                let fileslist = try await FilesList(filepath: filepath)
                
                guard let list = fileslist.Entries else {
                    observer.didEnumerate(items)
                    observer.finishEnumerating(upTo: nil)
                    return
                }
                
                if enumeratedItemIdentifier != .rootContainer && enumeratedItemIdentifier != .trashContainer && enumeratedItemIdentifier != .workingSet{
                    
                    list.forEach { element in
                        var e = element
                        
                        let fpath = URL.toItemIdentifier(path: enumeratedItemIdentifier.rawValue+"/"+element.Name)
                        e.Name = URL.toItemIdentifier(path: enumeratedItemIdentifier.rawValue+"/"+element.Name)
                        
                        items.append(Item(fileItem: e, parentItem: enumeratedItemIdentifier, filePath: fpath))
                    }
                } else {
                    list.forEach { element in
                        
                        let fpath = URL.toItemIdentifier(path: enumeratedItemIdentifier.rawValue+"/"+element.Name)
                        items.append(Item(fileItem: element, parentItem: enumeratedItemIdentifier, filePath: fpath))
                    }
                }
                
                observer.didEnumerate(items)
                observer.finishEnumerating(upTo: nil)
                
            } catch {
                print(error)
            }
        }
    }
    
    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        /* TODO:
         - query the server for updates since the passed-in sync anchor
         
         If this is an enumerator for the active set:
         - note the changes in your local database
         
         - inform the observer about item deletions and updates (modifications + insertions)
         - inform the observer when you have finished enumerating up to a subsequent sync anchor
         */
        Task{
            var filepath:String = ""
            var items: [Item] = []
            
            if enumeratedItemIdentifier != .rootContainer && enumeratedItemIdentifier != .trashContainer && enumeratedItemIdentifier != .workingSet{
                filepath = enumeratedItemIdentifier.rawValue
            }
            
            let itemcontents = try await getFilesListInPathRecursively(ipfspath: filepath)
            items.append(contentsOf: itemcontents)
  
            observer.didUpdate(items)
            observer.finishEnumeratingChanges(upTo: NSFileProviderSyncAnchor("response.rank".data(using: .utf8)!), moreComing: false)
        }
    }
    
    private func getFilesListInPathRecursively(ipfspath:String) async throws -> [Item] {
        var items: [Item] = []
        
        let filepath = URL.toIPFSPath(path: ipfspath)
        
        let fileslist = try await FilesList(filepath: filepath)
        
        guard let list = fileslist.Entries else {
            return items
        }
        
        if filepath != "/"{
            
            for element in list{
                var e = element
                let fpath = URL.toItemIdentifier(path: filepath+"/"+element.Name)
                e.Name = fpath
                
                let parent = getParentIdentifier(of: fpath)
                
                let item = Item(fileItem: e, parentItem: parent)
                items.append(item)
                
                if item.contentType == .folder {
                    let newitems = try await getFilesListInPathRecursively(ipfspath: item.itemIdentifier.rawValue)
                    items.append(contentsOf: newitems)
                }
            }
        } else {
            for element in list{
                let fpath = URL.toItemIdentifier(path: "/"+element.Name)
                
                let item = Item(fileItem: element, parentItem: enumeratedItemIdentifier, filePath: fpath)
                items.append(item)
                
                if item.contentType == .folder {
                    let newitems = try await getFilesListInPathRecursively(ipfspath: item.itemIdentifier.rawValue)
                    items.append(contentsOf: newitems)
                }
            }
        }
        
        return items
    }
    
    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        completionHandler(anchor)
    }
    
    func getParentIdentifier(of filePath:String) -> NSFileProviderItemIdentifier{
        let parrawid = filePath.components(separatedBy: "/").dropLast().joined(separator: "/")
        
        var parentIdentifier = NSFileProviderItemIdentifier(parrawid)
        
        if parrawid == "" {
            parentIdentifier = .rootContainer
        }
        
        return parentIdentifier
    }
}

class WorkingSetEnumerator: FileProviderEnumerator {
    init() {
        // Enumerate everything from the root, recursively.
        super.init(enumeratedItemIdentifier: .rootContainer)
    }
}
