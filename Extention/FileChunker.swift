//
//  FileChunker.swift
//  Extention
//
//  Created by Debasish Nandi on 13/07/23.
//

import Foundation
import os.log

class ChunkReader {
    private var CurrentChunk:Int
    private var ChunkSize:Int
    private var TotalChunks:Int? = 0
    
    private var reader:CFileStreamReader? = nil
    private var fileSize:Int? = nil
    
    public var progress:Progress?
    
    private let logger = Logger(subsystem: "com.cylogic.FileExplorerIPFS", category: "Chunker")
    
    init(chunksize:Int = UserDefaults.sharedContainerDefaults.defaultChunkSize) {
        self.CurrentChunk = 0
        self.ChunkSize = chunksize
    }
    
    deinit {
        precondition(reader == nil)
    }
    
    func open(url:URL) throws {
        self.reader = CFileStreamReader(fileURL: url)
        
        guard let readStream = reader else{
            logger.error("reader is nil")
            throw ErrorChunkReader.InvalidFileAccessOperation("open(): nil readStream")
        }
        
        try readStream.open()
        
        let size = try readStream.fileSize()
        self.fileSize = size
        
        self.TotalChunks = Int(ceil(Double(size/ChunkSize)))
        
        self.progress = Progress(totalUnitCount: Int64(ceil(Double(size/ChunkSize))+1))
        logger.debug("started reading file")
    }
    
    func count() throws -> UInt32 {
        guard let totalchunks = self.TotalChunks else {
            throw ErrorChunkReader.InvalidFileAccessOperation("count()")
        }
        
        return UInt32(totalchunks)
    }
    
    func getNext() throws -> Chunk? {
        precondition(reader != nil)
        
        guard let readStream = reader else{
            logger.error("reader in nil")
            throw ErrorChunkReader.InvalidFileAccessOperation("getNext(): nil readStream")
        }
        
        let dataOptional = try readStream.readWindow(maxLength: self.ChunkSize)
        guard let data = dataOptional else {
            logger.error("unexpected data type")
            throw ErrorChunkReader.InvalidFileAccessOperation("getNext(): nil data")
        }
        
        var range = try self.range()
        range.length = data.count
        
        return Chunk(data: data, range: range)
    }
    
    func close() {
        guard let readStream = reader else{
            logger.debug("chunk reader already closed")
            return
        }
        
        readStream.close()
        
        self.reader = nil
        logger.debug("closed chunk reader")
    }
    
    private func range() throws -> NSRange {
        let location = (self.CurrentChunk*self.ChunkSize)
        self.CurrentChunk += 1
        
        if TotalChunks == CurrentChunk {
            
            guard let size = fileSize else {
                throw ErrorChunkReader.InvalidFileAccessOperation("file size note set properly")
            }
            
            let limitChunk = size - location
            
            return NSRange(location: location, length: limitChunk)
        }
        
        return NSRange(location: location, length: ChunkSize)
    }
}

struct Chunk{
    let data:Data
    let range:NSRange
}

enum ErrorChunkReader:Error {
    case InvalidFileAccessOperation(String)
    case InvalidProgress
}
