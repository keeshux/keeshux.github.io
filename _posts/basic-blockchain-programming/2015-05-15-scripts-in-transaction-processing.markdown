---
layout: post
title: Scripts in transaction processing
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, transactions, utxo, outpoint, script]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 9

permalink: /basic-blockchain-programming/scripts-in-transaction-processing/
---

With some cryptography fundamentals and serialization practice under your belt, you should be more comfortable as we approach Bitcoin transactions. Well, *scripts* are the last step in the path. Here I'll give an overview of their role in transaction processing.

<!--more-->

### How bitcoins move

It's a common belief that bitcoins move from an address to another. In fact, they move through transaction *outputs*, whereas mining is the only special case in which bitcoins are created out of thin air. Outputs are the real endpoints holding money in the blockchain. However, when reused to send the money they hold to someone else, outputs become *inputs* to other transactions.

#### The transaction tree

Look at the picture below (courtesy of bitcoin.org) and notice how previous transaction outputs convert to spendable transaction inputs. This forms a deep tree of value transfers where each node represents a transaction. Whenever a transaction output is spent, the spending transaction becomes a child node.

![Transaction propagation][transaction-propagation]

Consider all these 7 transactions to be the only ones relevant to our wallet. Observe the path to TX 3 and assume 10k satoshis (0.0001 BTC) as the standard fee, here's a textual explanation:

1. Someone sends 100k to an output we "own".
2. The output becomes the spendable input of TX 0.
3. TX 0 distributes the previous output to new outputs of 40k and 50k.
4. The remaining value 100k - (40k + 50k) = 10k is the fee.
5. TX 1 reuses &lt;TX 0, output0&gt;, the one holding 40k.
6. TX 1 sends 30k to an output plus a 10k fee.
7. TX 3 reuses &lt;TX 1, output0&gt; to send 20k to output0 plus a 10k fee.

You know, in such a tree there must be a leaf at some point on the right. TX 3 is one of them, the other being TX 6, and both are marked with the *UTXO* acronym (Unspent Transaction Output). In our scenario, the leaves of the tree are:

* &lt;TX 3, output0&gt; = 20k
* &lt;TX 6, output0&gt; = 10k

They make up the wallet UTXO set and total 30k satoshis (0.0003 BTC), which happens to be the balance of the wallet. For your information, &lt;txid, output&gt; pairs are called *outpoints*.

If we extend the UTXO set to all blockchain transactions instead of constraining to a private wallet, we're able to track all the spendable bitcoins in the world. This is a convenient index to maintain for miners, because it's their way to find out if any transaction input is trying to double-spend a previously spent transaction output. In other words, transaction inputs must point to outputs in the global UTXO set in order to be spendable.

### Introducing scripts

There must be a mechanism to ensure that we're only allowed to spend certain transaction outputs, normally the ones associated with our wallet. Bitcoin solves this "authentication" problem in a fairly complex manner, yet extremely extensible and future-oriented: *Script*. Script is a programming language in all respects, with its only major limitation being the absence of loops. A script runs, terminates and eventually yields a boolean result.

I'll teach you the basics of the Script language in the following articles. For now, just bear in mind that blockchain transactions embed scripts for spending validation. Let's peek inside the whole thing.

#### Transaction validation

In the previous section, I spent some words on inputs and outputs. Now's the time to clarify what informations they pass along.  

Let alone some minor details, a transaction output contains:

* The amount of bitcoins to transfer.
* A script (the *output script*).

while a transaction input contains:

* An outpoint reference to the previous transaction output.
* A script (the *input script*).

In order to validate a transaction, all transaction inputs must validate. Follows the input validation process:

1. Go find the transaction referenced by the outpoint.
2. Find the output through its index in the transaction.
3. Take the output script.
4. Append the output script to the input script.
5. Execute the joined script on the Script interpreter.
6. If the script succeeds, then the transaction is valid.

That's the idea. It'll be a concrete process as soon as we examine Script and the transaction data structures.

#### Next block in chain?

You learned that a transaction moves bitcoins from output(s) to output(s). When spent, a former output becomes an input to the new transaction. Transaction outputs must not be spent twice. The UTXO set computes the balance of a wallet (or the entire Bitcoin network). Scripts describe the proper way to redeem a transaction output.

In the [next article][next] you'll get to know *Script*, the Bitcoin scripting language. {{ site.post_bottom_line }}


[transaction-propagation]: /s/f/basic-blockchain-programming/scripts-transaction-propagation.svg
[next]: {% post_url /basic-blockchain-programming/2015-05-25-bitcoin-script-language-part-one %}
