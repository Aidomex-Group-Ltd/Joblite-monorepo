root = Path.expand("..", __DIR__)
frontend = Path.expand("../frontend", root)
backend_files = Path.wildcard(Path.join(root, "lib/**/*.ex"))
frontend_files = Path.wildcard(Path.join(frontend, "lib/**/*.ex"))

violations =
  Enum.flat_map(backend_files, fn path ->
    if Regex.match?(
         ~r/\b(?:Phoenix\.(?!PubSub\b)|(?:use|import|alias)\s+Phoenix\b|Plug\.Conn|JobliteWeb\b)/,
         File.read!(path)
       ), do: ["UI dependency in backend: #{path}"], else: []
  end) ++
    Enum.flat_map(frontend_files, fn path ->
      if Regex.match?(
           ~r/\bJoblite\.Repo\b|\bEcto\.Query\b|\bfrom\s+\w+\s+in\b/,
           File.read!(path)
         ), do: ["Persistence access in frontend: #{path}"], else: []
    end)

source_files =
  backend_files ++
    frontend_files ++
    Path.wildcard(Path.join(frontend, "lib/**/*.heex"))

oversized =
  Enum.flat_map(source_files, fn path ->
    count = path |> File.stream!() |> Enum.count()
    if count > 250, do: IO.puts(:stderr, "Review #{count}-line file: #{path}")
    if count > 400, do: ["File exceeds 400 lines: #{path}"], else: []
  end)

case violations ++ oversized do
  [] ->
    IO.puts("Architecture smoke checks passed; this is not a compiler or security audit.")

  errors ->
    Enum.each(errors, &IO.puts(:stderr, &1))
    System.halt(1)
end
