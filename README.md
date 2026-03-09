# NewsFeedApp

An iOS news reader built with UIKit, Combine, and a lightweight MVVM layered architecture.

The app supports:
- Top headlines by category
- Article search
- Bookmarks stored locally
- Image caching
- Offline fallback for previously fetched articles

## App Glimpses

| Light Mode | Dark Mode |
| -- | -- | 
| <img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 Pro - 2026-03-09 at 09 00 37" src="https://github.com/user-attachments/assets/996ac814-925f-4397-b5f4-00bd72590d0b" /> | <img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 Pro - 2026-03-09 at 09 01 04" src="https://github.com/user-attachments/assets/10c31b78-e9ae-4af3-a003-11cdc4d0e4a7" /> | 

| Bookmark | Search |
| -- | -- |
| ![Simulator Screen Recording - iPhone 17 Pro - 2026-03-09 at 09 28 22](https://github.com/user-attachments/assets/dcce25d2-0741-45a4-b3e5-ca6717a35daf) | ![Simulator Screen Recording - iPhone 17 Pro - 2026-03-09 at 09 29 59](https://github.com/user-attachments/assets/f46b08f5-6ea0-43f7-aa7a-7d21d4d6c071) |


## Tech Stack


- `UIKit` for UI
- `Combine` for async state updates
- `URLSession` for networking
- `Core Data` for bookmarks
- `NSCache` + `URLCache` for image caching
- File-based cache for offline article payloads

## Project Structure

```text
NewsFeedApp/
  NewsFeedApp/
    Domain/
      Models/
      Repository/
      UseCases/
    Flows/
      Common/
      Feed/
      Search/
      Bookmarks/
      Detail/
    Networking/
    AppDependencyContainer.swift
    AppDelegate.swift
    SceneDelegate.swift
  NewsFeedApp.xcodeproj
  NewsFeedAppTests/
  NewsFeedAppUITests/
```

## Architecture

The code follows a simple layered design:

- `Flows`
  - view controllers and view models
  - owns presentation state and user interaction
- `Domain`
  - app models, repository contracts, and use cases
  - keeps business logic separate from UIKit
- `Networking`
  - API client, DTO mapping, repository implementations, cache storage
  - also contains Core Data bookmark storage

`AppDependencyContainer` wires everything together and builds the concrete dependencies used by the screens.

## Main Design Decisions

### 1. UIKit + ViewModel

The app uses programmatic UIKit screens with view models instead of storyboards for main flows.

Why:
- easier control over dynamic layouts
- clearer ownership of state
- simpler dependency injection

### 2. Repository + Use Case split

Repositories deal with data sources.
Use cases shape repository output into app-specific behavior.

Example:
- `NewsRepository` fetches and caches article payloads, with pagination pagesize of 20 articles.
- `FetchHeadlinesUseCase` enriches those articles with bookmark state

### 3. Offline support

Successful headline and search responses are cached to disk in the app cache directory.

When the app hits `networkUnavailable`, `NewsRepository` falls back to cached payloads for:
- top headlines
- search results
- trending articles

This gives offline read support for content the user has already loaded before.


### 4. Image caching

`ImageLoader` provides:
- in-memory caching with `NSCache`
- disk-backed HTTP caching with `URLCache`

This avoids re-downloading article images for every cell reuse and improves scrolling performance.

### 5. Local bookmarks

Bookmarks are stored in Core Data via `BookmarkRepository`.

Why Core Data here:
- bookmark persistence is local-only
- small structured dataset
- easy fetch/sort/delete behavior

## Setup

### Requirements

- Xcode 26.x
- iOS 26.x SDK
- a valid [NewsAPI](https://newsapi.org/) key

### 1. Clone the project

Clone the repository and locate and open the xcodeproj file:

- `git clone https://github.com/Omkar492/NewsFeedApp.git`

### 2. Configure the API key

The app reads the API key from `Info.plist` using the `NEWS_API_KEY` key.

Check:

[Info.plist](/Users/omkarchougule/Desktop/NewsFeedApp/NewsFeedApp/NewsFeedApp/NewsFeedApp/Info.plist)

If needed, set:

```xml
<key>NEWS_API_KEY</key>
<string>YOUR_KEY_HERE</string>
```

### 3. Build and run

Choose a concrete iOS simulator in Xcode, then run the `NewsFeedApp` scheme.

Do not run tests against `Any iOS Device`.
Use a concrete simulator such as `iPhone 16`.

## Features

### Feed

- category filter
- paginated top headlines
- bookmark toggle from the card

### Search

- debounced query input
- paginated results
- bookmark toggle from the card

### Bookmarks

- persistent saved article list
- remove bookmark from cell or context menu

### Detail

- in-app article web view
- bookmark from navigation bar
- share and open in Safari

## Caching Behavior

### Image cache

- memory cache first
- disk/HTTP cache second
- network only if needed

### Article cache

Cached by request type and parameters:
- category + page + page size for headlines
- query + page + page size for search
- single cache entry for trending

## Testing

Unit tests live in:

- [NewsFeedAppTests](/Users/omkarchougule/Desktop/NewsFeedApp/NewsFeedApp/NewsFeedApp/NewsFeedAppTests)

Coverage currently focuses on:
- repository mapping and offline fallback
- view model state transitions
- DTO and cache-store behavior
