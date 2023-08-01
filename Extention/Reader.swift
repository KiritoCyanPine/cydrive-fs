//
//  Reader.swift
//  Extention
//
//  Created by Debasish Nandi on 13/07/23.
//

import Foundation

class CFileStreamReader {
    let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    deinit {
        // You must close before releasing the last reference.
        precondition(self.file == nil)
    }

    private var file: UnsafeMutablePointer<FILE>? = nil

    func open() throws {
        guard let f = fopen(fileURL.path, "r") else {
            print(errno)
            throw ErrorCFileReader.FilePointerInit(NSPOSIXErrorDomain,errno)
        }

        self.file = f
    }

    func close() {
        if let f = self.file {
            self.file = nil
            let success = fclose(f) == 0
            assert(success)
        }
    }
    
    func fileSize() throws -> Int{
        guard let f = self.file else {
            throw ErrorCFileReader.InvalidFilePointer(NSPOSIXErrorDomain,EBADF)
        }
        
        fseek(f, 0, SEEK_END)
        
        let size = ftell(f)
        fseek(f, 0, SEEK_SET)
        
        return size
    }

    func readWindow(maxLength: Int = 1024) throws -> Data? {
        guard let f = self.file else {
            throw ErrorCFileReader.InvalidFilePointer(NSPOSIXErrorDomain,EBADF)
        }
        
        var buffer = [CChar](repeating: 0, count: maxLength)
        
        let bytesread = fread(&buffer, MemoryLayout<UInt8>.size, maxLength, f)
        
        if bytesread <= 0{
            if feof(f) != 0 {
                return nil
            } else {
                throw ErrorCFileReader.FilePointerReadFailure(NSPOSIXErrorDomain, errno)
            }
        }
        
        return Data(bytes: buffer, count: bytesread)
    }
}

enum ErrorCFileReader:Error {
    case InvalidFilePointer(String?,Int32?)
    case FilePointerCloseFailure(String?)
    case FilePointerReadFailure(String?,Int32?)
    case FilePointerInit(String?,Int32?)
}
