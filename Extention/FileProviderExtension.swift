//
//  FileProviderExtension.swift
//  Extention
//
//  Created by Debasish Nandi on 07/06/23.
//

import FileProvider
import Foundation
import ipfs_api
import os.log

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

class FileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    let domain: NSFileProviderDomain
    static var manager: NSFileProviderManager? = nil
    
    let temporaryDirectoryURL: URL
    
    let logger = Logger(subsystem: "com.cylogic.FileExplorerIPFS", category: "Extention")
    
    required init(domain: NSFileProviderDomain) {
        self.domain = domain
        FileProviderExtension.manager = NSFileProviderManager(for: domain)!
        
        do {
            temporaryDirectoryURL = try FileProviderExtension.manager!.temporaryDirectoryURL()
        } catch {
            fatalError("failed to get temporary directory: \(error)")
        }
        
        super.init()
    }
    
    
    func invalidate() {
    }
    
    
    func item(for identifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) -> Progress {
        Task {
            if identifier == .rootContainer || identifier == .trashContainer || identifier == .workingSet {
                completionHandler(Item(identifier: identifier ), nil)
                return
            }
            
            if identifier.rawValue == "/" {
                completionHandler(Item(identifier: .rootContainer ), nil)
                return
            }
            
            let fpath = URL.toIPFSPath(path: identifier.rawValue)
            
            let ipfsItem = try await getIPFSFileDetails(inpath: fpath)
            
            completionHandler(ipfsItem, nil)
            return
        }
        
        return Progress()
    }
    
    func fetchContents(for itemIdentifier: NSFileProviderItemIdentifier, version requestedVersion: NSFileProviderItemVersion?, request: NSFileProviderRequest, completionHandler: @escaping (URL?, NSFileProviderItem?, Error?) -> Void) -> Progress {

        let filepath = URL.toIPFSPath(path: "/"+itemIdentifier.rawValue)
        let dataURL = self.makeTemporaryURL("fetchedContents")
        
        do {
            return try FilesReadDownload(filepath: filepath, file: dataURL) { err in
                if let error = err {
                    self.logger.error("❌ Error In FetchContents : FilesReadDownload,\(error)")
                }
                
                var _ = self.item(for: itemIdentifier, request: request) { itemOptional, errorOptional in
                    defer {
                        if let item = itemOptional {
                            self.evictItem(Item: item)
                        }
                    }
                    
                    completionHandler(dataURL, itemOptional, nil)
                }
            }
        } catch {
            self.logger.error("❌ Error In FetchContents : , \(error)")
            completionHandler(nil, nil, NSError.fileProviderErrorForNonExistentItem(withIdentifier: itemIdentifier))
            return Progress()
        }
    }
    
    func createItem(basedOn itemTemplate: NSFileProviderItem, fields: NSFileProviderItemFields, contents url: URL?, options: NSFileProviderCreateItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        
        guard let cType = itemTemplate.contentType else{
            completionHandler(itemTemplate, [],false,NSFileProviderError(NSFileProviderError.Code.noSuchItem))
            return Progress()
        }
        
        var filepath: String
        
        if itemTemplate.parentItemIdentifier == .rootContainer {
            filepath = "/"+itemTemplate.filename
        } else {
            filepath = itemTemplate.parentItemIdentifier.rawValue+"/"+itemTemplate.filename
        }
        
        let fpath = URL.toIPFSPath(path: filepath)
        
        switch cType{
        case .folder:
            Task{
                do {
                    try await FilesMkDir(filepath: fpath)
                    
                    let itemPath = URL.toItemIdentifier(path: fpath)
                    
                    let folder = File(Name: itemPath, Hash: "", Size: 0, type: 1)
                    
                    let parentIdentifier = getParentIdentifier(of: itemPath)
                    
                    let item = Item(fileItem: folder,parentItem: parentIdentifier)
                    
                    completionHandler(item, [], false, nil)
                } catch {
                    self.logger.error("❌ Error In CreateItem <FOLDER>: , \(error)")
                }
                
                return
            }
        default:
            do{
                let createProgress = try self.WriteToIPFSWithProgress(filePath: fpath, url: url,completion: { errorOptional in
                    if let error = errorOptional {
                        self.logger.error("❌ [createitem] Files stat failed with error \(error) for path \(fpath)")
                        completionHandler(nil, [], false, nil)
                        return
                    }
                    
                    Task{
                        let newitem = try await self.getIPFSFileDetails(inpath: fpath)
                        defer { self.evictItem(Item: newitem) }
                        
                        completionHandler(newitem, [], false, nil)
                    }
                })
                
                return createProgress
            } catch {
                self.logger.error("❌ Error In CreateItem <DEFAULT>: , \(error)")
            }
        }
        
        let mayExist = options.contains(NSFileProviderCreateItemOptions.mayAlreadyExist)
        if mayExist {
            completionHandler(nil, [], false, nil)
        }
        
        return Progress()
    }
    
    func modifyItem(_ item: NSFileProviderItem, baseVersion version: NSFileProviderItemVersion, changedFields: NSFileProviderItemFields, contents newContents: URL?, options: NSFileProviderModifyItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: an item was modified on disk, process the item's modification
        
        return self.item(for: item.itemIdentifier, request: request) { itemOptional, errorOptional in
            guard let prevItem = itemOptional else {
                return
            }
            
            if changedFields.contains(.filename) || changedFields.contains(.parentItemIdentifier){
                // TODO: implement files move for ``RENAME``
                
                var tempsrc = prevItem.itemIdentifier.rawValue
                var tempdst = item.parentItemIdentifier.rawValue + "/" + item.filename
                
                if item.parentItemIdentifier == .rootContainer{
                    tempsrc = prevItem.itemIdentifier.rawValue
                    tempdst = item.filename
                }
                
                let src = URL.toIPFSPath(path: tempsrc)
                let dst = URL.toIPFSPath(path: tempdst)
                
                Task{
                    do {
                        try await FilesMv(src: src, dst: dst) { errorOptional in
                            if let err = errorOptional {
                                self.logger.error("❌ Error In FilesMV for file src = \(src) :: dst = \(dst) , due to error = \(err)")
                                completionHandler(nil,[],false,err)
                                return
                            }
                        }
                        
                        let newitem = try await self.getIPFSFileDetails(inpath: dst)
                        
                        defer {
                                self.evictItem(Item: newitem)
                        }
                        
                        completionHandler(newitem, [], false, nil)
                    } catch {
                        self.logger.error("❌ Error In ReNaming  : , \(error)")
                        completionHandler(prevItem, [], false, nil)
                    }
                }
                
                return
            }
            
            if changedFields.contains(.contents) {
                // TODO: Upload the new file into the repo for ``EDIT/CONTENT CHANGE``
                var filepath: String
                
                if item.parentItemIdentifier == .rootContainer {
                    filepath = item.filename
                } else {
                    filepath = item.parentItemIdentifier.rawValue+"/"+item.filename
                }
                
                filepath = URL.toIPFSPath(path: filepath)
                
                guard let url = newContents else {
                    return
                }
                
                let fpath = filepath
                
                do{
                    var _ = try self.WriteToIPFSWithProgress(filePath: fpath, url: url, enableTruncate: true) { errorOptional in
                        if let error = errorOptional {
                            self.logger.error("❌ [createitem] Files stat failed with error \(error) for path \(fpath)")
                            return
                        }
                    }
                    
                    Task{
                        let newitem = try await  self.getIPFSFileDetails(inpath: fpath)
                        defer { self.evictItem(Item: newitem) }
                        
                        completionHandler(newitem, [], false, nil)
                    }
                    
                } catch {
                    self.logger.error("❌ Error In CreateItem <DEFAULT>: , \(error)")
                    completionHandler(prevItem, [], false, nil)
                }
                
                return
            }
            
            completionHandler(prevItem, [], false, nil)
        }
    }
    
    func deleteItem(identifier: NSFileProviderItemIdentifier, baseVersion version: NSFileProviderItemVersion, options: NSFileProviderDeleteItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (Error?) -> Void) -> Progress {
        // TODO: an item was deleted on disk, process the item's deletion
        
        return self.item(for: identifier, request: request) { itemOptional, errorOptional in
            if let error = errorOptional {
                completionHandler(error)
                return
            }
            
            guard let item = itemOptional else {
                completionHandler(ExtentionError.InvalidFileProviderItem)
                return
            }
            
            let fPath = URL.toIPFSPath(path: item.itemIdentifier.rawValue)
            
            do {
                try FilesRm(ipfspath: fPath) { errorOptional in
                    if let error = errorOptional {
                        completionHandler(error)
                        return
                    }
                }
                
                completionHandler(nil)
                
            } catch {
                self.logger.error("❌ Error In CreateItem <DEFAULT>: , \(error)")
                completionHandler(error)
            }
        }
    }
    
    func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest) throws -> NSFileProviderEnumerator {
        var container = containerItemIdentifier
        
        if container == .workingSet {
            return WorkingSetEnumerator()
        }
        
        if containerItemIdentifier == .rootContainer{
            container = NSFileProviderItemIdentifier("/")
        }
        
        return FileProviderEnumerator(enumeratedItemIdentifier: container)
    }
}
