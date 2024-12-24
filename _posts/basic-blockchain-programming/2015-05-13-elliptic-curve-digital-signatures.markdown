---
layout: post
title: Elliptic-curve digital signatures
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, elliptic-curve, ecdsa, hashing]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 6

permalink: /basic-blockchain-programming/elliptic-curve-digital-signatures/
---

Now that you're able to generate EC keypairs, the next step is using them to sign and verify messages. By message I mean any data --from text to binary-- that needs to be authenticated. Specifically, Bitcoin clients produce signatures to authenticate their transactions, whereas miners verify such signatures to authorize and broadcast valid transactions.

<!--more-->

This post is going to deal with generic messages. Later on, we'll learn what kind of messages are involved in the Bitcoin transaction signing process.

### ECDSA signatures

Not surprisingly, the EC signature algorithm is [ECDSA][ecdsa] (Elliptic-Curve Digital Signature Algorithm). In ECDSA, all parties involved must agree on a hash function *H*, because we're going to sign *H*(message) rather than the message itself. It's worth noting that only the signing party S has access to the private key, while the verifying party V holds the corresponding public key to verify S signatures. I'll reuse the same [private key][ec-priv.pem] and [public key][ec-pub.pem] from the [previous post][previous].

The following examples operate on SHA-256 digests, but keep in mind that Bitcoin's designated *H* function is hash256, also known as double SHA-256 (read the [article on hashes][hashes]).

#### Sign

The first step is putting our message into a file, say [ex-message.txt][ex-message.txt]:

    This is a very confidential message

whose SHA-256 digest is (don't forget the trailing `\n`):

    45 54 81 3e 91 f3 d5 be
    79 0c 7c 60 8f 80 b2 b0
    0f 3e a7 75 12 d4 90 39
    e9 e3 dc 45 f8 9e 2f 01

After that, we sign the SHA-256 digest of the message with the private key:

    $ openssl dgst -sha256 -sign ec-priv.pem ex-message.txt >ex-signature.der

The [ex-signature.der][ex-signature.der] file is the message signature in *DER* format. OpenSSL uses the [DER encoding][der] for any binary output (keys, certificates, signatures etc.), but I'll skip the underlying details. You don't need to know the semantic of an ECDSA signature, just remember it's a simple pair of big numbers $$(r, s)$$.

You'll probably notice that the signature changes each time you run the program, that is, the default signing process is not *deterministic*. This can be an issue when serializing blockchain transactions, because signatures are part of the transaction bytes and you probably remember that [transaction bytes hash to the txid][hashes]. As a consequence, the txid would change each time you sign a transaction. This behaviour is namely a source of [transaction malleability][tx-malleability].

To display a hex-encoded signature, just add the `-hex` flag:

    $ openssl dgst -sha256 -hex -sign ec-priv.pem ex-message.txt

For a repeatable output, though, you'd better hexdump the DER file:

    $ hexdump ex-signature.der

#### Verify

Whenever an authenticated message is published to the network, the readers expect to find a signature attached. Both files are the input to the verification routine, provided that we received the author's public key in advance:

    $ openssl dgst -sha256 -verify ec-pub.pem -signature ex-signature.der ex-message.txt

If the signature is verified, we're able to state that the message is authentic.

### Code translation

The code below does what we did from the command line in the previous section.

#### Sign

OpenSSL makes the signing operation trivial, look at [ex-ecdsa-sign.c][ex-ecdsa-sign.c]:

{% highlight c %}

uint8_t priv_bytes[32] = { ... };
const char message[] = "This is a very confidential message\n";

EC_KEY *key;
uint8_t digest[32];
ECDSA_SIG *signature;
uint8_t *der, *der_copy;
size_t der_len;

...

key = bbp_ec_new_keypair(priv_bytes);
bbp_sha256(digest, (uint8_t *)message, strlen(message));
signature = ECDSA_do_sign(digest, sizeof(digest), key);

{% endhighlight %}

where `ECDSA_SIG` is a simple structure holding the $$(r, s)$$ pair described in the previous paragraph:

{% highlight c %}

struct {
    BIGNUM *r;
    BIGNUM *s;
} ECDSA_SIG;

{% endhighlight c %}

My test output (yours will differ):

    r: 2B2B529BDBDC93E78AF7E00228B179918B032D76902F74EF454426F7D06CD0F9
    s: 62DDC76451CD04CB567CA5C5E047E8AC41D3D4CF7CB92434D55CB486CCCF6AF2

With the `i2d_ECDSA_SIG` function we also get the DER-encoded signature:

{% highlight c %}

der_len = ECDSA_size(key);
der = calloc(der_len, sizeof(uint8_t));
der_copy = der;
i2d_ECDSA_SIG(signature, &der_copy);

{% endhighlight %}

that in my test is tidily rendered like this (can you spot `r` and `s` inside?):

    30 44
    02 20
    2b 2b 52 9b db dc 93 e7
    8a f7 e0 02 28 b1 79 91
    8b 03 2d 76 90 2f 74 ef
    45 44 26 f7 d0 6c d0 f9
    02 20
    62 dd c7 64 51 cd 04 cb
    56 7c a5 c5 e0 47 e8 ac
    41 d3 d4 cf 7c b9 24 34
    d5 5c b4 86 cc cf 6a f2

#### Verify

Verifying the signature is easy too, here's [ex-ecdsa-verify.c][ex-ecdsa-verify.c]:

{% highlight c %}

uint8_t pub_bytes[33] = { ... };
uint8_t der_bytes[] = { ... };
const char message[] = "This is a very confidential message\n";

EC_KEY *key;
const uint8_t *der_bytes_copy;
ECDSA_SIG *signature;
uint8_t digest[32];
int verified;

...

key = bbp_ec_new_pubkey(pub_bytes);
der_bytes_copy = der_bytes;
signature = d2i_ECDSA_SIG(NULL, &der_bytes_copy, sizeof(der_bytes));

{% endhighlight %}

Since we don't own the private key, we'll have to decode `pub_bytes` into a compressed public key with the following helper from [ec.h][ec.h]:

{% highlight c %}

EC_KEY *bbp_ec_new_pubkey(const uint8_t *pub_bytes, size_t pub_len);

{% endhighlight c %}

On the other hand, `der_bytes` is the DER-encoded signature returned by the signing program. We decode the DER signature into a convenient `ECDSA_SIG` structure and then do the verification against the same SHA-256 message digest:

{% highlight c %}

bbp_sha256(digest, (uint8_t *)message, strlen(message));
verified = ECDSA_do_verify(digest, sizeof(digest), signature, key);

{% endhighlight c %}

The `ECDSA_do_verify` function returns:

* `1` if the signature is valid.
* `0` if the signature is not valid.
* `-1` for unexpected errors.

Note: the signature decoding can be skipped by using `ECDSA_verify`, which takes a DER-encoded signature directly.

### Get the code!

Full source on [GitHub]({{ site.bbp_src_root }}).

### Next block in chain?

You learned how to sign a message with a private key and how to verify a message signature with a public key.

This is the last post about generic crypto, phew! In the [next article][next] I'll present the Bitcoin network. {{ site.post_bottom_line }}


[ecdsa]: http://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm
[hashes]: {% post_url /basic-blockchain-programming/2015-04-25-bytes-and-hashes %}
[der]: http://en.wikipedia.org/wiki/X.690
[tx-malleability]: http://www.coindesk.com/bitcoin-bug-guide-transaction-malleability/
[ec-priv.pem]: {{ site.bbp_src }}/ec-priv.pem
[ec-pub.pem]: {{ site.bbp_src }}/ec-pub.pem
[ec.h]: {{ site.bbp_src }}/ec.h
[ex-message.txt]: {{ site.bbp_src }}/ex-message.txt
[ex-signature.der]: {{ site.bbp_src }}/ex-signature.der
[ex-ecdsa-sign.c]: {{ site.bbp_src }}/ex-ecdsa-sign.c
[ex-ecdsa-verify.c]: {{ site.bbp_src }}/ex-ecdsa-verify.c
[hashes]: {% post_url /basic-blockchain-programming/2015-04-25-bytes-and-hashes %}
[previous]: {% post_url /basic-blockchain-programming/2015-05-12-elliptic-curve-keys %}
[next]: {% post_url /basic-blockchain-programming/2015-05-14-network-interoperability-part-one %}
