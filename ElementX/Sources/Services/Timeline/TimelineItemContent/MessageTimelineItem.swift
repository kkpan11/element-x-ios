//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import CoreGraphics
import Foundation
import MatrixRustSDK

/// A protocol that contains the base `m.room.message` event content properties.
/// The `CustomStringConvertible` conformance is to redact specific properties from the logs.
protocol MessageContentProtocol: RoomMessageEventContentProtocol, CustomStringConvertible {
    var body: String { get }
}

/// A timeline item that represents an `m.room.message` event.
struct MessageTimelineItem<Content: MessageContentProtocol> {
    let item: MatrixRustSDK.EventTimelineItem
    let content: Content

    var id: String {
        item.uniqueIdentifier()
    }

    var body: String {
        content.body
    }
    
    var isEdited: Bool {
        item.content().asMessage()?.isEdited() == true
    }

    var inReplyTo: String? {
        item.content().asMessage()?.inReplyTo()
    }
    
    var sender: String {
        item.sender()
    }

    var timestamp: Date {
        Date(timeIntervalSince1970: TimeInterval(item.timestamp() / 1000))
    }
}

// MARK: - Formatted Text

/// A protocol that contains the expected event content properties for a formatted message.
protocol FormattedMessageContentProtocol: MessageContentProtocol {
    var formatted: FormattedBody? { get }
}

extension MatrixRustSDK.TextMessageContent: FormattedMessageContentProtocol { }
extension MatrixRustSDK.EmoteMessageContent: FormattedMessageContentProtocol { }
extension MatrixRustSDK.NoticeMessageContent: FormattedMessageContentProtocol { }

/// A timeline item that represents an `m.room.message` event where
/// the `msgtype` would likely contain a formatted body.
extension MessageTimelineItem where Content: FormattedMessageContentProtocol {
    var htmlBody: String? {
        guard content.formatted?.format == .html else { return nil }
        return content.formatted?.body
    }
}

// MARK: - Media

extension MatrixRustSDK.ImageMessageContent: MessageContentProtocol { }

/// A timeline item that represents an `m.room.message` event with a `msgtype` of `m.image`.
extension MessageTimelineItem where Content == MatrixRustSDK.ImageMessageContent {
    var source: MediaSourceProxy {
        .init(source: content.source)
    }

    var width: CGFloat? {
        content.info?.width.map(CGFloat.init)
    }

    var height: CGFloat? {
        content.info?.height.map(CGFloat.init)
    }

    var blurhash: String? {
        content.info?.blurhash
    }
}

extension MatrixRustSDK.VideoMessageContent: MessageContentProtocol { }

/// A timeline item that represents an `m.room.message` event with a `msgtype` of `m.video`.
extension MessageTimelineItem where Content == MatrixRustSDK.VideoMessageContent {
    var source: MediaSourceProxy {
        .init(source: content.source)
    }

    var thumbnailSource: MediaSourceProxy? {
        guard let src = content.info?.thumbnailSource else {
            return nil
        }
        return .init(source: src)
    }

    var duration: UInt64 {
        content.info?.duration ?? 0
    }

    var width: CGFloat? {
        content.info?.width.map(CGFloat.init)
    }

    var height: CGFloat? {
        content.info?.height.map(CGFloat.init)
    }

    var blurhash: String? {
        content.info?.blurhash
    }
}

extension MatrixRustSDK.FileMessageContent: MessageContentProtocol { }

/// A timeline item that represents an `m.room.message` event with a `msgtype` of `m.file`.
extension MessageTimelineItem where Content == MatrixRustSDK.FileMessageContent {
    var source: MediaSourceProxy {
        .init(source: content.source)
    }

    var thumbnailSource: MediaSourceProxy? {
        guard let src = content.info?.thumbnailSource else {
            return nil
        }
        return .init(source: src)
    }
}