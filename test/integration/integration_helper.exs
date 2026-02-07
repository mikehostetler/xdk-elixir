Dotenvy.source!([".env"])
|> Enum.each(fn {k, v} -> System.put_env(k, v) end)

defmodule Xdk.Integration do
  @moduledoc false

  def bearer_token do
    System.get_env("BEARER_TOKEN") ||
      System.get_env("X_BEARER_TOKEN") ||
      System.get_env("TWITTER_BEARER_TOKEN")
  end

  def has_bearer_token?, do: is_binary(bearer_token()) and bearer_token() != ""

  def has_oauth1_creds? do
    Enum.all?(
      ["CONSUMER_KEY", "SECRET_KEY", "ACCESS_TOKEN", "ACCESS_TOKEN_SECRET"],
      fn k -> is_binary(System.get_env(k)) and System.get_env(k) != "" end
    )
  end

  def oauth1_credentials do
    OAuther.credentials(
      consumer_key: System.get_env("CONSUMER_KEY"),
      consumer_secret: System.get_env("SECRET_KEY"),
      token: System.get_env("ACCESS_TOKEN"),
      token_secret: System.get_env("ACCESS_TOKEN_SECRET")
    )
  end

  def setup_app_only_client do
    finch_name = :"Xdk.Integration.Finch.#{System.unique_integer([:positive])}"
    {:ok, _} = Finch.start_link(name: finch_name)

    client =
      Xdk.new(
        finch: finch_name,
        auth: {:bearer, bearer_token()}
      )

    %{client: client}
  end

  def setup_user_context_client do
    finch_name = :"Xdk.Integration.Finch.#{System.unique_integer([:positive])}"
    {:ok, _} = Finch.start_link(name: finch_name)

    client =
      Xdk.new(
        finch: finch_name,
        auth: {:oauth1, oauth1_credentials()}
      )

    %{client: client}
  end
end
