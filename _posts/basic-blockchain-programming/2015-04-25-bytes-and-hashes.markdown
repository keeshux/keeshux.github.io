---
layout: post
title: Bytes and hashes
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, hashing, sha-2, ripemd]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 1

permalink: /basic-blockchain-programming/bytes-and-hashes/
---

Hashing algorithms take a front seat in the Bitcoin ecosystem, you're going to find them everywhere in the blockchain so I believe it's the best subject to start with.

<!--more-->

Before we take off, keep in mind that almost all blockchain data structures are serialized in a [little-endian][little-endian] fashion, whereas few objects (like network addresses) retain the [big-endian][big-endian] byte order. If not otherwise stated I assume we're talking and working on little-endian machines. Take your time and try not to get confused or weird things may happen as soon as you join the peer network.

### Bitcoin hash functions

As far as we're concerned, a [hash function][hash-function] translates an arbitrary amount of bytes into a fixed one. Forget about non-reversibility and other stuff because the fixed length is the property we want to stick with for now. Among others, Bitcoin relies on hashes for several key purposes:

* Identifiers
* Addresses
* Transaction signatures
* [Checksums][checksum] and other validations

Bitcoin is very interesting in that it has adopted well-established, sometimes basic concepts of computer science yet to create something mind-blowingly innovative. Hashes are no exception, because Satoshi used combinations of [SHA-2][sha2] and [RIPEMD][ripemd] instead of defining his own cryptographic functions.

Specifically, he introduced two compound hash functions:

* *hash256*(d) = SHA-256(SHA-256(d))
* *hash160*(d) = RIPEMD-160(SHA-256(d))

where SHA-256 is a 256-bit variant of SHA-2, RIPEMD-160 is a 160-bit variant of RIPEMD and *d* is a generic array of bytes. No wonder the hash256 and hash160 functions return 256-bit (32 bytes) and 160-bit (20 bytes) arrays respectively.

Was the choice of double-hashing personal or security related? Sorry for not being a cryptogeek, but based on [some discussions][why-satoshi-hashes] my best guess is you'd better take this for granted.

### Hash256 for identifiers

If you're a bit familiar with any wallet or block explorer on the web you've stumbled upon hash256 at least once, because this is the kind of hash the blockchain uses to identify its core entities: *blocks* and *transactions*.

Consider the link to [this block][web-block] or [this transaction][web-tx] in the blockchain, skip the parts you don't understand and focus on the last component of both URLs which you'll also spot at some point in the web page. Those long strings are primary keys in the blockchain database, you access a unique block (transaction) with that identifier and you're guaranteed that no other block (transaction) will ever have the same identifier. Perhaps you also noticed that another property block and transaction ids share is their length, that is 64 characters.

Back to the geeky stuff for a minute. There's one more thing to these strings: they're made of hexadecimal digits (0-9 a-f). As a programmer a bell immediately rings in your head when you deal with hexes, doesn't it? Each hex pair represent a single byte of data and by doing the math you'll find out that a string of 64 hex digits is an array of 32 bytes, just like hash256. In fact, both identifiers result from a hash256 computation:

* *block_id* = hash256(block.header)
* *transaction_id* = hash256(transaction)

We'll dig into blocks and transactions later, but this is one application of hash256 it's worth noting from the very beginning. Other uses of hash256 will be explained later on.

### Hash160 for addresses

If hash256 is the king of Bitcoin hashes, no doubt hash160 is the queen. I know there only are two but it's nice to set some order of importance --I hope you don't blame me for sexism here. Nevertheless, even if hash256 spreads all across the blockchain, hash160 reigns over a single strategic land you've surely heard of: *addresses*!

Don't rush into addresses like many other tutorials do, they won't make any sense until you have a fair grasp of transactions. Just be patient, we'll cover them in detail.

### Hashes on the wire

Block and transaction hashes follow the little-endian rule and that's why your first attempts at publishing a raw transaction may be puzzling when you poll back the web explorers. For example, take the 64-chars hash of the above transaction (sometimes called *txid*) as seen on blockchain.info and split it into 32 groups of 2 hex digits (one byte each):

    46 28 71 64 db 45 a7 8a
    91 96 25 7d a4 5b 62 88
    1e 39 4a 3d 11 fb 40 39
    43 bb bf 8e c4 aa f9 ee

Say we want to handle this in our code, its best fit is an array:

{% highlight c %}

unsigned char txid[32] = { 0x46, 0x28, 0x71, ..., 0xee };

{% endhighlight %}

Now consider the nature of the txid, a big multibyte integer (256-bit) stored in an array due to the lack of a fitting primitive type. Our rough guess expects `46` to be the MSB (most significant byte) for being the leftmost in the string, yet we stored it at the lowest index. If we were on an Intel machine the `46` would be the LSB (least significant byte) instead. Weak.

Here's a less intuitive encoding:

{% highlight c %}

unsigned char txid[32] = { 0xee, ..., 0x71, 0x28, 0x46 };

{% endhighlight %}

See how `46` is now the MSB of the array for a little-endian machine that stores more significant bytes at higher memory locations? Fine, this finally makes sense.

Remember this when dealing with raw Bitcoin traffic, because a direct consequence is that we see "reversed hashes" on the wire.

### Next block in chain?

You learned that the Bitcoin blockchain is mostly a little-endian monster and it's our responsibility to submit binary data other peers will recognize. Blocks and transactions have equally formed primary keys that are basically a hash of their own bytes (or part of them). Bitcoin hash functions are normally built on top of other well-established hash functions.

In the [next article][next] we'll analyze *serialization* and gear up for some real code. {{ site.post_bottom_line }}


[hash-function]: http://en.wikipedia.org/wiki/Hash_function
[checksum]: http://en.wikipedia.org/wiki/Checksum
[sha2]: http://en.wikipedia.org/wiki/SHA-2
[ripemd]: http://en.wikipedia.org/wiki/RIPEMD
[why-satoshi-hashes]: https://bitcointalk.org/index.php?topic=45456.0
[web-block]: https://blockstream.info/block/00000000000000000ffd0d82302d4225aaa0ccfa29dc329f9e966b8fc83cbea5
[web-tx]: https://blockstream.info/tx/46287164db45a78a9196257da45b62881e394a3d11fb403943bbbf8ec4aaf9ee
[little-endian]: http://en.wikipedia.org/wiki/Endianness#Little-endian
[big-endian]: http://en.wikipedia.org/wiki/Endianness#Big-endian
[next]: {% post_url /basic-blockchain-programming/2015-05-01-serialization-part-one %}
