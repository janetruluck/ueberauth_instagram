defmodule Ueberauth.Strategy.Instagram do
  @moduledoc """
  Instagram Strategy for Überauth.
  """

  use Ueberauth.Strategy, default_scope: "public_content",
                          uid_field: :id,
                          allowed_request_params: [
                            :auth_type,
                            :scope
                          ]


  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles initial request for Instagram authentication.
  """
  def handle_request!(conn) do
    allowed_params = conn
     |> option(:allowed_request_params)
     |> Enum.map(&to_string/1)

    authorize_url = conn.params
      |> maybe_replace_param(conn, "scope", :default_scope)
      |> Enum.filter(fn {k,_v} -> Enum.member?(allowed_params, k) end)
      |> Enum.map(fn {k,v} -> {String.to_existing_atom(k), v} end)
      |> Keyword.put(:redirect_uri, callback_url(conn))
      |> Ueberauth.Strategy.Instagram.OAuth.authorize_url!

    redirect!(conn, authorize_url)
  end

  @doc """
  Handles the callback from Instagram.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    opts = [redirect_uri: callback_url(conn)]
    token = Ueberauth.Strategy.Instagram.OAuth.get_token!([code: code], opts).token

    if token.access_token == nil do
      err = token.other_params["error"]
      desc = token.other_params["error_description"]
      set_errors!(conn, [error(err, desc)])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:instagram_user, nil)
    |> put_private(:instagram_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.instagram_user[uid_field]
  end

  @doc """
  Includes the credentials from the instagram response.
  """
  def credentials(conn) do
    token = conn.private.instagram_token
    scopes = token.other_params["scope"] || ""
    scopes = String.split(scopes, ",")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token: token.access_token
    }
  end

  @doc """
  Fetches the fields to populate the info section of the
  `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.instagram_user

    %Info{
      nickname: user["username"],
      name: user["full_name"],
      description: user["bio"],
      image: user["profile_picture"],
      urls: %{
        website: user["website"]
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from
  the instagram callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.instagram_token,
        user: conn.private.instagram_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :instagram_token, token)
    user = token.other_params["user"]
    put_private(conn, :instagram_user, user)
  end

  defp option(conn, key) do
    default = Dict.get(default_options, key)

    conn
    |> options
    |> Dict.get(key, default)
  end
  defp option(nil, conn, key), do: option(conn, key)
  defp option(value, _conn, _key), do: value

  defp maybe_replace_param(params, conn, name, config_key) do
    if params[name] do
      params
    else
      Map.put(
        params,
        name,
        option(params[name], conn, config_key)
      )
    end
  end
end
