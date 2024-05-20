//
//  DeactivatePodViewModel.swift
//  OmniKit
//
//  Created by Pete Schwamb on 3/9/20.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKitUI
import OmniKit

public protocol PodDeactivater {
    func deactivatePod(completion: @escaping (OmnipodPumpManagerError?) -> Void)
    func forgetPod(completion: @escaping () -> Void)
}

extension OmnipodPumpManager: PodDeactivater {}


class DeactivatePodViewModel: ObservableObject, Identifiable {
    
    enum DeactivatePodViewModelState {
        case active
        case deactivating
        case resultError(DeactivationError)
        case finished
        
        var actionButtonAccessibilityLabel: String {
            switch self {
            case .active:
                return LocalizedString("停用Pod", comment: "Deactivate pod action button accessibility label while ready to deactivate")
            case .deactivating:
                return LocalizedString("停用。", comment: "Deactivate pod action button accessibility label while deactivating")
            case .resultError(let error):
                return String(format: "%@ %@", error.errorDescription ?? "", error.recoverySuggestion ?? "")
            case .finished:
                return LocalizedString("POD成功停用了。继续。", comment: "Deactivate pod action button accessibility label when deactivation complete")
            }
        }

        var actionButtonDescription: String {
            switch self {
            case .active:
                return LocalizedString("滑动到停用Pod", comment: "Action button description for deactivate while pod still active")
            case .resultError:
                return LocalizedString("重试", comment: "Action button description for deactivate after failed attempt")
            case .deactivating:
                return LocalizedString("停用...", comment: "Action button description while deactivating")
            case .finished:
                return LocalizedString("继续", comment: "Action button description when deactivated")
            }
        }
        
        var actionButtonStyle: ActionButton.ButtonType {
            switch self {
            case .active:
                return .destructive
            default:
                return .primary
            }
        }

        
        var progressState: ProgressIndicatorState {
            switch self {
            case .active, .resultError:
                return .hidden
            case .deactivating:
                return .indeterminantProgress
            case .finished:
                return .completed
            }
        }
        
        var showProgressDetail: Bool {
            switch self {
            case .active:
                return false
            default:
                return true
            }
        }
        
        var isProcessing: Bool {
            switch self {
            case .deactivating:
                return true
            default:
                return false
            }
        }
        
        var isFinished: Bool {
            if case .finished = self {
                return true
            }
            return false
        }

    }
    
    @Published var state: DeactivatePodViewModelState = .active

    public var stateNeedsDeliberateUserAcceptance : Bool {
        switch state {
        case .active:
            true
        default:
            false
        }
    }

    var error: DeactivationError? {
        if case .resultError(let error) = self.state {
            return error
        }
        return nil
    }

    var didFinish: (() -> Void)?
    
    var didCancel: (() -> Void)?
    
    var podDeactivator: PodDeactivater

    var podAttachedToBody: Bool

    var instructionText: String

    init(podDeactivator: PodDeactivater, podAttachedToBody: Bool, fault: DetailedStatus?) {

        var text: String = ""
        if let faultEventCode = fault?.faultEventCode {
            let notificationString = faultEventCode.notificationTitle
            switch faultEventCode.faultType {
            case .exceededMaximumPodLife80Hrs, .reservoirEmpty, .occluded:
                // Just prepend a simple sentence with the notification string for these faults.
                // Other occluded related 0x6? faults will be treated as a general pod error as per the PDM.
                text = String(format: "%@. ", notificationString)
            default:
                // Display the fault code value, the fault description and the pdmRef string for other errors.
                text = String(format: "⚠️ %1$@ (0x%2$02X)\n%3$@\n", notificationString, faultEventCode.rawValue, faultEventCode.faultDescription)
                if let pdmRef = fault?.pdmRef {
                    text += LocalizedString("参考：", comment: "PDM Ref string line") + pdmRef + "\n\n"
                }
            }
        }

        if podAttachedToBody {
            text += LocalizedString("请停用Pod。停用后，您可以将其删除并配对新的泵。", comment: "Instructions for deactivate pod when pod is on body")
        } else {
            text += LocalizedString("请停用Pod。停用后，您可以将一个新的泵配对。", comment: "Instructions for deactivate pod when pod not on body")
        }

        self.podDeactivator = podDeactivator
        self.podAttachedToBody = podAttachedToBody
        self.instructionText = text
    }
    
    public func continueButtonTapped() {
        if case .finished = state {
            didFinish?()
        } else {
            self.state = .deactivating
            podDeactivator.deactivatePod { (error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self.state = .resultError(DeactivationError.OmnipodPumpManagerError(error))
                    } else {
                        self.discardPod(navigateOnCompletion: false)
                    }
                }
            }
        }
    }
    
    public func discardPod(navigateOnCompletion: Bool = true) {
        podDeactivator.forgetPod {
            DispatchQueue.main.async {
                if navigateOnCompletion {
                    self.didFinish?()
                } else {
                    self.state = .finished
                }
            }
        }
    }
}

enum DeactivationError : LocalizedError {
    case OmnipodPumpManagerError(OmnipodPumpManagerError)
    
    var recoverySuggestion: String? {
        switch self {
        case .OmnipodPumpManagerError:
            return LocalizedString("与Pod通信存在问题。如果此问题持续存在，请点击丢弃泵。然后，您可以激活一个新的泵。", comment: "Format string for recovery suggestion during deactivate pod.")
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .OmnipodPumpManagerError(let error):
            return error.errorDescription
        }
    }
}
