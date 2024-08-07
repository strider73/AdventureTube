//
//  SelectedDetailView.swift
//  AdventureTube
//
//  Created by chris Lee on 7/3/22.
//

import SwiftUI


struct SelectedDetailView: View {
    @State private var selection: String? = nil

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: Text("View A"), tag: "A", selection: $selection) { EmptyView() }
                NavigationLink(destination: Text("View B"), tag: "B", selection: $selection) { EmptyView() }

                Button("Tap to show A") {
                    selection = "A"
                }

                Button("Tap to show B") {
                    selection = "B"
                }
            }
            .navigationTitle("Navigation")
        }
    }
}


struct SelectedDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SelectedDetailView()
    }
}
