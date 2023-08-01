//
//  Shell.swift
//  FileExplorerIPFS
//
//  Created by Debasish Nandi on 27/07/23.
//

import Foundation

@discardableResult // Add to suppress warnings when you don't want/need a result
func safeShell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh") //<--updated
    task.standardInput = nil

    try task.run() //<--updated
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

func startIPFS() {
    let result = try? safeShell("/Users/debasishnandi/Downloads/kubo/ipfs init")
    print(result!)
    Task{
        let result2 = try? safeShell("/Users/debasishnandi/Downloads/kubo/ipfs daemon")
        print(result2!)
    }
}

func stopIPFS() {
    let result = try? safeShell("Users/debasishnandi/Downloads/kubo/ipfs shutdown")
    print(result!)
}

func setIPFSPath() {
    let result = try? safeShell("export IPFS_PATH=/Users/debasishnandi/.ipfs")
    print(result!)
}
