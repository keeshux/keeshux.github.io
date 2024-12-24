---
layout: post
title: Serialization (pt. 1)
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, hex, endianness]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 2

permalink: /basic-blockchain-programming/serialization-part-one/
---

Enough of theory, we're up to some real code! Before treating full-blown entities, though, you need to learn how to serialize generic data through a small set a primitives. Think of C variables, we certainly want to know what `int` and `char` mean before defining a custom `struct`.

<!--more-->

Remember, little-endian is the default byte order. Code examples may include [common.h][common.h] for general purpose routines and [endian.h][endian.h] for naïve endian conversions. Hash functions are defined in [hash.h][hash.h] with help from OpenSSL. From now on I expect you don't get in trouble with pointer arithmetics.

### Integers

First of all, there's no use for negative integers in the blockchain. Integers are always unsigned, they can hold 8-bit, 16-bit, 32-bit or 64-bit values. In [ex-integers.c][ex-integers.c]:

{% highlight c %}

uint8_t n8 = 0x01;
uint16_t n16 = 0x4523;
uint32_t n32 = 0xcdab8967;
uint64_t n64 = 0xdebc9a78563412ef;

{% endhighlight %}

we serialize "n8 + n16 + n32 + n64" into (1 + 2 + 4 + 8) = 15 bytes. When storing single bytes we don't care about endianness, but we must in all other cases. That's why little-endian order has to be enforced for multibyte values:

{% highlight c %}

uint8_t ser[15];

*ser = n8;
*(uint16_t *)(ser + 1) = bbp_eint16(BBP_LITTLE, n16);
*(uint32_t *)(ser + 3) = bbp_eint32(BBP_LITTLE, n32);
*(uint64_t *)(ser + 7) = bbp_eint64(BBP_LITTLE, n64);

{% endhighlight %}

If the machine is little-endian, the numbers are stored without additional manipulation. If not, their bytes are reversed.

The resulting `ser` array (15 bytes):

    01
    23 45
    67 89 ab cd
    ef 12 34 56 78 9a bc de

### Fixed-length data

By fixed-length data I mean data whose length is known in advance and therefore doesn't need to be attached. In actual code, `memcpy` is all we need to serialize binary data.

#### Null-padded strings

Fixed-length strings are encoded in UTF-8 and padded with `\0` characters up to the desired length. This is the case of the Bitcoin p2p protocol, where messages are identified by human-readable names like `version`, `tx`, `getblocks` etc. with a maximum length of 12 characters. In [ex-fixed-strings.c][ex-fixed-strings.c]:

{% highlight c %}

uint32_t n32 = 0x68f7a38b;
char str[] = "FooBar";
size_t str_len = 10;
uint16_t n16 = 0xee12;

{% endhighlight %}

we serialize "n32 + str + n16" into (4 + 10 + 2) = 16 bytes. Safely assume that ASCII strings encode to raw bytes for free. The actual string length is required to compute the padding:

{% highlight c %}

size_t str_real_len = strlen(str);
size_t str_pad_len = str_len - str_real_len;

{% endhighlight %}

Final packing:

{% highlight c %}

uint8_t ser[16];

*(uint32_t *)(ser) = bbp_eint32(BBP_LITTLE, n32);
memcpy(ser + 4, str, str_real_len);
if (str_pad_len > 0) {
    memset(ser + 4 + str_real_len, '\0', str_pad_len);
}
*(uint16_t *)(ser + 4 + str_len) = bbp_eint16(BBP_LITTLE, n16);

{% endhighlight %}

The resulting `ser` array (16 bytes):

    8b a3 f7 68
    46 6f 6f 42 61 72 00 00 00 00
    12 ee

#### Hashes

Hashes are another typical example of fixed-length data. In [ex-hashes.c][ex-hashes.c] (requires OpenSSL):

{% highlight c %}

char message[] = "Hello Bitcoin!";
uint16_t prefix = 0xd17f;
uint8_t suffix = 0x8c;
uint8_t digest[32];

{% endhighlight %}

we serialize "prefix + hash256(message) + suffix" into (2 + 32 + 1) = 35 bytes. Below we first calculate the SHA-256 digest of the message:

{% highlight c %}

bbp_sha256(digest, (uint8_t *)message, strlen(message));

{% endhighlight %}

The SHA-256 algorithm yields a 256-bit digest, so we allocate an array of 32 bytes in advance. `SHA256_DIGEST_LENGTH` would be equivalent here, but I want to be as explicit as possible. The SHA-256 digest for the "Hello Bitcoin!" string is:

    51 8a d5 a3 75 fa 52 f8
    4b 2b 3d f7 93 3a d6 85
    eb 62 cf 69 86 9a 96 73
    15 61 f9 4d 10 82 6b 5c

By hashing again:

{% highlight c %}

bbp_sha256(digest, digest, 32);

{% endhighlight %}

we get the hash256 digest:

    90 98 6e a4 e2 8b 84 7c
    c7 f9 be ba 87 ea 81 b2
    21 ca 6e af 98 28 a8 b0
    4c 29 0c 21 d8 91 bc da

with `90` being the MSB because SHA-256 works big-endian. Final packing:

{% highlight c %}

uint8_t ser[35];

*(uint16_t *)(ser) = bbp_eint16(BBP_LITTLE, prefix);
memcpy(ser + 2, digest, 32);
*(ser + 2 + 32) = suffix;

{% endhighlight %}

The resulting `ser` array (35 bytes):

    7f d1
    90 98 6e a4 e2 8b 84 7c
    c7 f9 be ba 87 ea 81 b2
    21 ca 6e af 98 28 a8 b0
    4c 29 0c 21 d8 91 bc da
    8c

### Get the code!

Full source on [GitHub]({{ site.bbp_src_root }}).

### Next block in chain?

You learned how to serialize fixed-length data for the blockchain.

In the [second part][next] we'll deal with variable-length data. {{ site.post_bottom_line }}


[common.h]: {{ site.bbp_src }}/common.h
[endian.h]: {{ site.bbp_src }}/endian.h
[hash.h]: {{ site.bbp_src }}/hash.h
[ex-integers.c]: {{ site.bbp_src }}/ex-integers.c
[ex-fixed-strings.c]: {{ site.bbp_src }}/ex-fixed-strings.c
[ex-hashes.c]: {{ site.bbp_src }}/ex-hashes.c
[next]: {% post_url /basic-blockchain-programming/2015-05-01-serialization-part-two %}
