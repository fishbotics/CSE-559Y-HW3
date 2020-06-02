//
//  ContentView.swift
//  Mobile Systems Project 3
//
//  Created by Adam Fishman on 5/27/20.
//  Copyright © 2020 Adam Fishman. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cameraManager: CameraManager

    var body: some View {
        VStack {
            Text("Adam's CSE 599Y Screen-screen communication")
                .font(.title)
                .foregroundColor(Color.white)
            Text("\(self.cameraManager.bitString)")
                .foregroundColor(Color.green)
            Button(action: {
                self.cameraManager.toggle_capture()
            }) {
                if cameraManager.capturing {
                    Text("Stop capture")
                } else {
                    Text("Capture")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        .environmentObject(CameraManager())

    }
}
