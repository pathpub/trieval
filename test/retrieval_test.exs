defmodule TrievalTest do
  use ExUnit.Case
  doctest Trieval

  @test_data ~w/apple apply ape bed between betray cat cold hot
                warm winter maze smash crush under above people
                negative poison place out divide zebra extended/

  @test_trie Trieval.new(@test_data)

  @payload_trie Enum.map(@test_data, fn item = <<first, _ :: binary>> ->
    {item, <<first>>}
  end) |> Retrieval.new


  test "empty trie" do
    assert Trieval.new == %Trieval.Trie{}
  end

  test "contains?" do
    assert Trieval.contains?(@test_trie, "apple") == true
    assert Trieval.contains?(@test_trie, "smash") == true
    assert Trieval.contains?(@test_trie, "abcde") == false
    assert Trieval.contains?(@test_trie, "app")   == false
  end

  test "prefix" do
    assert Trieval.prefix(@test_trie, "app") == ["apple", "apply"]
    assert Trieval.prefix(@test_trie, "n")   == ["negative"]
    assert Trieval.prefix(@test_trie, "abc") == []
  end

  test "pattern errors" do
    assert match?({:error, _}, Trieval.pattern(@test_trie, "ab*[^zsd"))
    assert match?({:error, _}, Trieval.pattern(@test_trie, "ab*[^zsd]{}"))
    assert match?({:error, _}, Trieval.pattern(@test_trie, "ab*[^zsd]{1[^abc]a}"))
    assert match?({:error, _}, Trieval.pattern(@test_trie, "ab*[^zsd]{1[^abc]"))
    assert match?({:error, _}, Trieval.pattern(@test_trie, "ab*[^zsd]{1[^ab*c]a}{1}"))
  end

  test "pattern" do
    assert Trieval.pattern(@test_trie, "*{1}{1}**") == ["apple", "apply"]
    assert Trieval.pattern(@test_trie, "[^abc]{1}{1}**") == []
    assert Trieval.pattern(@test_trie, "[co]**") == ["cat", "out"]
    assert Trieval.pattern(@test_trie, "{1[^okjh]}x[tnm]{1}*{2}{1}{2}") == ["extended"]
  end

  test "payload prefix" do
    assert Retrieval.prefix(@payload_trie, "app") == [{"apple", "a"}, {"apply", "a"}]
    assert Retrieval.prefix(@payload_trie, "n")   == [{"negative", "n"}]
    assert Retrieval.prefix(@payload_trie, "abc") == []
  end

  test "payload pattern" do
    assert Retrieval.pattern(@payload_trie, "*{1}{1}**") == [{"apple", "a"}, {"apply", "a"}]
    assert Retrieval.pattern(@payload_trie, "[^abc]{1}{1}**") == []
    assert Retrieval.pattern(@payload_trie, "[co]**") == [{"cat", "c"}, {"out", "o"}]
    assert Retrieval.pattern(@payload_trie, "{1[^okjh]}x[tnm]{1}*{2}{1}{2}") == [{"extended", "e"}]
  end

end
