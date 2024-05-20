//
//  CheckInsertedCannulaView.swift
//  OmniKit
//
//  Created by Pete Schwamb on 4/3/20.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI

struct CheckInsertedCannulaView: View {
    
    
    @State private var cancelModalIsPresented: Bool = false
    
    private var didRequestDeactivation: () -> Void
    private var wasInsertedProperly: () -> Void

    init(didRequestDeactivation: @escaping () -> Void, wasInsertedProperly: @escaping () -> Void) {
        self.didRequestDeactivation = didRequestDeactivation
        self.wasInsertedProperly = wasInsertedProperly
    }

    var body: some View {
        GuidePage(content: {
            VStack {
                LeadingImage("Cannula Inserted")
            
                HStack {
                    FrameworkLocalText("套管是否正确插入？", comment: "Question to confirm the cannula is inserted properly").bold()
                    Spacer()
                }
                HStack {
                    FrameworkLocalText("将套管正确插入皮肤时，泵顶部的窗户应为粉红色。", comment: "Description of proper cannula insertion").fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }.padding(.vertical)
            }

        }) {
            VStack(spacing: 10) {
                Button(action: {
                    self.wasInsertedProperly()
                }) {
                    Text(LocalizedString("是的", comment: "Button label for user to answer cannula was properly inserted"))
                        .actionButtonStyle(.primary)
                }
                Button(action: {
                    self.didRequestDeactivation()
                }) {
                    Text(LocalizedString("不", comment: "Button label for user to answer cannula was not properly inserted"))
                        .actionButtonStyle(.destructive)
                }
            }.padding()
        }
        .alert(isPresented: $cancelModalIsPresented) { cancelPairingModal }
        .navigationBarTitle(LocalizedString("检查套管", comment: "navigation bar title for check cannula"), displayMode: .automatic)
        .navigationBarItems(trailing: cancelButton)
        .navigationBarBackButtonHidden(true)
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
            primaryButton: .destructive(FrameworkLocalText("是的，停用Pod", comment: "Button title for confirm deactivation option"), action: { didRequestDeactivation() } ),
            secondaryButton: .default(FrameworkLocalText("不，继续使用Pod", comment: "Continue pairing button title of in pairing cancel modal"))
        )
    }

}

struct CheckInsertedCannulaView_Previews: PreviewProvider {
    static var previews: some View {
        CheckInsertedCannulaView(didRequestDeactivation: {}, wasInsertedProperly: {} )
    }
}
