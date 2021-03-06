defmodule MemoGenerator do
  @moduledoc """
  MemoGenerator - An Elixir application that generates a memo in markdown format based on your team's trello boards
  """

  require Logger

  @api_key Application.get_env(:memo_generator, :api_key)
  @api_token Application.get_env(:memo_generator, :api_token)

  @expected_board_fields ~w(name shortUrl memberships dateLastActivity id)
  @expected_list_fields ~w(name id)
  @expected_card_fields ~w(dateLastActivity desc name shortUrl id)

  @doc """
  Function to generate memo for all boards on a trello workspace (without logo or splash)
  """
  def go(:all, filename, title) do
    {:ok, file} = File.open(filename, [:write])

    file
    |> write("# " <> title)
    |> add_date

    for board <- get_boards() do
      board
      |> write_board_header(file)
      |> get_lists
      |> process_and_write_lists(file)

      Logger.info("Rendered all cards and lists for board: " <> board["name"])
    end

    Logger.info("Finished rendering: " <> title <> ", into file: " <> filename)

    :ok
  end

  @doc """
  Function to generate memo for all boards in the list (without logo or splash)
  """
  def go(board_list, filename, title) when is_list(board_list) do
    {:ok, file} = File.open(filename, [:write])

    file
    |> write("# " <> title)
    |> add_date

    for board <- get_boards(board_list) do
      board
      |> write_board_header(file)
      |> get_lists
      |> process_and_write_lists(file)

      Logger.info("Rendered all cards and lists for board: " <> board["name"])
    end

    Logger.info("Finished rendering: " <> title <> ", into file: " <> filename)

    :ok
  end

  @doc """
  Function to generate memo for all boards on a trello workspace
  """
  def go(:all, filename, title, %{logo: logo, splash: splash}) do
    {:ok, file} = File.open(filename, [:write])

    file
    |> draw_logo(logo)
    |> write("# " <> title)
    |> add_date
    |> add_splash(splash)

    for board <- get_boards() do
      board
      |> write_board_header(file)
      |> get_lists
      |> process_and_write_lists(file)

      Logger.info("Rendered all cards and lists for board: " <> board["name"])
    end

    Logger.info("Finished rendering: " <> title <> ", into file: " <> filename)

    :ok
  end

  @doc """
  Function to generate memo for all boards on a trello workspace (without logo)
  """
  def go(:all, filename, title, %{splash: splash}) do
    {:ok, file} = File.open(filename, [:write])

    file
    |> write("# " <> title)
    |> add_date
    |> add_splash(splash)

    for board <- get_boards() do
      board
      |> write_board_header(file)
      |> get_lists
      |> process_and_write_lists(file)

      Logger.info("Rendered all cards and lists for board: " <> board["name"])
    end

    Logger.info("Finished rendering: " <> title <> ", into file: " <> filename)

    :ok
  end

  @doc """
  Function to generate memo for all boards on a trello workspace (without splash)
  """
  def go(:all, filename, title, %{logo: logo}) do
    {:ok, file} = File.open(filename, [:write])

    file
    |> draw_logo(logo)
    |> write("# " <> title)
    |> add_date

    for board <- get_boards() do
      board
      |> write_board_header(file)
      |> get_lists
      |> process_and_write_lists(file)

      Logger.info("Rendered all cards and lists for board: " <> board["name"])
    end

    Logger.info("Finished rendering: " <> title <> ", into file: " <> filename)

    :ok
  end

  @doc """
  Function to generate memo for all boards in the list
  """
  def go(board_list, filename, title, %{logo: logo, splash: splash}) when is_list(board_list) do
    {:ok, file} = File.open(filename, [:write])

    file
    |> draw_logo(logo)
    |> write("# " <> title)
    |> add_date
    |> add_splash(splash)

    for board <- get_boards(board_list) do
      board
      |> write_board_header(file)
      |> get_lists
      |> process_and_write_lists(file)

      Logger.info("Rendered all cards and lists for board: " <> board["name"])
    end

    Logger.info("Finished rendering: " <> title <> ", into file: " <> filename)

    :ok
  end

  @doc """
  Function to generate memo for all boards in the list (without splash)
  """
  def go(board_list, filename, title, %{logo: logo}) when is_list(board_list) do
    {:ok, file} = File.open(filename, [:write])

    file
    |> draw_logo(logo)
    |> write("# " <> title)
    |> add_date

    for board <- get_boards(board_list) do
      board
      |> write_board_header(file)
      |> get_lists
      |> process_and_write_lists(file)

      Logger.info("Rendered all cards and lists for board: " <> board["name"])
    end

    Logger.info("Finished rendering: " <> title <> ", into file: " <> filename)

    :ok
  end

  @doc """
  Function to generate memo for all boards in the list (without logo)
  """
  def go(board_list, filename, title, %{splash: splash}) when is_list(board_list) do
    {:ok, file} = File.open(filename, [:write])

    file
    |> write("# " <> title)
    |> add_date
    |> add_splash(splash)

    for board <- get_boards(board_list) do
      board
      |> write_board_header(file)
      |> get_lists
      |> process_and_write_lists(file)

      Logger.info("Rendered all cards and lists for board: " <> board["name"])
    end

    Logger.info("Finished rendering: " <> title <> ", into file: " <> filename)

    :ok
  end

  @doc """
  Error case
  """
  def go(_board_list, _filename, _title, _config),
    do: :error

  @doc """
  Function to delete a rendered memo
  """
  def delete(filename) do
    case File.rm(filename) do
      :ok ->
        Logger.info("Succesfully deleted file: " <> filename)
        :ok

      _ ->
        Logger.error("Could not delete file: " <> filename)
        :error
    end
  end

  @doc """
  Function to return all boards that belong to a workspace
  """
  def get_boards do
    resp =
      HTTPoison.get!(
        "https://api.trello.com/1/members/me/boards?key=#{@api_key}&token=#{@api_token}"
      )

    resp.body
    |> Poison.decode!()
    |> Enum.reduce([], fn board, acc -> acc ++ [Map.take(board, @expected_board_fields)] end)
  end

  @doc """
  Function to return desired boards
  """
  def get_boards(board_list) when is_list(board_list) do
    resp =
      HTTPoison.get!(
        "https://api.trello.com/1/members/me/boards?key=#{@api_key}&token=#{@api_token}"
      )

    resp.body
    |> Poison.decode!()
    |> Enum.filter(fn board -> Enum.member?(board_list, board["name"]) end)
    |> Enum.reduce([], fn board, acc -> acc ++ [Map.take(board, @expected_board_fields)] end)
  end

  @doc """
  Function to return all boards that belong to a workspace
  """
  def get_all_board_names do
    resp =
      HTTPoison.get!(
        "https://api.trello.com/1/members/me/boards?key=#{@api_key}&token=#{@api_token}"
      )

    resp.body
    |> Poison.decode!()
    |> Enum.reduce([], fn board, acc -> acc ++ [board["name"]] end)
  end

  defp get_lists(board) do
    resp =
      HTTPoison.get!(
        "https://api.trello.com/1/boards/#{board["id"]}/lists?key=#{@api_key}&token=#{@api_token}"
      )

    resp.body
    |> Poison.decode!()
    |> Enum.reduce([], fn list, acc -> acc ++ [Map.take(list, @expected_list_fields)] end)
  end

  defp get_cards(list) do
    resp =
      HTTPoison.get!(
        "https://api.trello.com/1/lists/#{list["id"]}/cards?key=#{@api_key}&token=#{@api_token}"
      )

    resp.body
    |> Poison.decode!()
    |> Enum.reduce([], fn list, acc -> acc ++ [Map.take(list, @expected_card_fields)] end)
  end

  defp process_and_write_lists(lists, file) do
    if lists == [] do
      IO.write(file, "> **No _lists_ were found for this board**\n\n")
      IO.write(file, "<br>")
    else
      for list <- lists do
        list
        |> write_list_header(file)
        |> get_cards
        |> process_and_write_cards(file)

        Logger.info("Rendered all cards for list: " <> list["name"])
      end
    end
  end

  defp process_and_write_cards(cards, file) do
    if cards == [] do
      IO.write(file, "> **No _cards_ were found**\n\n")
    else
      for card <- cards do
        card
        |> write_card_info(file)
      end
    end

    IO.write(file, "<br>\n\n")

    :ok
  end

  defp write_board_header(board, file) do
    IO.write(file, "## Board: [#{board["name"]}](#{board["shortUrl"]})\n\n")
    board
  end

  defp write_list_header(list, file) do
    IO.write(file, "### Section: " <> list["name"] <> "\n\n")
    list
  end

  defp write_card_info(card, file) do
    IO.write(file, "--- \n\n")
    IO.write(file, "#### Task: [#{card["name"]}](#{card["shortUrl"]}) \n\n")

    if card["desc"] == "" do
      IO.write(file, "> _No details have been given about this task_\n\n")
    else
      IO.write(file, "> " <> card["desc"] <> "\n\n\n\n")
    end

    IO.write(
      file,
      "##### **Last Updated: _#{String.slice(card["dateLastActivity"], 0, 10)}_** \n\n"
    )

    card
  end

  defp draw_logo(file, logo) do
    Logger.info("Rendered logo")

    IO.write(
      file,
      "<img src=\"#{logo}\" alt=\"drawing\" width=\"100\" height=\"100\" align=\"left\" />\n\n"
    )

    file
  end

  defp add_date(file) do
    {{year, month, day}, _hms} = :calendar.local_time()

    IO.write(file, "   [#{year}-#{month}-#{day}]\n\n")

    file
  end

  defp add_splash(file, splash) do
    Logger.info("Rendered splash")

    IO.write(file, splash <> "\n\n <br> \n\n")
    IO.write(file, "\n\n <br> \n\n")
    file
  end

  defp write(file, text) do
    IO.write(file, text)
    file
  end
end
