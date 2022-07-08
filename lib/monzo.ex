defmodule Transactions do
  @derive [Poison.Encoder]
  defstruct [:transactions]
end

defmodule Transaction do
  @derive [Poison.Encoder]
  defstruct [:amount, :created, :notes, :counterparty]
end

defmodule CounterParty do
  @derive [Poison.Encoder]
  defstruct [:name]
end

defmodule CounterParties do
  @derive [Poison.Encoder]
  defstruct [:counter_parties]
end
