//
//  ContentView.swift
//  Readictionary
//
//  Created by Roberto Pineda on 12/27/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Reading View")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.2))
            Divider()
            Text("Dictionary View")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.2))
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
