defmodule AppBootstrap do
  @switches [
    strict: [app: :string, env: :string, out: :string],
    aliases: [a: :app, e: :env, o: :out]
  ]

  @spec main(OptionParser.argv) :: no_return
  def main(argv) do
    with {:ok, parsed} <- parse_args(argv),
         {:ok, app_env} <- read_app_env(parsed[:app] || "./app.json"),
         {:ok, local_env} <- read_local_env(parsed[:env] || "./.env"),
         new_dotenv = merge_env(local_env, app_env) |> format_dotenv,
         :ok <- File.write(parsed[:out], new_dotenv) do
      IO.puts "New env written to #{parsed[:out]}"
      exit(:normal)
    else
      error ->
        exit(error)
    end
  end

  @spec parse_args(OptionParser.argv) :: {:ok, OptionParser.parsed}
                                       | {:error, String.t}
  defp parse_args(argv) do
    case OptionParser.parse(argv, @switches) do
      {parsed, _, []} -> {:ok, parsed}
      _ -> {:error, "Invalid arguments passed"}
    end
  end

  @spec read_app_env(String.t) :: {:ok, map} | {:error, String.t}
  defp read_app_env(app_json_path) do
    with {:ok, json} <- File.read(app_json_path),
         {:ok, map} <- Poison.decode(json),
         env when is_map(env) <- Map.get(map, "env") do
      {:ok, env}
    else
      _ -> {:error, ~s(No "env" found in app.json)}
    end
  end

  @spec read_local_env(String.t) :: {:ok, map} | {:error, String.t}
  defp read_local_env(env_path) do
    env_string =
      case File.read(env_path) do
        {:ok, env_string} -> env_string
        {:error, _} -> ""
      end

    parse_dotenv(env_string)
  end

  @spec parse_dotenv(String.t) :: {:ok, map} | {:error, String.t}
  defp parse_dotenv(env_string) do
    env_string
    |> String.split("\n")
    |> Enum.reduce_while({:ok, %{}}, fn line, {:ok, dotenv} ->
      case line do
        "" ->
          {:cont, {:ok, dotenv}}
        _value_line ->
          case parse_line(line) do
            {:ok, {key, value}} ->
              {:cont, {:ok, Map.put(dotenv, key, value)}}
            error ->
              {:halt, error}
          end
      end
    end)
  end

  @spec parse_line(String.t) :: {:ok, {String.t, String.t}} | {:error, String.t}
  defp parse_line(line) do
    case String.split(line, "=", parts: 2) do
      [key, value] ->
        {:ok, {key, strip_quotes(value)}}
      line ->
        {:error, ~s(Could not parse dotenv line: #{line})}
    end
  end

  @spec strip_quotes(String.t) :: String.t
  defp strip_quotes(value) do
    if String.starts_with?(value, ~s(")) and String.ends_with?(value, ~s(")) do
      String.slice(value, 1..-2)
    else
      value
    end
  end

  @spec merge_env(map, map) :: map
  defp merge_env(local, app) do
    Enum.reduce(app, local, fn ({key, descriptor}, local) ->
      case Map.get(local, key) do
        value when not is_nil(value) ->
          local
        nil ->
          Map.put(local, key, get_value(key, descriptor))
      end
    end)
  end

  @spec get_value(String.t, map) :: String.t
  defp get_value(key, descriptor) do
    case descriptor do
      %{"development_value" => value} -> value
      %{"value" => value} -> value
      %{"development_required" => false} -> ""
      %{"required" => false} -> ""
      %{"description" => description} ->
        puts ~s(Provide a value for "#{key}":)
        puts ~s("#{description}")
        IO.gets("➜ ") |> String.trim_trailing
    end
  end

  @spec format_dotenv(map) :: String.t
  defp format_dotenv(dotenv) do
    Enum.reduce(dotenv, "", fn
      ({_, ""}, string) -> string
      ({key, value}, string) -> "#{string}#{key}=#{value}\n"
    end)
  end

  @spec puts(String.t) :: :ok
  defp puts(string), do: IO.puts :stderr, string
end
