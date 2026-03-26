// ContentView.swift
// ProteinLens — Day 4
// Entry point — hosts the live camera view

import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraView()
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
