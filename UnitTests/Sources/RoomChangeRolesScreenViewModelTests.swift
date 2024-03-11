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

import XCTest

@testable import ElementX

@MainActor
class RoomChangeRolesScreenViewModelTests: XCTestCase {
    var viewModel: RoomChangeRolesScreenViewModelProtocol!
    var roomProxy: RoomProxyMock!
    
    var context: RoomChangeRolesScreenViewModelType.Context {
        viewModel.context
    }

    func testInitialStateAdministrators() {
        setupRoomProxy()
        viewModel = RoomChangeRolesScreenViewModel(mode: .administrator, roomProxy: roomProxy, userIndicatorController: UserIndicatorControllerMock())
        XCTAssertEqual(context.viewState.membersToPromote, [])
        XCTAssertEqual(context.viewState.membersToDemote, [])
        XCTAssertEqual(context.viewState.members, context.viewState.visibleMembers)
        XCTAssertEqual(context.viewState.membersWithRole.count, 1)
        XCTAssertEqual(context.viewState.membersWithRole.first?.id, RoomMemberProxyMock.mockAdmin.userID)
        XCTAssertFalse(context.viewState.hasChanges)
        XCTAssertFalse(context.viewState.isSearching)
    }

    func testInitialStateModerators() {
        setupRoomProxy()
        viewModel = RoomChangeRolesScreenViewModel(mode: .moderator, roomProxy: roomProxy, userIndicatorController: UserIndicatorControllerMock())
        XCTAssertEqual(context.viewState.membersToPromote, [])
        XCTAssertEqual(context.viewState.membersToDemote, [])
        XCTAssertEqual(context.viewState.members, context.viewState.visibleMembers)
        XCTAssertEqual(context.viewState.membersWithRole.count, 1)
        XCTAssertEqual(context.viewState.membersWithRole.first?.id, RoomMemberProxyMock.mockModerator.userID)
        XCTAssertFalse(context.viewState.hasChanges)
        XCTAssertFalse(context.viewState.isSearching)
    }
    
    func testToggleUserOn() {
        testInitialStateModerators()
        guard let firstUser = context.viewState.members.first(where: { !context.viewState.isMemberSelected($0) }) else {
            XCTFail("There should be a regular user available to promote.")
            return
        }
        
        context.send(viewAction: .toggleMember(firstUser))
        
        XCTAssertEqual(context.viewState.membersToPromote, [firstUser])
        XCTAssertEqual(context.viewState.membersToDemote, [])
        XCTAssertEqual(context.viewState.membersWithRole.count, 2)
        XCTAssertTrue(context.viewState.membersWithRole.contains(firstUser))
        XCTAssertTrue(context.viewState.hasChanges)
    }
    
    func testToggleUserOff() {
        testToggleUserOn()
        guard let firstUser = context.viewState.membersToPromote.first else {
            XCTFail("There should be a promoted member before we begin.")
            return
        }
        
        context.send(viewAction: .toggleMember(firstUser))
        
        XCTAssertEqual(context.viewState.membersToPromote, [])
        XCTAssertEqual(context.viewState.membersToDemote, [])
        XCTAssertEqual(context.viewState.membersWithRole.count, 1)
        XCTAssertFalse(context.viewState.membersWithRole.contains(firstUser))
        XCTAssertFalse(context.viewState.hasChanges)
    }
    
    func testDemoteToggledUser() {
        testToggleUserOn()
        guard let firstUser = context.viewState.membersToPromote.first else {
            XCTFail("There should be a promoted member before we begin.")
            return
        }
        
        context.send(viewAction: .demoteMember(firstUser))
        
        XCTAssertEqual(context.viewState.membersToPromote, [])
        XCTAssertEqual(context.viewState.membersToDemote, [])
        XCTAssertEqual(context.viewState.membersWithRole.count, 1)
        XCTAssertFalse(context.viewState.membersWithRole.contains(firstUser))
        XCTAssertFalse(context.viewState.hasChanges)
    }
    
    func testToggleModeratorOff() {
        testInitialStateModerators()
        guard let existingModerator = context.viewState.membersWithRole.first else {
            XCTFail("There should be a member with the role before we begin.")
            return
        }
        
        context.send(viewAction: .toggleMember(existingModerator))
        
        XCTAssertEqual(context.viewState.membersToPromote, [])
        XCTAssertEqual(context.viewState.membersToDemote, [existingModerator])
        XCTAssertEqual(context.viewState.membersWithRole.count, 0)
        XCTAssertFalse(context.viewState.membersWithRole.contains(existingModerator))
        XCTAssertTrue(context.viewState.hasChanges)
    }
    
    func testToggleModeratorOn() {
        testToggleModeratorOff()
        
        guard let demotedMember = context.viewState.membersToDemote.first else {
            XCTFail("There should be a member selected to demote before we begin.")
            return
        }
        
        context.send(viewAction: .toggleMember(demotedMember))
        
        XCTAssertEqual(context.viewState.membersToPromote, [])
        XCTAssertEqual(context.viewState.membersToDemote, [])
        XCTAssertEqual(context.viewState.membersWithRole.count, 1)
        XCTAssertTrue(context.viewState.membersWithRole.contains(demotedMember))
        XCTAssertFalse(context.viewState.hasChanges)
    }
    
    func testDemoteModerator() {
        testInitialStateModerators()
        guard let existingModerator = context.viewState.membersWithRole.first else {
            XCTFail("There should be a member with the role before we begin.")
            return
        }
        
        context.send(viewAction: .demoteMember(existingModerator))
        
        XCTAssertEqual(context.viewState.membersToPromote, [])
        XCTAssertEqual(context.viewState.membersToDemote, [existingModerator])
        XCTAssertEqual(context.viewState.membersWithRole.count, 0)
        XCTAssertFalse(context.viewState.membersWithRole.contains(existingModerator))
        XCTAssertTrue(context.viewState.hasChanges)
    }
    
    func testSaveChanges() async throws {
        setupRoomProxy()
        viewModel = RoomChangeRolesScreenViewModel(mode: .moderator, roomProxy: roomProxy, userIndicatorController: UserIndicatorControllerMock())
        
        guard let firstUser = context.viewState.members.first(where: { !context.viewState.isMemberSelected($0) }),
              let existingModerator = context.viewState.membersWithRole.first else {
            XCTFail("There should be a regular user and a moderator to begin with.")
            return
        }
        
        context.send(viewAction: .toggleMember(firstUser))
        context.send(viewAction: .toggleMember(existingModerator))
        context.send(viewAction: .save)
        
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertTrue(roomProxy.updatePowerLevelsForUsersCalled)
        XCTAssertEqual(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.count, 2)
        XCTAssertEqual(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains(where: { $0.userID == existingModerator.id && $0.powerLevel == 0 }), true)
        XCTAssertEqual(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains(where: { $0.userID == firstUser.id && $0.powerLevel == 50 }), true)
    }
    
    private func setupRoomProxy() {
        roomProxy = RoomProxyMock(with: .init(members: .allMembersAsAdmin))
    }
}