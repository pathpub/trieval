defmodule TrievalTest do
  use ExUnit.Case
  doctest Trieval

  @test_data ~w/apple apply ape bed between betray cat cold hot
                warm winter maze smash crush under above people
                negative poison place out divide zebra extended
		dad daddy dadoobidoo/

  @test_trie Trieval.new(@test_data)

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

  test "prefix!" do
    assert Trieval.prefix!(@test_trie, "da") == {"dad", ["daddy", "dadoobidoo", "dad"]}
    assert Trieval.prefix!(@test_trie, "winter") == {"winter", ["winter"]}
    assert Trieval.prefix!(@test_trie, "abc") == {nil, []}
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

end
