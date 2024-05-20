//
//  InsertCannulaView.swift
//  OmniKit
//
//  Created by Pete Schwamb on 2/5/20.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI
import SlideButton
import OmniKit

struct InsertCannulaView: View {
    
    @ObservedObject var viewModel: InsertCannulaViewModel
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @State private var cancelModalIsPresented: Bool = false
    
    var body: some View {
        GuidePage(content: {
            VStack {
                LeadingImage("Pod")

                HStack {
                    InstructionList(instructions: [
                        LocalizedString("滑动下面的开关以启动套管插入。", comment: "Label text for step one of insert cannula instructions"),
                        LocalizedString("等到插入完成。", comment: "Label text for step two of insert cannula instructions"),
                    ])
                    .disabled(viewModel.state.instructionsDisabled)

                }
                .padding(.bottom, 8)
            }
            .accessibility(sortPriority: 1)
        }) {
            VStack {
                if self.viewModel.state.showProgressDetail {
                    self.viewModel.error.map {
                        ErrorView($0, errorClass: $0.recoverable ? .normal : .critical)
                            .accessibility(sortPriority: 0)
                    }

                    if self.viewModel.error == nil {
                        VStack {
                            ProgressIndicatorView(state: self.viewModel.state.progressState)
                            if self.viewModel.state.isFinished {
                                FrameworkLocalText("插入", comment: "Label text indicating insertion finished.")
                                    .bold()
                                    .padding(.top)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
                if self.viewModel.error != nil {
                    Button(action: {
                        self.viewModel.didRequestDeactivation?()
                    }) {
                        Text(LocalizedString("停用Pod", comment: "Button text for deactivate pod button"))
                            .accessibility(identifier: "button_deactivate_pod")
                            .actionButtonStyle(.secondary)
                    }
                    .disabled(self.viewModel.state.isProcessing)
                }
                
                if (self.viewModel.error == nil || self.viewModel.error?.recoverable == true) {
                    actionButton
                    .disabled(self.viewModel.state.isProcessing)
                    .zIndex(1)
                }
            }
            .transition(AnyTransition.opacity.combined(with: .move(edge: .bottom)))
            .padding()
        }
        .alert(isPresented: $cancelModalIsPresented) { cancelPairingModal }
        .navigationBarTitle(LocalizedString("插入套管", comment: "navigation bar title for insert cannula"), displayMode: .automatic)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(trailing: cancelButton)
    }
    var actionText : some View {
        Text(self.viewModel.state.nextActionButtonDescription)
            .accessibility(identifier: "button_next_action")
            .accessibility(label: Text(self.viewModel.state.actionButtonAccessibilityLabel))
            .font(.headline)

    }


    @ViewBuilder
    var actionButton: some View {
        if self.viewModel.stateNeedsDeliberateUserAcceptance {
            SlideButton(action: {
                self.viewModel.continueButtonTapped()
            }) {
                actionText
            }

        } else {
            Button(action: {
                self.viewModel.continueButtonTapped()
            }) {
                actionText
                    .actionButtonStyle(.primary)
            }

        }


    }

    
    var cancelButton: some View {
        Button(LocalizedString("取消", comment: "Cancel button text in navigation bar on insert cannula screen")) {
            cancelModalIsPresented = true
        }
        .accessibility(identifier: "button_cancel")
    }
    
    var cancelPairingModal: Alert {
        return Alert(
            title: FrameworkLocalText("您确定要取消POD设置吗？", comment: "Alert title for cancel pairing modal"),
            message: FrameworkLocalText("如果取消POD设置，则当前POD将被停用，并且将无法使用。", comment: "Alert message body for confirm pod attachment"),
            primaryButton: .destructive(FrameworkLocalText("是的，停用Pod", comment: "Button title for confirm deactivation option"), action: { viewModel.didRequestDeactivation?() } ),
            secondaryButton: .default(FrameworkLocalText("不，继续使用Pod", comment: "Continue pairing button title of in pairing cancel modal"))
        )
    }

}

class MockCannulaInserter: CannulaInserter {
    func insertCannula(completion: @escaping (Result<TimeInterval,OmnipodPumpManagerError>) -> Void) {
        let mockDelay = TimeInterval(seconds: 3)
        let result :Result<TimeInterval, OmnipodPumpManagerError> = .success(mockDelay)
        completion(result)
    }

    func checkCannulaInsertionFinished(completion: @escaping (OmnipodPumpManagerError?) -> Void) {
        completion(nil)
    }

    var cannulaInsertionSuccessfullyStarted: Bool = false
}

struct InsertCannulaView_Previews: PreviewProvider {
    static var mockInserter = MockCannulaInserter()
    static var model = InsertCannulaViewModel(cannulaInserter: mockInserter)
    static var previews: some View {
        InsertCannulaView(viewModel: model)
    }
}
