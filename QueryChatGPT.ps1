function Query-ChatGPT {

param(
  # the query to be sent to chatGPT
  [string] $Query, 
  
  # API key
  [string] $ApiKey,
  
  # Model that you want to select
  [string] $Model = "chatGPT",
  
  # Temperature to be passed to the mode.ll
  $Temperature = 0.9 
  )

 

  # Set the headers with your API key
  $headers = @{
    "Authorization" = $ApiKey
    "Content-Type" = "application/json"
  }
  
  # Set the body with your query and other options
  $body = @{
    "model" = $Model
    "query" = $Query
    "temperature" = $Temperature 
    "frequency_penalty" = 0.5 # Penalizes new tokens based on frequency
    "presence_penalty" = 0.6 # Penalizes new tokens based on presence
    "stop" = "\n\n" # Stops generating when reaching this token
  } | ConvertTo-Json

  # Invoke the REST method with POST method and return response
  Invoke-RestMethod -Uri https://api.openai.com/v1/engines/chatgpt/completions -Method Post -Headers $headers -Body $body

}
