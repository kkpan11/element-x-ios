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

import ElementX
import XCTest

class InvitesScreenUITests: XCTestCase {
    func testInvitesWithNoBadges() {
        let app = Application.launch(.invites)
        app.assertScreenshot(.invites)
    }
    
    func testInvitesWithBadges() {
        let app = Application.launch(.invitesWithBadges)
        app.assertScreenshot(.invitesWithBadges)
    }
    
    func testNoInvites() {
        let app = Application.launch(.invitesNoInvites)
        XCTAssertTrue(app.staticTexts[A11yIdentifiers.invitesScreen.noInvites].exists)
        app.assertScreenshot(.invitesNoInvites)
    }
    
    func testDeclineInvite() {
        let app = Application.launch(.invites)
        let declineButton = app.buttons[A11yIdentifiers.invitesScreen.decline].firstMatch
        XCTAssert(declineButton.exists)
        declineButton.tap()
        XCTAssertEqual(app.alerts.count, 1)
        app.assertScreenshot(.invites, step: 1)
    }
}