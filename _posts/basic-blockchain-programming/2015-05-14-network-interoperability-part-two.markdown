---
layout: post
title: Network interoperability (pt. 2)
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, base58, base58check, wif, addresses, p2pkh, p2sh, hashing]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 8

permalink: /basic-blockchain-programming/network-interoperability-part-two/
---

Here we are, finally ready to bring ECDSA keys to the real blockchain world. This post will describe the blockchain objects we send and receive bitcoins with, namely keys and addresses. Eventually, you'll be able to generate the most essential Bitcoin wallet.

<!--more-->

### Private keys

So far, you've read a lot of crypto code to generate ECDSA keypairs and signatures. At the end of the series, you'll see the role of private keys in transaction signatures. Meanwhile, you just need to know how to serialize private keys in a format that wallet software will understand.

By now you should be familiar with our [sample private key][ec-priv.pem]:

    16 26 07 83 e4 0b 16 73
    16 73 62 2a c8 a5 b0 45
    fc 3e a4 af 70 f7 27 f3
    f9 e9 2b dd 3a 1d dc 42

Our next goal is converting this private key to WIF.

#### Wallet Import Format (WIF)

The *Wallet Import Format* (WIF) is the first example of Base58Check encoding. Given the following table:

|        |version|
|--------|-------|
|Mainnet |`80`   |
|Testnet3|`ef`   |

we get the WIF representation of a private key this way:

1. Prepend `80` for Mainnet or `ef` for Testnet3.
2. Append `01` if the key will correspond to a compressed public key.
3. Encode to Base58Check.

See our sample key encoded to WIF:

    /* 1 (Testnet3 version) */
    
    ef
    16 26 07 83 e4 0b 16 73
    16 73 62 2a c8 a5 b0 45
    fc 3e a4 af 70 f7 27 f3
    f9 e9 2b dd 3a 1d dc 42
    
    /* 2 (yes to compressed public keys) */
    
    ef
    16 26 07 83 e4 0b 16 73
    16 73 62 2a c8 a5 b0 45
    fc 3e a4 af 70 f7 27 f3
    f9 e9 2b dd 3a 1d dc 42
    01

    /* 3.1 (hash256 of step 2) */
    
    35 06 7f 25 1e 07 d0 2b
    59 ca f4 cc 77 36 20 7d
    73 0d 21 88 f9 62 8f 47
    a9 2a 1a 92 7d 33 7b 2a 
    
    /* 3.2 (4-bytes checksum) */
    
    35 06 7f 25
    
    /* 3.3 (append checksum to step 2) */
    
    ef
    16 26 07 83 e4 0b 16 73
    16 73 62 2a c8 a5 b0 45
    fc 3e a4 af 70 f7 27 f3
    f9 e9 2b dd 3a 1d dc 42
    01
    35 06 7f 25
    
    /* 3.4 (encode Base58) */
    
    cNKkmrwHuShs2mvkVEKfXULxXhxRo3yy1cK6sq62uBp2Pc8Lsa76

Look at [ex-wif.c][ex-wif.c] for the conversion done in code.

The final output is a valid WIF key for the Testnet3 network. Conversely, the ECDSA key is parsed back from WIF by decoding Base58 and taking the 32 bytes after the version byte. Beware of step 2, we must know in advance if we plan to use compressed public keys, because the conversion form affects the address we'll generate from the private key (read next paragraph).

WIF private keys take:

* A 1-byte version.
* A 32-bytes ECDSA private key.
* An optional `01`.
* A 4-bytes checksum.

and therefore measure 38 bytes at most.

### Addresses

In case you ever sent or received bitcoins, you should recognize one of the transaction parameters at the very least: *addresses*. You know, those very long strings you share to receive coins from someone, usually in the form of a QR code.

To understand how addresses "receive" money, you'll first have to hack into Bitcoin scripts. However, it's good to know from the start that most Bitcoin addresses are computed from the public key of our ECDSA keypair. Precisely, a *P2PKH* address (pay-to-public-key-hash) is defined as hash160(public_key), that is a short form for RIPEMD-160(SHA-256(public_key)).

The other address type is *P2SH* (pay-to-script-hash) and mainly relates to multisignature, which I won't address in this series.

#### Encoding

Given our [sample public key][ec-pub.pem] (in compressed form):

    02
    82 00 6e 93 98 a6 98 6e
    da 61 fe 91 67 4c 3a 10
    8c 39 94 75 bf 1e 73 8f
    19 df c2 db 11 db 1d 28

and the following table:

|        |version|
|--------|-------|
|Mainnet |`00`   |
|Testnet3|`6f`   |

we generate a P2PKH address this way:

1. Perform hash160 on the public key.
2. Prepend `00` for Mainnet or `6f` for Testnet3.
3. Encode to Base58Check.

Indeed, another example of Base58Check encoding. See the address generated from our public key:

    /* 1 (hash160 of public key) */

    6b f1 9e 55 f9 4d 98 6b
    46 40 c1 54 d8 64 69 93
    41 91 95 11

    /* 2 (Testnet3 version) */
    
    6f
    6b f1 9e 55 f9 4d 98 6b
    46 40 c1 54 d8 64 69 93
    41 91 95 11
    
    /* 3.1 (hash256 of step 2) */
    
    41 7c 62 6a 31 b5 9b 6e
    1a 0b 7f 30 36 e6 d3 49
    26 61 20 cf cc e6 9b 46
    69 ac a8 7f ff a9 e1 21 
    
    /* 3.2 (4-bytes checksum) */
    
    41 7c 62 6a
    
    /* 3.3 (append checksum to step 2) */
    
    6f
    6b f1 9e 55 f9 4d 98 6b
    46 40 c1 54 d8 64 69 93
    41 91 95 11
    41 7c 62 6a
    
    /* 3.4 (encode Base58) */
    
    mqMi3XYqsPvBWtrJTk8euPWDVmFTZ5jHuK

Look at [ex-address.c][ex-address.c] for the generation done in code.

P2PKH addresses take:

* A 1-byte version.
* A 20-bytes hash160 of the public key.
* A 4-bytes checksum.

and therefore measure 25 bytes.

#### A note on conversion form

In the paragraph about WIF, I said that `01` must be appended to the private key in case we'll use the corresponding public key in compressed form. Now that you know how to generate a P2PKH address, you should figure that compressed and uncompressed public keys yield different hash160 digests and therefore different addresses. A private key has in fact 2 corresponding public keys and addresses, and you'll soon realize that this may have undesirable consequences in transaction validation.

### Magic version prefixes

A nice side-effect of the version byte is that Bitcoin Base58-encoded strings always begin with special letters:

|                  |version|prefix     |
|------------------|-------|-----------|
|Mainnet keys      |`80`   |`5`,`K`,`L`|
|Testnet3 keys     |`ef`   |`9`,`c`    |
|Mainnet addresses |`00`   |`1`        |
|Testnet3 addresses|`6f`   |`m`,`n`    |

The prefix helps us identify immediately the meaning of a Base58 string. Apart from being convenient, this is a totally intentional Bitcoin feature.

### The essential wallet

A lot of work huh? At last we have a wallet-friendly keypair for Testnet3:

    WIF: cNKkmrwHuShs2mvkVEKfXULxXhxRo3yy1cK6sq62uBp2Pc8Lsa76
    Address: mqMi3XYqsPvBWtrJTk8euPWDVmFTZ5jHuK

Displayed as QR codes:

![WIF][qr-wif] ![Address][qr-address]

Such a pair is the foundation of a Bitcoin wallet. We share the public address to receive coins on it, then we sign transactions with the private WIF to spend the received coins.

If you have a [testnet wallet][testnet-wallet] and import the WIF private key, the associated address should appear as well. At the time of writing, I loaded the address with [some coins][wallet-balance] available for spending. In case you want more test coins, use a faucet like [TP's TestNet Faucet][testnet-faucet]. That's all you need to start fiddling with the blockchain!

### Get the code!

Full source on [GitHub]({{ site.bbp_src_root }}).

### Next block in chain?

You learned how to convert ECDSA private keys to Wallet-Import-Format (WIF) and generate P2PKH addresses from the corresponding public key. The most essential wallet consists of a private WIF key and its associated public address.

In the [next article][next] I'll introduce *scripts*, the key part of transaction processing. {{ site.post_bottom_line }}


[qr-wif]: /s/f/basic-blockchain-programming/network-qr-wif.svg
[qr-address]: /s/f/basic-blockchain-programming/network-qr-address.svg
[wallet-balance]: https://www.biteasy.com/testnet/addresses/mqMi3XYqsPvBWtrJTk8euPWDVmFTZ5jHuK
[testnet-wallet]: https://play.google.com/store/apps/details?id=de.schildbach.wallet_test
[testnet-faucet]: http://tpfaucet.appspot.com/
[ec-priv.pem]: {{ site.bbp_src }}/ec-priv.pem
[ec-pub.pem]: {{ site.bbp_src }}/ec-pub.pem
[ex-wif.c]: {{ site.bbp_src }}/ex-wif.c
[ex-address.c]: {{ site.bbp_src }}/ex-address.c
[next]: {% post_url /basic-blockchain-programming/2015-05-15-scripts-in-transaction-processing %}
