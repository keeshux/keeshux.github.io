---
layout: post
title: Serialization (pt. 2)
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, hex, endianness]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 3

permalink: /basic-blockchain-programming/serialization-part-two/
---

Things get a little trickier when the length of a binary string can't be predicted, but the solution is pretty straightforward: the string is prefixed with useful information about its length. The core of variable-length serialization is the *varint* pseudotype.

<!--more-->

### Variable integers

We've met 4 integer types so far: int8, int16, int32 and int64. What if we wanted to save memory on average though? With millions of transactions, the blockchain is likely to notice conservative efforts on integer serialization, hence the *varint* type.

A varint may be of any of the above lengths, as long as such length is specified --except for int8-- in an additional 1-byte prefix:

{% highlight c %}

typedef enum {
    BBP_VARINT16 = 0xfd,
    BBP_VARINT32 = 0xfe,
    BBP_VARINT64 = 0xff
} bbp_varint_t;

{% endhighlight %}

8-bit varints have no such prefix because they're a value per se. A table will hopefully shed some light:

|size  |value                    |encoding                        |
|------|-------------------------|--------------------------------|
|8-bit |`8c`                     |`8c`                            |
|16-bit|`12 a4`                  |*`fd`* `12 a4`                  |
|32-bit|`12 a4 5b 78`            |*`fe`* `12 a4 5b 78`            |
|64-bit|`12 a4 5b 78 12 c4 56 d8`|*`ff`* `12 a4 5b 78 12 c4 56 d8`|

See how the varint prefix introduces the size of the number coming after. The only limitation of varint8 is that it's unable to represent the `fd`-`ff` values as they have a special meaning, so a varint16 would be required.

Check out [varint.h][varint.h] for a varint parsing implementation.

#### Example

Consider the byte string:

    13 9c fd 7d 80 44 6b a2 20 cc

as seen in [ex-varints.c][ex-varints.c]:

{% highlight c %}

uint8_t bytes[] = {
    0x13, 0x9c, 0xfd, 0x7d,
    0x80, 0x44, 0x6b, 0xa2,
    0x20, 0xcc
};

{% endhighlight %}

and the corresponding high-level structure:

{% highlight c %}

typedef struct {
    uint16_t fixed1;
    uint64_t var2;
    uint32_t fixed3;
    uint8_t fixed4;
} foo_t;

{% endhighlight %}

The struct has 3 fixed-length integers and 1 variable-length integer (by contract). Since varints can hold up to 64-bit values, we need to allocate the largest size. Here's how we proceed to decode the binary string into the struct:

{% highlight c %}

foo_t decoded;
size_t varlen;

decoded.fixed1 = bbp_eint16(BBP_LITTLE, *(uint16_t *)bytes);
decoded.var2 = bbp_varint_get(bytes + 2, &varlen);
decoded.fixed3 = bbp_eint32(BBP_LITTLE, *(uint32_t *)(bytes + 2 + varlen));
decoded.fixed4 = *(bytes + 2 + varlen + 4);

{% endhighlight %}

In other words:

1. The first field is an int16: `9c13`.
2. Go ahead and move to `bytes + 2` (int16 takes 2 bytes).
3. `bytes + 2` holds `fd` and announces a varint16.
4. Skip to the following 2 bytes.
5. The second field is `807d`.
6. Go ahead and move to `bytes + 5` (varint16 takes `varlen = 3` bytes).
7. The third field is an int32: `20a26b44`.
8. The fourth field is an int8: `cc`.

### Variable data

Now that you're able to read a varint, deserializing variable data is a no-brainer. Technically, variable data is just some binary data prefixed with a varint holding its length. Consider the 13-bytes string:

    fd 0a 00 e3 03 41 8b a6
    20 e1 b7 83 60

as seen in [ex-vardata.c][ex-vardata.c]:

{% highlight c %}

uint8_t bytes[] = {
    0xfd, 0x0a, 0x00, 0xe3,
    0x03, 0x41, 0x8b, 0xa6,
    0x20, 0xe1, 0xb7, 0x83,
    0x60
};

{% endhighlight %}

Here's the decoding process:

{% highlight c %}

size_t len;
size_t varlen;
uint8_t data[100] = { 0 };

len = bbp_varint_get(bytes, &varlen);
memcpy(data, bytes + varlen, len);

{% endhighlight %}

Like in the previous example, we find a varint16 at the beginning of the array holding the value `0a`, that is 10 in decimal base. 10 is the length of the data coming next, so we read 10 bytes starting from `byte + 3` because a varint16 takes `varlen = 3` bytes. That's it!

The same applies for variable strings, you just encode them in UTF-8 before serialization.

### Get the code!

Full source on [GitHub]({{ site.bbp_src_root }}).

### Next block in chain?

You learned how to serialize variable-length data for the blockchain. You're fully set to exploit the bigger entities!

In the [next article][next] I'll teach you some concepts about *keys* and blockchain property. {{ site.post_bottom_line }}


[varint.h]: {{ site.bbp_src }}/varint.h
[ex-varints.c]: {{ site.bbp_src }}/ex-varints.c
[ex-vardata.c]: {{ site.bbp_src }}/ex-vardata.c
[next]: {% post_url /basic-blockchain-programming/2015-05-11-keys-as-property %}
