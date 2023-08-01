//
//  ContentView.swift
//  FileExplorerIPFS
//
//  Created by Debasish Nandi on 07/06/23.
//

import SwiftUI

struct ContentView: View {
    
    @State private var filepath: String = ""
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, Cydrive!")
            
            Button("Mount Cydrive", action: startServe)
            
            Button("Unmount Cydrive", action: endServe)
            
            TextField("File path of the file...", text: $filepath)
            
            HStack{
                Button("Evict Items", action:{ evict(filepath: filepath)})
                Button("Refresh Dir", action:{ refreshScreen(identifire:filepath)})
            }
        }
        .padding()
        
        
        
    }
     
}

struct FrameSizeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            .frame(minWidth: 100, maxWidth: 400, minHeight: 500, maxHeight: 50)
        }
    }
}

func startServe() {
        var _: () = FileProvide().applicationDidFinishLaunching()
}

func endServe() {
    var _: () = FileProvide().endCydrive()
}

func evict(filepath:String) {
    var _ = FileProvide().evictRoot(filepath: filepath)
}

func refreshScreen(identifire:String) {
    var _ = FileProvide().RefreshRoot(filepath: identifire)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
