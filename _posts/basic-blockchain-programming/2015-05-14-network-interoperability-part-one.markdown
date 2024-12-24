---
layout: post
title: Network interoperability (pt. 1)
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, base58, base58check, networking]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 7

permalink: /basic-blockchain-programming/network-interoperability-part-one/
---

Often, the average bitcoiner is not aware that multiple blockchains exist. Most people transparently connect to the main network, because wallet software by default operates in the realm of real money. In fact, you're going to discover 3 different Bitcoin networks with their own peculiarities.

<!--more-->

### Parallel universes

As an user, I expect you to know that Bitcoin is backed by a vast peer-to-peer network. To be more precise, there are 2 public subnetworks:

* *Mainnet*
* *Testnet3*

with the "3" suffix meaning the 3rd generation of Testnet. Under normal operation wallet clients connect to Mainnet, the only network where bitcoins have concrete value in real life. Testnet name is self-explanatory, it's the best choice for testing and software development since Testnet coins are worthless.

The third network is sort a virtual network and is called *Regtest*. The name stands for "regression test" and it's a specific mode of Bitcoin Core in which local blocks are mined immediately. Regtest is therefore substantially different from Mainnet and Testnet3, where miners must comply with a certain set of consensus rules. Quick blocks make Regtest particularly interesting: it makes possible creating custom blockchains with negligible processing power.

#### Identifying networks

Mainnet and Testnet3 mainly differ in the default TCP port for p2p access and the prefix of transmitted packets (little-endian):

|        |port |packet prefix |
|--------|-----|--------------|
|Mainnet |8333 |`f9 be b4 d9` |
|Testnet3|18333|`0b 11 09 07` |

Additionally, Testnet3 validation rules are much more relaxed thus making room for experimental transactions.

Let alone the genesis block, blockchains are completely network agnostic. That is, blocks and transactions embed no information about the network they live in. There's no way to tell the network that broadcast a transaction from the transaction data alone. Incidentally, a transaction can be published as-is to both Mainnet and Testnet3.

To avoid ambiguity, user shared entities (namely private keys and *addresses*) were made network-dependent by adding magic prefixes. Later we'll learn what these prefixes are and how they affect the way keys and addresses are displayed.

### The Base58 encoding

There are entities that even the average Bitcoin user is bound to deal with: keys and addresses. In an attempt to make them shorter and slightly more human-readable than hexes, Bitcoin introduces the *Base58* encoding. Base58 is a stripped down version of [Base64][base64], a widely known scheme to display binary data in ASCII text. Here's how Base58 differs:

* Base58 only has alphanumeric symbols, no `+` and `/`.
* Base58 excludes `0`, `O`, `I`, `l` for visual ambiguity.
* Base58 strings are fully selectable with a double-click.
* Base58 symbol values follow the ASCII ordering.

The complete Base58 alphabet:

|Value|Ch|Value|Ch|Value|Ch|Value|Ch|
|-----|--|-----|--|-----|--|-----|--|
|    0| 1|   15| G|   30| X|   45| n|
|    1| 2|   16| H|   31| Y|   46| o|
|    2| 3|   17| J|   32| Z|   47| p|
|    3| 4|   18| K|   33| a|   48| q|
|    4| 5|   19| L|   34| b|   49| r|
|    5| 6|   20| M|   35| c|   50| s|
|    6| 7|   21| N|   36| d|   51| t|
|    7| 8|   22| P|   37| e|   52| u|
|    8| 9|   23| Q|   38| f|   53| v|
|    9| A|   24| R|   39| g|   54| w|
|   10| B|   25| S|   40| h|   55| x|
|   11| C|   26| T|   41| i|   56| y|
|   12| D|   27| U|   42| j|   57| z|
|   13| E|   28| V|   43| k|     |  |
|   14| F|   29| W|   44| m|     |  |

With such a mapping, the Base58 encoding is just a number base conversion. The only tricky part comes from big numbers, as seen in [base58.h][base58.h]. Beware of endianness, contrary to the majority of blockchain objects Base58 strings are encoded big-endian.

#### Base58Check

Since Base58 strings are long and unfriendly, a checksum suffix is typically appended to avoid typos. The checksum consists of the first 4 bytes of hash256(payload). The (payload + checksum) format is called *Base58Check*. Steps:

1. Perform hash256 on the payload bytes.
2. The first 4 bytes of the hash256 digest are the checksum.
3. Append the checksum to the payload.
4. Encode the result to Base58.

Base58Check examples will be treated in the second part.

### Get the code!

Full source on [GitHub]({{ site.bbp_src_root }}).

### Next block in chain?

You learned that there are 3 different Bitcoin networks. Real money flows on Mainnet, while test money resides on Testnet3. Regtest is for testing local, custom blockchains. All the long strings shared for bitcoin transfers are encoded Base58.

In the [next article][next] I'll complete the big picture with keys serialization and *addresses*, the typical transaction endpoints. {{ site.post_bottom_line }}


[base64]: http://en.wikipedia.org/wiki/Base64
[base58.h]: {{ site.bbp_src }}/base58.h
[qr-address]: https://blockchain.info/qr?data=16w2AWamiH2SS68NYSMDcrbh5MnZ1c5eju&size=300
[next]: {% post_url /basic-blockchain-programming/2015-05-14-network-interoperability-part-two %}
