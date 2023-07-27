defmodule Pongx.Repo do
  use Ecto.Repo,
    otp_app: :pongx,
    adapter: Ecto.Adapters.Postgres
end
