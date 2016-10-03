# Überauth Instagram
[![License][license-img]][license]

[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

> Instagram OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [Instagram Developers](https://www.instagram.com/developer/).

1. Add `:ueberauth_instagram` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_instagram, "~> 0.1"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_instagram]]
    end
    ```

1. Add Instagram to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        instagram: {Ueberauth.Strategy.Instagram, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Instagram.OAuth,
      client_id: System.get_env("INSTAGRAM_CLIENT_ID"),
      client_secret: System.get_env("INSTAGRAM_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured URL you can initialize the request through:

    /auth/instagram

Or with options:

    /auth/instagram?scope=basic

By default the requested scope is "public_content". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    instagram: {Ueberauth.Strategy.Instagram, [default_scope: "basic,public_content,followers_list"]}
  ]
```

See [Instagram API Reference > Login Permissions](https://www.instagram.com/developer/authorization/) for full list of scopes.


## License

Please see [LICENSE](https://github.com/ueberauth/ueberauth_instagram/blob/master/LICENSE) for licensing details.

