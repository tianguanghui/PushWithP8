//
//  P8.swift
//  PushWithP8
//
//  Created by GreyWolf on 2021/8/26.
//

import Foundation

public typealias P8 = String

extension P8 {
    /// Convert PEM format .p8 file to DER-encoded ASN.1 data
    public func toASN1() throws -> ASN1 {
        let base64 = self
            .split(separator: "\n")
            .filter({ $0.hasPrefix("-----") == false })
            .joined(separator: "")

        guard let asn1 = Data(base64Encoded: base64) else {
            throw CupertinoJWTError.invalidP8
        }
        return asn1
    }
}
