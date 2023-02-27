function Get-OpenAIAvailableModels {
  param(
  # API key
  [string] $ApiKey
  )  
   # Set the headers with your API key
  $headers = @{
    "Authorization" = "Bearer $ApiKey"
    "Content-Type" = "application/json"
  }
  
  $obj = Invoke-RestMethod -Uri https://api.openai.com/v1/models -Method Get -Headers $headers
  return $obj.data
}

function Query-OpenAIPromptResponse {

param(
  # the query to be sent to chatGPT/model
  [string] $Prompt, 
  
  # API key
  [string] $ApiKey,
  
  # Model that you want to select
  # See https://platform.openai.com/docs/models/gpt-3
  [string] $Model = "text-davinci-003",
  
  # Temperature to be passed to the mode.ll
  $Temperature = 0.9 
  ) 

  # Set the headers with your API key
  $headers = @{
    "Authorization" = "Bearer $ApiKey"
    "Content-Type" = "application/json"
  }
  
  # Set the body with your query and other options
  $body = @{
    "model" = $Model
    "prompt" = $Prompt
    "temperature" = $Temperature 
    "stop" = "\n\n" # Stops generating when reaching this token
  } | ConvertTo-Json

  # Invoke the REST method with POST method and return response
  $obj = Invoke-RestMethod -Uri https://api.openai.com/v1/completions -Method Post -Headers $headers -Body $body
  return $obj.choices.text
}
