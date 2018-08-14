import Foundation

class InputSigner {
    enum SignError: Error {
        case noPreviousOutput
        case noPreviousOutputAddress
        case noPublicKeyInAddress
        case noPrivateKey
    }

    let hdWallet: HDWallet

    init(hdWallet: HDWallet) {
        self.hdWallet = hdWallet
    }

    func sigScriptData(transaction: Transaction, index: Int) throws -> [Data] {
        let input = transaction.inputs[index]

        guard let prevOutput = input.previousOutput else {
            throw SignError.noPreviousOutput
        }

        guard let address = prevOutput.address else {
            throw SignError.noPreviousOutputAddress
        }

        guard let publicKey = address.publicKey else {
            throw SignError.noPublicKeyInAddress
        }

        guard let privateKey = try? hdWallet.privateKey(index: address.index, chain: address.external ? .external : .internal) else {
            throw SignError.noPrivateKey
        }

        let serializedTransaction = try transaction.serializedForSignature(inputIndex: index) + UInt32(1)
        let signatureHash = Crypto.sha256sha256(serializedTransaction)
        let signature = try Crypto.sign(data: signatureHash, privateKey: privateKey.raw) + Data(bytes: [0x01])

        return [signature, publicKey]
    }

}
