//
//  PodAlert.swift
//  OmniKit
//
//  Created by Pete Schwamb on 7/9/20.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKit
import HealthKit

public enum PumpManagerAlert: Hashable {
    case multiCommand(triggeringSlot: AlertSlot?)
    case podExpireImminent(triggeringSlot: AlertSlot?)
    case userPodExpiration(triggeringSlot: AlertSlot?, scheduledExpirationReminderOffset: TimeInterval)
    case lowReservoir(triggeringSlot: AlertSlot?, lowReservoirReminderValue: Double)
    case suspendInProgress(triggeringSlot: AlertSlot?)
    case suspendEnded(triggeringSlot: AlertSlot?)
    case podExpiring(triggeringSlot: AlertSlot?)
    case finishSetupReminder(triggeringSlot: AlertSlot?)
    case timeOffsetChangeDetected

    var isRepeating: Bool {
        return repeatInterval != nil
    }

    var repeatInterval: TimeInterval? {
        switch self {
        case .suspendEnded:
            return .minutes(15)
        default:
            return nil
        }
    }

    var contentTitle: String {
        switch self {
        case .multiCommand:
            return LocalizedString("多重命令警报", comment: "Alert content title for multiCommand pod alert")
        case .userPodExpiration:
            return LocalizedString("POD到期提醒", comment: "Alert content title for userPodExpiration pod alert")
        case .podExpiring:
            return LocalizedString("豆荚过期", comment: "Alert content title for podExpiring pod alert")
        case .podExpireImminent:
            return LocalizedString("豆荚过期", comment: "Alert content title for podExpireImminent pod alert")
        case .lowReservoir:
            return LocalizedString("低水箱", comment: "Alert content title for lowReservoir pod alert")
        case .suspendInProgress:
            return LocalizedString("暂停提醒", comment: "Alert content title for suspendInProgress pod alert")
        case .suspendEnded:
            return LocalizedString("恢复胰岛素", comment: "Alert content title for suspendEnded pod alert")
        case .finishSetupReminder:
            return LocalizedString("POD配对不完整", comment: "Alert content title for finishSetupReminder pod alert")
        case .timeOffsetChangeDetected:
            return LocalizedString("时间变化检测到", comment: "Alert content title for timeOffsetChangeDetected pod alert")
        }
    }

    var contentBody: String {
        switch self {
        case .multiCommand:
            return LocalizedString("多重命令警报", comment: "Alert content body for multiCommand pod alert")
        case .userPodExpiration(_, let offset):
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour]
            formatter.unitsStyle = .full
            let timeString = formatter.string(from: TimeInterval(offset))!
            return String(format: LocalizedString("Pod 将在 %1$@ 后过期。", comment: "Format string for alert content body for userPodExpiration pod alert. (1: time until expiration)"), timeString)
        case .podExpiring:
            return LocalizedString("立即更改POD。 POD活跃了72小时。", comment: "Alert content body for podExpiring pod alert")
        case .podExpireImminent:
            return LocalizedString("立即更改POD。胰岛素输送将在1小时内停止。", comment: "Alert content body for podExpireImminent pod alert")
        case .lowReservoir(_, let lowReservoirReminderValue):
            let quantityFormatter = QuantityFormatter(for: .internationalUnit())
            let valueString = quantityFormatter.string(from: HKQuantity(unit: .internationalUnit(), doubleValue: lowReservoirReminderValue)) ?? String(describing: lowReservoirReminderValue)
            return String(format: LocalizedString("Pod 中剩余 %1$@ 胰岛素或更少。 尽快更换 Pod。", comment: "Format string for alert content body for lowReservoir pod alert. (1: reminder value)"), valueString)
        case .suspendInProgress:
            return LocalizedString("暂停提醒", comment: "Alert content body for suspendInProgress pod alert")
        case .suspendEnded:
            return LocalizedString("胰岛素暂停期已结束。\n\n您可以从主屏幕上的横幅或泵设置屏幕恢复输送。 15 分钟后将再次提醒您。", comment: "Alert content body for suspendEnded pod alert")
        case .finishSetupReminder:
            return LocalizedString("请完成配对您的豆荚。", comment: "Alert content body for finishSetupReminder pod alert")
        case .timeOffsetChangeDetected:
            return LocalizedString("泵上的时间与当前时间不同。您可以在设置中查看泵的时间并同步到当前时间。", comment: "Alert content body for timeOffsetChangeDetected pod alert")
        }
    }

    var triggeringSlot: AlertSlot? {
        switch self {
        case .multiCommand(let slot):
            return slot
        case .userPodExpiration(let slot, _):
            return slot
        case .podExpiring(let slot):
            return slot
        case .podExpireImminent(let slot):
            return slot
        case .lowReservoir(let slot, _):
            return slot
        case .suspendInProgress(let slot):
            return slot
        case .suspendEnded(let slot):
            return slot
        case .finishSetupReminder(let slot):
            return slot
        case .timeOffsetChangeDetected:
            return nil
        }
    }

    // Override background (UserNotification) content

    var backgroundContentTitle: String {
        return contentTitle
    }

    var backgroundContentBody: String {
        switch self {
        case .suspendEnded:
            return LocalizedString("悬架时间增加了。打开应用程序并简历。", comment: "Alert notification body for suspendEnded pod alert user notification")
        default:
            return contentBody
        }
    }


    var actionButtonLabel: String {
        return LocalizedString("好的", comment: "Action button default text for PodAlerts")
    }

    var foregroundContent: Alert.Content {
        return Alert.Content(title: contentTitle, body: contentBody, acknowledgeActionButtonLabel: actionButtonLabel)
    }

    var backgroundContent: Alert.Content {
        return Alert.Content(title: backgroundContentTitle, body: backgroundContentBody, acknowledgeActionButtonLabel: actionButtonLabel)
    }

    var alertIdentifier: String {
        switch self {
        case .multiCommand:
            return "multiCommand"
        case .userPodExpiration:
            return "userPodExpiration"
        case .podExpiring:
            return "podExpiring"
        case .podExpireImminent:
            return "podExpireImminent"
        case .lowReservoir:
            return "lowReservoir"
        case .suspendInProgress:
            return "suspendInProgress"
        case .suspendEnded:
            return "suspendEnded"
        case .timeOffsetChangeDetected:
            return "timeOffsetChangeDetected"
        case .finishSetupReminder:
            return "finishSetupReminder"
        }
    }

    var repeatingAlertIdentifier: String {
        return alertIdentifier + "-repeating"
    }
}

extension PumpManagerAlert: RawRepresentable {

    public typealias RawValue = [String: Any]

    public init?(rawValue: RawValue) {
        guard let identifier = rawValue["identifier"] as? String else {
            return nil
        }

        let slot: AlertSlot?

        if let rawSlot = rawValue["slot"] as? AlertSlot.RawValue {
            slot = AlertSlot(rawValue: rawSlot)
        } else {
            slot = nil
        }

        switch identifier {
        case "multiCommand":
            self = .multiCommand(triggeringSlot: slot)
        case "userPodExpiration":
            guard let offset = rawValue["offset"] as? TimeInterval, offset > 0 else {
                return nil
            }
            self = .userPodExpiration(triggeringSlot: slot, scheduledExpirationReminderOffset: offset)
        case "podExpiring":
            self = .podExpiring(triggeringSlot: slot)
        case "podExpireImminent":
            self = .podExpireImminent(triggeringSlot: slot)
        case "lowReservoir":
            guard let value = rawValue["value"] as? Double else {
                return nil
            }
            self = .lowReservoir(triggeringSlot: slot, lowReservoirReminderValue: value)
        case "suspendInProgress":
            self = .suspendInProgress(triggeringSlot: slot)
        case "suspendEnded":
            self = .suspendEnded(triggeringSlot: slot)
        case "timeOffsetChangeDetected":
            self = .timeOffsetChangeDetected
        default:
            return nil
        }
    }

    public var rawValue: [String : Any] {
        var rawValue: RawValue = [
            "identifier": alertIdentifier
        ]

        rawValue["slot"] = triggeringSlot?.rawValue

        switch self {
        case .lowReservoir(_, lowReservoirReminderValue: let value):
            rawValue["value"] = value
        case .userPodExpiration(_, scheduledExpirationReminderOffset: let offset):
            rawValue["offset"] = offset
        default:
            break
        }

        return rawValue
    }
}

extension PodAlert {
    var isIgnored: Bool {
        switch self {
        case .podSuspendedReminder, .finishSetupReminder:
            return true
        default:
            return false
        }
    }
}
