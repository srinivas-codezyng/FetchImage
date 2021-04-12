// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Nuke
import Combine

private enum ImageLoadState{
    case YetToStart
    case LoadingLowQuality
    case CompletedLowQualityLoad
    case LoadingHighQuality
    case CompletedHighQualityLoad
    case Failed
}

public final class FetchImage: ObservableObject, Identifiable {
    /// The original request.
    public private(set) var request: ImageRequest?

    /// Returns the fetched image.
    ///
    /// - note: In case pipeline has `isProgressiveDecodingEnabled` option enabled
    /// and the image being downloaded supports progressive decoding, the `image`
    /// might be updated multiple times during the download.
    @Published public private(set) var image: PlatformImage?

    /// Returns an error if the previous attempt to fetch the image failed with an error.
    /// Error is cleared out when the download is restarted.
    @Published public private(set) var error: Error?

    /// Returns `true` if the image is being loaded.
    @Published public private(set) var isLoading: Bool = false
   
    @Published private var imageLoadState :ImageLoadState = ImageLoadState.YetToStart

    public struct Progress {
        /// The number of bytes that the task has received.
        public let completed: Int64

        /// A best-guess upper bound on the number of bytes the client expects to send.
        public let total: Int64
    }

    /// The progress of the image download.
    @Published public var progress = Progress(completed: 0, total: 0)

    /// Updates the priority of the task, even if the task is already running.
    public var priority: ImageRequest.Priority = .normal {
        didSet { task?.priority = priority }
    }

    public var pipeline: ImagePipeline = .shared
    private var task: ImageTask?

    deinit {
        cancel()
    }

    private var disposeBag:[AnyCancellable] = []
    
    public init() {}

    public func load(_ url: URL,lowQualityURL:URL? = nil) {
        guard imageLoadState == .YetToStart else {
            return
        }
        if let lowQualityURL = lowQualityURL  {
            self.$imageLoadState.sink { (_) in
           } receiveValue: {[weak self] (state) in
              if state == .CompletedLowQualityLoad {
                    self?.disposeBag.removeAll()
                    self?.load(ImageRequest(url: url), state: .LoadingHighQuality)
               }
           }.store(in: &disposeBag)
            
            self.load(ImageRequest(url: lowQualityURL), state: .LoadingLowQuality)
           
            return
        }
        
        self.load(ImageRequest(url: url),state: .LoadingHighQuality)
    }
    

    private func load(_ request: ImageRequest, state : ImageLoadState) {
        imageLoadState = state
        // Cancel previous task after starting a new one to make sure that if
        // there is an existing task already running we don't cancel it and start
        // a new once.
        let previousTask = self.task
        defer { previousTask?.cancel() }

        self.request = request

        // Try to display the regular image if it is available in memory cache
        if let container = pipeline.cachedImage(for: request) {
            self.isLoading = false
            image = container.image
            updateLoadState()
            return // Nothing to do
        }

        isLoading = true
        _load(request: request)
    }
    
    private func updateLoadState(){
        if imageLoadState == .LoadingLowQuality {
            imageLoadState = .CompletedLowQualityLoad
        }else{
            imageLoadState = .CompletedHighQualityLoad
        }
    }

    private func _load(request: ImageRequest) {
        progress = Progress(completed: 0, total: 0)

        task = pipeline.loadImage(
            with: request,
            progress: { [weak self] response, completed, total in
                guard let self = self else { return }

                self.progress = Progress(completed: completed, total: total)

                if let image = response?.image {
                    self.image = image // Display progressively decoded image
                }
            },
            completion: { [weak self] in
                self?.didFinishRequest(result: $0)
            }
        )

        if priority != request.priority {
            task?.priority = priority
        }
    }

    private func didFinishRequest(result: Result<ImageResponse, ImagePipeline.Error>) {
        task = nil
        isLoading = false

        switch result {
        case let .success(response):
            self.image = response.image
            self.updateLoadState()
        case let .failure(error):
            self.error = error
            self.imageLoadState = .Failed
        }
    }

    /// Marks the request as being cancelled. Continues to display a downloaded
    /// image.
    public func cancel() {
        task?.cancel() // Guarantees that no more callbacks are will be delivered
        task = nil
        isLoading = false
    }

    /// Resets the `FetchImage` instance by cancelling the request and removing
    /// all of the state including the loaded image.
    public func reset() {
        cancel()
        _reset()
    }

    private func _reset() {
        isLoading = false
        image = nil
        error = nil
        progress = Progress(completed: 0, total: 0)
        request = nil
    }
}

public extension FetchImage {
    var view: SwiftUI.Image? {
        #if os(macOS)
        return image.map(Image.init(nsImage:))
        #else
        return image.map(Image.init(uiImage:))
        #endif
    }
}
