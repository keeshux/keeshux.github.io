---
layout: post
title: A developer-oriented series about Bitcoin
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 0
  ongoing: false

permalink: /basic-blockchain-programming/
---

It was 2013 when I first dove into [Bitcoin][bitcoin] as a (wannabe) developer and since then I hoarded a remarkable amount of websites, articles, readings, threads, mailing lists. Well, it's been 2 years and I can still see a clear, major bottleneck: we fall extremely short of developer resources. While it may be a matter of pioneering (is it really? we're far beyond 2009...), when it comes down to investors, politics and philosophy we all agree that Bitcoin is in the spotlight.

<!--more-->

Why is Bitcoin development so _elitist_? I truly believe this aspect alone defeats the motivations behind Bitcoin and I realized there's a steep learning curve in front of those willing to step in. Let alone [bitcoinj][bitcoinj] providing very well for Java programmers, the support for other languages sadly looks like [Google Code][sad-google-code]. Even the frameworks for the JavaScript + Node.js platform are mostly a work in progress and those who aren't often miss out on the networking tier. The renowned [BitPay's Bitcore][bitcore] is no exception.

Given the above, many enthusiasts out there might not have the tools or the time to join the active side of the community. As of today, reinventing the wheel at times may be as unreasonable as unavoidable.

### Around the blockchain

The goal of this series is speeding up the learning process by providing a step-by-step description of the blockchain from a programmer perspective. No in-depth experience is required, I only assume:

- You're a programmer.
- You know hex system and endianness.
- You're able to read C code.
- You interacted with Bitcoin at some point (e.g. you paid a product in bitcoins).

Ideally, you've had a wallet once in your life and possibly used it to send or receive some coins. You've been flooded by hundreds of articles and wikis worshipping the revolutionary nature of the blockchain, but you've been curious enough to read past the buzzwords. You may have taken a peek at websites like [blockchain.info][blockchain.info] to gain insight into your own transactions or just for the sake of tasting the hackerish side of the thing. Skip the math behind the [mining process][mining], still you know that bitcoins spring out of an algorithm somehow.

Well, that's how far I expect you to have gone. Meanwhile there's [plenty of wikis and articles][blockchain-innovation] explaining way better than me what the blockchain is and why it's such an awesome discovery by the human being.

### Roadmap

Here I'll cover the Bitcoin transaction system and teach you how to assemble your own transactions. Since the [beginning][next], I'll draw a path leading you to understanding how the high-level blockchain entities translate to raw bytes. Nuts and bolts, no big deal. I'll start with a few theoretical concepts to make better sense of the code snippets attached but trust me, I want this series to be practical.

However, this is a beginner course and it'll take you a *little* more to get your feet wet with the [Bitcoin Core][bitcoin-core] codebase. With this in mind, this is surely a good place to start.

### Sample code

All [sample code][github] is written in C language and prefixed with `ex-`. To quickly compile a sample on an UNIX-like platform (like Linux, Mac OS X, *BSD), I suggest you use the [test.sh][test.sh] bash script after editing it to point to your local OpenSSL headers. Here's how:

    ./test.sh ex-sample-name

given that you want to compile and execute the code from `ex-sample-name.c`. The executable is written to `ex-sample-name.out`.


[bitcoin]: https://bitcoin.org/
[bitcoinj]: https://bitcoinj.github.io/
[sad-google-code]: http://thecodinglove.com/post/68461911503/when-i-go-on-google-code/
[bitcore]: http://bitcore.io/
[blockchain.info]: https://blockchain.info/
[mining]: https://en.bitcoin.it/wiki/Mining
[blockchain-innovation]: http://www.brookings.edu/blogs/techtank/posts/2015/01/13-blockchain-innovation-kaushal
[bitcoin-core]: https://github.com/bitcoin/bitcoin
[github]: {{ site.bbp_src_root }}
[test.sh]: {{ site.bbp_src }}/test.sh
[next]: {% post_url /basic-blockchain-programming/2015-04-25-bytes-and-hashes %}
