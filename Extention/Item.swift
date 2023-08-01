//
//  FileProviderItem.swift
//  Extention
//
//  Created by Debasish Nandi on 07/06/23.
//

import FileProvider
import UniformTypeIdentifiers
import ipfs_api

class Item: NSObject, NSFileProviderItemProtocol {

    // TODO: implement an initializer to create an item from your extension's backing model
    // TODO: implement the accessors to return the values from your extension's backing model
    
    private let identifier: NSFileProviderItemIdentifier
    
    private var parentItem: NSFileProviderItemIdentifier?
    
    private let fileItemPath: String?
    
    var fileDetails: File?
    
    init(identifier: NSFileProviderItemIdentifier) {
        self.identifier = identifier
        self.fileItemPath = identifier.rawValue
    }
    
    init(fileItem: File) {
        self.identifier = NSFileProviderItemIdentifier(fileItem.Name)
        self.fileDetails = fileItem
        self.fileItemPath = self.identifier.rawValue
    }
    
    #warning("Item : create a better constructor")
    init(fileItem: File, parentItem:NSFileProviderItemIdentifier) {
        self.identifier = NSFileProviderItemIdentifier(fileItem.Name)
        self.parentItem = parentItem
        self.fileDetails = fileItem
        self.fileItemPath = fileItem.Name
    }
    
    #warning("Item : create a better constructor")
    init(fileItem: File, parentItem:NSFileProviderItemIdentifier, filePath: String) {
        self.identifier = NSFileProviderItemIdentifier(fileItem.Name)
        self.parentItem = parentItem
        self.fileDetails = fileItem
        self.fileItemPath = filePath
    }
    
    var FilePath: String? {
        return self.fileItemPath
    }
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        return identifier
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        return parentItem ?? .rootContainer
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        let result:NSFileProviderItemCapabilities = [
            .allowsReading,
            .allowsEvicting,
            .allowsWriting,
            .allowsRenaming,
            .allowsReparenting,
            .allowsAddingSubItems,
            .allowsDeleting,
            .allowsContentEnumerating,
        ]
        
        return result
    }
    
    var itemVersion: NSFileProviderItemVersion {
        NSFileProviderItemVersion(contentVersion: "a content version".data(using: .utf8)!, metadataVersion: "a metadata version".data(using: .utf8)!)
    }
    
    #warning("Item : add sharing status according to the Response")
    var isShared: Bool {
        return false
    }
    
#if os(macOS)
    @available(macOSApplicationExtension 13.0, *)
    var contentPolicy: NSFileProviderContentPolicy {
        return .downloadLazily
    }
#endif
    
    var filename: String {
        let name = identifier.rawValue
        guard let fname = name.components(separatedBy: "/").last else {
            return identifier.rawValue
        }
        
        return fname
    }
    
    var contentType: UTType {
        if identifier == NSFileProviderItemIdentifier.rootContainer || fileDetails?.Type == 1 {
            return .folder
        }
        
        return .item
    }
    
    var documentSize: NSNumber?{
        return fileDetails?.Size as? NSNumber
    }
    
    var creationDate: Date? {
        var dateComponents = DateComponents()
        dateComponents.year = 2023
        dateComponents.month = 7
        dateComponents.day = 25
        dateComponents.hour = 12
        dateComponents.minute = 30
        dateComponents.second = 0
        let calendar = Calendar.current

        // Create the date from the date components
        return calendar.date(from: dateComponents)
    }
    
    var contentModificationDate: Date? {
        // Set a date using DateComponents
        var dateComponents = DateComponents()
        dateComponents.year = 2023
        dateComponents.month = 7
        dateComponents.day = 25
        dateComponents.hour = 12
        dateComponents.minute = 30
        dateComponents.second = 0
        let calendar = Calendar.current

        // Create the date from the date components
        return calendar.date(from: dateComponents)
    }
}

class CyItem: NSObject, NSFileProviderItemProtocol {
    private let identifier: NSFileProviderItemIdentifier
    
    private var parentItem: NSFileProviderItemIdentifier?
    
    private let fileItemPath: String?
    
    var fileDetails: FileInfoWSh?
    
    init(identifier: NSFileProviderItemIdentifier) {
        self.identifier = identifier
        self.fileItemPath = identifier.rawValue
    }
    
    init(fileItem: FileInfoWSh) {
        self.identifier = NSFileProviderItemIdentifier(fileItem.Name)
        self.fileDetails = fileItem
        self.fileItemPath = self.identifier.rawValue
    }
    
    #warning("Item : create a better constructor")
    init(fileItem: FileInfoWSh, parentItem:NSFileProviderItemIdentifier) {
        self.identifier = NSFileProviderItemIdentifier(fileItem.Name)
        self.parentItem = parentItem
        self.fileDetails = fileItem
        self.fileItemPath = fileItem.Name
    }
    
    #warning("Item : create a better constructor")
    init(fileItem: FileInfoWSh, parentItem:NSFileProviderItemIdentifier, filePath: String) {
        self.identifier = NSFileProviderItemIdentifier(fileItem.Name)
        self.parentItem = parentItem
        self.fileDetails = fileItem
        self.fileItemPath = filePath
    }
    
    var FilePath: String? {
        return self.fileItemPath
    }
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        return identifier
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        return parentItem ?? .rootContainer
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        let result:NSFileProviderItemCapabilities = [
            .allowsReading,
            .allowsEvicting,
            .allowsWriting,
            .allowsRenaming,
            .allowsReparenting,
            .allowsAddingSubItems,
            .allowsDeleting,
            .allowsContentEnumerating,
        ]
        
        return result
    }
    
    var itemVersion: NSFileProviderItemVersion {
        NSFileProviderItemVersion(contentVersion: "a content version".data(using: .utf8)!, metadataVersion: "a metadata version".data(using: .utf8)!)
    }
    
    #warning("Item : add sharing status according to the Response")
    var isShared: Bool {
        guard let filedets = fileDetails else{
            return false
        }
        
        return !filedets.IsLocal
    }
    
#if os(macOS)
    @available(macOSApplicationExtension 13.0, *)
    var contentPolicy: NSFileProviderContentPolicy {
        return .downloadLazily
    }
#endif
    
    var filename: String {
        let name = identifier.rawValue
        guard let fname = name.components(separatedBy: "/").last else {
            return identifier.rawValue
        }
        
        return fname
    }
    
    var contentType: UTType {
        if identifier == NSFileProviderItemIdentifier.rootContainer || fileDetails?.IsDirectory == true {
            return .folder
        }
        
        return .item
    }
    
    var documentSize: NSNumber?{
        return fileDetails?.Size as? NSNumber
    }
    
    var creationDate: Date? {
        var dateComponents = DateComponents()
        dateComponents.year = 2023
        dateComponents.month = 7
        dateComponents.day = 25
        dateComponents.hour = 12
        dateComponents.minute = 30
        dateComponents.second = 0
        let calendar = Calendar.current

        // Create the date from the date components
        return calendar.date(from: dateComponents)
    }
    
    var contentModificationDate: Date? {
        
        // Set a date using DateComponents
        var dateComponents = DateComponents()
        dateComponents.year = 2023
        dateComponents.month = 7
        dateComponents.day = 25
        dateComponents.hour = 12
        dateComponents.minute = 30
        dateComponents.second = 0
        let calendar = Calendar.current

        // Create the date from the date components
        return calendar.date(from: dateComponents)
    }
}
