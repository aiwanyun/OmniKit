//
//  OmnipodSettingsView.swift
//  ViewDev
//
//  Created by Pete Schwamb on 3/8/20.
//  Copyright © 2020 Pete Schwamb. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit
import OmniKit
import RileyLinkBLEKit

struct OmnipodSettingsView: View  {

    @ObservedObject var viewModel: OmnipodSettingsViewModel

    @ObservedObject var rileyLinkListDataSource: RileyLinkListDataSource

    var handleRileyLinkSelection: (RileyLinkDevice) -> Void

    @State private var showingDeleteConfirmation = false

    @State private var showSuspendOptions = false

    @State private var showManualTempBasalOptions = false

    @State private var showSyncTimeOptions = false

    @State private var sendingTestBeepsCommand = false

    @State private var cancelingTempBasal = false

    var supportedInsulinTypes: [InsulinType]

    @Environment(\.guidanceColors) var guidanceColors
    @Environment(\.insulinTintColor) var insulinTintColor
    
    private var daysRemaining: Int? {
        if case .timeRemaining(let remaining, _) = viewModel.lifeState, remaining > .days(1) {
            return Int(remaining.days)
        }
        return nil
    }
    
    private var hoursRemaining: Int? {
        if case .timeRemaining(let remaining, _) = viewModel.lifeState, remaining > .hours(1) {
            return Int(remaining.hours.truncatingRemainder(dividingBy: 24))
        }
        return nil
    }
    
    private var minutesRemaining: Int? {
        if case .timeRemaining(let remaining, _) = viewModel.lifeState, remaining < .hours(2) {
            return Int(remaining.minutes.truncatingRemainder(dividingBy: 60))
        }
        return nil
    }
    
    func timeComponent(value: Int, units: String) -> some View {
        Group {
            Text(String(value)).font(.system(size: 28)).fontWeight(.heavy)
                .foregroundColor(viewModel.podOk ? .primary : .secondary)
            Text(units).foregroundColor(.secondary)
        }
    }
    
    var lifecycleProgress: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(self.viewModel.lifeState.localizedLabelText)
                    .foregroundColor(self.viewModel.lifeState.labelColor(using: guidanceColors))
                Spacer()
                daysRemaining.map { (days) in
                    timeComponent(value: days, units: days == 1 ?
                                  LocalizedString("天", comment: "Unit for singular day in pod life remaining") :
                                    LocalizedString("天", comment: "Unit for plural days in pod life remaining"))
                }
                hoursRemaining.map { (hours) in
                    timeComponent(value: hours, units: hours == 1 ?
                                  LocalizedString("小时", comment: "Unit for singular hour in pod life remaining") :
                                    LocalizedString("小时", comment: "Unit for plural hours in pod life remaining"))
                }
                minutesRemaining.map { (minutes) in
                    timeComponent(value: minutes, units: minutes == 1 ?
                                  LocalizedString("分钟", comment: "Unit for singular minute in pod life remaining") :
                                    LocalizedString("分钟", comment: "Unit for plural minutes in pod life remaining"))
                }
            }
            ProgressView(progress: CGFloat(self.viewModel.lifeState.progress)).accentColor(self.viewModel.lifeState.progressColor(guidanceColors: guidanceColors))
        }
    }
    
    func cancelDelete() {
        showingDeleteConfirmation = false
    }
    
    
    var deliverySectionTitle: String {
        if self.viewModel.isScheduledBasal {
            return LocalizedString("计划的基础", comment: "Title of insulin delivery section")
        } else {
            return LocalizedString("胰岛素输送", comment: "Title of insulin delivery section")
        }
    }
    
    var deliveryStatus: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(deliverySectionTitle)
                .foregroundColor(Color(UIColor.secondaryLabel))
            if viewModel.podOk, viewModel.isSuspendedOrResuming {
                HStack(alignment: .center) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 34))
                        .fixedSize()
                        .foregroundColor(viewModel.suspendResumeButtonColor(guidanceColors: guidanceColors))
                    FrameworkLocalText("Insulin\nSuspended", comment: "Text shown in insulin delivery space when insulin suspended")
                        .fontWeight(.bold)
                        .fixedSize()
                }
            } else if let basalRate = self.viewModel.basalDeliveryRate {
                HStack(alignment: .center) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(self.viewModel.basalRateFormatter.string(from: basalRate) ?? "")
                            .font(.system(size: 28))
                            .fontWeight(.heavy)
                            .fixedSize()
                        FrameworkLocalText("U/hr", comment: "Units for showing temp basal rate").foregroundColor(.secondary)
                    }
                }
            } else {
                HStack(alignment: .center) {
                    Image(systemName: "x.circle.fill")
                        .font(.system(size: 34))
                        .fixedSize()
                        .foregroundColor(guidanceColors.critical)
                    FrameworkLocalText("No\nDelivery", comment: "Text shown in insulin remaining space when no pod is paired")
                        .fontWeight(.bold)
                        .fixedSize()
                }
            }
        }
    }
    
    func reservoir(filledPercent: CGFloat, fillColor: Color) -> some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
            GeometryReader { geometry in
                let offset = geometry.size.height * 0.05
                let fillHeight = geometry.size.height * 0.81
                Rectangle()
                    .fill(fillColor)
                    .mask(
                        Image(frameworkImage: "pod_reservoir_mask_swiftui")
                            .resizable()
                            .scaledToFit()
                    )
                    .mask(
                        Rectangle().path(in: CGRect(x: 0, y: offset + fillHeight - fillHeight * filledPercent, width: geometry.size.width, height: fillHeight * filledPercent))
                    )
            }
            Image(frameworkImage: "pod_reservoir_swiftui")
                .renderingMode(.template)
                .resizable()
                .foregroundColor(fillColor)
                .scaledToFit()
        }.frame(width: 23, height: 32)
    }
    
    
    var reservoirStatus: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedString("胰岛素剩余", comment: "Header for insulin remaining on pod settings screen"))
                .foregroundColor(Color(UIColor.secondaryLabel))
            HStack {
                if let podError = viewModel.podError {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 34))
                        .fixedSize()
                        .foregroundColor(guidanceColors.critical)

                    Text(podError).fontWeight(.bold)
                } else if let reservoirLevel = viewModel.reservoirLevel, let reservoirLevelHighlightState = viewModel.reservoirLevelHighlightState {
                    reservoir(filledPercent: CGFloat(reservoirLevel.percentage), fillColor: reservoirColor(for: reservoirLevelHighlightState))
                    Text(viewModel.reservoirText(for: reservoirLevel))
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .fixedSize()
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 34))
                        .fixedSize()
                        .foregroundColor(guidanceColors.warning)
                    
                    FrameworkLocalText("没有Pod", comment: "Text shown in insulin remaining space when no pod is paired").fontWeight(.bold)
                }
                
            }
        }
    }

    var manualTempBasalRow: some View {
        Button(action: {
            self.manualBasalTapped()
        }) {
            FrameworkLocalText("设定临时基础率", comment: "Button title to set temporary basal rate")
        }
        .sheet(isPresented: $showManualTempBasalOptions) {
            ManualTempBasalEntryView(
                enactBasal: { rate, duration, completion in
                    viewModel.runTemporaryBasalProgram(unitsPerHour: rate, for: duration) { error in
                        completion(error)
                        if error == nil {
                            showManualTempBasalOptions = false
                        }
                    }
                },
                didCancel: {
                    showManualTempBasalOptions = false
                },
                allowedRates: viewModel.allowedTempBasalRates
            )
        }
    }


    func suspendResumeRow() -> some View {
        HStack {
            Button(action: {
                self.suspendResumeTapped()
            }) {
                HStack {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(viewModel.suspendResumeButtonColor(guidanceColors: guidanceColors))
                    Text(viewModel.suspendResumeActionText)
                        .foregroundColor(viewModel.suspendResumeActionColor())
                }
            }
            .actionSheet(isPresented: $showSuspendOptions) {
                suspendOptionsActionSheet
            }
            Spacer()
            if viewModel.basalTransitioning {
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
            }
        }
    }
    
    private var doneButton: some View {
        Button(LocalizedString("完毕", comment: "Title of done button on OmnipodSettingsView"), action: {
            self.viewModel.doneTapped()
        })
    }
    
    var headerImage: some View {
        VStack(alignment: .center) {
            Image(frameworkImage: "Pod")
                .resizable()
                .aspectRatio(contentMode: ContentMode.fit)
                .frame(height: 100)
                .padding(.horizontal)
        }.frame(maxWidth: .infinity)
    }
    
    var body: some View {
        List {
            Section() {
                VStack(alignment: .trailing) {
                    Button(action: {
                        sendingTestBeepsCommand = true
                        Task { @MainActor in
                            do {
                                try await viewModel.playTestBeeps()
                            }
                            sendingTestBeepsCommand = false
                        }
                    }) {
                        Image(systemName: "speaker.wave.2.circle")
                            .imageScale(.large)
                            .foregroundColor(viewModel.rileylinkConnected ? .accentColor : .secondary)
                            .padding(.top,5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!viewModel.rileylinkConnected || sendingTestBeepsCommand)

                    headerImage

                    lifecycleProgress

                    HStack(alignment: .top) {
                        deliveryStatus
                        Spacer()
                        reservoirStatus
                    }
                    if let faultAction = viewModel.recoveryText {
                        Divider()
                        Text(faultAction)
                            .font(Font.footnote.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if let notice = viewModel.notice {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notice.title)
                            .font(Font.subheadline.weight(.bold))
                        Text(notice.description)
                            .font(Font.footnote.weight(.semibold))
                    }.padding(.vertical, 8)
                }
            }

            Section(header: SectionHeader(label: LocalizedString("活动", comment: "Section header for activity section"))) {
                suspendResumeRow()
                    .disabled(!self.viewModel.podOk)
                if self.viewModel.podOk, case .suspended(let suspendDate) = self.viewModel.basalDeliveryState {
                    HStack {
                        FrameworkLocalText("暂停", comment: "Label for suspended at time")
                        Spacer()
                        Text(self.viewModel.timeFormatter.string(from: suspendDate))
                            .foregroundColor(Color.secondary)
                    }
                }
            }

            Section() {
                if let manualTempRemaining = self.viewModel.manualBasalTimeRemaining, let remainingText = self.viewModel.timeRemainingFormatter.string(from: manualTempRemaining) {
                    HStack {
                        if cancelingTempBasal {
                            ProgressView()
                                .padding(.trailing)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(guidanceColors.warning)
                        }
                        Button(action: {
                            self.cancelManualBasal()
                        }) {
                            FrameworkLocalText("取消手动基础", comment: "Button title to cancel manual basal")
                        }
                    }
                    HStack {
                        FrameworkLocalText("其余的", comment: "Label for remaining time of manual basal")
                        Spacer()
                        Text(remainingText)
                            .foregroundColor(.secondary)
                    }
                } else {
                    manualTempBasalRow
                }
            }
            .disabled(cancelingTempBasal || !self.viewModel.podOk)

            Section(header: HStack {
                FrameworkLocalText("设备", comment: "Header for devices section of RileyLinkSetupView")
                Spacer()
                ProgressView()
            }) {
                ForEach(rileyLinkListDataSource.devices, id: \.peripheralIdentifier) { device in
                    Toggle(isOn: rileyLinkListDataSource.autoconnectBinding(for: device)) {
                        HStack {
                            Text(device.name ?? "Unknown")
                            Spacer()

                            if rileyLinkListDataSource.autoconnectBinding(for: device).wrappedValue {
                                if device.isConnected {
                                    Text(formatRSSI(rssi:device.rssi)).foregroundColor(.secondary)
                                } else {
                                    Image(systemName: "wifi.exclamationmark")
                                        .imageScale(.large)
                                        .foregroundColor(guidanceColors.warning)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleRileyLinkSelection(device)
                        }
                    }
                }
            }
            .onAppear { rileyLinkListDataSource.isScanningEnabled = true }
            .onDisappear { rileyLinkListDataSource.isScanningEnabled = false }

            Section() {
                HStack {
                    FrameworkLocalText("POD激活", comment: "Label for pod insertion row")
                    Spacer()
                    Text(self.viewModel.activatedAtString)
                        .foregroundColor(Color.secondary)
                }

                HStack {
                    if let expiresAt = viewModel.expiresAt, expiresAt < Date() {
                        FrameworkLocalText("Pod过期", comment: "Label for pod expiration row, past tense")
                    } else {
                        FrameworkLocalText("Pod到期", comment: "Label for pod expiration row")
                    }
                    Spacer()
                    Text(self.viewModel.expiresAtString)
                        .foregroundColor(Color.secondary)
                }

                if let podDetails = self.viewModel.podDetails {
                    NavigationLink(destination: PodDetailsView(podDetails: podDetails, title: LocalizedString("POD详细信息", comment: "title for pod details page"))) {
                        FrameworkLocalText("POD详细信息", comment: "Text for pod details disclosure row")
                            .foregroundColor(Color.primary)
                    }
                } else {
                    HStack {
                        FrameworkLocalText("POD详细信息", comment: "Text for pod details disclosure row")
                        Spacer()
                        Text(" - ")
                            .foregroundColor(Color.secondary)
                    }
                }

                if let previousPodDetails = viewModel.previousPodDetails {
                    NavigationLink(destination: PodDetailsView(podDetails: previousPodDetails, title: LocalizedString("以前的Pod", comment: "title for previous pod page"))) {
                        FrameworkLocalText("以前的POD详细信息", comment: "Text for previous pod details row")
                            .foregroundColor(Color.primary)
                    }
                } else {
                    HStack {
                        FrameworkLocalText("以前的POD详细信息", comment: "Text for previous pod details row")
                        Spacer()
                        Text(" - ")
                            .foregroundColor(Color.secondary)
                    }
                }
            }

            Section() {
                Button(action: {
                    self.viewModel.navigateTo?(self.viewModel.lifeState.nextPodLifecycleAction)
                }) {
                    Text(self.viewModel.lifeState.nextPodLifecycleActionDescription)
                        .foregroundColor(self.viewModel.lifeState.nextPodLifecycleActionColor)
                }
            }

            Section(header: SectionHeader(label: LocalizedString("配置", comment: "Section header for configuration section")))
            {
                NavigationLink(destination:
                                NotificationSettingsView(
                                    dateFormatter: self.viewModel.dateFormatter,
                                    expirationReminderDefault: self.$viewModel.expirationReminderDefault,
                                    scheduledReminderDate: self.viewModel.expirationReminderDate,
                                    allowedScheduledReminderDates: self.viewModel.allowedScheduledReminderDates,
                                    lowReservoirReminderValue: self.viewModel.lowReservoirAlertValue,
                                    onSaveScheduledExpirationReminder: self.viewModel.saveScheduledExpirationReminder,
                                    onSaveLowReservoirReminder: self.viewModel.saveLowReservoirReminder))
                {
                    FrameworkLocalText("通知设置", comment: "Text for pod details disclosure row").foregroundColor(Color.primary)
                }
                NavigationLink(destination: BeepPreferenceSelectionView(initialValue: viewModel.beepPreference, onSave: viewModel.setConfirmationBeeps)) {
                    HStack {
                        FrameworkLocalText("信心提醒", comment: "Text for confidence reminders navigation link")
                            .foregroundColor(Color.primary)
                        Spacer()
                        Text(viewModel.beepPreference.title)
                            .foregroundColor(.secondary)
                    }
                }
                NavigationLink(destination: SilencePodSelectionView(initialValue: viewModel.silencePodPreference, onSave: viewModel.setSilencePod)) {
                    HStack {
                        FrameworkLocalText("静音Pod", comment: "Text for silence pod navigation link")
                            .foregroundColor(Color.primary)
                        Spacer()
                        Text(viewModel.silencePodPreference.title)
                            .foregroundColor(.secondary)
                    }
                }
                NavigationLink(destination: InsulinTypeSetting(initialValue: viewModel.insulinType, supportedInsulinTypes: supportedInsulinTypes, allowUnsetInsulinType: false, didChange: viewModel.didChangeInsulinType)) {
                    HStack {
                        FrameworkLocalText("胰岛素类型", comment: "Text for insulin type navigation link").foregroundColor(Color.primary)
                        if let currentTitle = viewModel.insulinType?.brandName {
                            Spacer()
                            Text(currentTitle)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section() {
                HStack {
                    FrameworkLocalText("泵送时间", comment: "The title of the command to change pump time zone")
                    Spacer()
                    if viewModel.isClockOffset {
                        Image(systemName: "clock.fill")
                            .foregroundColor(guidanceColors.warning)
                    }
                    TimeView(timeZone: viewModel.timeZone)
                        .foregroundColor( viewModel.isClockOffset ? guidanceColors.warning : nil)
                }
                if viewModel.synchronizingTime {
                    HStack {
                        FrameworkLocalText("调整泵的时间...", comment: "Text indicating ongoing pump time synchronization")
                            .foregroundColor(.secondary)
                        Spacer()
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    }
                } else if self.viewModel.timeZone != TimeZone.currentFixed {
                    Button(action: {
                        showSyncTimeOptions = true
                    }) {
                        FrameworkLocalText("同步到当前时间", comment: "The title of the command to change pump time zone")
                    }
                    .actionSheet(isPresented: $showSyncTimeOptions) {
                        syncPumpTimeActionSheet
                    }
                }
            }

            Section() {
                NavigationLink(destination: PodDiagnosticsView(
                    title: LocalizedString("POD诊断", comment: "Title for the pod diagnostic view"),
                    diagnosticCommands: viewModel.diagnosticCommands,
                    podOk: viewModel.podOk,
                    noPod: viewModel.noPod))
                {
                    FrameworkLocalText("POD诊断", comment: "Text for pod diagnostics row")
                        .foregroundColor(Color.primary)
                }
            }

            if self.viewModel.lifeState.allowsPumpManagerRemoval {
                Section() {
                    Button(action: {
                        self.showingDeleteConfirmation = true
                    }) {
                        FrameworkLocalText("切换到其他胰岛素输送设备", comment: "Label for PumpManager deletion button")
                            .foregroundColor(guidanceColors.critical)
                    }
                    .actionSheet(isPresented: $showingDeleteConfirmation) {
                        removePumpManagerActionSheet
                    }
                }
            }
        }
        .alert(isPresented: $viewModel.alertIsPresented, content: { alert(for: viewModel.activeAlert!) })
        .insetGroupedListStyle()
        .navigationBarItems(trailing: doneButton)
        .navigationBarTitle(self.viewModel.viewTitle)
    }

    var syncPumpTimeActionSheet: ActionSheet {
        ActionSheet(title: FrameworkLocalText("时间变化检测到", comment: "Title for pod sync time action sheet."), message: FrameworkLocalText("泵上的时间与当前时间不同。您想将泵上的时间更新到当前时间吗？", comment: "Message for pod sync time action sheet"), buttons: [
            .default(FrameworkLocalText("是的，与当前时间同步", comment: "Button text to confirm pump time sync")) {
                self.viewModel.changeTimeZoneTapped()
            },
            .cancel(FrameworkLocalText("不，保持泵原样", comment: "Button text to cancel pump time sync"))
        ])
    }
    
    var removePumpManagerActionSheet: ActionSheet {
        ActionSheet(title: FrameworkLocalText("卸下泵", comment: "Title for Omnipod PumpManager deletion action sheet."), message: FrameworkLocalText("您确定要停止使用Omnipod吗？", comment: "Message for Omnipod PumpManager deletion action sheet"), buttons: [
            .destructive(FrameworkLocalText("删除Omnipod", comment: "Button text to confirm Omnipod PumpManager deletion")) {
                self.viewModel.stopUsingOmnipodTapped()
            },
            .cancel()
        ])
    }
    
    var suspendOptionsActionSheet: ActionSheet {
        ActionSheet(
            title: FrameworkLocalText("暂停交互", comment: "Title for suspend duration selection action sheet"),
            message: FrameworkLocalText("胰岛素输送将停止，直到您手动恢复为止。选择何时想提醒您恢复交互？", comment: "Message for suspend duration selection action sheet"),
            buttons: [
                .default(FrameworkLocalText("30分钟", comment: "Button text for 30 minute suspend duration"), action: { self.viewModel.suspendDelivery(duration: .minutes(30)) }),
                .default(FrameworkLocalText("1小时", comment: "Button text for 1 hour suspend duration"), action: { self.viewModel.suspendDelivery(duration: .hours(1)) }),
                .default(FrameworkLocalText("1小时30分钟", comment: "Button text for 1 hour 30 minute suspend duration"), action: { self.viewModel.suspendDelivery(duration: .hours(1.5)) }),
                .default(FrameworkLocalText("2小时", comment: "Button text for 2 hour suspend duration"), action: { self.viewModel.suspendDelivery(duration: .hours(2)) }),
                .cancel()
            ])
    }

    func suspendResumeTapped() {
        switch self.viewModel.basalDeliveryState {
        case .active, .tempBasal:
            showSuspendOptions = true
        case .suspended:
            self.viewModel.resumeDelivery()
        default:
            break
        }
    }

    func manualBasalTapped() {
        showManualTempBasalOptions = true
    }

    func cancelManualBasal() {
        cancelingTempBasal = true
        viewModel.runTemporaryBasalProgram(unitsPerHour: 0, for: 0) { error in
            cancelingTempBasal = false
            if let error = error {
                self.viewModel.activeAlert = .cancelManualBasalError(error)
            }
        }
    }

    
    private func errorText(_ error: Error) -> String {
        if let error = error as? LocalizedError {
            return [error.localizedDescription, error.recoverySuggestion].compactMap{$0}.joined(separator: ". ")
        } else {
            return error.localizedDescription
        }
    }
    
    private func alert(for alert: OmnipodSettingsViewAlert) -> SwiftUI.Alert {
        switch alert {
        case .suspendError(let error):
            return SwiftUI.Alert(
                title: Text("未能暂停胰岛素输送", comment: "Alert title for suspend error"),
                message: Text(errorText(error))
            )
            
        case .resumeError(let error):
            return SwiftUI.Alert(
                title: Text("无法恢复胰岛素输送", comment: "Alert title for resume error"),
                message: Text(errorText(error))
            )
            
        case .syncTimeError(let error):
            return SwiftUI.Alert(
                title: Text("未能设置泵的时间", comment: "Alert title for time sync error"),
                message: Text(errorText(error))
            )

        case .cancelManualBasalError(let error):
            return SwiftUI.Alert(
                title: Text("未能取消手册的基础", comment: "Alert title for failing to cancel manual basal error"),
                message: Text(errorText(error))
            )

        }
    }

    func reservoirColor(for reservoirLevelHighlightState: ReservoirLevelHighlightState) -> Color {
        switch reservoirLevelHighlightState {
        case .normal:
            return insulinTintColor
        case .warning:
            return guidanceColors.warning
        case .critical:
            return guidanceColors.critical
        }
    }

    var decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        return formatter
    }()

    private func formatRSSI(rssi: Int?) -> String {
        if let rssi = rssi, let rssiStr = decimalFormatter.decibleString(from: rssi) {
            return rssiStr
        } else {
            return ""
        }
    }

}
