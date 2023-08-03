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
    
    public static var ContentMap:[String:CyItem] = [:]
    
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
                var items: [CyItem] = []
                
                if enumeratedItemIdentifier != .rootContainer && enumeratedItemIdentifier != .trashContainer && enumeratedItemIdentifier != .workingSet{
                    filepath = enumeratedItemIdentifier.rawValue
                }
                
                filepath = URL.toIPFSPathForOprations(path: filepath)
                
                let fileslist = try await FilesLswsh(filepath: filepath)
                
                guard let list = fileslist.Entries else {
                    observer.didEnumerate(items)
                    observer.finishEnumerating(upTo: nil)
                    return
                }
                
                if enumeratedItemIdentifier != .rootContainer && enumeratedItemIdentifier != .trashContainer && enumeratedItemIdentifier != .workingSet && !URL.isValidEmailAddress(filepath){
                    
                    list.forEach { element in
                        var e = element
                        
                        let fpath = URL.toItemIdentifier(string: enumeratedItemIdentifier.rawValue+"/"+element.Name)
                        e.Name = fpath
                        
                        let item = CyItem(fileItem: e, parentItem: enumeratedItemIdentifier, filePath: fpath)
                        FileProviderEnumerator.ContentMap[fpath] = item
                        
                        items.append(item)
                    }
                } else {
                    for element in list {
                        let fpath = URL.toItemIdentifier(string: "/"+element.Name)
                        
                        if URL.isValidEmailAddress(fpath) {
                            
                            let allItems = try await getFilesListInPath(ipfspath: fpath)
                            
                            items.append(contentsOf: allItems)
                        } else {
                            
                            let item = CyItem(fileItem: element, parentItem: enumeratedItemIdentifier, filePath: fpath)
                            FileProviderEnumerator.ContentMap[fpath] = item
                            
                            items.append(item)
                        }
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
        observer.finishEnumeratingChanges(upTo: NSFileProviderSyncAnchor("response.rank".data(using: .utf8)!), moreComing: false)
    }
    
//    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
//        /* TODO:
//         - query the server for updates since the passed-in sync anchor
//
//         If this is an enumerator for the active set:
//         - note the changes in your local database
//
//         - inform the observer about item deletions and updates (modifications + insertions)
//         - inform the observer when you have finished enumerating up to a subsequent sync anchor
//         */
//        Task{
//            var filepath:String = ""
//            var items: [Item] = []
//
//            if enumeratedItemIdentifier != .rootContainer && enumeratedItemIdentifier != .trashContainer && enumeratedItemIdentifier != .workingSet && URL.isValidEmailAddress(enumeratedItemIdentifier.rawValue){
//                filepath = enumeratedItemIdentifier.rawValue
//            }
//
//            let itemcontents = try await getFilesListInPathRecursively(ipfspath: filepath)
//            items.append(contentsOf: itemcontents)
//
//            observer.didUpdate(items)
//            observer.finishEnumeratingChanges(upTo: NSFileProviderSyncAnchor("response.rank".data(using: .utf8)!), moreComing: false)
//        }
//    }
    
    private func getFilesListInPath(ipfspath:String) async throws -> [CyItem] {
        var items: [CyItem] = []
        
        let filepath = URL.toIPFSPath(path: ipfspath)
        
        let fileslist = try await FilesLswsh(filepath: filepath)
        
        guard let list = fileslist.Entries else {
            return items
        }
        
        if !URL.isValidEmailAddress(filepath){
            for element in list{
                var e = element
                let fpath = URL.toItemIdentifier(string: filepath+"/"+element.Name)
                e.Name = fpath
                
                let parent = getParentIdentifier(of: fpath)
                
                let item = CyItem(fileItem: e, parentItem: parent, filePath: fpath)
                FileProviderEnumerator.ContentMap[fpath] = item

                items.append(item)

            }
        } else {
            for element in list{
                let fpath = URL.toItemIdentifier(string: "/"+element.Name)
                
                let item = CyItem(fileItem: element, parentItem: enumeratedItemIdentifier, filePath: fpath)
                FileProviderEnumerator.ContentMap[fpath] = item
                
                items.append(item)
            }
        }
        
        return items
    }
    
    private func getFilesListInPathRecursively(ipfspath:String) async throws -> [CyItem] {
        var items: [CyItem] = []
        
        let filepath = URL.toIPFSPath(path: ipfspath)
        
        let fileslist = try await FilesLswsh(filepath: filepath)
        
        guard let list = fileslist.Entries else {
            return items
        }
        
        if !URL.isValidEmailAddress(filepath){
            for element in list{
                var e = element
                let fpath = URL.toItemIdentifier(string: filepath+"/"+element.Name)
                e.Name = fpath
                
                let parent = getParentIdentifier(of: fpath)
                
                let item = CyItem(fileItem: e, parentItem: parent)
                items.append(item)
                
                if item.contentType == .folder {
                    let newitems = try await getFilesListInPathRecursively(ipfspath: item.itemIdentifier.rawValue)
                    items.append(contentsOf: newitems)
                }
            }
        } else {
            for element in list{
                let fpath = URL.toItemIdentifier(string: "/"+element.Name)
                
                let item = CyItem(fileItem: element, parentItem: enumeratedItemIdentifier, filePath: fpath)
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
        var parrawid = filePath.components(separatedBy: "/").dropLast().joined(separator: "/")
        
        parrawid = URL.toItemIdentifier(string: parrawid)
        
        var parentIdentifier = NSFileProviderItemIdentifier("/"+parrawid)
        
        if parrawid == "/" || URL.isValidEmailAddress(parrawid){
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
