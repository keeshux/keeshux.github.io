---
layout: post
title: Inside transactions
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, transaction, utxo, outpoint, script]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 13

permalink: /basic-blockchain-programming/inside-transactions/
---

With all things in place, we're ready to examine what Bitcoin transactions are made of. All the loose ends about scripts will be tied up, plus you'll practice some C code to accomplish our main mission, that is writing a raw transaction by hand.

<!--more-->

Unfortunately, transactions and scripts are sort of a chicken and egg situation. Whatever subject you start from, you'll definitely need a basic grasp of the other one to get things going. I chose to leave transactions last because I liked a bottom-up approach to this series, but I had to take some concepts for granted --like inputs and outputs-- that are going to be clear in this final part.

### Transaction data structures

This is what a transaction embeds:

* Some constant values.
* An array of one or more inputs.
* An array of one or more outputs.

Before writing raw transactions, I'm going to describe the data structures defined in [tx.h][tx.h]. Needless to say, all number fields will be serialized little-endian.

#### Output

Transaction outputs are the blockchain entities actually holding bitcoin value:

{% highlight c %}

typedef struct {
    uint64_t value;
    uint64_t script_len;
    uint8_t *script;
} bbp_txout_t;

{% endhighlight %}

The `value` field is the transferred bitcoin amount in satoshis, and the `script_len` (varint) plus `script` (byte array) fields are a vardata holding the output script code. The script contains the instructions to later redeem the output value. Within a transaction, each output has an index that is its offset in the outputs array.

#### Outpoint

Any Bitcoin transaction that is not coinbase (read next section), must refer to one or more previously mined transactions, because what transactions do is moving coins from some outputs to others. Well, an *outpoint* is a fixed structure that expresses a pointer to an existing transaction output:

{% highlight c %}

typedef struct {
    uint8_t txid[32];
    uint32_t index;
} bbp_outpoint_t;

{% endhighlight %}

Unsurprisingly, the `txid` field is the hash256 identifier of the referred transaction (little-endian), while `index` is the 0-based offset of the output in the transaction outputs array.

#### Input

A transaction input is an entity able to redeem value from a previously unspent output, also known as UTXO:

{% highlight c %}

typedef struct {
    bbp_outpoint_t outpoint;
    uint64_t script_len;
    uint8_t *script;
    uint32_t sequence;
} bbp_txin_t;

{% endhighlight %}

The `outpoint` field is the pointer to the UTXO we want to spend. The `script_len` (varint) plus `script` (byte array) fields are a vardata holding the input script that, prepended to the UTXO script, is expected to succeed. The `sequence` field is left for advanced operations, most of the time you'll just set it to `ffffffff`.

#### Transaction

Now that all subcomponents were described, here's the layout of a blockchain transaction:

{% highlight c %}

typedef struct {
    uint32_t version;
    uint64_t inputs_len;
    bbp_txin_t *inputs;
    uint64_t outputs_len;
    bbp_txout_t *outputs;
    uint32_t locktime;
} bbp_tx_t;

{% endhighlight %}

The `version` of a transaction is established by network consensus and is currently constant `1`. I won't cover `locktime` for now, just set it to zero. When serialized, the inputs and outputs arrays are prefixed with a varint announcing their count.

### Serialization

To make things clearer, I want to show you how to serialize a transaction in code. The `bbp_tx_serialize` function is taken from [tx.h][tx.h]:

{% highlight c %}

void bbp_tx_serialize(const bbp_tx_t *tx, uint8_t *raw, bbp_sighash_t flag) {
    uint8_t *ptr;
    size_t varlen;
    int i;
    
    ptr = raw;

    /* version */
    *(uint32_t *)ptr = bbp_eint32(BBP_LITTLE, tx->version);
    ptr += sizeof(uint32_t);

    /* inputs count */
    bbp_varint_set(ptr, tx->inputs_len, &varlen);
    ptr += varlen;

    /* inputs */
    for (i = 0; i < tx->inputs_len; ++i) {
        bbp_txin_t *txin = &tx->inputs[i];

        /* outpoint */
        memcpy(ptr, txin->outpoint.txid, 32);
        ptr += 32;
        *(uint32_t *)ptr = bbp_eint32(BBP_LITTLE, txin->outpoint.index);
        ptr += sizeof(uint32_t);

        /* script */
        bbp_varint_set(ptr, txin->script_len, &varlen);
        ptr += varlen;
        memcpy(ptr, txin->script, txin->script_len);
        ptr += txin->script_len;

        /* sequence */
        *(uint32_t *)ptr = bbp_eint32(BBP_LITTLE, txin->sequence);
        ptr += sizeof(uint32_t);
    }

    /* outputs count */
    bbp_varint_set(ptr, tx->outputs_len, &varlen);
    ptr += varlen;

    /* outputs */
    for (i = 0; i < tx->outputs_len; ++i) {
        bbp_txout_t *txout = &tx->outputs[i];

        /* value */
        *(uint64_t *)ptr = bbp_eint64(BBP_LITTLE, txout->value);
        ptr += sizeof(uint64_t);

        /* script */
        bbp_varint_set(ptr, txout->script_len, &varlen);
        ptr += varlen;
        memcpy(ptr, txout->script, txout->script_len);
        ptr += txout->script_len;
    }

    /* locktime */
    *(uint32_t *)ptr = bbp_eint32(BBP_LITTLE, tx->locktime);
    ptr += sizeof(uint32_t);

    if (flag) {

        /* sighash */
        *(uint32_t *)ptr = bbp_eint32(BBP_LITTLE, flag);
    }
}

{% endhighlight %}

Ignore the `flag` parameter and assume it's `0` to skip the last `if` block. The code is pretty simple and I think it doesn't need further explanations. If you're in trouble, you might consider reading again the articles on [blockchain serialization][serialization].

One last thing. The `bbp_tx_serialize` function expects a properly allocated byte array, so you must use `bbp_tx_size` to get the exact amount of bytes required to serialize the `tx` transaction, for example:

{% highlight c %}

bbp_tx_t tx;
size_t len;
uint8_t *raw;

...

len = bbp_tx_size(&tx, 0);
raw = malloc(len);
bbp_tx_serialize(&tx, raw, 0);

{% endhighlight %}

### Coinbase transactions

*Coinbase* transactions (which inspired the [Coinbase][coinbase] company name) are the only transactions without real inputs. They're sort of genesis transactions, because they create bitcoins from nowhere and are not connected to any previous transaction. Each block in the blockchain has one and one only coinbase transaction that rewards the block miner with the famous ever-halving amount of bitcoins (currently 25 BTC).

Here's an example [coinbase transaction][example-coinbase] from Mainnet. It has a single output that sends a 25 BTC reward plus some fee to the following address:

    1KFHE7w8BhaENAswwryaoccDb6qcT6DbYY

by using a standard P2PKH output script:

    OP_DUP
    OP_HASH160

    [c8 25 a1 ec f2 a6 83 0c
     44 01 62 0c 3a 16 f1 99
     50 57 c2 ab]

    OP_EQUALVERIFY
    OP_CHECKSIG

The push data element is exactly the above address properly Base58Check-decoded. Likewise, the transaction has only one input. Since a coinbase transaction creates bitcoins, its input doesn't point to any previous UTXO. Typically, coinbase input scripts are placeholders for block metadata, like the block height in the blockchain, the name of the mining software, generic binary data etc.

### Next block in chain?

You learned the fundamental transaction data structures. Most transactions draw coins from previous outputs, while coinbase transactions generate coins from nowhere.

In the [next article][next] you'll learn to build your first blockchain transaction. {{ site.post_bottom_line }}


[coinbase]: https://www.coinbase.com/
[example-coinbase]: https://blockstream.info/tx/e7472be34d36b9068e54466b4ef1d06456f65aa33aa78a4725278b6d37ebcb60
[tx.h]: {{ site.bbp_src }}/tx.h
[serialization]: {% post_url /basic-blockchain-programming/2015-05-01-serialization-part-one %}
[next]: {% post_url /basic-blockchain-programming/2015-06-03-the-first-transaction-part-one %}
