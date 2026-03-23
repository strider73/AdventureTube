//
//  AddStoryViewVM+SSE.swift
//  AdventureTube
//
//  Created by chris Lee on 16/3/2026.
//

import Foundation
import Combine

extension AddStoryViewVM{
    
    func startSSETracking(trackingId: String, onCompleted: @escaping (JobStatusDTO) -> Void) {
        publishingStatus = .streaming

        AdventureTubeAPIService.shared.streamJobStatus(trackingId: trackingId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case .failure(let error) = completion {
                    print("SSE error, falling back to polling: \(error.localizedDescription)")
                    self.startPollingFallback(trackingId: trackingId, onCompleted: onCompleted)
                }
            }, receiveValue: { [weak self] jobStatus in
                self?.handleJobStatus(jobStatus, onCompleted: onCompleted)
            })
            .store(in: &cancellables)
    }

    func startPollingFallback(trackingId: String, onCompleted: @escaping (JobStatusDTO) -> Void) {
        publishingStatus = .pollingFallback
        var pollCount = 0
        let maxPolls = 20

        Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .prefix(maxPolls)
            .flatMap { [weak self] _ -> AnyPublisher<ServiceResponse<JobStatusDTO>, Error> in
                pollCount += 1
                print("Polling attempt \(pollCount)/\(maxPolls)")
                guard self != nil else {
                    return Fail(error: BackendError.unknownError).eraseToAnyPublisher()
                }
                return AdventureTubeAPIService.shared.pollJobStatus(trackingId: trackingId)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case .failure(let error) = completion {
                    self.publishingStatus = .failed(message: error.localizedDescription)
                } else {
                    // Completed all polls without terminal status
                    if case .pollingFallback = self.publishingStatus {
                        self.publishingStatus = .failed(message: "Polling job timed out. Please check your job status later.")
                    }
                }
            }, receiveValue: { [weak self] response in
                guard let self = self, let jobStatus = response.data else { return }
                if jobStatus.status.isTerminal {
                    self.handleJobStatus(jobStatus, onCompleted: onCompleted)
                }
            })
            .store(in: &cancellables)
    }


    func handleJobStatus(_ jobStatus: JobStatusDTO, onCompleted: @escaping (JobStatusDTO) -> Void) {
        switch jobStatus.status {
        case .COMPLETED:
            AdventureTubeAPIService.shared.cancelSSEStream()
            onCompleted(jobStatus)
        case .DUPLICATED:
            publishingStatus = .failed(message: jobStatus.errorMessage ?? "The story is laready publised")
            AdventureTubeAPIService.shared.cancelSSEStream()
        case .FAILED:
            publishingStatus = .failed(message: jobStatus.errorMessage ?? "Job failed on server")
            AdventureTubeAPIService.shared.cancelSSEStream()
        case .PENDING:
            publishingStatus = .streaming
        }
    }
    
}
