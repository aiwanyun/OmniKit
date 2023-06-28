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
    
    public var podAttachedToBody: Bool
    
    var instructionText: String {
        if podAttachedToBody {
            return LocalizedString("请停用豆荚。停用后，您可以将其删除并配对新的吊舱。", comment: "Instructions for deactivate pod when pod is on body")
        } else {
            return LocalizedString("请停用豆荚。停用后，您可以将一个新的吊舱配对。", comment: "Instructions for deactivate pod when pod not on body")
        }
    }
    
    enum DeactivatePodViewModelState {
        case active
        case deactivating
        case resultError(DeactivationError)
        case finished
        
        var actionButtonAccessibilityLabel: String {
            switch self {
            case .active:
                return LocalizedString("停用豆荚", comment: "Deactivate pod action button accessibility label while ready to deactivate")
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
                return LocalizedString("停用豆荚", comment: "Action button description for deactivate while pod still active")
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

    var error: DeactivationError? {
        if case .resultError(let error) = self.state {
            return error
        }
        return nil
    }

    var didFinish: (() -> Void)?
    
    var didCancel: (() -> Void)?
    
    var podDeactivator: PodDeactivater

    init(podDeactivator: PodDeactivater, podAttachedToBody: Bool) {
        self.podDeactivator = podDeactivator
        self.podAttachedToBody = podAttachedToBody
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
            return LocalizedString("与豆荚通信存在问题。如果此问题持续存在，请点击丢弃吊舱。然后，您可以激活一个新的吊舱。", comment: "Format string for recovery suggestion during deactivate pod.")
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .OmnipodPumpManagerError(let error):
            return error.errorDescription
        }
    }
}
