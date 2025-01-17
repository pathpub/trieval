defmodule Trieval do
  alias Trieval.Trie
  alias Trieval.PatternParser

  @moduledoc """
  Trieval provides an interface for creating and managing trie data structures. A trie, also known as a prefix tree, is a type of search tree used to store associative data structures.

  This module provides functions to create new tries, insert values, and perform various operations on the trie. It supports creating tries from binaries, lists of binaries, and tuples of binaries.
  """

  @doc """
  Returns a new trie. Providing no arguments creates an empty trie.
  Optionally, a binary, a list of binaries or a tuple of binaries can be passed to `new/1`.

  ## Examples

      iex> Trieval.new()
      %Trieval.Trie{trie: %{}}

  """
  @spec new() :: %Trieval.Trie{trie: map()}
  def new, do: %Trie{}

  @doc """
  Returns a new trie containing lists of binaries representing the provided values passed to `new/1`.
  Optional values are a binary, a list of binaries or a tuple of binaries can be passed to `new/1`.

  ## Examples

      iex> Trieval.new("apple")
      %Trieval.Trie{trie: %{97 => %{112 => %{112 => %{108 => %{101 => %{mark: :mark}}}}}}}

      iex> Trieval.new(~w/apple apply ape ample/)
      %Trieval.Trie{
                trie: %{
                  97 => %{
                    109 => %{112 => %{108 => %{101 => %{mark: :mark}}}},
                    112 => %{
                      101 => %{mark: :mark},
                      112 => %{
                        108 => %{
                          101 => %{mark: :mark},
                          121 => %{mark: :mark}
                        }
                      }
                    }
                  }
                }
              }

  """
  @spec new(binary() | maybe_improper_list() | {binary(), any()}) :: %Trieval.Trie{trie: map()}
  def new(binaries) when is_list(binaries) do
    insert(%Trie{}, binaries)
  end

  def new(binary) when is_binary(binary) do
    insert(%Trie{}, binary)
  end

  def new(binary_and_payload) when is_tuple(binary_and_payload) do
    insert(%Trie{}, binary_and_payload)
  end

  @doc """
  Inserts a binary, list of binaries or tuple of binaries into an existing trie.

  ## Examples

      iex> Trieval.new() |> Trieval.insert("apple")
      %Trieval.Trie{trie: %{97 => %{112 => %{112 => %{108 => %{101 => %{mark: :mark}}}}}}}

      Trieval.new(~w/apple apply ape ample/) |> Trieval.insert(~w/zebra corgi/)
      %Trieval.Trie{trie: %{...}}

  """
  @spec insert(%Trieval.Trie{trie: map()}, binary() | maybe_improper_list() | {binary(), any()}) :: %Trieval.Trie{trie: map()}
  def insert(%Trie{trie: trie}, binaries) when is_list(binaries) do
    %Trie{trie: Enum.reduce(binaries, trie, &_insert(&2, &1))}
  end

  def insert(%Trie{trie: trie}, binary) when is_binary(binary) do
    %Trie{trie: _insert(trie, binary)}
  end

  def insert(%Trie{trie: trie}, binary_and_payload) when is_tuple(binary_and_payload) do
    %Trie{trie: _insert(trie, binary_and_payload)}
  end

  defp _insert(trie, {<<next, rest::binary>>, payload}) do
    case Map.has_key?(trie, next) do
      true -> Map.put(trie, next, _insert(trie[next], {rest, payload}))
      false -> Map.put(trie, next, _insert(%{}, {rest, payload}))
    end
  end

  defp _insert(trie, {<<>>, payload}) do
    Map.put(trie, :mark, payload)
  end

  defp _insert(trie, <<next, rest::binary>>) do
    case Map.has_key?(trie, next) do
      true -> Map.put(trie, next, _insert(trie[next], rest))
      false -> Map.put(trie, next, _insert(%{}, rest))
    end
  end

  defp _insert(trie, <<>>) do
    Map.put(trie, :mark, :mark)
  end

  @doc """
  Returns whether or not a trie contains a given binary key.

  ## Examples

      iex> Trieval.new(~w/apple apply ape ample/) |> Trieval.contains?("apple")
      true

      iex> Trieval.new(~w/apple apply ape ample/) |> Trieval.contains?("zebra")
      false

  """
  @spec contains?(%Trieval.Trie{trie: map()}, binary()) :: boolean()
  def contains?(%Trie{trie: trie}, binary) when is_binary(binary) do
    _contains?(trie, binary)
  end

  defp _contains?(trie, <<next, rest::binary>>) do
    case Map.has_key?(trie, next) do
      true -> _contains?(trie[next], rest)
      false -> false
    end
  end

  defp _contains?(%{mark: _}, <<>>) do
    true
  end

  defp _contains?(_trie, <<>>) do
    false
  end

  @doc """
  Collects all binaries that begin with a given prefix.

  ## Examples

      iex> Trieval.new(~w/apple apply ape ample/) |> Trieval.prefix("ap")
      ["ape", "apple", "apply"]

      iex> Trieval.new(~w/apple apply ape ample/) |> Trieval.prefix("z")
      []

  """
  @spec prefix(%Trieval.Trie{trie: map()}, binary()) :: list()
  def prefix(%Trie{trie: trie}, binary) when is_binary(binary) do
    _prefix(trie, binary, binary)
  end

  defp _prefix(trie, <<next, rest::binary>>, acc) do
    case Map.has_key?(trie, next) do
      true -> _prefix(trie[next], rest, acc)
      false -> []
    end
  end

  # An interesting discovery I made here is that treating the accumulator as a binary is actually quicker
  # than converting the prefix to a char list, prepending to it, reversing when a word is found, and converting
  # to a binary.
  defp _prefix(trie, <<>>, acc) do
    Enum.flat_map(trie, fn
      {:mark, :mark} -> [acc]
      {:mark, payload} -> [{acc, payload}]
      {ch, sub_trie} -> _prefix(sub_trie, <<>>, acc <> <<ch>>)
    end)
  end

  @doc """
  Collects all binaries that begin with a given prefix. Returns matching binaries, along
  with matching binaries' longest common prefix. Example use-case would be for auto-completion.

  ## Examples

      iex> Trieval.new(~w/apple apply ape/) |> Trieval.longest_common_prefix("a")
      {"ap", ["ape", "apple", "apply"]}

      iex> Trieval.new(~w/apple apply ape ample/) |> Trieval.longest_common_prefix("z")
      {nil, []}

  """
  @spec longest_common_prefix(%Trieval.Trie{trie: map()}, binary()) :: {[nil | bitstring()], list()}
  def longest_common_prefix(%Trie{trie: trie}, binary) when is_binary(binary) do
    _longest_common_prefix(trie, binary, binary)
  end

  defp _longest_common_prefix(trie, <<next, rest::binary>>, acc) do
    case Map.has_key?(trie, next) do
      true -> _longest_common_prefix(trie[next], rest, acc)
      false -> {nil, []}
    end
  end

  defp _longest_common_prefix(trie, <<>>, acc) do
    case Enum.count(trie) do
      1 ->
        case Map.keys(trie) do
          [:mark] -> {acc, [acc]}
          [ch] -> _longest_common_prefix(trie[ch], <<>>, acc <> <<ch>>)
        end

      _ ->
        matches = _prefix(trie, <<>>, acc)
        {acc, matches}
    end
  end

  @doc """
  Collects all binaries match a given pattern. Returns either a list of matches
  or an error in the form `{:error, reason}`.

  ## Patterns

       `*`      - Wildcard, matches any character.

       `[...]`  - Inclusion group, matches any character between brackets.

       `[^...]` - Exclusion group, matches any character not between brackets.

       `{...}`  - Capture group, must be named and can be combined with an
                  inclusion or exclusion group, otherwise treated as a wildcard.
                  All future instances of same name captures are swapped with
                  the value of the initial capture.

  ## Examples

      iex> Trieval.new(~w/apple apply ape ample/) |> Trieval.pattern("a{1}{1}**")
      ["apple", "apply"]

      iex> Trieval.new(~w/apple apply ape ample/) |> Trieval.pattern("*{1[^p]}{1}**")
      []

      iex> Trieval.new(~w/apple apply zebra house/) |> Trieval.pattern("[hz]****")
      ["house", "zebra"]

      iex> Trieval.new(~w/apple apply zebra house/) |> Trieval.pattern("[hz]***[^ea]")
      []

      iex> Trieval.new(~w/apple apply zebra house/) |> Trieval.pattern("[hz]***[^ea")
      {:error, "Dangling group (exclusion) starting at column 8, expecting ]"}

  """
  @spec pattern(%Trieval.Trie{trie: map()}, binary()) :: list() | {:error, <<_::64, _::_*8>>}
  def pattern(%Trie{trie: trie}, pattern) when is_binary(pattern) do
    _pattern(trie, %{}, pattern, <<>>, :parse)
  end

  defp _pattern(trie, capture_map, pattern, acc, :parse) do
    case PatternParser.parse(pattern) do
      {:error, message} -> {:error, message}
      parsed_pattern -> _pattern(trie, capture_map, parsed_pattern, acc)
    end
  end

  defp _pattern(trie, capture_map, [{:character, ch} | rest], acc) do
    case Map.has_key?(trie, ch) do
      true -> _pattern(trie[ch], capture_map, rest, acc <> <<ch>>)
      false -> []
    end
  end

  defp _pattern(trie, capture_map, [:wildcard | rest], acc) do
    Enum.flat_map(trie, fn
      {:mark, _} -> []
      {ch, sub_trie} -> _pattern(sub_trie, capture_map, rest, acc <> <<ch>>)
    end)
  end

  defp _pattern(trie, capture_map, [{:exclusion, exclusions} | rest], acc) do
    pruned_trie = Enum.filter(trie, fn {k, _v} -> !Map.has_key?(exclusions, k) end)

    Enum.flat_map(pruned_trie, fn
      {:mark, _} -> []
      {ch, sub_trie} -> _pattern(sub_trie, capture_map, rest, acc <> <<ch>>)
    end)
  end

  defp _pattern(trie, capture_map, [{:inclusion, inclusions} | rest], acc) do
    pruned_trie = Enum.filter(trie, fn {k, _v} -> Map.has_key?(inclusions, k) end)

    Enum.flat_map(pruned_trie, fn
      {:mark, _} -> []
      {ch, sub_trie} -> _pattern(sub_trie, capture_map, rest, acc <> <<ch>>)
    end)
  end

  defp _pattern(trie, capture_map, [{:capture, name} | rest], acc) do
    case Map.has_key?(capture_map, name) do
      true ->
        match = capture_map[name]

        case Map.has_key?(trie, match) do
          true -> _pattern(trie[match], capture_map, rest, acc <> <<match>>)
          false -> []
        end

      false ->
        Enum.flat_map(trie, fn
          {:mark, _} ->
            []

          {ch, sub_trie} ->
            capture_map = Map.put(capture_map, name, ch)
            _pattern(sub_trie, capture_map, rest, acc <> <<ch>>)
        end)
    end
  end

  defp _pattern(trie, capture_map, [{:capture, name, :exclusion, exclusions} | rest], acc) do
    case Map.has_key?(capture_map, name) do
      true ->
        match = capture_map[name]

        case Map.has_key?(trie, match) do
          true -> _pattern(trie[match], capture_map, rest, acc <> <<match>>)
          false -> []
        end

      false ->
        pruned_trie = Enum.filter(trie, fn {k, _v} -> !Map.has_key?(exclusions, k) end)

        Enum.flat_map(pruned_trie, fn
          {:mark, _} ->
            []

          {ch, sub_trie} ->
            capture_map = Map.put(capture_map, name, ch)
            _pattern(sub_trie, capture_map, rest, acc <> <<ch>>)
        end)
    end
  end

  defp _pattern(trie, capture_map, [{:capture, name, :inclusion, inclusions} | rest], acc) do
    case Map.has_key?(capture_map, name) do
      true ->
        match = capture_map[name]

        case Map.has_key?(trie, match) do
          true -> _pattern(trie[match], capture_map, rest, acc <> <<match>>)
          false -> []
        end

      false ->
        pruned_trie = Enum.filter(trie, fn {k, _v} -> Map.has_key?(inclusions, k) end)

        Enum.flat_map(pruned_trie, fn
          {:mark, _} ->
            []

          {ch, sub_trie} ->
            capture_map = Map.put(capture_map, name, ch)
            _pattern(sub_trie, capture_map, rest, acc <> <<ch>>)
        end)
    end
  end

  defp _pattern(trie, _capture_map, [], acc) do
    case Map.has_key?(trie, :mark) do
      true ->
        case Map.get(trie, :mark) do
          :mark -> [acc]
          payload -> [{acc, payload}]
        end

      false ->
        []
    end
  end
end
