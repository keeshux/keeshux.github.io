---
layout: post
title: The first transaction (pt. 2)
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, transaction, p2pkh, utxo, outpoint, script, hashing, ecdsa]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 15

permalink: /basic-blockchain-programming/the-first-transaction-part-two/
---

The [first part][previous] covered the basics of transaction building, like creating outputs from the destination addresses and gathering the needed input value. The most complicated part was constructing a message for the input signature. Now that we have one, we're going to generate a signature and finally a script for the transaction input. The last step is about packing all the stuff together.

<!--more-->

### The input script

As a result of [ex-tx-build.c][ex-tx-build.c], we built the signable message for our input. In [ex-tx-sign.c][ex-tx-sign.c] we'll reuse the message as a starting point.

#### Producing the signature

Rather than the message itself, we'll sign its hash256 digest:

    62 44 98 0f a0 75 2e 5b
    46 43 ed b3 53 fd a5 23
    8a 9a 3d 44 49 16 76 78
    8e fd d2 5d d6 48 55 ba

with our [ECDSA private key][ec-priv.pem]:

    16 26 07 83 e4 0b 16 73
    16 73 62 2a c8 a5 b0 45
    fc 3e a4 af 70 f7 27 f3
    f9 e9 2b dd 3a 1d dc 42

This is one DER signature I yielded (yours will differ):

    30 44 02 20 11 1a 48 2a
    ba 6a fb a1 2a 6f 27 de
    76 7d d4 d0 64 17 de f6
    65 bd 10 0b c6 8c 42 84
    5c 75 2a 8f 02 20 5e 86
    f5 e0 54 b2 c6 ca c5 d6
    63 66 4e 35 77 9f b0 34
    38 7c 07 84 8b c7 72 44
    42 ca cf 65 93 24 

#### Flag and assembly

The `SIGHASH` flag (now 8-bit) is appended again to the signature, and together with the compressed [ECDSA public key][ec-pub.pem]:

    02
    82 00 6e 93 98 a6 98 6e
    da 61 fe 91 67 4c 3a 10
    8c 39 94 75 bf 1e 73 8f
    19 df c2 db 11 db 1d 28

we're finally able to build our P2PKH input script:

    47 30 44 02 20 11 1a 48
    2a ba 6a fb a1 2a 6f 27
    de 76 7d d4 d0 64 17 de
    f6 65 bd 10 0b c6 8c 42
    84 5c 75 2a 8f 02 20 5e
    86 f5 e0 54 b2 c6 ca c5
    d6 63 66 4e 35 77 9f b0
    34 38 7c 07 84 8b c7 72
    44 42 ca cf 65 93 24 01

    21 02 82 00 6e 93 98 a6
    98 6e da 61 fe 91 67 4c
    3a 10 8c 39 94 75 bf 1e
    73 8f 19 df c2 db 11 db
    1d 28

Yes, the signing process is possibly the most annoying and error-prone part of our work.

### Packing the transaction

We're all set to pack the transaction from our inputs and outputs. Let's look at [ex-tx-pack.c][ex-tx-pack.c].

#### Inputs and outputs

Like I did for outputs, I also wrote a C macro in [tx.h][tx.h] for creating P2PKH inputs. The macro takes an UTXO outpoint, a signature, a public key and a `SIGHASH` flag:

{% highlight c %}

void bbp_txin_create_p2pkh(bbp_txin_t *txin, const bbp_outpoint_t *outpoint,
        const char *sig, const char *pub, bbp_sighash_t flag);

{% endhighlight %}

We use the macro to create our input, whereas the outputs code is taken from [ex-tx-build.c][ex-tx-build.c] as is:

{% highlight c %}

bbp_outpoint_fill(&outpoint,
        "f34e1c37e736727770fed85d1b129713ef7f300304498c31c833985f487fa2f3", 0);
bbp_txin_create_p2pkh(&ins[0], &outpoint,
        "30440220111a482aba6afba12a6f27de767dd4d06...",
        "0282006e9398a6986eda61fe91674c3a108c39947...",
        BBP_SIGHASH_ALL);

bbp_txout_create_p2pkh(&outs[0], 25100000,
        "18ba14b3682295cb05230e31fecb000892406608");
bbp_txout_create_p2pkh(&outs[1], 61900000,
        "6bf19e55f94d986b4640c154d864699341919511");

{% endhighlight %}

#### Final structure

The easiest step is assembling the transaction structure and feeding it to `bbp_tx_serialize`:

{% highlight c %}

tx.version = bbp_eint32(BBP_LITTLE, 1);
tx.outputs_len = 2;
tx.outputs = outs;
tx.inputs_len = 1;
tx.inputs = ins;
tx.locktime = 0;
rawtx_len = bbp_tx_size(&tx, 0);
rawtx = malloc(rawtx_len);
bbp_tx_serialize(&tx, rawtx, 0);

{% endhighlight %}

The `flag` parameter is set to `0` to pack a signed transaction instead of a signable message. The serialized transaction is:

    /* version (32-bit) */
    01 00 00 00

    /* number of inputs (varint) */
    01

    /* UTXO txid (hash256, little-endian) */
    f3 a2 7f 48 5f 98 33 c8
    31 8c 49 04 03 30 7f ef
    13 97 12 1b 5d d8 fe 70
    77 72 36 e7 37 1c 4e f3

    /* UTXO index (32-bit) */
    00 00 00 00

    /* input script (varint + data) */
    6a 47 30 44 02 20 11 1a
    48 2a ba 6a fb a1 2a 6f
    27 de 76 7d d4 d0 64 17
    de f6 65 bd 10 0b c6 8c
    42 84 5c 75 2a 8f 02 20
    5e 86 f5 e0 54 b2 c6 ca
    c5 d6 63 66 4e 35 77 9f
    b0 34 38 7c 07 84 8b c7
    72 44 42 ca cf 65 93 24
    01 21 02 82 00 6e 93 98
    a6 98 6e da 61 fe 91 67
    4c 3a 10 8c 39 94 75 bf
    1e 73 8f 19 df c2 db 11
    db 1d 28 
    
    /* UTXO sequence */
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

and measures 225 bytes. The txid is obtained by performing hash256 on the transaction (big-endian):

    99 96 e2 f6 4b 6a f0 23
    2d d9 c8 97 39 5c e5 1f
    dd 35 e6 35 9e dd 28 55
    c6 0f f8 23 d8 d6 57 d1 

#### Publishing to the network

We made it, we've just built our first Bitcoin transaction! What's next? Of course we want to commit our transaction to the blockchain. To do that, web services exist to save us the burden of communicating with the p2p network.

For example, the [Blockr push service][tx-push] (Testnet in our scenario) comes handy to publish raw transactions to the blockchain. Insert a raw transaction like the `rawtx` output from [ex-tx-pack.c][ex-tx-pack.c] and you're done, you can even double-check it before confirming. If you didn't double-spend any of your UTXOs before and you've done everything correctly, you should see the transaction live after a few minutes. That is, as soon as it's mined in a block.

However, if you try to publish our sample transaction, you'll get the following error:

![Transaction push error][tx-push-error]

Don't worry, that's because I already published it by myself. See how it looks like [on a block explorer][sample-tx].

### Get the code!

Full source on [GitHub]({{ site.bbp_src_root }}).

### Next block in chain?

You learned how to sign transaction inputs and pack a raw blockchain transaction. The transaction identifier (txid) is the hash256 digest of the transaction bytes.

In the [next article][next] we'll have a look at *wallet software*. {{ site.post_bottom_line }}


[tx-push]: https://tbtc.blockr.io/tx/push
[tx-push-error]: /s/f/basic-blockchain-programming/tx-push-error.png
[sample-tx]: https://blockstream.info/testnet/tx/9996e2f64b6af0232dd9c897395ce51fdd35e6359edd2855c60ff823d8d657d1
[tx.h]: {{ site.bbp_src }}/tx.h
[ex-tx-build.c]: {{ site.bbp_src }}/ex-tx-build.c
[ex-tx-sign.c]: {{ site.bbp_src }}/ex-tx-sign.c
[ex-tx-pack.c]: {{ site.bbp_src }}/ex-tx-pack.c
[ec-priv.pem]: {{ site.bbp_src }}/ec-priv.pem
[ec-pub.pem]: {{ site.bbp_src }}/ec-pub.pem
[previous]: {% post_url /basic-blockchain-programming/2015-06-03-the-first-transaction-part-one %}
[next]: {% post_url /basic-blockchain-programming/2015-06-23-wallet-software %}
