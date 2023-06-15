defmodule PentoWeb.WrongLive do
    use PentoWeb, :live_view

    def mount(_params, session, socket) do
        {
        :ok,
        assign(
        socket,
        score: 0,
        message: "Guess a number.",
        session_id: session["live_socket_id"]
        )
        }
    end

    @spec render(any) :: Phoenix.LiveView.Rendered.t()
    def render(assigns) do
        ~H"""
        <h1>Your score: <%= @score %></h1>
        <h2>
        <%= @message %>
        </h2>
        <h2>
        <%= for n <- 1..10 do %>
        <.link href="#" phx-click="guess" phx-value-number= {n} >
        <%= n %>
        </.link>
        <% end %>
        <pre>
        <%= @current_user.email %>
        <%= @session_id %>
        </pre>
        </h2>
        """
    end

    def time() do
        DateTime.utc_now |> to_string
    end

    def handle_event("guess", %{"number" => guess}, socket) do
        message = "Your guess: #{guess}. Wrong. Guess again. "
        score = socket.assigns.score - 1
        time = time()
        {
        :noreply,
        assign(
        socket,
        message: message,
        score: score,
        time: time)}
    end
end