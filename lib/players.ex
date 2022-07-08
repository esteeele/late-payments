defmodule Players do
  @derive [Poison.Encoder]
  defstruct [:games]
end

defmodule Games do
  @derive [Poison.Encoder]
  defstruct [:date, :players, :amount]
end
