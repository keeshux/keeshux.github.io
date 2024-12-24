---
layout: post
title: Keys as property
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, elliptic-curve]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 4

permalink: /basic-blockchain-programming/keys-as-property/
---

The blockchain is a gigantic database everybody can look through and submit new transactions to. Transactions set up a transfer of property and, regardless of the asset involved in the transfer, property is strictly bound to *keys*.

<!--more-->

If we restrict our field to Bitcoin's core business, that is digital money, keys enable us to spend the money we hold. We lose our home keys, we're locked out. We lose our Bitcoin keys, we lose our bitcoins. As simple as that. Bitcoins can be shared too, like in a co-owned bank account. In such a scenario, all co-owners (or just some privileged ones) must agree on spending the money otherwise the transaction won't take place.

### The need for asymmetry

In the last few years, we've seen bank accounts move from country-specific coordinates to standard IBANs (International Bank Account Number). For what it's worth an IBAN is a long, mostly numeric string associated with a unique bank account in the whole banking network. We share our IBAN to receive money from someone and at the same time we're sort of guaranteed that disclosing an IBAN won't compromise our account credentials.

Bitcoin accomplishes that with [public-key cryptography][asymmetric-crypto] (PKC). We're given *private* (secret) keys to manage and spend our money, but we share *public* (non-secret) keys to generate endpoints able to receive money. At the same time, public keys can somewhat convince others that the money is ours. This is a widespread technique when handling valuable digital assets. What makes it virtually unbreakable is that by owning a private key we're able to derive a public key while the opposite is unfeasible, like in a one-way function.

### Authentication

Bitcoin keys belong to the domain of [elliptic curves][ec-math] (EC). Without going through [technicalities][ec-crypto], EC math was chosen because it serves the purpose of PKC in both a secure and very efficient way. Below are the tasks Bitcoin needs PKC for:

* Keypair generation (private key + public key)
* Signing
* Signature verification

If you're even a bit into cryptography, you might have spot two missing features: encryption and decryption. Indeed, the blockchain is not encrypted, so PKC is only used for *signatures*.

[Signatures][signatures] are a means to authenticate a digital message (read a string of bytes) given that the message receiver is then able to verify the authorship of the signature. The asymmetry lies in that private keys generate signatures, whereas public keys verify them. How's all this possibly related to digital money? By signing, we agree on spending a certain amount of money. By verifying our signature, a third party can tell that money is ours and approve the transaction.

Let's get slightly more practical. Assume all parties agree on:

* An elliptic curve *C*
* A cryptographic hash function *H* whose result we call the *digest*

Follows our simplified message signing process:

    digest = H(message)
    signature = ec_sign(C, digest, private_key)

where the resulting signature is just a string of bytes. On the other hand, when sending our message to third parties we also attach the above signature and our public key. The receiver can now verify the signature:

    digest = H(message)
    is_auth = ec_verify(C, digest, signature, public_key)

If the verification succeeds, the message is authentic. The ec_* functions involve complex EC math I won't dig into. Don't be scared, it won't take a crypto guru to tackle the blockchain. After all, this can't even be *that* clear until we dissect transactions.

### Next block in chain?

You learned that blockchain transactions set up a transfer of property --be it money or any other asset-- and digital property is bound to cryptographic keys. Bitcoin relies on elliptic-curve cryptography, which is a family of cutting-edge public-key cryptography algorithms. Signatures certify digital property.

In the [next article][next] you'll practice some EC crypto in code. {{ site.post_bottom_line }}


[asymmetric-crypto]: http://en.wikipedia.org/wiki/Public-key_cryptography
[ec-math]: http://en.wikipedia.org/wiki/Elliptic_curve
[ec-crypto]: http://en.wikipedia.org/wiki/Elliptic_curve_cryptography
[signatures]: http://en.wikipedia.org/wiki/Digital_signature
[next]: {% post_url /basic-blockchain-programming/2015-05-12-elliptic-curve-keys %}
