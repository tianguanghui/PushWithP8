//
//  ECKeyData.swift
//  PushWithP8
//
//  Created by GreyWolf on 2021/8/26.
//

import Foundation

public typealias ECKeyData = Data

extension ECKeyData {
    public func toPrivateKey() throws -> ECPrivateKey {
        var error: Unmanaged<CFError>? = nil

        guard let privateKey =
            SecKeyCreateWithData(self as CFData, [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeyClass: kSecAttrKeyClassPrivate, kSecAttrKeySizeInBits: 256] as CFDictionary, &error) else {
            throw error!.takeRetainedValue()
        }
        return privateKey
    }
}
