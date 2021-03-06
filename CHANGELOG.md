# FetchImage 0.x

## FetchImage 0.4.0

*Mar 6, 2021*

- Rework the APIs to support @StateObject. FetchImage now has an API design recommended in [WWDC 2020: Data Essentials in SwiftUI](https://developer.apple.com/videos/play/wwdc2020/10040/)
- Remove low data mode support

## FetchImage 0.3.0

*Dec 26, 2020*

- **Breaking Change** `FetchImage` no longer starts the request in the initializer, you must call `fetch()`.
- Add `reset()` method which clears the entire `FetchImage` state including the downloaded image. This is crucial for long lists where you don't want `FetchImage` instances to retains images which are off screen.

## FetchImage 0.2.1

*May 23, 2020*

- Fix build error – [#3](https://github.com/kean/FetchImage/pull/3) by [Yu Tawata](https://github.com/yuta24)

## FetchImage 0.2.0

*May 20, 2020*

- Update to Nuke 9

## FetchImage 0.1.0

*Mar 19, 2020*

- Initial release. See an [introductory post](https://kean.github.io/post/introducing-fetch-image) for more information.
