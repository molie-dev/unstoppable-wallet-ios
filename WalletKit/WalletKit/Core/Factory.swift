import Foundation

class Factory {

    func block(withHeader header: BlockHeader, previousBlock: Block) -> Block {
        return Block(withHeader: header, previousBlock: previousBlock)
    }

    func block(withHeader header: BlockHeader, height: Int) -> Block {
        return Block(withHeader: header, height: height)
    }

    func transaction(version: Int, inputs: [TransactionInput], outputs: [TransactionOutput], lockTime: Int) -> Transaction {
        return Transaction(version: version, inputs: inputs, outputs: outputs, lockTime: lockTime)
    }

    func transactionInput(withPreviousOutputTxReversedHex previousOutputTxReversedHex: String, previousOutputIndex: Int, script: Data, sequence: Int) -> TransactionInput {
        return TransactionInput(withPreviousOutputTxReversedHex: previousOutputTxReversedHex, previousOutputIndex: previousOutputIndex, script: script, sequence: sequence)
    }

    func transactionOutput(withValue value: Int, index: Int, lockingScript script: Data = Data(), type: ScriptType = .unknown, keyHash: Data = Data()) throws -> TransactionOutput {
        return TransactionOutput(withValue: value, index: index, lockingScript: script, type: type, keyHash: keyHash)
    }

}
