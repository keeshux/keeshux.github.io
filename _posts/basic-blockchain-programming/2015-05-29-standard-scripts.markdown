---
layout: post
title: Standard scripts
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, transactions, script, p2pkh]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 12

permalink: /basic-blockchain-programming/standard-scripts/
---

I told you what a script is, but not exactly what it's needed for. By the way, in the article about [transaction processing][tx-processing] I gave you an overview of how bitcoins move around by introducing transaction inputs and outputs. We're about to connect the dots.

<!--more-->

### The validation script

So far, we learned that a script is a piece of code that executes and yields a result. When building a transaction from an unspent transaction output (UTXO), there are two scripts we're particularly interested in:

* The unspent output script, call it *OS*.
* The spending input script, call it *IS*.

The problem is producing such an *IS* that the concatenated script *VS* = *IS* + *OS* (the *validation script*), after being executed, returns a non-zero value. With this in mind, the validation script decides if the transaction input has right to spend the previous unspent output. It may sound difficult to understand, but it's not.

Consider the input script:

    OP_6 OP_DUP

and the previous output script:

    OP_ADD OP_12 OP_EQUAL

Now join them to have the following validation script:

    OP_6 OP_DUP OP_ADD OP_12 OP_EQUAL

and see how the stack evolves:

    []
    [6]
    [6, 6]
    [12]
    [12, 12]
    [1]

Fine, the validation script ends with 1 (`OP_TRUE`) on the stack, so the input script can spend the previous output script.

#### Weaknesses

In fact, many other input scripts comply, like:

    OP_4 OP_8

or:

    OP_1 OP_15 OP_ADD OP_7 OP_SUB OP_3

See how anybody with some basic math knowledge could easily steal the output coins. Conversely, look at this very simple output script:

    OP_FALSE

No matter the input script, the validation script will never succeed. Any bitcoin sent to this output will be lost forever.

In fact, all the above scripts are dangerous and would be rejected by Mainnet for not being *standard*. Miners don't accept transactions with non-standard scripts because in many situations they may result in money loss, directly or indirectly.

### Standard scripts

Virtually any kind of script can be included in a transaction. Still, only standard scripts will be accepted by Mainnet miners for security reasons. The "standard" term comes from the `IsStandard` check, a piece of code from Bitcoin Core ensuring that a script matches one of several well-known categories.

As of Bitcoin Core 0.10, these are considered standard scripts:

1. P2PKH (pay-to-public-key-hash)
2. P2SH (pay-to-script-hash)
3. P2PK (pay-to-public-key)
4. Multisignature
5. `OP_RETURN` metadata

In this course we'll only treat the first ones. For your information, Testnet miners skip the `IsStandard` check completely, thus making the Testnet network suitable for trying experimental scripts.

### P2PKH scripts

The most common standard scripts in the blockchain are named after [P2PKH addresses][addresses] (pay-to-public-key-hash). By having a destination P2PKH Bitcoin address, we can write an output script that will send coins to it. By having the private key from which the destination address was generated, we can write an input script that will later spend such coins.

#### Output script

A P2PKH output script contains a Base58Check-decoded destination address, that is the hash160 of an ECDSA public key:

    OP_DUP
    OP_HASH160
    [hash160(public_key)]
    OP_EQUALVERIFY
    OP_CHECKSIG

Take our sample compressed public key:

    02
    82 00 6e 93 98 a6 98 6e
    da 61 fe 91 67 4c 3a 10
    8c 39 94 75 bf 1e 73 8f
    19 df c2 db 11 db 1d 28

and its hash160 digest:

    6b f1 9e 55 f9 4d 98 6b
    46 40 c1 54 d8 64 69 93
    41 91 95 11

that after Testnet versioning and Base58Check encoding is displayed as:

    mqMi3XYqsPvBWtrJTk8euPWDVmFTZ5jHuK

The output script that sends money to this address is:

    76 (OP_DUP)
    a9 (OP_HASH160)

    14 6b f1 9e 55 f9 4d 98
    6b 46 40 c1 54 d8 64 69
    93 41 91 95 11

    88 (OP_EQUALVERIFY)
    ac (OP_CHECKSIG)

where `14` is an implicit push opcode indicating there are 20 bytes coming next, namely the hash160 digest. The output script alone is meaningless without knowing the corresponding input script, so keep reading.

#### Input script

A P2PKH input script contains a DER-encoded ECDSA signature and a raw public key, either uncompressed or compressed. In such an input script, there are no opcodes other than pushes:

    [signature]
    [public_key]

For example, take the 70-bytes signature from the [ECDSA chapter][ecdsa] and append the `SIGHASH_ALL` constant (`01`) to it:

    30 44
    02 20
    2b 2b 52 9b db dc 93 e7
    8a f7 e0 02 28 b1 79 91
    8b 03 2d 76 90 2f 74 ef
    45 44 26 f7 d0 6c d0 f9
    02 20
    62 dd c7 64 51 cd 04 cb
    56 7c a5 c5 e0 47 e8 ac
    41 d3 d4 cf 7c b9 24 34
    d5 5c b4 86 cc cf 6a f2
    01

The `SIGHASH` suffix is an advanced topic related to [contracts][contracts]. In this series we'll stick with `SIGHASH_ALL` because we'll always sign all transaction inputs.

If you now take the public key from the previous paragraph, you have a typical input script:

    47 30 44 02 20 2b 2b 52
    9b db dc 93 e7 8a f7 e0
    02 28 b1 79 91 8b 03 2d
    76 90 2f 74 ef 45 44 26
    f7 d0 6c d0 f9 02 20 62
    dd c7 64 51 cd 04 cb 56
    7c a5 c5 e0 47 e8 ac 41
    d3 d4 cf 7c b9 24 34 d5
    5c b4 86 cc cf 6a f2 01

    21 02 82 00 6e 93 98 a6
    98 6e da 61 fe 91 67 4c
    3a 10 8c 39 94 75 bf 1e
    73 8f 19 df c2 db 11 db
    1d 28

where `47` and `21` are the hex lengths of the pushed signature and public key respectively.

#### Validation

If we want to spend the money we received on our sample address, we must provide a specific input script so that the composite validation script succeeds. If the input is "authentic", the following script will return non-zero:

    [signature]
    [public_key]
    OP_DUP
    OP_HASH160
    [hash160(public_key)]
    OP_EQUALVERIFY
    OP_CHECKSIG

A step by step description in case the input script is valid:

1. The input signature is pushed.
2. The input public key is pushed.
3. The top item (public key) is duplicated on the stack.
4. The top item (public key) is hashed with hash160.
5. The output hash160 is pushed.
6. Input and output hash160 are popped then checked for equality.
7. The input signature is verified against the public key.
8. `OP_TRUE` is pushed as a result of successful signature verification.

Let's see what happens on the stack:

    []
    [signature]
    [signature, public_key]
    [signature, public_key, public_key]
    [signature, public_key, hash160(public_key)]
    [signature, public_key, hash160(public_key), hash160(public_key)]
    [signature, public_key]
    [1]

The final stack holds `OP_TRUE`, so the transaction input is legit. Along the road, two constraints were satisfied:

1. The public key in the input script must hash to the Bitcoin address in the output script (step 6).
2. The signature must be valid for the public key (step 7).

You may think that the input script alone is enough for signature verification, and you'd be wrong. I didn't mention the third parameter of the verification process: the message! This is left for the next posts about transactions and, for your information, it's going to be a tricky subject.

By the way, can you also see how important is to know if a private key is associated to an uncompressed or compressed public key? In case of "compression mismatch" between public keys and addresses, the first constraint would break. As a consequence, you cannot spend bitcoins sent to a compressed address with an input script containing an uncompressed public key, and vice versa.

### Next block in chain?

You learned that only a standard subset of all possible scripts are accepted by the Bitcoin network. P2PKH scripts are the most common standard scripts you'll find in the blockchain. Input and output scripts together form validation scripts. Miners execute validation scripts to either accept or reject a transaction.

In the [next article][next] we'll finally start analyzing *transactions*. You're about to make sense of the Bitcoin magic. {{ site.post_bottom_line }}


[tx-processing]: {% post_url /basic-blockchain-programming/2015-05-15-scripts-in-transaction-processing %}
[contracts]: https://en.bitcoin.it/wiki/Contracts
[addresses]: {% post_url /basic-blockchain-programming/2015-05-14-network-interoperability-part-two %}
[ecdsa]: {% post_url /basic-blockchain-programming/2015-05-13-elliptic-curve-digital-signatures %}
[next]: {% post_url /basic-blockchain-programming/2015-06-01-inside-transactions %}
