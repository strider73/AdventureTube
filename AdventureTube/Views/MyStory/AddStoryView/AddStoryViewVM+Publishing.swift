//
//  AddStoryViewVM+Publishing.swift
//  AdventureTube
//
//  Created by chris Lee on 29/3/22.
//

import Foundation
import Combine
import CoreData

extension AddStoryViewVM {

    // MARK: - Async Publish with SSE Job Tracking

    func uploadStory(){
        do {
            try validaterAllContentsBeforeStoreToCoreData()
        } catch {
            print("there is error \(error.localizedDescription)")
            isShowErrorMessage = true
            errorMessage = error.localizedDescription
            return
        }

        let fetchRequest = NSFetchRequest<StoryEntity>(entityName:"StoryEntity")
        let filter = NSPredicate(format: "youtubeId == %@", youtubeContentItem.contentDetails.videoId)
        fetchRequest.predicate = filter

        var targetStoryEntity: StoryEntity?

        do {
            let stories = try manager.context.fetch(fetchRequest)
            if stories.count > 0 {
                targetStoryEntity = stories.first
                print("found story from coreData")
            }
        } catch let error {
            print("Error fetching. \(error.localizedDescription)")
        }

        guard let storyEntity = targetStoryEntity else {
            publishingStatus = .failed(message: "Story not found in local storage")
            isPublishing = true
            return
        }

        do {
            let jsonData = try createJsonFromStory(storyEntity: storyEntity)

            isPublishing = true
            publishingStatus = .uploading

            AdventureTubeAPIService.shared.publishStory(jsonData)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Publish error: \(error.localizedDescription)")
                        self?.publishingStatus = .failed(message: error.localizedDescription)
                    }
                }, receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    if response.success, let jobStatus = response.data {
                        print("Publish accepted, trackingId: \(jobStatus.trackingId)")
                        self.startSSETracking(trackingId: jobStatus.trackingId) { [weak self] jobStatus in
                            guard let self = self else { return }
                            self.storyEntity?.isPublished = true
                            self.isStoryPublished = true
                            self.manager.save()
                            self.publishingStatus = .completed(chaptersCount: jobStatus.chaptersCount, placesCount: jobStatus.placesCount)
                        }
                    } else {
                        self.publishingStatus = .failed(message: response.message ?? "Publish request failed")
                    }
                })
                .store(in: &cancellables)
        } catch let error {
            print("Error create json. \(error.localizedDescription)")
            publishingStatus = .failed(message: error.localizedDescription)
            isPublishing = true
        }
    }



    func dismissPublishingOverlay() {
        publishingStatus = .idle
        isPublishing = false
        AdventureTubeAPIService.shared.cancelSSEStream()
    }

    func deletePublishedStory() {
        guard let youtubeId = storyEntity?.youtubeId, !youtubeId.isEmpty else {
            isShowErrorMessage = true
            errorMessage = "No story to delete"
            return
        }

        // Cancel any lingering SSE connection first
        AdventureTubeAPIService.shared.cancelSSEStream()

        isPublishing = true
        publishingStatus = .deleting

        AdventureTubeAPIService.shared.deleteStory(youtubeContentId: youtubeId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Delete error: \(error)")
                    self?.publishingStatus = .failed(message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] response  in
                guard let self = self else { return }
                print("Delete process pending for youtubeId: \(youtubeId)")
                if response.success, let jobStatus = response.data{
                    print("Delete pending, trackingId: \(jobStatus.trackingId)")
                    self.startSSETracking(trackingId: jobStatus.trackingId){[weak self] jobStatus in
                        guard let self = self else { return }
                        self.storyEntity?.isPublished = false
                        self.isStoryPublished = false
                        self.manager.save()
                        self.publishingStatus = .deleted
                        
                    }
                }else{
                    self.publishingStatus = .failed(message: response.message ?? "Delete request failed")
                }
            })
            .store(in: &cancellables)
    }
}
