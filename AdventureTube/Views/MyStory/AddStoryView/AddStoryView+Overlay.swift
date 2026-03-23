//
//  AddStoryView+Overlay.swift
//  AdventureTube
//
//  Created by chris Lee on 17/3/2026.
//

import SwiftUI

extension AddStoryView {

    // MARK: - Publishing Overlay

    var publishingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {} // Block taps on background

            VStack(spacing: 20) {
                publishingStatusContent
            }
            .frame(width: 280)
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }

    @ViewBuilder
    var publishingStatusContent: some View {
        switch addStoryVM.publishingStatus {
        case .uploading:
            ProgressView()
                .scaleEffect(1.5)
            Text("Uploading story...")
                .font(.headline)
        case .deleting:
            ProgressView()
                .scaleEffect(1.5)
            Text("Deleting story...")
                .font(.headline)
        case .streaming:
            ProgressView()
                .scaleEffect(1.5)
            Text("Publishing...")
                .font(.headline)
            Text("Receiving real-time updates")
                .font(.caption)
                .foregroundColor(.gray)
        case .pollingFallback:
            ProgressView()
                .scaleEffect(1.5)
            Text("Publishing...")
                .font(.headline)
            Text("Checking status...")
                .font(.caption)
                .foregroundColor(.gray)
        case .completed(let chaptersCount, let placesCount):
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.green)
            Text("Published!")
                .font(.headline)
            Text("\(chaptersCount) chapters, \(placesCount) places")
                .font(.subheadline)
                .foregroundColor(.gray)
            Button("OK") {
                addStoryVM.dismissPublishingOverlay()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        case .deleted:
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.green)
            Text("Deleted!")
                .font(.headline)
            Text("Your story has been removed from the server.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("OK") {
                addStoryVM.dismissPublishingOverlay()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        case .duplicate:
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.orange)
            Text("Already Exists")
                .font(.headline)
            Text("This story has already been published.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("OK") {
                addStoryVM.dismissPublishingOverlay()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        case .failed(let message):
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.red)
            Text("Failed")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("OK") {
                addStoryVM.dismissPublishingOverlay()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        case .idle:
            EmptyView()
        }
    }
}
