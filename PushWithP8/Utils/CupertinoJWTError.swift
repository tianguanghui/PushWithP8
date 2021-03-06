//
//  CupertinoJWTError.swift
//  PushWithP8
//
//  Created by GreyWolf on 2021/8/26.
//

import Foundation

public enum CupertinoJWTError: Error {
    case digestDataCorruption
    case invalidP8
    case invalidAsn1
    case keyNotSupportES256Signing
}

extension CupertinoJWTError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .digestDataCorruption:
            return "Internal error."
        case .invalidP8:
            return "The .p8 string has invalid format."
        case .invalidAsn1:
            return "The ASN.1 data has invalid format."
        case .keyNotSupportES256Signing:
            return "The private key does not support ES256 signing"
        }
    }
}
