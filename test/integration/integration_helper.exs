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
end
