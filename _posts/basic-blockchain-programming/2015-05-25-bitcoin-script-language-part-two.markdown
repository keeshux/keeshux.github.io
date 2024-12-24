---
layout: post
title: The Bitcoin Script language (pt. 2)
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, transactions, script, assembly, opcode, stack, hashing, ecdsa]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 11

permalink: /basic-blockchain-programming/bitcoin-script-language-part-two/
---

In the [first part][previous] I introduced the Script opcodes for constants and push data. We're slowly approaching the scripts you'll include in real transactions. Specifically, we're bound to deal with hashes and ECDSA signatures at some point, that's why Script has even opcodes for crypto functions.

<!--more-->

#### Arithmetic

Look at some of the many arithmetic opcodes:

|opcode  |encoding|
|--------|--------|
|`OP_ADD`|`93`    |
|`OP_SUB`|`94`    |

Both are totally stack-based operations, meaning that they take no explicit argument. `OP_ADD` (`OP_SUB`) pops the top two items of the stack and adds (substracts) them. The result of the operation is then pushed on top again.

Example:

    55 59 93 56 94

or:

    OP_5 OP_9 OP_ADD OP_6 OP_SUB

Here's how the stack evolves:

    []
    [5]
    [5, 9]
    [14]
    [14, 6]
    [8]

The script returns 8.

#### Comparison

Again, scripts are used for transaction validation, and comparisons are a primary need for a validator:

|opcode          |encoding|
|----------------|--------|
|`OP_EQUAL`      |`87`    |

`OP_EQUAL` pops and compares the top two items on the stack, then pushes `OP_TRUE` if they're equal or `OP_FALSE` otherwise.

Example:

    02 c3 72 02 03 72 01 c0 93 87

or:

    [c3 72] [03 72] [c0] OP_ADD OP_EQUAL

Here's how the stack evolves:

    []
    [c3 72]
    [c3 72, 03 72]
    [c3 72, 03 72, c0]
    [c3 72, c3 72]
    [1]

It's worth noting that the script eventually "succeeds", because it returns `OP_TRUE`.

#### Stack manipulation

This is the only opcode you're going to use for stack manipulation:

|opcode  |encoding|
|--------|--------|
|`OP_DUP`|`76`    |

`OP_DUP` takes no arguments, it just duplicates the top stack item.

Example:

    04 b9 0c a2 fe 76 87

or:

    [b9 0c a2 fe] OP_DUP OP_EQUAL

Here's how the stack evolves:

    []
    [b9 0c a2 fe]
    [b9 0c a2 fe, b9 0c a2 fe]
    [1]

Obviously, the script succeeds, since `OP_EQUAL` would never fail after `OP_DUP`!

#### Crypto

These opcodes are certainly the most interesting:

|opcode             |encoding|
|-------------------|--------|
|`OP_HASH160`       |`a9`    |
|`OP_CHECKSIG`      |`ac`    |

`OP_HASH160` pops the top stack item, performs hash160 on it and then pushes the result back. Basically, this opcode computes the Bitcoin P2PKH address from an ECDSA public key.

`OP_CHECKSIG` pops the top two stack items, the first being an ECDSA public key and the second being a DER-encoded ECDSA signature. After that, it pushes `OP_TRUE` if the signature is valid for that public key or `OP_FALSE` otherwise. It's the Script version of OpenSSL's `ECDSA_verify`.

Both opcodes will be described in the next post.

### Where's the code?

There are no code examples in this chapter. In the end a script is an array of data where your only contribution is mapping opcodes names to raw bytes. We could have developed a tiny Script interpreter, but it's way beyond our goals. Typical Bitcoin clients don't run scripts as it's a mining task, so our concern is just writing well-formed scripts that miners would accept.

### Next block in chain?

You learned some more Script opcodes, including crypto functions essential to ECDSA verifications.

In the [next article][next] we'll examine the role of keys and addresses in *standard scripts*. {{ site.post_bottom_line }}


[previous]: {% post_url /basic-blockchain-programming/2015-05-25-bitcoin-script-language-part-one %}
[next]: {% post_url /basic-blockchain-programming/2015-05-29-standard-scripts %}
