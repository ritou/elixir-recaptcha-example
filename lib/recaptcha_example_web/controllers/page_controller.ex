defmodule RecaptchaExampleWeb.PageController do
  use RecaptchaExampleWeb, :controller

  @recaptcha_site_key System.get_env("RECAPTCHA_SITE_KEY") || Application.fetch_env!(:recaptcha_example, :recaptcha_site_key)
  @recaptcha_secret   System.get_env("RECAPTCHA_SECRET") || Application.fetch_env!(:recaptcha_example, :recaptcha_secret)
  @recaptcha_config %{recaptcha_site_key: @recaptcha_site_key, recaptcha_secret: @recaptcha_secret}

  def index(conn, _params) do
    render conn, "index.html", %{config: @recaptcha_config, response: "", error: ""}
  end

  def recaptcha(conn, params) do
    assigns =
      case parse_recaptcha_token(params["recaptcha_token"]) do
        {:ok, response} ->
          %{response: "#{inspect response}", error: ""}
        error ->
          %{response: "", error: "#{inspect error}"}
      end
    render conn, "index.html", assigns |> Map.put(:config, @recaptcha_config)
  end

  @headers [
    {"Content-type", "application/x-www-form-urlencoded"},
    {"Accept", "application/json"}
  ]

  @verify_url "https://www.google.com/recaptcha/api/siteverify"

  defp parse_recaptcha_token(nil), do: {:error, :recaptcha_token_not_found}
  defp parse_recaptcha_token(token) do
    body = %{secret: "6Ldiq2AUAAAAAPwhWIVXcQ67rOOQokQ8gYbzqzFI", response: token} |> URI.encode_query()
    case HTTPoison.post(@verify_url, body, @headers) do
      {:ok, response} ->
        body = response.body |> Poison.decode!()
        if body["success"] do
          {:ok, body}
        else
          {:error, body}
        end
      _ ->
        {:error, :verify_error}
    end
  end

end
