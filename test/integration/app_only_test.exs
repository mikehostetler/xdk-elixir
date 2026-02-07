Code.require_file("integration_helper.exs", __DIR__)

defmodule Xdk.Integration.AppOnlyTest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @moduletag timeout: 60_000

  setup_all do
    unless Xdk.Integration.has_bearer_token?() do
      raise "BEARER_TOKEN not set — add it to .env or export it"
    end

    Xdk.Integration.setup_app_only_client()
  end

  # -- Users --

  describe "Users.get_by_username/3" do
    test "looks up a user with field expansion", %{client: client} do
      assert {:ok, resp} =
               Xdk.Users.get_by_username(client, "XDevelopers",
                 user_fields: ["id", "name", "username", "public_metrics"]
               )

      data = resp["data"]
      assert data["id"]
      assert data["username"] =~ ~r/xdevelopers/i
      assert data["public_metrics"]
    end
  end

  describe "Users.get_by_id/3" do
    test "looks up a user by ID", %{client: client} do
      {:ok, lookup} = Xdk.Users.get_by_username(client, "XDevelopers")
      user_id = lookup["data"]["id"]

      assert {:ok, resp} =
               Xdk.Users.get_by_id(client, user_id,
                 user_fields: ["id", "name", "username"]
               )

      assert resp["data"]["id"] == user_id
    end
  end

  describe "Users.get_by_ids/2" do
    test "looks up multiple users", %{client: client} do
      {:ok, lookup} = Xdk.Users.get_by_username(client, "XDevelopers")
      user_id = lookup["data"]["id"]

      assert {:ok, resp} = Xdk.Users.get_by_ids(client, ids: [user_id])
      assert is_list(resp["data"])
      assert length(resp["data"]) == 1
    end
  end

  describe "Users.get_by_usernames/2" do
    test "looks up multiple usernames", %{client: client} do
      assert {:ok, resp} =
               Xdk.Users.get_by_usernames(client,
                 usernames: ["XDevelopers", "X"]
               )

      assert is_list(resp["data"])
      assert length(resp["data"]) == 2
    end
  end

  describe "Users.get_followers/3" do
    test "returns followers for a user", %{client: client} do
      {:ok, lookup} = Xdk.Users.get_by_username(client, "XDevelopers")
      user_id = lookup["data"]["id"]

      assert {:ok, resp} = Xdk.Users.get_followers(client, user_id, max_results: 10)
      assert is_list(resp["data"])
    end
  end

  describe "Users.get_following/3" do
    test "returns following for a user", %{client: client} do
      {:ok, lookup} = Xdk.Users.get_by_username(client, "XDevelopers")
      user_id = lookup["data"]["id"]

      assert {:ok, resp} = Xdk.Users.get_following(client, user_id, max_results: 10)
      assert is_list(resp["data"])
    end
  end

  describe "Users.get_posts/3" do
    test "returns a user's tweets", %{client: client} do
      {:ok, lookup} = Xdk.Users.get_by_username(client, "XDevelopers")
      user_id = lookup["data"]["id"]

      assert {:ok, resp} =
               Xdk.Users.get_posts(client, user_id,
                 max_results: 5,
                 tweet_fields: ["id", "text", "created_at"]
               )

      assert is_list(resp["data"])
      first = hd(resp["data"])
      assert first["id"]
      assert first["text"]
    end
  end

  describe "Users.get_mentions/3" do
    test "returns mentions for a user", %{client: client} do
      {:ok, lookup} = Xdk.Users.get_by_username(client, "XDevelopers")
      user_id = lookup["data"]["id"]

      assert {:ok, resp} =
               Xdk.Users.get_mentions(client, user_id,
                 max_results: 5,
                 tweet_fields: ["id", "text"]
               )

      assert is_list(resp["data"]) or resp["data"] == nil
    end
  end

  # -- Posts --

  describe "Posts.search_recent/2" do
    test "searches recent tweets with field expansion", %{client: client} do
      assert {:ok, resp} =
               Xdk.Posts.search_recent(client,
                 query: "elixir lang",
                 max_results: 10,
                 tweet_fields: ["id", "text", "created_at", "author_id"]
               )

      data = resp["data"]
      assert is_list(data)
      assert length(data) > 0

      first = hd(data)
      assert first["id"]
      assert first["author_id"]
    end
  end

  describe "Posts.get_by_id/3" do
    test "fetches a single tweet by ID", %{client: client} do
      {:ok, search} =
        Xdk.Posts.search_recent(client, query: "hello", max_results: 10)

      tweet_id = hd(search["data"])["id"]

      assert {:ok, resp} =
               Xdk.Posts.get_by_id(client, tweet_id,
                 tweet_fields: ["id", "text", "author_id"]
               )

      assert resp["data"]["id"] == tweet_id
    end
  end

  describe "Posts.get_by_ids/2" do
    test "fetches multiple tweets by ID", %{client: client} do
      {:ok, search} =
        Xdk.Posts.search_recent(client, query: "hello", max_results: 10)

      ids = Enum.map(search["data"], & &1["id"]) |> Enum.take(3)

      assert {:ok, resp} = Xdk.Posts.get_by_ids(client, ids: ids)
      assert is_list(resp["data"])
      assert length(resp["data"]) == length(ids)
    end
  end

  describe "Posts.get_liking_users/3" do
    test "returns users who liked a tweet", %{client: client} do
      {:ok, search} =
        Xdk.Posts.search_recent(client, query: "elixir", max_results: 10)

      tweet_id = hd(search["data"])["id"]

      result = Xdk.Posts.get_liking_users(client, tweet_id, max_results: 10)
      assert match?({:ok, _}, result) or match?({:error, %Xdk.Errors.ApiError{}}, result)
    end
  end

  describe "Posts.get_quoted/3" do
    test "returns quote tweets", %{client: client} do
      {:ok, search} =
        Xdk.Posts.search_recent(client, query: "elixir", max_results: 10)

      tweet_id = hd(search["data"])["id"]

      result = Xdk.Posts.get_quoted(client, tweet_id, max_results: 10)
      assert match?({:ok, _}, result) or match?({:error, %Xdk.Errors.ApiError{}}, result)
    end
  end

  describe "Posts.get_counts_recent/2" do
    test "returns tweet counts", %{client: client} do
      assert {:ok, resp} =
               Xdk.Posts.get_counts_recent(client, query: "elixir")

      assert is_list(resp["data"])
      assert resp["meta"]["total_tweet_count"] >= 0
    end
  end

  # -- Pagination --

  describe "Paginator" do
    test "paginates across multiple pages", %{client: client} do
      fetch = fn token ->
        opts = [query: "elixir", max_results: 10]
        opts = if token, do: Keyword.put(opts, :pagination_token, token), else: opts
        Xdk.Posts.search_recent(client, opts)
      end

      items =
        Xdk.Paginator.items(fetch)
        |> Enum.take(15)

      assert length(items) > 10
    end
  end

  # -- Query encoding --

  describe "CSV field expansion" do
    test "multiple fields are sent as CSV and returned", %{client: client} do
      assert {:ok, resp} =
               Xdk.Users.get_by_username(client, "XDevelopers",
                 user_fields: ["id", "name", "username", "description", "profile_image_url"]
               )

      data = resp["data"]
      assert data["description"] != nil or data["profile_image_url"] != nil
    end
  end

  # -- Error handling --

  describe "error handling" do
    test "not-found resource returns errors array", %{client: client} do
      result = Xdk.Posts.get_by_id(client, "0000000000000000000")

      case result do
        {:error, %Xdk.Errors.ApiError{}} -> :ok
        {:error, %Xdk.Errors.RateLimitError{}} -> :ok
        {:ok, %{"errors" => [_ | _]}} -> :ok
        {:ok, %{"data" => _}} -> flunk("expected error for bogus tweet ID, got data")
      end
    end

    test "API error struct contains status and body", %{client: client} do
      case Xdk.Posts.get_by_id(client, "0000000000000000000") do
        {:error, %Xdk.Errors.ApiError{status: status, body: body}} ->
          assert is_integer(status)
          assert body != nil

        {:ok, %{"errors" => _}} ->
          :ok

        {:error, %Xdk.Errors.RateLimitError{}} ->
          :ok
      end
    end
  end

  # -- General --

  describe "General.get_open_api_spec/1" do
    test "fetches the OpenAPI spec", %{client: client} do
      assert {:ok, resp} = Xdk.General.get_open_api_spec(client)
      assert is_map(resp) or is_binary(resp)
    end
  end

  # -- Trends --

  describe "Trends.get_by_woeid/3" do
    test "returns trends for a location", %{client: client} do
      result = Xdk.Trends.get_by_woeid(client, "1")
      assert match?({:ok, _}, result) or match?({:error, %Xdk.Errors.ApiError{}}, result)
    end
  end

  # -- Usage --

  describe "Usage.get/2" do
    test "returns API usage data", %{client: client} do
      result = Xdk.Usage.get(client)
      assert match?({:ok, _}, result) or match?({:error, %Xdk.Errors.ApiError{}}, result)
    end
  end
end
