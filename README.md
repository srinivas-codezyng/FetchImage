<br/>

<p align="left"><img src="https://cloud.githubusercontent.com/assets/1567433/13918338/f8670eea-ef7f-11e5-814d-f15bdfd6b2c0.png" height="180"/>

# FetchImage

`FetchImage` is a Swift package that makes it easy to download images using [`Nuke`](https://github.com/kean/Nuke) and display them in SwiftUI apps.

## Overview

`FetchImage` is an observable object ([`ObservableObject`](https://developer.apple.com/documentation/combine/observableobject)) that allows you to manage the download of an image and observe the results of the download.

```swift
public final class FetchImage: ObservableObject, Identifiable {
    /// Returns the fetched image.
    ///
    /// - note: In case pipeline has `isProgressiveDecodingEnabled` option enabled
    /// and the image being downloaded supports progressive decoding, the `image`
    /// might be updated multiple times during the download.
    @Published public private(set) var image: PlatformImage?

    /// Returns an error if the previous attempt to fetch the most recent attempt
    /// to load the image failed with an error.
    @Published public private(set) var error: Error?

    /// Returns `true` if the image is being loaded.
    @Published public private(set) var isLoading: Bool = false

    /// The progress of the image download.
    @Published public var progress = Progress()
}
```

## Usage

`FetchImage` doesn't ship an image view because it's trivial to create one using SwiftUI and customize it precisely the way you want. 

An example of `FetchImage` usage in a custom SwiftUI view:

```swift
public struct ImageView: View {
    let url: URL

    @StateObject private var image = FetchImage()

    public var body: some View {
        ZStack {
            Rectangle().fill(Color.gray)
            image.view?
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        }
        .onAppear { image.load(url) }
        .onDisappear(perform: image.reset)
    }
}
```

Usage with a list:

```swift
struct DetailsView: View {
    @State var refresh: Bool = false

    var body: some View {
        List(imageUrls, id: \.self) {
            ImageView(url: $0)
                .frame(height: 200)
        }
    }
}
```

> For iOS 13, use `@ObservedObject`. WARNING: `@ObservedObject` does not own the instance,
> you need to maintain the strong references to the `FetchImage` instances somewhere else.

`FetchImage` gives you full control over how to manage the download and how to display the image. For example, one thing that you could do is to replace `onAppear` and `onDisappear` hooks to lower the priority of the requests instead of cancelling them. This might be useful if you want to continue loading and caching the images even if the user leaves the screen, but you still want the images the are currently on screen to be downloaded first.

```swift
.onAppear {
    self.image.priority = .normal
    self.image.fetch() // Restart the request if previous download failed
}
.onDisappear {
    self.image.priority = .low
}
```

# Requirements

| Nuke          | Swift           | Xcode           | Platforms                                         |
|---------------|-----------------|-----------------|---------------------------------------------------|
| FetchImage     | Swift 5.1       | Xcode 11.3      | iOS 13.0 / watchOS 6.0 / macOS 10.15 / tvOS 13.0  |

# License

FetchImage is available under the MIT license. See the LICENSE file for more info.
