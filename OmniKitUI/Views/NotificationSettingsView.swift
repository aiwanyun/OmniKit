//
//  NotificationSettingsView.swift
//  OmniKit
//
//  Created by Pete Schwamb on 2/3/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit

struct NotificationSettingsView: View {

    var dateFormatter: DateFormatter
    
    @Binding var expirationReminderDefault: Int
    
    @State private var showingHourPicker: Bool = false
    
    var scheduledReminderDate: Date?
    
    var allowedScheduledReminderDates: [Date]?
    
    var lowReservoirReminderValue: Int
    
    var onSaveScheduledExpirationReminder: ((_ selectedDate: Date?, _ completion: @escaping (_ error: Error?) -> Void) -> Void)?
    
    var onSaveLowReservoirReminder: ((_ selectedValue: Int, _ completion: @escaping (_ error: Error?) -> Void) -> Void)?
    
    var insulinQuantityFormatter = QuantityFormatter(for: .internationalUnit())

    var body: some View {
        RoundedCardScrollView {
            RoundedCard(
                title: LocalizedString("Omnipod提醒", comment: "Title for omnipod reminders section"),
                footer: LocalizedString("该应用程序在POD上配置提醒，以在POD到期之前通知您。设置您要在配对新吊舱时要配置的提前小时数。", comment: "Footer text for omnipod reminders section")
            ) {
                ExpirationReminderPickerView(expirationReminderDefault: $expirationReminderDefault)
            }

            if let allowedDates = allowedScheduledReminderDates {
                RoundedCard(
                    footer: LocalizedString("这是您在配对当前吊舱时安排的提醒。", comment: "Footer text for scheduled reminder area"))
                {
                    Text(LocalizedString("预定的提醒", comment: "Scheduled reminder card title on NotificationSettingsView"))
                    Divider()
                    scheduledReminderRow(scheduledDate: scheduledReminderDate, allowedDates: allowedDates)
                }
            }

            RoundedCard(footer: LocalizedString("当POD中的胰岛素量达到此水平时，该应用程序会通知您。", comment: "Footer text for low reservoir value row")) {
                lowReservoirValueRow
            }

            RoundedCard<EmptyView>(
                title: LocalizedString("关键警报", comment: "Title for critical alerts description"),
                footer: LocalizedString("The reminders above will not sound if your device is in Silent or Do Not Disturb mode.\n\nThere are other critical Pod alerts and alarms that will sound even if your device is set to Silent or Do Not Disturb mode.", comment: "Description text for critical alerts")
            )
        }
        .navigationBarTitle(LocalizedString("通知设置", comment: "navigation title for notification settings"))
    }
    
    @State private var scheduleReminderDateEditViewIsShown: Bool = false
    
    private func scheduledReminderRow(scheduledDate: Date?, allowedDates: [Date]) -> some View {
        Group {
            if let scheduledDate = scheduledDate, scheduledDate <= Date() {
                scheduledReminderRowContents(disclosure: false)
            } else {
                NavigationLink(
                    destination: ScheduledExpirationReminderEditView(
                        scheduledExpirationReminderDate: scheduledDate,
                        allowedDates: allowedDates,
                        dateFormatter: dateFormatter,
                        onSave: onSaveScheduledExpirationReminder,
                        onFinish: { scheduleReminderDateEditViewIsShown = false }),
                    isActive: $scheduleReminderDateEditViewIsShown)
                {
                    scheduledReminderRowContents(disclosure: true)
                }
            }
        }
    }
    
    private func scheduledReminderRowContents(disclosure: Bool) -> some View {
        RoundedCardValueRow(
            label: LocalizedString("时间", comment: "Label for scheduled reminder value row"),
            value: scheduledReminderDateString(scheduledReminderDate),
            highlightValue: false,
            disclosure: disclosure
        )
    }
    
    private func scheduledReminderDateString(_ scheduledDate: Date?) -> String {
        if let scheduledDate = scheduledDate {
            return dateFormatter.string(from: scheduledDate)
        } else {
            return LocalizedString("没有提醒", comment: "Value text for no expiration reminder")
        }
    }

    @State private var lowReservoirReminderEditViewIsShown: Bool = false

    var lowReservoirValueRow: some View {
        NavigationLink(
            destination: LowReservoirReminderEditView(
                lowReservoirReminderValue: lowReservoirReminderValue,
                insulinQuantityFormatter: insulinQuantityFormatter,
                onSave: onSaveLowReservoirReminder,
                onFinish: { lowReservoirReminderEditViewIsShown = false }),
            isActive: $lowReservoirReminderEditViewIsShown)
        {
            RoundedCardValueRow(
                label: LocalizedString("低储层提醒", comment: "Label for low reservoir reminder row"),
                value: insulinQuantityFormatter.string(from: HKQuantity(unit: .internationalUnit(), doubleValue: Double(lowReservoirReminderValue))) ?? "",
                highlightValue: false,
                disclosure: true)
        }
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            NavigationView {
                NotificationSettingsView(dateFormatter: DateFormatter(), expirationReminderDefault: .constant(2), scheduledReminderDate: Date(), allowedScheduledReminderDates: [Date()], lowReservoirReminderValue: 20)
                    .previewDevice(PreviewDevice(rawValue:"iPod touch (7th generation)"))
                    .previewDisplayName("iPod touch (7th generation)")
            }

            NavigationView {
                NotificationSettingsView(dateFormatter: DateFormatter(), expirationReminderDefault: .constant(2), scheduledReminderDate: Date(), allowedScheduledReminderDates: [Date()], lowReservoirReminderValue: 20)
                    .colorScheme(.dark)
                    .previewDevice(PreviewDevice(rawValue: "iPhone XS Max"))
                    .previewDisplayName("iPhone XS Max - Dark")
            }
        }
    }
}
