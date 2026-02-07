Code.require_file("integration_helper.exs", __DIR__)

defmodule Xdk.Integration.UserContextTest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @moduletag :user_context
  @moduletag timeout: 60_000

  setup_all do
    unless Xdk.Integration.has_oauth1_creds?() do
      raise "OAuth 1.0a credentials not set — add CONSUMER_KEY, SECRET_KEY, ACCESS_TOKEN, ACCESS_TOKEN_SECRET to .env"
    end

    Xdk.Integration.setup_user_context_client()
  end

  describe "Users.get_me/2" do
    test "returns the authenticated user", %{client: client} do
      assert {:ok, resp} =
               Xdk.Users.get_me(client,
                 user_fields: ["id", "name", "username", "created_at"]
               )

      data = resp["data"]
      assert data["id"]
      assert data["username"]
      assert data["created_at"]
    end
  end

  describe "Users.get_me/2 with expansions" do
    test "returns expanded fields", %{client: client} do
      assert {:ok, resp} =
               Xdk.Users.get_me(client,
                 user_fields: [
                   "id",
                   "name",
                   "username",
                   "public_metrics",
                   "description",
                   "profile_image_url"
                 ]
               )

      data = resp["data"]
      assert data["id"]
      assert data["public_metrics"]
    end
  end

  describe "Users.get_bookmarks/3" do
    test "returns bookmarks for authenticated user", %{client: client} do
      {:ok, me} = Xdk.Users.get_me(client)
      user_id = me["data"]["id"]

      result = Xdk.Users.get_bookmarks(client, user_id, max_results: 5)

      case result do
        {:ok, %{"data" => data}} when is_list(data) -> assert true
        {:ok, %{"data" => nil}} -> assert true
        {:ok, %{}} -> assert true
        {:error, %Xdk.Errors.ApiError{status: 403}} -> assert true
        {:error, %Xdk.Errors.RateLimitError{}} -> assert true
      end
    end
  end

  describe "Users.get_timeline/3" do
    test "returns reverse chronological timeline", %{client: client} do
      {:ok, me} = Xdk.Users.get_me(client)
      user_id = me["data"]["id"]

      assert {:ok, resp} =
               Xdk.Users.get_timeline(client, user_id,
                 max_results: 5,
                 tweet_fields: ["id", "text", "created_at"]
               )

      data = resp["data"]
      assert is_list(data)
      assert length(data) > 0

      first = hd(data)
      assert first["id"]
      assert first["text"]
    end
  end

  describe "Users.get_mentions/3" do
    test "returns mentions for authenticated user", %{client: client} do
      {:ok, me} = Xdk.Users.get_me(client)
      user_id = me["data"]["id"]

      assert {:ok, resp} =
               Xdk.Users.get_mentions(client, user_id,
                 max_results: 5,
                 tweet_fields: ["id", "text", "author_id"]
               )

      assert is_list(resp["data"]) or resp["data"] == nil
    end
  end

  describe "Users.get_liked_posts/3" do
    test "returns liked tweets for authenticated user", %{client: client} do
      {:ok, me} = Xdk.Users.get_me(client)
      user_id = me["data"]["id"]

      result = Xdk.Users.get_liked_posts(client, user_id, max_results: 5)

      case result do
        {:ok, %{"data" => data}} when is_list(data) -> assert true
        {:ok, %{"data" => nil}} -> assert true
        {:ok, %{}} -> assert true
        {:error, %Xdk.Errors.ApiError{status: 403}} -> assert true
        {:error, %Xdk.Errors.RateLimitError{}} -> assert true
      end
    end
  end

  describe "Users.get_following/3 (user context)" do
    test "returns following list for authenticated user", %{client: client} do
      {:ok, me} = Xdk.Users.get_me(client)
      user_id = me["data"]["id"]

      assert {:ok, resp} = Xdk.Users.get_following(client, user_id, max_results: 10)
      assert is_list(resp["data"])
    end
  end

  describe "Users.get_followers/3 (user context)" do
    test "returns follower list for authenticated user", %{client: client} do
      {:ok, me} = Xdk.Users.get_me(client)
      user_id = me["data"]["id"]

      assert {:ok, resp} = Xdk.Users.get_followers(client, user_id, max_results: 10)
      assert is_list(resp["data"])
    end
  end

  describe "Users.get_blocking/3" do
    test "returns block list for authenticated user", %{client: client} do
      {:ok, me} = Xdk.Users.get_me(client)
      user_id = me["data"]["id"]

      result = Xdk.Users.get_blocking(client, user_id, max_results: 10)

      case result do
        {:ok, %{"data" => data}} when is_list(data) -> assert true
        {:ok, %{}} -> assert true
        {:error, %Xdk.Errors.ApiError{}} -> assert true
        {:error, %Xdk.Errors.RateLimitError{}} -> assert true
      end
    end
  end

  describe "Users.get_muting/3" do
    test "returns mute list for authenticated user", %{client: client} do
      {:ok, me} = Xdk.Users.get_me(client)
      user_id = me["data"]["id"]

      result = Xdk.Users.get_muting(client, user_id, max_results: 10)

      case result do
        {:ok, %{"data" => data}} when is_list(data) -> assert true
        {:ok, %{}} -> assert true
        {:error, %Xdk.Errors.ApiError{}} -> assert true
        {:error, %Xdk.Errors.RateLimitError{}} -> assert true
      end
    end
  end

  describe "Posts.search_recent/2 (user context)" do
    test "search works with OAuth 1.0a auth", %{client: client} do
      assert {:ok, resp} =
               Xdk.Posts.search_recent(client,
                 query: "elixir lang",
                 max_results: 10,
                 tweet_fields: ["id", "text", "author_id"]
               )

      assert is_list(resp["data"])
      assert length(resp["data"]) > 0
    end
  end

  describe "Users.get_posts/3 (user context)" do
    test "returns own tweets", %{client: client} do
      {:ok, me} = Xdk.Users.get_me(client)
      user_id = me["data"]["id"]

      assert {:ok, resp} =
               Xdk.Users.get_posts(client, user_id,
                 max_results: 5,
                 tweet_fields: ["id", "text"]
               )

      assert is_list(resp["data"]) or resp["data"] == nil
    end
  end
end
