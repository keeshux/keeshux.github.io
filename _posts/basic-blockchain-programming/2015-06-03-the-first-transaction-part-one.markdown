---
layout: post
title: The first transaction (pt. 1)
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, transaction, p2pkh, utxo, outpoint, script, hashing, ecdsa]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 14

permalink: /basic-blockchain-programming/the-first-transaction-part-one/
---

The core business of the Bitcoin blockchain technology is definitely building *transactions*. I'll show you the necessary steps to write your own P2PKH transactions, that is the kind of standard transactions you'll find most often in the blockchain.

<!--more-->

### How to build a P2PKH transaction

In order to build a transaction, an ECDSA keypair alone is not enough. We need the blockchain history of the keypair at our disposal, or better said, the transactions sending value to the address associated with our keypair. Then, we'll use the ECDSA private key to produce signatures for such transaction outputs, so that they become inputs to our transaction.

Given:

* An ECDSA keypair *K*.
* A third-party P2PKH output address *A*.
* The amount *S* to transfer in satoshis.

we want to send *S* satoshis to address *A* via our keypair *K*. Here's the overall procedure:

1. Scan the blockchain for the relevant UTXOs to *K*.
2. Build a transaction output from *S* and *A*.
3. Gather enough input value from the UTXOs to reach *S*.
4. For each input, generate the subject of its signature.
5. Generate ECDSA signatures for each input subject.
6. Pack the transaction.

Let's start from [ex-tx-build.c][ex-tx-build.c].

#### The UTXO set

At the very beginning of an ECDSA keypair history, the derived P2PKH address has no transaction outputs associated with it and therefore has no bitcoin value for the blockchain. When someone later publishes a transaction that sends bitcoins to our address, the keypair suddenly becomes a valuable asset. Consider our now famous Testnet address:

    mqMi3XYqsPvBWtrJTk8euPWDVmFTZ5jHuK

and its [blockchain history][history]. Among all transactions, [three outputs][utxos] are still unspent at the time of writing:

1. [`f34e1c37e736...a2f3`][tx-1]
2. [`65216856608d...20c6`][tx-2]
3. [`6b580bada66e...3934`][tx-3]

totalling a 0.951 BTC output value (= 95100000 satoshis). Specifically, these are the outputs sending money to our address:

* The first output of tx 1 (0.87 BTC).
* The first output of tx 2 (0.001 BTC).
* The second output of tx 3 (0.08 BTC).

If you now translate the words into data structures:

* `<f34e1c37e736...a2f3, 0>`
* `<65216856608d...20c6, 0>`
* `<6b580bada66e...3934, 1>`

you have the UTXO outpoints for our keypair/wallet. Besides making up the balance of the wallet, the importance of the UTXO set lies in that it contains the outpoints we can reuse to build our own transactions. After spending an UTXO in a transaction input, it's removed from the set because an UTXO is always spent in its entirety.

For what it's worth, scanning UTXOs would require a lot of networking code, so building a wallet history from web explorers is a quick alternative. This will cost you some privacy though, as you generally don't want to share your addresses with untrusted services.

#### The destination output

You should know by now how to build a P2PKH transaction output. Say we want to send 0.251 BTC (25100000 satoshis, little-endian):

    e0 fe 7e 01 00 00 00 00

to this address:

    mhmhRnN58ki9zbRJ63mpNGQXoYvdMXZsXt

that decodes to the following hash160 digest:

    18 ba 14 b3 68 22 95 cb
    05 23 0e 31 fe cb 00 08
    92 40 66 08

Here's the first output of our transaction:

    /* value (0.251 BTC) */
    e0 fe 7e 01 00 00 00 00

    /* script length */
    19

    /* P2PKH script */
    76 a9 14 18 ba 14 b3 68
    22 95 cb 05 23 0e 31 fe
    cb 00 08 92 40 66 08 88
    ac

I wrote a convenient C macro in [tx.h][tx.h] for building P2PKH outputs from a value and a hash160:

{% highlight c %}

void bbp_txout_create_p2pkh(bbp_txout_t *txout,
        const uint64_t value, const char *hash160);

{% endhighlight %}

Basically, the hash160 bytes are enclosed in the `OP_DUP OP_HASH160` and `OP_EQUALVERIFY OP_CHECKSIG` opcodes. Hexes are interpreted from left to right and are therefore encoded little-endian. We use the macro to easily create our first output:

{% highlight c %}

bbp_txout_create_p2pkh(&outs[0], 25100000,
        "18ba14b3682295cb05230e31fecb000892406608");

{% endhighlight %}

#### Gathering the inputs

Our UTXO set is worth <0.87, 0.001, 0.08> BTC respectively, so the first one:

    <f34e1c37e736...a2f3, 0>

is just enough for a 0.251 BTC output. In fact our input value exceeds the output value by 0.619 BTC, which are silently returned to the transaction miner as a fee. We know an UTXO cannot be spent partially, and since the fee is somewhat relevant to us, we add a second output for *change*.

Our final transaction will have one input and two outputs, the second being a change output that returns the exceeding input value to our own address. Here's the second output of our transaction:

    /* value (0.619 BTC) */
    e0 84 b0 03 00 00 00 00

    /* script length */
    19

    /* P2PKH script */
    76 a9 14 6b f1 9e 55 f9
    4d 98 6b 46 40 c1 54 d8
    64 69 93 41 91 95 11 88
    ac

On the other hand, it's quite obvious that output value cannot possibly exceed input value. Non-coinbase transactions never create bitcoin value. This is our second output in code:

{% highlight c %}

bbp_txout_create_p2pkh(&outs[1], 61900000,
        "6bf19e55f94d986b4640c154d864699341919511");

{% endhighlight %}

#### Building the signature subject

This is tricky if not even controversial, because the subject of transaction signatures is not the transaction itself. When studying ECDSA signatures, you learned that the signing process takes three steps:

1. Generate an ECDSA keypair.
2. Create a message.
3. Sign the message with the private key to produce a signature.

The problem here is that a Bitcoin transaction cannot be signed the usual way, since signatures are actually part of the transaction, namely the input scripts. The approach has to be different. In fact, we'll produce a different signature for each transaction input, which in turn will embed it in its P2PKH script.

In practice, for each input *I*, the message to be signed is a slightly modified version of the transaction where:

1. The *I* script is set to the output script of the UTXO it refers to.
2. Input scripts other than *I* are truncated to zero-length.
3. A `SIGHASH` flag is appended.

For a single input transaction we won't need to truncate any other input script:

{% highlight c %}

bbp_outpoint_fill(&outpoint,
        "f34e1c37e736727770fed85d1b129713ef7f300304498c31c833985f487fa2f3", 0);
bbp_txout_create_p2pkh(&prev_outs[0], 87000000,
        "6bf19e55f94d986b4640c154d864699341919511");
bbp_txin_create_signable(&ins_sign[0], &outpoint, &prev_outs[0]);

{% endhighlight %}

We have the outputs and the signable inputs, so we go ahead and construct the message:

{% highlight c %}

tx.version = bbp_eint32(BBP_LITTLE, 1);
tx.outputs_len = 2;
tx.outputs = outs;
tx.inputs_len = 1;
tx.inputs = ins_sign;
tx.locktime = 0;
msg_len = bbp_tx_size(&tx, BBP_SIGHASH_ALL);
msg = malloc(msg_len);
bbp_tx_serialize(&tx, msg, BBP_SIGHASH_ALL);

{% endhighlight %}

The external functions all come from [tx.h][tx.h]:

* From the previous post, you know that the `bbp_tx_size` and `bbp_tx_serialize` functions take care of sizing and serializing a transaction structure to raw bytes.
* The `bbp_outpoint_fill` function fills a `bbp_outpoint_t` structure from an UTXO. The UTXO reference consist of a previous transaction txid and the output index within the transaction.
* The `bbp_txin_create_signable` function creates a fake input for our message by copying the corresponding UTXO script.

Since we'll sign all transaction inputs, we set the `flag` parameter to `SIGHASH_ALL` (`01`). Beware that it's here padded to 32-bit for no apparent reason.

#### The final message

Here's the subject of our input signature:

    /* version (32-bit) */
    01 00 00 00

    /* number of inputs (varint) */
    01

    /* input UTXO txid (hash256, little-endian) */
    f3 a2 7f 48 5f 98 33 c8
    31 8c 49 04 03 30 7f ef
    13 97 12 1b 5d d8 fe 70
    77 72 36 e7 37 1c 4e f3

    /* input UTXO index (32-bit) */
    00 00 00 00

    /* input UTXO script (varint + data) */
    19 76 a9 14 6b f1 9e 55
    f9 4d 98 6b 46 40 c1 54
    d8 64 69 93 41 91 95 11
    88 ac
    
    /* input sequence */
    ff ff ff ff

    /* number of outputs (varint) */
    02

    /* output value (64-bit) */
    e0 fe 7e 01 00 00 00 00

    /* output script (varint + data) */
    19 76 a9 14 18 ba 14 b3
    68 22 95 cb 05 23 0e 31
    fe cb 00 08 92 40 66 08
    88 ac

    /* change output value (64-bit) */
    e0 84 b0 03 00 00 00 00

    /* change output script (varint + data) */
    19 76 a9 14 6b f1 9e 55
    f9 4d 98 6b 46 40 c1 54
    d8 64 69 93 41 91 95 11
    88 ac

    /* locktime (32-bit) */
    00 00 00 00

    /* SIGHASH (32-bit) */
    01 00 00 00

Compare the above bytes to the `msg` output from [ex-tx-build.c][ex-tx-build.c]. This is also the message against which the `OP_CHECKSIG` opcode validates an input signature.

### Get the code!

Full source on [GitHub]({{ site.bbp_src_root }}).

### Next block in chain?

You learned that the first step in transaction building is obtaining the UTXO set of a keypair. Outputs define the value we need to gather. Transaction output value must not exceed gathered UTXO value. Change outputs solve the indivisibility problem of UTXOs. UTXO scripts appear in the signable message of their corresponding inputs.

In the [next article][next] we'll sign and pack our raw transaction. {{ site.post_bottom_line }}


[history]: https://www.biteasy.com/testnet/addresses/mqMi3XYqsPvBWtrJTk8euPWDVmFTZ5jHuK
[utxos]: https://api.biteasy.com/testnet/v1/addresses/mqMi3XYqsPvBWtrJTk8euPWDVmFTZ5jHuK/unspent-outputs
[tx-1]: https://blockstream.info/testnet/tx/f34e1c37e736727770fed85d1b129713ef7f300304498c31c833985f487fa2f3
[tx-2]: https://blockstream.info/testnet/tx/65216856608dba6b74e1ea202eb712f64d340bc8cf48b8db5624447b15bd20c6
[tx-3]: https://blockstream.info/testnet/tx/6b580bada66ebde408a5c24f44e5a27aa5108922cadfb20726ea6ce194a53934
[tx.h]: {{ site.bbp_src }}/tx.h
[ex-tx-build.c]: {{ site.bbp_src }}/ex-tx-build.c
[next]: {% post_url /basic-blockchain-programming/2015-06-03-the-first-transaction-part-two %}
