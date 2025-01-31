---
[![Build Status](https://github.com/pathpub/trieval/workflows/CI/badge.svg)](https://github.com/pathpub/trieval/actions)

# Trieval

Trieval is a tradional trie implementation in pure Elixir that supports pattern based lookup and a variety
of other functionality. Documentation can be found [HERE](https://hexdocs.pm/trieval/Trieval.html).

- [Installation](#installation)
- [Usage](#usage)
  - [Creating a new trie](#creating-a-new-trie)
  - [Insertion](#insertion)
  - [Key membership](#checking-for-key-membership)
  - [Prefix lookup](#prefix-lookup)
  - [Longest common prefix lookup](#longest-common-prefix-lookup)
  - [Pattern lookup](#pattern-lookup)
    - [Wildcard](#wildcard)
    - [Inclusion group](#inclusion-group)
    - [Exclusion group](#exclusion-group)
    - [Capture group](#capture-group)
    - [Escaping pattern symbols](#escaping-pattern-symbols)
- [License](#license)

## Installation

Add Trieval to your `mix.exs` dependencies:

```elixir
def deps do
  [{:trieval, "~> 1.0.0"}]
end
```

## Usage

##### Creating a new trie

There's three ways to create a new trie struct. Provide zero arguments to create an empty trie,
provide a binary key or list of binary keys to create a trie with nodes.

```elixir
Trieval.new
%Trieval.Trie{trie: ...}

Trieval.new("example")
%Trieval.Trie{trie: ...}

Trieval.new(~w/this is an example/)
%Trieval.Trie{trie: ...}
```

For the rest of our examples we are going to assume we have created the following trie:

```elixir
trie = Trieval.new(~w/apple apply ape bed between betray cat noon hot
                        warm winter boob smash crush under above people
                        negative poison place out divide zebra extended/)
```

##### Insertion

Just like creating a new trie you can either provide a single binary key or a list of binary keys for
insertion.

```elixir
Trieval.insert(trie, "elephant")
|> Trieval.insert("banana")
|> Trieval.insert(~w/cheese orange alchemy/)
```

##### Key membership

Checking if a trie contains a binary key is quick and easy.

```elixir
Trieval.contains?(trie, "apple")
true

Trieval.contains?(trie, "extended")
true

Trieval.contains?(trie, "doodle")
false
```

##### Prefix lookup

Looking up all binary keys that begin with a certain prefix is very common.

```elixir
Trieval.prefix(trie, "a")
["above", "ape", "apple", "apply"]

Trieval.prefix(trie, "app")
["apple", "apply"]

Trieval.prefix(trie, "be")
["bed", "betray", "between"]

Trieval.prefix(trie, "th")
[]
```

##### Longest common prefix lookup

Similar to the above `prefix/2` function but in this case we return a tuple containing
the longest common prefix found and a list of all words that share this prefix.
An example use-case for this would be an auto-completion feature in a text input field.

```elixir
Trieval.new(~w/apple apply ape/) |> Trieval.longest_common_prefix("a")
{"ap", ["ape", "apple", "apply"]}

Trieval.new(~w/apple apply ape ample/) |> Trieval.longest_common_prefix("z")
{nil, []}
```

##### Pattern lookup

Trieval supports a variety of patterns that can be arbitrarily combined. Erroneous patterns
return a tuple of the form `{:error, reason}`.

###### Wildcard

The wildcard pattern `*` simply matches on _any_ character.

```elixir
# Three letter word
# "*" - Matches any character
# "p" - Matches "p"
# "e" - Matches "e"
Trieval.pattern(trie, "*pe")
["ape"]

# Five letter word
# "a" - Matches "a"
# "*" - Matches any character
# "*" - Matches any character
# "*" - Matches any character
# "y" - Matches "y"
Trieval.pattern(trie, "a***y")
["apply"]

# Three letter word
# "*" - Matches any character
# "*" - Matches any character
# "*" - Matches any character
Trieval.pattern(trie, "***")
["ape", "bed", "cat", "hot", "out"]

# "*" - Matches any character
# "n" - Matches "n"
# Two letter word that ends with "n"
Trieval.pattern(trie, "*n")
[]
```

###### Inclusion group

The inclusion group pattern `[...]` matches on any character _inside of the brackets_.

```elixir
# Three letter word
# "[ab]" - Matches "a" or "b"
# "*"    - Matches any character
# "*"    - Matches any character
Trieval.pattern(trie, "[ab]**")
["ape", "bed"]

# Three letter word
# "[ab]" - Matches "a" or "b"
# "*"    - Matches any character
# "d"    - Matches "d"
Trieval.pattern(trie, "[ab]*d")
["bed"]

# Five letter word
# "[abz]" - Matches "a", "b", or, "z"
# "[eb]"  - Matches "e" or "b"
# "*"     - Matches any character
# "*"     - Matches any character
# "[ea]"  - Matches "e" or "a"
Trieval.pattern(trie, "[abz][eb]**[ea]")
["above", "zebra"]

# Four letter word
# "[yxzo]" - Matches "y", "x", "z", or "o"
# "*"      - Matches any character
# "*"      - Matches any character
# "*"      - Matches any character
Trieval.pattern(trie, "[yxzo]***")
[]

# Oh no, a bad pattern
Trieval.pattern(trie, "[abc][ezf")
{:error, "Dangling group (inclusion) starting at column 6, expecting ]"}
```

###### Exclusion group

The exclusion group pattern `[^...]` matches on any character _not inside of the brackets_.

```elixir
# Five letter word
# "[abz]" - Matches "a", "b", or, "z"
# "[^eb]" - Matches any character but "e" or "b"
# "*"     - Matches any character
# "*"     - Matches any character
# "[ea]"  - Matches "e" or "a"
Trieval.pattern(trie, "[abz][^eb]**[ea]")
["apple"]

# Six letter word
# "[pd]"  - Matches "p" or "d"
# "*"     - Matches any character
# "*"     - Matches any character
# "*"     - Matches any character
# "[^od]" - Matches any character but "o" or "d"
# "*"     - Matches any character
Trieval.pattern(trie, "[pd]***[^od]*")
["people"]

# Three letter word
# "[^abc]" - Matches any character but "a", "b", or, "c"
# "*"      - Matches any character
# "*"      - Matches any character
Trieval.pattern(trie, "[^abc]**")
["hot", "out"]

# Oh no, a bad pattern
Trieval.pattern(trie, "[^abc")
{:error, "Dangling group (exclusion) starting at column 1, expecting ]"}
```

###### Capture group

The default capture group pattern `{name}` must have a name and matches on any character. A name can be any combination of characters
but it is convention to start with the start with the name `1` and increment the name of the next capture group by one. Subsequent usage of
the named capture group must match the character captured by the first capture group. In other words, capture
groups are useful when looking for binaries with the same character in different positions. Capture groups
can be combined with an `inclusion group ({name[...]})` or an `exclusion group ({name[^...]})`. It is mandatory that the capture group's
name is the first thing that appears after the opening curly brace and the optional inclusion or exclusion group must the last thing that appears before
the closing curly brace. In the event that a pattern is provided that doesn't follow these rules an error will be returned.

```elixir
# Four letter word
# "{1}" - Creates a new capture group named "1", matches any character
# "{2}" - Creates a new capture group named "2", matches any character
# "{2}" - Matches any character captured by initial capture group "{2}"
# "{1}" - Matches any character captured by initial capture group "{1}"
# You may have recognized that this pattern is for searching for four letter palindromes, neat!
Trieval.pattern(trie, "{1}{2}{2}{1}")
["boob", "noon"]

# Four letter word
# "{1[^nm]}" - Creates a new capture group named "1", matches any character but "n" or "m"
# "{2[oe]}"  - Creates a new capture group named "2", matches "o" or "e"
# "{2}"      - Matches any character captured by initial capture group "{2}"
# "{1}"      - Matches any character captured by initial capture group "{1}"
# Notice that it no longer accepts "noon" because of the exclusion of "n" in capture group "{1}"
Trieval.pattern(trie, "{1[^nm]}{2[oe]}{2}{1}")
["boob"]

# Eight letter word
# "{aa}" - Creates a new capture group named "aa", matches any character
# "*"    - Matches any character
# "*"    - Matches any character
# "{aa}" - Matches any character captured by initial capture group "{aa}"
# "*"    - Matches any character
# "{b}"  - Creates a new capture group named "b", matches any character
# "{aa}" - Matches any character captured by initial capture group "{aa}"
# "{b}"  - Matches any character captured by initial capture group "{b}"
# In English, find a size eight binary that has the same character in the first, fourth, and seventh position
# Additionally, it must have the same character in the sixth and eighth position
# The rest are wildcards, shove anything that fits in between
Trieval.pattern(trie, "{aa}**{aa}*{b}{aa}{b}")
["extended"]

# Oh no, a bad pattern
Trieval.pattern(trie, "{}**{aa}*{b}{aa}{b}")
{:error, "Unnamed capture starting at column 1, capture cannot be empty"}

# Oh no, a bad pattern
Trieval.pattern(trie, "{aa}**{aa}*{b}{aa}{b")
{:error, "Dangling group (capture) starting at column 19, expecting }"}

# Oh no, a bad pattern
Trieval.pattern(trie, "{aa[^abc]a}**{aa}*{b}{aa}{b}")
{:error, "Group (exclusion) must in the tail position of capture starting at column 4"}
```

###### Escaping pattern symbols

You may have been wondering if it's possible to match on pattern symbols to find binaries that contain the wildcard `*`,
the exclusion carot `^`, and others. The answer is yes, the pattern parser allows you to escape otherwise
reserved symbols to be used directly in patterns.

The following symbols can be escaped:

| Symbol | Escaped symbol |
| :----: | :------------: |
|   \*   |     \\\\\*     |
|   ^   |     \\\\^     |
|   [   |     \\\\[     |
|   ]   |     \\\\]     |
|   {   |     \\\\{     |
|   }   |     \\\\}     |

And in action:

```elixir
# Three letter word
# "\\*" - Matches "*"
# "*"   - Matches any character
# "*"   - Matches any character
Trieval.new(~w/*ab [x*/) |> Trieval.pattern("\\***")
["*ab"]

# Three letter word
# "[\\*\\[]" - Matches "*" or "["
# "*"        - Matches any character
# "*"        - Matches any character
Trieval.new(~w/*ab [x*/) |> Trieval.pattern("[\\*\\[]**")
["*ab", "[x*"]

# Oh no, a bad pattern
Trieval.new(~w/*ab [x*/) |> Trieval.pattern("[*]**")
{:error, "Unescaped symbol * at column 2"}
```

## License

Originally Retrieval, written by [Rob-bie](https://github.com/Rob-bie/retrieval/)

Updated by the team at [pathpub](https://path.pub)

```
This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the LICENSE file for more details.
```
---
