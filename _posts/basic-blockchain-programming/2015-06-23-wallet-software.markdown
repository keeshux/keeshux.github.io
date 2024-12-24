---
layout: post
title: Wallet software
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, wallet, ecdsa, thin client, utxo]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 16

permalink: /basic-blockchain-programming/wallet-software/
---

Commonly, Bitcoin users rely on clients called *wallets* to create transactions and interact with the p2p network. Even Bitcoin Core is a wallet itself, besides being the official software for mining. Other well-known wallets are [Electrum][electrum], [Hive][hive] etc. Here I'll try to describe the components of a wallet.

### Data model

These are the typical data structures that a wallet maintains internally. Most of them accomplish the core business of the wallet, that is building transactions and broadcasting them to the Bitcoin network. Things like *change addresses* or encryption are convenient features yet not mandatory for a fully working implementation.

#### Keypairs

In the last paragraphs about the [Bitcoin network][network-2], you learned how to create a primitive wallet. Given an ECDSA keypair, a basic Bitcoin wallet is made of:

* The WIF-encoded private key.
* The Base58Check-encoded hash160 of the public key, i.e. the P2PKH address.

Real wallets actually create many keypairs, but stick with a single one for the sake of simplicity. In a tiered context, the keypair is the foundation of our data model and will "hold" our coins.

#### Blockchain

The blockchain component determines if a wallet is *thin* or *heavyweight*. Heavyweight wallets like Bitcoin Core are backed by a full blockchain, whereas thin wallets like Electrum and Hive only need a part of it or none at all, thus being suitable for slow connections or devices with limited capabilities like smartphones.

"Heavy" really means it. At the time of writing, a Bitcoin Core wallet would take about 40GB of disk space to allocate the full blockchain locally, which includes all broadcast Bitcoin transactions since the beginning of time. And increasing. Conveniently, a thin client is much faster under the assumption that a normal user is not interested in every transaction in Bitcoin history. Instead, it will only download *relevant* transactions, that is transactions in which the user appears as a sender or a receiver.

Focus on keypairs again. If our wallet only deals with standard P2PKH transactions --and most do--, we can safely assume that:

1. The user is a receiver when his address appears in a transaction output script.
2. The user is a sender when his public key appears in a transaction input script.

Let's see why. Consider the typical P2PKH output script:

    OP_DUP
    OP_HASH160
    [hash160(public_key)]
    OP_EQUALVERIFY
    OP_CHECKSIG

the typical P2PKH input script:

    [signature]
    [public_key]

and the relevancy scan in pseudocode:

    outpoint = struct { txid, index };

    relevant_txs = {};  /* txid -> tx */
    utxos = {};         /* outpoint */
    balance = 0;

    for (tx in blockchain.txs) {

        /* 1 */
        for (txout in tx.outputs) {
            if (!is_p2pkh_output(txout.script)) {
                continue;
            }
            if (txout.script contains hash160(keypair.public_key)) {
                relevant_txs.add(tx);

                outpoint = outpoint(tx.id, txout.index);
                utxos.add(outpoint);
                balance += txout.value;
            }
        }

        /* 2 */
        for (txin in tx.inputs) {
            if (!is_p2pkh_input(txin.script)) {
                continue;
            }
            if (txin.script contains keypair.public_key) {
                relevant_txs.add(tx);

                outpoint = txin.outpoint;
                previous_tx = relevant_txs[outpoint.txid];
                prev_txout = previous_tx.outputs[outpoint.index];
                utxos.remove(outpoint);
                balance -= prev_txout.value;
            }
        }
    }

(1) If any P2PKH transaction output contains the hash160 of our public key --our Bitcoin address--, the transaction is relevant to our wallet. Such an output associates more coins to our wallet keypair and contributes to the *output value* of the wallet. Until it's spent, the output is an element of the UTXO set of the wallet, therefore increasing the balance.

(2) If any P2PKH transaction input contains our public key, the transaction is relevant to our wallet. Such a transaction input spends coins associated with our wallet keypair, specifically it spends the output referenced by the input outpoint. The previous output is removed from the UTXO set because outputs are always spent in their entirety. After the spend, the balance decreases.

Incidentally, you may notice that the relevant transactions form the *history* of a wallet.

#### UTXOs

So, given a keypair, the two criteria dramatically cut down the search time for relevant transactions in the blockchain, be it local (heavyweight wallet) or remote (thin wallet). To build new transactions, though, we must track the UTXO set, which appears to be a bonus result of the scanning process. All transaction outputs are initially added to the UTXOs, but they're later removed if reused in another transaction as input outpoints. The final set provides us with the available outpoints for building new transactions.

We can also compute the wallet balance from the UTXOs:

    balance = 0;

    for (outpoint in utxos) {
        unspent_tx = relevant_txs[outpoint.txid];
        unspent_txout = unspent_tx.outputs[outpoint.index];
        balance += unspent_txout.value;
    }

### Modularization

From an architectural perspective, a wallet software can be split into 3 independent modules:

1. Signing module.
2. Public addresses module.
3. Networking module.

Most wallets are essentially monolithic, others are hybrid in that they sign transactions in a separate module. [TREZOR][trezor] is a well-known example of hybrid wallet where the signing module is even pushed to an external device.

#### Signing

This module is the only one holding sensitive data: the private key(s). It receives an unsigned transaction and returns a signed one, ready to be published to the Bitcoin network. Since the signing task involves just ECDSA, the module can be -and often is- conveniently implemented in hardware. This arrangement allows for strong [2-factor authentication][2fa].

![One-Time Password device][otp]

Think of OTP (One-Time Password) devices, those handy password generators designed to fit in your keyring. OTPs are often used for private banking to generate a login token that is only valid within a short time period. The token is the second step you take to enter your bank account after entering your credentials, and additional tokens can be requested for particularly sensitive operations. Your brain (the credentials) and the OTP device (the token) together protect the account. You won't be able to log in in case you miss any of the two.

![TREZOR signing device][trezor-key]

Now look at the TREZOR. The TREZOR signing device is also part of a 2-factor authentication scheme, because the ability to create a transaction depends on 2 physically separate modules: the TREZOR itself (for the ECDSA keys) and a networking/blockchain software running on desktop or mobile (for the UTXOs). The device receives an unsigned transaction and signs it after manual confirmation. Then, the signed transaction is sent back to the network-connected software and finally broadcast. Again, the device alone won't be able to build transactions because it has zero knowledge of the blockchain. Likewise, a transaction cannot be signed by the networked software as it has no access to the private keys.

#### Public addresses

Private and public keys are strongly related, still they can live in completely different contexts. In fact, they're loosely coupled by nature. That's why a wallet may opt for a public addresses distribution module. However, in our single keypair scenario such a module would be overkill, because we would be distributing just one public address.

Public-key distribution would only make sense after learning about [deterministic wallets][deterministic-wallets], which I won't deal with in this series. Plus, most wallets have this module conveniently merged into the networking component, since public addresses need to be constantly monitored for incoming transactions.

#### Networking

The networking module would sit in the middle of the other two, and it's also the controller module. It's in charge of several, sometimes complicated tasks:

1. Connecting to the Bitcoin p2p network.
2. Synchronizing and keeping up with the blockchain.
3. Monitoring relevant transactions.
4. Publishing transactions.

Especially task 1 and 2 can be a [PITA][pita], look at the vague protocol description for [blockchain download][blockchain-download]. It's no surprise that many wallet manifacturers -like [Electrum][electrum] and [Mycelium][mycelium]- have chosen to set up their own centralized synchronization network. Thin wallets are severely affected by the overwhelming complexity of blockchain synchronization.

Task 3 is described in the above paragraph about the blockchain model, and requires the knowledge of the public key of our keypair. With the public key we're able to monitor/restore both incoming and outcoming P2PKH transactions. Most importantly, the relevant transactions history determines the UTXO set of the wallet, which we'll need to build new transactions.

Task 4 is definitely the easiest, unless a wallet is advanced enough to pick the best UTXOs according to [coin selection heuristics][coin-selection]. After gathering the UTXOs and composing the unsigned transaction, it's transmitted to the signing module. The unsigned transaction is signed and returned to the networking module, which in turn announces it to the Bitcoin network. Finally, it waits for the transaction to be mined in the upcoming blocks of the blockchain.

### Goodbye!

That's all. From now on, you should be *way* more comfortable with how Bitcoin works under the hood. Of course there's much more to uncover, so I'm particularly interested in what topics you'd love to know more about. That's why your feedback is golden, let me know in the comments what you enjoyed or didn't about this series.

This is free work and I won't explicitly beg for donations. I'd rather be glad if you take your time to spread the word and share these articles with your friends or on social networks. After all, Bitcoin is far from being mainstream and significantly counts on word of mouth.

And remember, all the code is on my [GitHub repository][github].

Keep mining!


[electrum]: https://electrum.org
[hive]: https://hivewallet.com
[mycelium]: https://mycelium.com
[trezor]: https://www.bitcointrezor.com/
[trezor-key]: https://www.bitcointrezor.com/images/carousel_4.png
[otp]: http://www.firebrick.co.uk/images/otp.jpg
[2fa]: https://en.wikipedia.org/wiki/Two-factor_authentication
[deterministic-wallets]: https://codinginmysleep.com/hd-wallets-in-plain-english/
[pita]: https://www.urbandictionary.com/define.php?term=pita
[blockchain-download]: https://en.bitcoin.it/wiki/Block_chain_download
[coin-selection]: https://bitcoin.stackexchange.com/questions/1077/what-is-the-coin-selection-algorithm
[github]: {{ site.bbp_src_root }}
[network-2]: {% post_url /basic-blockchain-programming/2015-05-14-network-interoperability-part-two %}
[tx-1]: {% post_url /basic-blockchain-programming/2015-06-03-the-first-transaction-part-one %}
