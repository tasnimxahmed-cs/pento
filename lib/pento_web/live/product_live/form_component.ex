defmodule PentoWeb.ProductLive.FormComponent do
  use PentoWeb, :live_component

  alias Pento.Catalog

  @impl true
  def render(assigns) do
    # :timer.sleep(5000)
    #IO.puts "ENTRIES:::"
    #IO.inspect(assigns.uploads.image.entries)
    ~H"""
    <div>
        <.header>
        <%= @title %>
        <:subtitle>
          Use this form to manage product records in your database.
        </:subtitle>
      </.header>

        <.simple_form
          :let={f}
          for={@changeset}
          id="product-form"
          multipart
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
        <.input field={f[:name]}
          type="text" label="Name" />
        <.input field={f[:description]}
          type="text" label="Description" />
        <.input field={f[:unit_price]}
          type="number" label="Unit price" step="any" />
        <.input field={f[:sku]}
          type="number" label="Sku" />
        <div phx-drop-target={ @uploads.image.ref }>
          <.label>Image</.label>
            <.live_file_input upload={@uploads.image} />
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Product</.button>
        </:actions>
      </.simple_form>
      <%= for image <- @uploads.image.entries do %>
        <div class="mt-4">
          <.live_img_preview entry={image} width="60" />
        </div>
        <progress value={image.progress} max="100" />
        <%= for err <- upload_errors(@uploads.image, image) do %>
          <.error><%= err %></.error>
        <% end %>
      <% end %>
    </div>

    """
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    changeset = Catalog.change_product(product)
    {:ok, socket
      |> assign(assigns)
      |> assign(:changeset, changeset)
      |> allow_upload(:image,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 9_000_000,
        auto_upload: true
      )}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> Catalog.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, params) do
    product_params = params_with_image(socket, params)

    case Catalog.update_product(socket.assigns.product, product_params) do
      {:ok, _product} ->
        if(Map.has_key?(socket.assigns, :patch)) do
          {:noreply,
            socket
            |> put_flash(:info, "Product updated successfully")
            |> push_patch(to: socket.assigns.patch)}
        else
          {:noreply,
            socket
            |> put_flash(:info, "Product updated successfully")
            |> push_navigate(to: socket.assigns.navigate)}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_product(socket, :new, params) do
    product_params = params_with_image(socket, params)

    case Catalog.create_product( product_params) do
      {:ok, _product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp upload_static_file(%{path: path}, _entry) do
    # Plug in your production image file persistence implementation here!
    filename = Path.basename(path)
    dest = Path.join("priv/static/images", filename)
    File.cp!(path, dest)

    {:ok, ~p"/images/#{filename}"}
  end

  def upload_image_error(%{image: %{errors: errors}}, entry) when length(errors) > 0 do
    {_, msg} =
      Enum.find(errors, fn {ref, _} ->
        ref == entry.ref || ref == entry.upload_ref
      end)

    upload_error_msg(msg)
  end

  def upload_image_error(_, _), do: ""

  defp upload_error_msg(:not_accepted) do
    "Invalid file type"
  end

  defp upload_error_msg(:too_many_files) do
    "Too many files"
  end

  defp upload_error_msg(:too_large) do
    "File exceeds max size"
  end

  def params_with_image(socket, params) do
    path =
      socket
      |> consume_uploaded_entries(:image, &upload_static_file/2)
      |> List.first

    Map.put(params, "image_upload", path)
  end
end
