defmodule Payments do
  @moduledoc """
  Documentation for `Payments`.
  """

  @doc """
  Looks up who is still owing payments for games on the softball team
  """
  def find_missing_payments do
    url =
      "https://api.monzo.com/transactions?account_id=acc_0000AJNIt7yprpuBaDqJYA&since=2022-05-01T23:00:00Z"

    # access_token = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJlYiI6ImxZMlJrWEpVY1RLMVB0eGc0dHVpIiwianRpIjoiYWNjdG9rXzAwMDBBTEhSeU1YeXhmY2h6ODNpQlYiLCJ0eXAiOiJhdCIsInYiOiI2In0.tzKpxZwrYCni-DCxdRZ5nldEVTh5E7zqCn8KbhdviG2tIMkZWuu7IvFnEKnuIUlL15blqH-9GV4HxKl8v90sRA"

    access_token = System.get_env("MONZO_API_TOKEN")

    # use json file to work out total amount owed then use the monzo API to subtract from that
    {:ok, file} = File.read("./players-per-match.json")
    games_json = Poison.decode!(file)

    players_per_games = games_json["games"]

    total_owed_per_player =
      List.foldl(players_per_games, %{}, fn game, acc ->
        # if value not specified assume a league game for £6
        amount = Map.get(game, "amount", 6)
        amount = amount * 100
        # iterate players and update acc with value
        List.foldl(game["players"], acc, fn player, acc ->
          Map.update(acc, String.downcase(player), amount, fn existing_value ->
            existing_value + amount
          end)
        end)
      end)

    headers = [Authorization: "Bearer #{access_token}"]

    case HTTPoison.get(url, headers, []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        transactions = Poison.decode!(body)

        transaction_list =
          Enum.filter(
            transactions["transactions"],
            fn transaction -> transaction["amount"] > 0 end
          )

        actual_owed_per_player =
          List.foldl(transaction_list, total_owed_per_player, fn transaction, acc ->
            counter_party_name =
              transaction["counterparty"]["name"] |> String.trim() |> String.downcase()

            amount = transaction["amount"]

            matches =
              Enum.filter(
                Map.keys(total_owed_per_player),
                fn name -> String.contains?(name, counter_party_name) end
              )

            case matches do
              [] ->
                IO.puts("Missing player: " <> counter_party_name)
                acc

              [name] ->
                Map.update(acc, name, -1, fn existing_value -> existing_value - amount end)

              [_head | _tail] ->
                IO.puts("Duplicate player name: " <> counter_party_name)
                acc
            end
          end)

        IO.inspect(actual_owed_per_player)
        laggards = Enum.filter(actual_owed_per_player, fn {_name, amount} -> amount > 100 end)

        IO.inspect(laggards)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:ok, %HTTPoison.Response{status_code: 401}} ->
        IO.puts("Request to Monzo is Forbidden, most likely token has expired")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end
end
