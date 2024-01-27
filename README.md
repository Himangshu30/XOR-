# XOR-BASH
1. Overview
Bitwise operators allow simple, fast, and basic operations on the individual bits of the variables involved. They may seem a heritage of the assembly language era. Yet, we still need them in cryptography, computer graphics, hash functions, compression algorithms, encoding, network protocols, and other types of applications.

In this tutorial, we’ll explore their usage in Bash after clarifying the correspondence between numbers and the bits used to represent them.

2. Binary Representation of Numbers – A Quick Refresher
We can represent the same numerical quantities with different bases, using methods to convert from one base to another. In particular, we need to be familiar with binary integer numbers.

Bash performs all its arithmetic on intmax_t numbers with no checking for overflow. As detailed in stdint.h, intmax_t designates a signed integer type capable of representing any value between -2^63 and 2^63-1 (on 64-bit computers). So, Bash’s bitwise operators work only on signed integers, whose binary representation is in two’s complement. This means:

all numbers are represented with 32 bits or 64 bits, depending on the processor
the first bit on the left indicates the sign, which is 0 for positive numbers and 1 for negative numbers
if the number is positive, its value in base 10 results from a summation of powers of 2
if the number is negative, its absolute value corresponds to its opposite, with all bits inverted and to which we have added 1.
Let’s see an example 64-bit number:

+17 = 0000000000000000000000000000000000000000000000000000000000010001
    = 2**0 + 2**4 = 1 + 16 = 17
Copy
Its opposite -17 requires inverting all bits and adding 1:

+17 = 0000000000000000000000000000000000000000000000000000000000010001
      ----------------------------------------------------------------
      1111111111111111111111111111111111111111111111111111111111101110 +
                                                                     1 =
      ----------------------------------------------------------------
-17 = 1111111111111111111111111111111111111111111111111111111111101111
Copy
This basic understanding of binary numbers is a prerequisite for using bitwise operators.

2.1. Bash’s Tools for Base Conversion
Bash’s arithmetic expansion allows us to write numbers in any base by prefixing the numeric digits of the base followed by the hash symbol. Thus, we can specify the binary number 1001 and print its value in base 10:

$ echo $((2#1001))
9
Copy
bc allows us to convert effortlessly between bases, using the parameters ibase (for the input base) and obase (for the output base). So, let’s convert the decimal number 9 to base 2:

$ echo "ibase=10;obase=2;9" | bc
1001
Copy
But these simple examples apply only to unsigned integers, while bitwise operators require the two’s complement notation for both positive and negative integers. In addition, the internal representation of numbers has a fixed number of bits.

2.2. Bash’s Representation of Positive and Negative Integers
Let’s define a function that shows us the individual bits that make up a number, positive or negative. Our goal is to print the individual bits used internally by Bash so that we know what we are applying the bitwise operators on:

# Given a decimal number, prints its two's complement with the number of bits used by Bash
twos() {
    n=$(getconf LONG_BIT) # detect the machine architecture, 32bit or 64bit
    printf 'obase=2; 2^%d+%d\n' "$n" "$1" | bc | sed -E "s/.*(.{$n})$/\1/"
}
Copy
We’ll gloss over this function’s algorithmic and mathematical details. Let’s just copy and paste the function into the terminal to test it:

$ twos 100
0000000000000000000000000000000000000000000000000000000001100100
$ twos -100
1111111111111111111111111111111111111111111111111111111110011100
$ twos 9223372036854775807
0111111111111111111111111111111111111111111111111111111111111111
$ twos -9223372036854775808
1000000000000000000000000000000000000000000000000000000000000000
Copy
The last two numbers are the maximum and minimum integers on a 64-bit machine.

Let’s now define the inverse function:

# Given a two's complement representation of a signed number, prints its decimal notation
dec() {
  printf 'n=%d; ibase=2; v=%s; v-2^n*(v/2^(n-1))\n' "$(getconf LONG_BIT)" "$1"| bc
}
Copy
Let’s test it:

$ dec 1111111111111111111111111111111111111111111111111111111110011100
-100
$ dec 0000000000000000000000000000000000000000000000000000000001100100
100
Copy
We will use twos() and dec() in the following examples to better illustrate the operations.

3. Bitwise Operators
Bash allows us to use bitwise operators via expr, let, declare, or arithmetic expansion. All the following examples of bitwise AND are therefore valid. But, we should be aware that many operators need to be escaped or quoted:

$ expr 1 \& 0
0
$ let A=1\&0
$ echo $A
0
$ declare -i B=1\&0
$ echo $B
0
$ echo $[ 1 & 0 ] # deprecated notation, but still used and working
0
$ echo $((1 & 0))
0
Copy
Below, we’ll use only the last type of $((…)), which is the most straightforward to read and doesn’t require escaping or quoting.

Let’s not forget to take into account the operator precedence. For instance, these two expressions are equivalent, but the second one’s less confusing since it makes the order of precedence explicit:

$ echo $(( 8 | ~ 4 >> 1 ^ 2 & 6 ))
-1
$ echo $(( 8 | (((~ 4) >> 1) ^ (2 & 6)) ))
-1
Copy
Finally, some familiarity with the concept of truth tables would be helpful, as the tables below of NOT, AND, OR, and XOR are the simplest and most direct ways to illustrate their operation.

3.1. Bitwise NOT Operator (~)
The bitwise NOT operator inverts all bits. Its truth table is the simplest:

  A | NOT A 
 ---|------- 
  0 |     1 
  1 |     0 
Copy
The arithmetic expansion allows us to test the NOT operator:

$ echo $(( ~ -3))
2
Copy
Let’s check what happens to the individual bits:

$ twos -3
1111111111111111111111111111111111111111111111111111111111111101
Copy
The NOT operator handles bits in the following way:

1111111111111111111111111111111111111111111111111111111111111101
---------------------------------------------------------------- NOT
0000000000000000000000000000000000000000000000000000000000000010
Copy
Here is the final result:

$ dec 0000000000000000000000000000000000000000000000000000000000000010
2
Copy
As a general rule, we can observe that applying the NOT operator is always equivalent to subtracting 1 to the opposite of the input number. This rule is because Bash uses two’s complement, which implements the sign change by inverting all bits and adding 1.

3.2. Bitwise AND Operator (&, &=)
The bitwise AND operator returns 1 only if both bits are equal to 1:

  A | B | A AND B 
 ---|---|--------- 
  0 | 0 |       0 
  0 | 1 |       0 
  1 | 0 |       0 
  1 | 1 |       1 
Copy
The arithmetic expansion allows us to test the AND operator:

$ echo $(( -1000 & 20 ))
16
Copy
Let’s check what happens to the individual bits:

$ twos -1000
1111111111111111111111111111111111111111111111111111110000011000
$ twos 20
0000000000000000000000000000000000000000000000000000000000010100
Copy
The AND operator handles bits in the following way:

1111111111111111111111111111111111111111111111111111110000011000
0000000000000000000000000000000000000000000000000000000000010100
---------------------------------------------------------------- AND
0000000000000000000000000000000000000000000000000000000000010000
Copy
Here is the final result:

$ dec 0000000000000000000000000000000000000000000000000000000000010000
16
Copy
The &= operator performs bitwise AND with a variable and stores the result in that variable:

$ A=-1000;
$ (( A &= 20 ))
$ echo $A
16
Copy
Looking at the truth table and knowing that the sign is the first bit on the left, it follows that the output will be a negative number only if the two input numbers are both negative.

3.3. Bitwise OR Operator (|, |=)
The bitwise OR operator returns 1 if at least one of the two bits is equal to 1:

  A | B | A OR B 
 ---|---|-------- 
  0 | 0 |      0 
  0 | 1 |      1 
  1 | 0 |      1 
  1 | 1 |      1 
Copy
Let’s use the arithmetic expansion to test the OR operator:

echo $(( 123 | -321 ))
-257
Copy
Next, let’s see what happens to the individual bits:

$ twos 123
0000000000000000000000000000000000000000000000000000000001111011
$ twos -321
1111111111111111111111111111111111111111111111111111111010111111
Copy
The OR operator handles bits in the following way:

0000000000000000000000000000000000000000000000000000000001111011
1111111111111111111111111111111111111111111111111111111010111111
---------------------------------------------------------------- OR
1111111111111111111111111111111111111111111111111111111011111111
Copy
Here is the final result:

$ dec 1111111111111111111111111111111111111111111111111111111011111111
-257
Copy
The |= operator performs bitwise OR with a variable and stores the result in that variable:

$ A=123;
$ (( A |= -321 ))
$ echo $A
-257
Copy
In this case, the output will be a positive number only if the two input numbers are both positive.

3.4. Bitwise XOR Operator (^, ^=)
The bitwise XOR operator returns 1 if only one of the two bits is equal to 1:

  A | B | A XOR B 
 ---|---|-------- 
  0 | 0 |       0 
  0 | 1 |       1 
  1 | 0 |       1 
  1 | 1 |       0 
Copy
The arithmetic expansion allows us to test the XOR operator:

echo $(( -314 ^ 537  ))
-801
Copy
Let’s look at the individual bits:

$ twos -314
1111111111111111111111111111111111111111111111111111111011000110
$ twos 537
0000000000000000000000000000000000000000000000000000001000011001
Copy
The XOR operator handles bits in the following way:

<code class="language-bash">1111111111111111111111111111111111111111111111111111111011000110
0000000000000000000000000000000000000000000000000000001000011001
---------------------------------------------------------------- XOR
1111111111111111111111111111111111111111111111111111110011011111
Copy
Here is the final result:

$ dec 1111111111111111111111111111111111111111111111111111110011011111
-801
Copy
The ^= operator performs bitwise XOR with a variable and stores the result in that variable:

$ A=-314;
$ (( A ^= 537 ))
$ echo $A
-801
Copy
In this case, the output will be a positive number only if the two input numbers are both positive or negative. As a general rule, writing C=$((A ^ B)) is identical to C=$((A & ~B | ~A & B )). This is proved by starting from the truth table and applying the Karnaugh map simplification technique.

3.5. Left Bitwise Shift (<<, <<=)
In general, in various programming languages, there are two types of bitwise shifts: logical shifts and arithmetic shifts. Both shift bits left or right. The difference is that arithmetic shifts preserve the sign in two’s complement notation (except in overflow cases), while logical shifts don’t. Some languages offer both types of shifts, while Bash offers arithmetic shifts exclusively.

Bash’s shift is “arithmetic” because it is an arithmetic operation – a multiplication in the left shift case. The operator takes the number of bits to shift as the second argument. If n is the number of bits to be shifted and x an integer, then $((x<<n)) and $((x*2**n)), that is x multiplied by the nth power of 2, are the same operation:

$ n=3
$ x=-1000
$ echo $(( x << n ))
-8000
$ echo $(( x * 2**n ))
-8000
 
$ x=-8070450532247928857
$ echo $(( x << n ))
9223372036854775608
$ echo $(( x * 2**n ))
9223372036854775608
Copy
Let’s note that the sign is only kept in the first case because x*2**n doesn’t generate overflow. In the second case, by contrast, the multiplication result would be a number smaller than the minimum possible integer, that is, -2**63 on a 64-bit CPU.

Let’s check what happens to the individual bits in the first case:

$ twos -1000
1111111111111111111111111111111111111111111111111111110000011000
Copy
The left shift operator handles bits in the following way:

starting from the left, the first bit remains as it is because it’s the sign
starting from the left, the second, third, and fourth bits leave because the 3-bit shift results in their elimination
three new bits equal to 0 come to the right (the left shift never adds bits equal to 1)
Here’s the final result:

1111111111111111111111111111111111111111111111111110000011000000
Copy
We can see that it’s the integer we expect:

$ dec 1111111111111111111111111111111111111111111111111110000011000000
-8000
Copy
The <<= operator performs a left shift with a variable and stores the result in that variable:

$ A=-1000
$ (( A <<= 3 ))
$ echo $A
-8000
Copy
As a final note, shifts can result in an implementation-defined or undefined behavior, so we must take care when using them. What we’ve covered here takes into account the operation of Bash 5.

3.6. Right Bitwise Shift (>>, >>=)
The same considerations already expressed for the left bitwise shift apply, i.e., it’s an arithmetic shift with sign preservation (in this case, there is no possibility of overflow).

The right shift corresponds to a division. $((x>>n)) and $((x/2**n)) are the same operation if x is positive, or if x is negative and a multiple of -2**n. Instead, if x is negative and not a multiple of -2**n, then $((x>>n)) equals $((x/2**n-1)).

Let’s see two examples:

$ x=1030
$ n=3
$ echo $(( x >> n ))
128
$ echo $(( x / 2**n))
128
 
$ x=-1030
$ echo $(( x >> n ))
-129
$ echo $(( x / 2**n))
-128
Copy
Let’s check what happens to the individual bits in the second case:

$ twos -1030
1111111111111111111111111111111111111111111111111111101111111010
Copy
The right shift operator handles bits in the following way:

starting from the right, the first, second, and third bits leave because the 3-bit shift results in their elimination
starting from the left, the first bit remains as is because it’s the sign
three new bits equal to 1 come to the left after the first bit (the right shift adds 0s for positive integers and 1s for negative integers)
Here is the final result:

1111111111111111111111111111111111111111111111111111111101111111
Copy
It’s the expected integer:

$ dec 1111111111111111111111111111111111111111111111111111111101111111
-129
Copy
The >>= operator performs a left shift with a variable and stores the result in that variable:

$ A=-1030
$ (( A >>= 3 ))
$ echo $A
-129
Copy
As with the left shift, we must be careful using this operator since it can result in an implementation-defined or undefined behavior. What we’ve seen takes into account the operation of Bash 5.

4. Conclusion
In this article, we’ve seen how Bash represents numbers by bits and what basic operations we can do on these bits.

Knowledge of the basic rules of Boolean algebra is not strictly necessary, but it will undoubtedly help us to understand bitwise operators better.

