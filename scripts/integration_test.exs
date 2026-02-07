#!/usr/bin/env elixir

# Live API integration test
# Usage: mix run scripts/integration_test.exs

Dotenvy.source!([".env"])
|> Enum.each(fn {k, v} -> System.put_env(k, v) end)

defmodule IntegrationTest do
  @moduledoc false

  def run do
    token =
      System.get_env("BEARER_TOKEN") ||
        System.get_env("X_BEARER_TOKEN") ||
        System.get_env("TWITTER_BEARER_TOKEN") ||
        raise "Set BEARER_TOKEN in .env"

    {:ok, _} = Finch.start_link(name: IntegrationTest.Finch)
    client = Xdk.new(finch: IntegrationTest.Finch, auth: {:bearer, token})

    IO.puts("\n=== XDK Elixir Integration Test ===\n")

    results =
      [
        {"Users.get_by_username", fn -> test_get_by_username(client) end},
        {"Posts.search_recent", fn -> test_search_recent(client) end},
        {"Posts.get_by_id", fn -> test_get_by_id(client) end},
        {"Query CSV encoding", fn -> test_csv_fields(client) end},
        {"Paginator", fn -> test_paginator(client) end},
        {"Error handling (not found)", fn -> test_error_handling(client) end}
      ]
      |> Enum.map(fn {name, test_fn} ->
        IO.write("  #{name}... ")

        try do
          test_fn.()
          IO.puts("✓")
          :pass
        rescue
          e ->
            IO.puts("✗ #{Exception.message(e)}")
            :fail
        end
      end)

    passes = Enum.count(results, &(&1 == :pass))
    fails = Enum.count(results, &(&1 == :fail))

    IO.puts("\n#{passes} passed, #{fails} failed\n")

    if fails > 0, do: System.halt(1)
  end

  # -- Individual tests --

  defp test_get_by_username(client) do
    {:ok, resp} =
      Xdk.Users.get_by_username(client, "XDevelopers",
        user_fields: ["id", "name", "public_metrics"]
      )

    data = resp["data"]
    assert data["id"], "missing id"
    assert data["public_metrics"], "public_metrics not returned"
  end

  defp test_search_recent(client) do
    {:ok, resp} =
      Xdk.Posts.search_recent(client,
        query: "elixir lang",
        max_results: 10,
        tweet_fields: ["id", "text", "created_at", "author_id"]
      )

    data = resp["data"]
    assert is_list(data), "expected data to be a list"
    assert length(data) > 0, "no results for 'elixir lang'"

    first = hd(data)
    assert first["id"], "missing id on first tweet"
    assert first["author_id"], "author_id not returned (fields expansion failed?)"
  end

  defp test_get_by_id(client) do
    # First find a tweet ID via search
    {:ok, search} = Xdk.Posts.search_recent(client, query: "hello", max_results: 10)
    tweet_id = hd(search["data"])["id"]

    {:ok, resp} =
      Xdk.Posts.get_by_id(client, tweet_id,
        tweet_fields: ["id", "text", "author_id"]
      )

    assert resp["data"]["id"] == tweet_id, "returned wrong tweet"
  end

  defp test_csv_fields(client) do
    {:ok, resp} =
      Xdk.Users.get_by_username(client, "XDevelopers",
        user_fields: ["id", "name", "username", "description", "profile_image_url"]
      )

    data = resp["data"]
    assert data["description"] != nil or data["profile_image_url"] != nil,
           "multi-field CSV expansion failed — fields not returned"
  end

  defp test_paginator(client) do
    fetch = fn token ->
      opts = [query: "elixir", max_results: 10]
      opts = if token, do: Keyword.put(opts, :pagination_token, token), else: opts
      Xdk.Posts.search_recent(client, opts)
    end

    items =
      Xdk.Paginator.items(fetch)
      |> Enum.take(15)

    assert length(items) > 10, "paginator should have fetched across pages (got #{length(items)})"
  end

  defp test_error_handling(client) do
    result = Xdk.Posts.get_by_id(client, "0000000000000000000")

    case result do
      {:error, %Xdk.Errors.ApiError{status: status}} when status in [400, 403, 404] ->
        :ok

      {:error, %Xdk.Errors.RateLimitError{}} ->
        :ok

      {:ok, %{"errors" => [_ | _]}} ->
        :ok

      {:ok, %{"data" => _}} ->
        raise "expected error for bogus tweet ID, got success with data"

      {:error, other} ->
        raise "unexpected error type: #{inspect(other)}"
    end
  end

  # -- Helpers --

  defp assert(truthy, message) do
    unless truthy, do: raise(message)
  end
end

IntegrationTest.run()
