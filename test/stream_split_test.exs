defmodule StreamSplitTest do
  use ExUnit.Case
  doctest StreamSplit, import: true

  test "empty stream" do
    stream = Stream.resource(fn -> nil end, fn s -> {:halt, s} end, fn _ -> nil end)
    assert Enum.to_list(stream) == []
    {elements, []} = StreamSplit.take_and_drop(stream, 1)
    assert elements == []
  end

  test "multiple pops" do
    {1, stream} = Stream.cycle([1, 2, 3]) |> StreamSplit.pop()
    {2, stream} = stream |> StreamSplit.pop()
    {3, stream} = stream |> StreamSplit.pop()
    {1, _stream} = stream |> StreamSplit.pop()
  end

  test "does not leak" do
    {_, stream} = Stream.cycle([1, 2, 3]) |> StreamSplit.pop()

    stream_after_some_pops =
      1..1000
      |> Enum.reduce(stream, fn _, stream_acc ->
        {_, stream_acc} = StreamSplit.pop(stream_acc)
        stream_acc
      end)

    init_size = byte_size(:erlang.term_to_binary(stream))
    final_size = byte_size(:erlang.term_to_binary(stream_after_some_pops))

    assert_in_delta final_size / init_size, 1, 0.1
  end
end
