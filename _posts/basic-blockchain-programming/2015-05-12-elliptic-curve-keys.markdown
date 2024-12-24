---
layout: post
title: Elliptic-curve keys
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, elliptic-curve, ecdsa]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 5

permalink: /basic-blockchain-programming/elliptic-curve-keys/
---

In the [previous post][previous] I gave you an overview of public-key cryptography and its relation with the blockchain. You're about to familiarize with real crypto functions to generate Bitcoin keypairs.

In the hope of making the topic as clear as possible, the article might seem a little verbose. By the way, your patience will be rewarded as the course will be downhill from here.

<!--more-->

### An overview of Bitcoin keys

Some facts about Bitcoin EC cryptography:

* Private keys are 32 bytes long.
* Public keys are 64 bytes (uncompressed form) or 32 bytes (compressed form) long plus a 1-byte prefix.
* The elliptic curve *C* is the [secp256k1][sec2] curve.
* EC crypto is based on [modular arithmetic][modular].

In this overwhelming context, our only input is the private key. The public key is uniquely derived from the private key, be it uncompressed or compressed. First, we'll use [OpenSSL][openssl] to generate a sample keypair from the command line. Next, we'll do the same via C code.

TO MAC USERS: I strongly encourage you to test this code on a homebrew release of OpenSSL. OS X 10.10 ships with the long gone 0.9.8 version and some commands may not work as expected!

For your information, Bitcoin Core developers are slowly moving away from OpenSSL towards [their own implementation of secp256k1 crypto][libsecp256k1].

#### Private key

A private key is a 32-byte number chosen at random, and you know that 32 bytes make for a very big number, as big as $$2^{256}$$. Such a number is therefore ridiculously hard to guess, assuming it's generated with a very high degree of randomness.

Getting a new, random key is straightforward:

    $ openssl ecparam -name secp256k1 -genkey -out ec-priv.pem

The output file [ec-priv.pem][ec-priv.pem] includes the curve name (secp256k1) and the private key, both encoded base64 with other additional stuff. The file can be quickly decoded to text so that you can see the raw hexes:

    $ openssl ec -in ec-priv.pem -text -noout

Here's what my keypair looks like (your output will differ):

    read EC key
    Private-Key: (256 bit)
    priv:
        16:26:07:83:e4:0b:16:73:16:73:62:2a:c8:a5:b0:
        45:fc:3e:a4:af:70:f7:27:f3:f9:e9:2b:dd:3a:1d:
        dc:42
    pub: 
        04:82:00:6e:93:98:a6:98:6e:da:61:fe:91:67:4c:
        3a:10:8c:39:94:75:bf:1e:73:8f:19:df:c2:db:11:
        db:1d:28:13:0c:6b:3b:28:ae:f9:a9:c7:e7:14:3d:
        ac:6c:f1:2c:09:b8:44:4d:b6:16:79:ab:b1:d8:6f:
        85:c0:38:a5:8c
    ASN1 OID: secp256k1

where the private key is better displayed as:

    16 26 07 83 e4 0b 16 73
    16 73 62 2a c8 a5 b0 45
    fc 3e a4 af 70 f7 27 f3
    f9 e9 2b dd 3a 1d dc 42

The key reflects our identity, so we want to keep it secret and safe. I mean, had this not been a sample private key, I wouldn't share it with anybody. We'll sign our messages with it so that the world can trust we actually wrote them. If someone steals our private key, he'll be able to fake our identity. In Bitcoin, he'll be able to take our money. Watch out!

#### Public key

By default, a public key is made of two 32-byte numbers, the so-called *uncompressed* form. The numbers represent the $$(x, y)$$ coordinates of a point on the secp256k1 elliptic curve, which has the following formula:

$$y^2 = x^3 + 7$$

The point location is determined by the private key, while it's unfeasible to infer the private key from the point coordinates. After all, this is what makes EC cryptography secure. Due to its dependent nature, $$y$$ can be implied from $$x$$ and the curve formula. In fact, the *compressed* form saves space by omitting the $$y$$ value.

From the private key, it's possible to take out the public part and store it to an external file I called [ec-pub.pem][ec-pub.pem]:

    $ openssl ec -in ec-priv.pem -pubout -out ec-pub.pem

If we now decode the public key:

    $ openssl ec -in ec-pub.pem -pubin -text -noout

the text description will obviously not include the private key:

    read EC key
    Private-Key: (256 bit)
    pub: 
        04:82:00:6e:93:98:a6:98:6e:da:61:fe:91:67:4c:
        3a:10:8c:39:94:75:bf:1e:73:8f:19:df:c2:db:11:
        db:1d:28:13:0c:6b:3b:28:ae:f9:a9:c7:e7:14:3d:
        ac:6c:f1:2c:09:b8:44:4d:b6:16:79:ab:b1:d8:6f:
        85:c0:38:a5:8c
    ASN1 OID: secp256k1

A more readable version:

    04

    82 00 6e 93 98 a6 98 6e
    da 61 fe 91 67 4c 3a 10
    8c 39 94 75 bf 1e 73 8f
    19 df c2 db 11 db 1d 28

    13 0c 6b 3b 28 ae f9 a9
    c7 e7 14 3d ac 6c f1 2c
    09 b8 44 4d b6 16 79 ab
    b1 d8 6f 85 c0 38 a5 8c

The uncompressed conversion form takes 65 bytes:

* The constant `04` prefix.
* The 32-byte $$x$$ coordinate.
* The 32-byte $$y$$ coordinate.

It's easy to convert an uncompressed public key to the compressed form, we just omit the $$y$$ and change the prefix according to its value. The first byte becomes `02` for even values of $$y$$ and `03` for odd values. My $$y$$ ends with `8c`, so the new prefix is `02`:

    02

    82 00 6e 93 98 a6 98 6e
    da 61 fe 91 67 4c 3a 10
    8c 39 94 75 bf 1e 73 8f
    19 df c2 db 11 db 1d 28

The same is accomplished with:

    $ openssl ec -in ec-pub.pem -pubin -text -noout -conv_form compressed

that yields:

    read EC key
    Private-Key: (256 bit)
    pub: 
        02:82:00:6e:93:98:a6:98:6e:da:61:fe:91:67:4c:
        3a:10:8c:39:94:75:bf:1e:73:8f:19:df:c2:db:11:
        db:1d:28
    ASN1 OID: secp256k1

In conclusion, the compressed conversion form takes 33 bytes:

* The constant `02` or `03` prefix.
* The 32-byte $$x$$ coordinate.

### Generating a keypair from code

The keypair generation task is cumbersome, yet not difficult with the aid of the OpenSSL library. I wrote a helper function in [ec.h][ec.h] declared as follows:

{% highlight c %}

EC_KEY *bbp_ec_new_keypair(const uint8_t *priv_bytes);

{% endhighlight %}

Let's analyze part of its code together. Several OpenSSL data structures are involved:

* `BN_CTX`, `BIGNUM`
* `EC_KEY`
* `EC_GROUP`, `EC_POINT`

The first two `struct`s belong to the arbitrary-precision arithmetic area of OpenSSL, because we need to deal with very big numbers. All the other types relate to EC crypto. `EC_KEY` can be a full keypair (private + public) or just a public key, whereas `EC_GROUP` and `EC_POINT` help us calculate the public key from a private key.

Most importantly, we create an `EC_KEY` structure to hold the keypair:

{% highlight c %}

key = EC_KEY_new_by_curve_name(NID_secp256k1);

{% endhighlight %}

Loading the private key is easy, but requires an intermediate step. Before feeding the input `priv_bytes` to the keypair, we need to translate it to a `BIGNUM`, here named `priv`:

{% highlight c %}

BN_init(&priv);
BN_bin2bn(priv_bytes, 32, &priv);
EC_KEY_set_private_key(key, &priv);

{% endhighlight %}

For complex big numbers operations, OpenSSL needs a context, that's why a `BN_CTX` is also created. The public key derivation needs a deeper understanding of EC math, which is not the aim of this series. Basically, we locate a fixed point $$G$$ on the curve (the *generator*, `group` in the code) and multiply it by the scalar private key $$n$$, a virtually irreversible operation in modular arithmetic. The resulting $$P = n * G$$ is a second point, the public key `pub`. Eventually, the public key is loaded into the keypair:

{% highlight c %}

ctx = BN_CTX_new();
BN_CTX_start(ctx);

group = EC_KEY_get0_group(key);
pub = EC_POINT_new(group);
EC_POINT_mul(group, pub, &priv, NULL, NULL, ctx);
EC_KEY_set_public_key(key, pub);

{% endhighlight %}

WARNING: the code is simplified and doesn't check for library errors.

### Example

It's finally time to test our keypair in [ex-ec-keypair.c][ex-ec-keypair.c]. We expect the code to output the same results we got from `openssl` on the command line, given that `priv_bytes` holds our sample private key:

{% highlight c %}

uint8_t priv_bytes[32] = {
   0x16, 0x26, 0x07, 0x83, 0xe4, 0x0b, 0x16, 0x73,
   0x16, 0x73, 0x62, 0x2a, 0xc8, 0xa5, 0xb0, 0x45,
   0xfc, 0x3e, 0xa4, 0xaf, 0x70, 0xf7, 0x27, 0xf3,
   0xf9, 0xe9, 0x2b, 0xdd, 0x3a, 0x1d, 0xdc, 0x42
};

EC_KEY *key;
uint8_t priv[32];
uint8_t *pub;
const BIGNUM *priv_bn;

point_conversion_form_t conv_forms[] = {
   POINT_CONVERSION_UNCOMPRESSED,
   POINT_CONVERSION_COMPRESSED
};
...

/* 1 */

key = bbp_ec_new_keypair(priv_bytes);
...

/* 2 */

priv_bn = EC_KEY_get0_private_key(key);
BN_bn2bin(priv_bn, priv);
...

/* 3 */

for (i = 0; i < sizeof(conv_forms) / sizeof(point_conversion_form_t); ++i) {
    size_t pub_len;
    uint8_t *pub_copy;

    EC_KEY_set_conv_form(key, conv_forms[i]);

    pub_len = i2o_ECPublicKey(key, NULL);
    pub = calloc(pub_len, sizeof(uint8_t));

    /* pub_copy is needed because i2o_ECPublicKey alters the input pointer */
    pub_copy = pub;
    if (i2o_ECPublicKey(key, &pub_copy) != pub_len) {
        ...
    }
    ...
}
...

{% endhighlight %}

The test proceeds this way:

1. Initializes an `EC_KEY` keypair with `priv_bytes`.
2. Puts the private key back into `priv` through a `BIGNUM`.
3. Puts the derived public key into `pub` in all conversion forms.

The third step is the most complicated. The conversion form is set first, which in turn affects the length of the public key (33 or 65). The actual length is obtained with a `NULL`-argument call to `i2o_ECPublicKey`, so that `pub` is allocated enough bytes to hold the output. `i2o_ECPublicKey` finally converts the public key from the internal representation to octects, hence the `i2o` prefix (octet = byte). The encoded bytes are written to `pub` through `pub_copy`.

Try running the program and compare it with the output of the `openssl` command line tool.

### Get the code!

Full source on [GitHub]({{ site.bbp_src_root }}).

### Next block in chain?

You learned how to generate a new EC keypair. With some custom code, you also learned how to create a keypair from raw bytes.

In the [next article][next] you'll use EC keypairs to produce and verify *digital signatures*. {{ site.post_bottom_line }}


[sec2]: http://www.secg.org/sec2-v2.pdf
[modular]: http://en.wikipedia.org/wiki/Modular_arithmetic
[openssl]: https://www.openssl.org/
[libsecp256k1]: https://github.com/bitcoin/secp256k1
[ec-priv.pem]: {{ site.bbp_src }}/ec-priv.pem
[ec-pub.pem]: {{ site.bbp_src }}/ec-pub.pem
[ec.h]: {{ site.bbp_src }}/ec.h
[ex-ec-keypair.c]: {{ site.bbp_src }}/ex-ec-keypair.c
[previous]: {% post_url /basic-blockchain-programming/2015-05-11-keys-as-property %}
[next]: {% post_url /basic-blockchain-programming/2015-05-13-elliptic-curve-digital-signatures %}
