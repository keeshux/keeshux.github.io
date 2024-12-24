---
layout: post
title: The Bitcoin Script language (pt. 1)
image_name: /s/f/bitcoin/bitcoin

categories: [bitcoin]
tags: [bitcoin, blockchain, programming, development, transactions, script, assembly, opcode, stack]
hashtags: ["Bitcoin", "blockchain"]

series:
  name: Basic blockchain programming
  index: 10

permalink: /basic-blockchain-programming/bitcoin-script-language-part-one/
---

*Script* is a simple scripting language, as well as the core of Bitcoin transaction processing. If you ever wrote assembly code you'll find this article very easy to understand --probably entertaining--, otherwise it might well be one of the most challenging. Keep focused!

<!--more-->

### Meet machine code

A script is a computer program, and as a programmer you certainly know what a program is. A program takes an input, executes for some time, then returns an output. Programming languages are our tool to write programs that computers will understand, because most languages come with *compilers* that map human-friendly code to CPU operations, also known as *opcodes*.

#### Opcodes

Opcodes include memory manipulation, math, loops, function calls and everything you find in procedural programming languages like C. They make up the spoken language of a CPU, the so-called *machine code*. Since bytes are computers' preferred idiom, no wonder opcodes are bytes as well. As a result, machine code is a string of bytes representing operations to be executed on a CPU.

Consider this piece of code in a high-level programming language like C:

{% highlight c %}

x = 0x23;
x += 0x4b;
x *= 0x1e;

{% endhighlight %}

Now suppose you want to compile and run this code on a hypothetical little-endian CPU with a single cell of 16-bit memory (a *register*) and the following set of opcodes:

|opcode   |encoding|V     |
|---------|--------|------|
|SET(V)   |`ab` V  |16-bit|
|ADD(V)   |`ac` V  |16-bit|
|MUL(V)   |`ad` V  |16-bit|

The opcodes explained:

* SET loads the register with the value V.
* ADD adds V to the register.
* MUL multiplies the register by V.

A compiler for such a CPU would generate these 9 bytes of machine code:

    ab 23 00 ac 4b 00 ad 1e 00

Here's how it's interpreted:

1. Load the register with the value `23`.
2. Add `4b` to the register, that is now `23 + 4b = 6e`.
3. Multiply the register by `1e`, yielding `6e * 1e = ce4`.

The register holds the final result, that is `ce4`.

#### Stack memory

Most of the time, we need to track complex program states with *variables*. In C, depending on whether a variable is allocated statically or with `malloc`, it's stored in a differently arranged memory. While `malloc`-ed data is accessed like an element in a very big array, static variables are pushed to and popped from a pile of items called *stack*. A stack operates in a LIFO fashion (Last In First Out), meaning that the last item you push will be the first to pop out.

Consider this dummy function:

{% highlight c %}

int foo() {

    /* 1 */

    /* 2 */
    uint8_t a = 0x12;
    uint16_t b = 0xa4;
    uint32_t c = 0x2a5e7;

    /* 3 */
    uint32_t d = a + b + c;

    return d;

    /* 4 */
}

{% endhighlight %}

The stack is initially empty (1):

    []

Then, three variables are pushed (2):

    [12]
    [12, a4 00]
    [12, a4 00, e7 a5 02 00]

A fourth variable is assigned the sum of the others and pushed onto the stack (3):

    [12, a4 00, e7 a5 02 00, 9d a6 02 00]

The tip of the stack is the return value and is sent back to the function caller by other means. Each temporary stack variable is popped at the end of the block (4), because the push/pop operations must be balanced so that the stack always goes back to its initial state:

    [12, a4 00, e7 a5 02 00]
    [12, a4 00]
    [12]
    []

### The Script machine code

Likewise, Bitcoin Core has its own "virtual processor" to interpret the *Script* machine code. Script features a rich set of opcodes, yet very limited compared to full-fledged CPUs like Intel's, to name one. Some key facts about Script:

1. Script does not loop.
2. Script always terminates.
3. Script memory access is stack-based.

In fact, point 1 implies 2. Point 3 means there's no such thing like named variables in Script, you just do your calculations on a stack. Typically, the stack items you push become the operands of subsequent opcodes. At the end of the script, the top stack item is the return value.

Before presenting real world scripts, let's first enumerate some opcodes. For a full set please check out the official [wiki page][opcodes].

#### Constants

The following opcodes push the numbers 0-16 onto the stack:

|opcode        |encoding |
|--------------|---------|
|`OP_0`        |`00`     |
|`OP_1`-`OP_16`|`51`-`60`|

By convention, `OP_0` and `OP_1` also express the boolean `OP_FALSE` (zero) and `OP_TRUE` (non-zero).

Example:

    54 57 00 60

or:

    OP_4 OP_7 OP_0 OP_16

Here's how the stack evolves:

    []
    [4]
    [4, 7]
    [4, 7, 0]
    [4, 7, 0, 16]

The return value is the top item, so the script returns 16. Quite pointless, I know, but it's a start.

#### Push data

Several opcodes are provided to push custom data. They differ in the size of the operands:

|opcode        |encoding|L (length)|D (data)|
|--------------|--------|----------|--------|
|`OP_PUSHDATA1`|`4c` L D|8-bit     |L bytes |
|`OP_PUSHDATA2`|`4d` L D|16-bit    |L bytes |
|`OP_PUSHDATA4`|`4e` L D|32-bit    |L bytes |

For example, if your data length can be stored as a 8-bit number, then `OP_PUSHDATA1` is your best choice. Look at this:

    4c 14 11 06 03 55 04 8a
    0c 70 3e 63 2e 31 26 30
    24 06 6c 95 20 30

The first byte is clearly a `OP_PUSHDATA1` opcode, followed by a 1-byte length of `14` that is decimal 20. So, 20 bytes of data are coming next. The effect of this instruction is that such data is pushed onto the stack:

    [11 06 03 55 04 8a 0c 70
     3e 63 2e 31 26 30 24 06
     6c 95 20 30]

Indeed --like with [varints][varints]--, there's a special encoding for very short data. If an opcode lies between `01` and `4b` (included), it's a push data operation where the opcode itself is the length in bytes:

|opcode|encoding|L (length)|D (data)|
|------|--------|----------|--------|
|L     |L D     |`01`-`4b` |L bytes |

For example, in the string:

    07 8f 49 b2 e2 ec 7c 44

the opcode `07` means that 7 bytes of data are to be pushed:

    [8f 49 b2 e2 ec 7c 44]

### Next block in chain?

You learned a little bit about machine code and opcodes. Script is a simple low-level language understood by miners software. Script state is tracked with stack memory.

In the [next article][next] I'll show you opcodes that do something more than just pushing data. {{ site.post_bottom_line }}


[opcodes]: https://en.bitcoin.it/wiki/Script
[varints]: {% post_url /basic-blockchain-programming/2015-05-01-serialization-part-two %}
[next]: {% post_url /basic-blockchain-programming/2015-05-25-bitcoin-script-language-part-two %}
