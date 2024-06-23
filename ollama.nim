import httpclient, json, strutils

type
  OllamaClientObj* = object
    client*: HttpClient
    baseUrl*: string
  OllamaClient* = ref OllamaClientObj

proc `=destroy`*(o: OllamaClientObj) =
  o.client.close()
  `=destroy`(o.client)
  `=destroy`(o.baseUrl)

proc newOllamaClient*(baseUrl = "http://localhost:11434"): OllamaClient =
  result.baseUrl = baseUrl
  result.client = newHttpClient()

proc makeRequest(cl: OllamaClient, endpoint: string, mthd: HttpMethod, body: JsonNode = nil): JsonNode =
  let response = cl.client.request(cl.baseUrl & endpoint, mthd, $body, newHttpHeaders())
  if response.status != $Http200:
    raise newException(ValueError, "Request failed: " & $response.status & " - " & response.body)
  result = parseJson(response.body)

proc generateCompletion*(client: OllamaClient, model: string, prompt: string, stream: bool = false): JsonNode =
  let body = %* {
    "model": model,
    "prompt": prompt,
    "stream": stream
  }
  result = client.makeRequest("/api/generate", HttpPost, body)

proc generateChat*(client: OllamaClient, model: string, messages: seq[JsonNode], stream: bool = true): JsonNode =
  let body = %* {
    "model": model,
    "messages": messages,
    "stream": stream
  }
  result = client.makeRequest("/api/chat", HttpPost, body)

proc createModel*(client: OllamaClient, name: string, modelfile: string): JsonNode =
  let body = %* {
    "name": name,
    "modelfile": modelfile
  }
  result = client.makeRequest("/api/create", HttpPost, body)

proc listLocalModels*(client: OllamaClient): JsonNode =
  result = client.makeRequest("/api/tags", HttpGet)

proc showModelInfo*(client: OllamaClient, name: string): JsonNode =
  let body = %* {
    "name": name
  }
  result = client.makeRequest("/api/show", HttpPost, body)

proc copyModel*(client: OllamaClient, source: string, destination: string): JsonNode =
  let body = %* {
    "source": source,
    "destination": destination
  }
  result = client.makeRequest("/api/copy", HttpPost, body)

proc deleteModel*(client: OllamaClient, name: string): JsonNode =
  let body = %* {
    "name": name
  }
  result = client.makeRequest("/api/delete", HttpDelete, body)

proc pullModel*(client: OllamaClient, name: string): JsonNode =
  let body = %* {
    "name": name
  }
  result = client.makeRequest("/api/pull", HttpPost, body)

proc pushModel*(client: OllamaClient, name: string): JsonNode =
  let body = %* {
    "name": name
  }
  result = client.makeRequest("/api/push", HttpPost, body)

proc generateEmbeddings*(client: OllamaClient, model: string, prompt: string): JsonNode =
  let body = %* {
    "model": model,
    "prompt": prompt
  }
  result = client.makeRequest("/api/embeddings", HttpPost, body)

proc listRunningModels*(client: OllamaClient): JsonNode =
  result = client.makeRequest("/api/ps", HttpGet)

# Example usage:
when isMainModule:
  let client = newOllamaClient()
  let response = generateCompletion(client, "llama3", "Why is the sky blue?")
  echo response.pretty
