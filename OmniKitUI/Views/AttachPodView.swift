//
//  AttachPodView.swift
//  OmniKit
//
//  Created by Pete Schwamb on 2/23/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI

struct AttachPodView: View {
    
    enum Modal: Int, Identifiable {
        var id: Int { rawValue }
        
        case attachConfirmationModal
        case cancelModal
    }
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var didConfirmAttachment: () -> Void
    var didRequestDeactivation: () -> Void
    
    @State private var activeModal: Modal?
    
    var body: some View {
        GuidePage(content: {
            VStack {
                LeadingImage("Pod")

                HStack {
                    InstructionList(instructions: [
                        LocalizedString("准备站点。", comment: "Label text for step one of attach pod instructions"),
                        LocalizedString("卸下泵的清除针盖，然后检查套管。然后取下纸张衬里。", comment: "Label text for step two of attach pod instructions"),
                        LocalizedString("检查POD，申请站点，然后确认POD附件。", comment: "Label text for step three of attach pod instructions")
                    ])
                }
                .padding(.bottom, 8)
            }
            .accessibility(sortPriority: 1)
        }) {
            Button(action: {
                activeModal = .attachConfirmationModal
            }) {
                FrameworkLocalText("继续", comment: "Action button title for attach pod view")
                    .accessibility(identifier: "button_next_action")
                    .actionButtonStyle(.primary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .zIndex(1)
        }
        .alert(item: $activeModal, content: self.alert(for:))
        .navigationBarTitle(LocalizedString("附加泵", comment: "navigation bar title attach pod"), displayMode: .automatic)
        .navigationBarItems(trailing: cancelButton)
        .navigationBarBackButtonHidden(true)
    }
    
    var cancelButton: some View {
        Button(LocalizedString("取消", comment: "Cancel button text in navigation bar on pair pod UI")) {
            activeModal = .cancelModal
        }
        .accessibility(identifier: "button_cancel")
    }

    private func alert(for modal: Modal) -> Alert {
        switch modal {
        case .attachConfirmationModal:
            return confirmationModal
        case .cancelModal:
            return cancelPairingModal
        }
    }
    
    var confirmationModal: Alert {
        return Alert(
            title: FrameworkLocalText("确认泵附件", comment: "Alert title for confirm pod attachment"),
            message: FrameworkLocalText("Please confirm that the Pod is securely attached to your body.\n\nThe cannula can be inserted only once with each Pod. Tap “Confirm” when Pod is attached.", comment: "Alert message body for confirm pod attachment"),
            primaryButton: .default(FrameworkLocalText("确认", comment: "Button title for confirm attachment option"), action: didConfirmAttachment),
            secondaryButton: .cancel()
        )
    }
    
    var cancelPairingModal: Alert {
        return Alert(
            title: FrameworkLocalText("您确定要取消POD设置吗？", comment: "Alert title for cancel pairing modal"),
            message: FrameworkLocalText("如果取消POD设置，则当前POD将被停用，并且将无法使用。", comment: "Alert message body for confirm pod attachment"),
            primaryButton: .destructive(FrameworkLocalText("是的，停用Pod", comment: "Button title for confirm deactivation option"), action: didRequestDeactivation),
            secondaryButton: .default(FrameworkLocalText("不，继续使用Pod", comment: "Continue pairing button title of in pairing cancel modal"))
        )
    }
}

struct AttachPodView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ZStack {
                Color(UIColor.secondarySystemBackground).edgesIgnoringSafeArea(.all)
                AttachPodView(didConfirmAttachment: {}, didRequestDeactivation: {})
            }
        }
    }
}
