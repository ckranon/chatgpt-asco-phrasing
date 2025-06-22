library(httr)
library(stringr)
library(dplyr)

# Read the data and rename columns
# IMPORTANT CHANGE: Read 'id' as character to prevent type mismatch with results_df
data <- read.csv("gptraw.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE) # Add stringsAsFactors=FALSE for older R versions
data <- data[c(1, 4)] # Select columns 1 and 4
colnames(data) <- c('id', 'text')

# Ensure 'id' column is explicitly character type after reading
# This is the most robust way to handle potential variations in gptraw.csv
data$id <- as.character(data$id)


# Get OpenAI API Key from environment variables
OPENAI_API_KEY <- Sys.getenv("OPENAI_API_KEY")

# Ensure the API key is available
if (OPENAI_API_KEY == "") {
  stop("OPENAI_API_KEY environment variable not set. Please set it before running the script.")
}

# hey_chatGPT function (modified to return raw content)
hey_chatGPT <- function(question_for_gpt) {
  chat_GPT_answer <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    add_headers(Authorization = paste("Bearer", OPENAI_API_KEY)),
    content_type_json(),
    encode = "json",
    body = list(
      model = "gpt-4o",
      temperature = 0,
      messages = list(
        list(
          role = "user",
          content = question_for_gpt
        )
      )
    )
  )

  # Check for HTTP errors
  if (http_error(chat_GPT_answer)) {
    warning(paste("HTTP error:", status_code(chat_GPT_answer), content(chat_GPT_answer, "text", encoding = "UTF-8")))
    return(NA_character_)
  }

  response_content <- content(chat_GPT_answer)$choices[[1]]$message$content

  if (is.null(response_content) || length(response_content) == 0) {
    return(NA_character_)
  }

  return(response_content)
}

# Our focus right now is investigating ASCO.
prompts <- list(
  asco = "¿En qué medida esta respuesta demuestra asco, en una escala 1-5? Responde sólo con un número: cada punto significa algo; 1 siendo 'muy poco o ningún asco', 2 siendo 'un poco de asco', 3 siendo 'algo de asco', 4 siendo 'bastante asco', y 5 siendo 'mucho asco'. Simplemente muestra el número, no especifiques entre paréntesis. Haz tu mejor esfuerzo para asignar una puntuación del 1 al 5, incluso si el texto no es claro o muy breve. Si no hay cita, no existe, o está vacía, responde exactamente con: NA — en mayúsculas, sin comillas, sin ningún otro texto, sin explicaciones ni disculpas, sin repetir nada, sin frases adicionales. Aquí está la cita:"
)

# Initialize an empty data frame to store results
results_df <- data.frame(
  id = character(), # Initialized as character
  text = character(),
  output = character(),
  stringsAsFactors = FALSE
)

# Loop over each row of original data
for (i in 1:nrow(data)) {
  current_text <- data[i, "text"]
  current_id <- data[i, "id"] # This is now guaranteed to be character

  for (emotion in names(prompts)) {
    full_prompt <- paste(prompts[[emotion]], current_text)

    cat(paste0("Processing ID: ", current_id, ", Emotion: ", emotion, "\n"))

    gpt_response <- hey_chatGPT(full_prompt)

    retry_count <- 0
    max_retries <- 3
    while ((is.null(gpt_response) || is.na(gpt_response) || nchar(gpt_response) == 0) && retry_count < max_retries) {
      retry_count <- retry_count + 1
      Sys.sleep(1)
      cat(paste0("  Retrying for ID: ", current_id, ", Emotion: ", emotion, " (Attempt ", retry_count, ")\n"))
      gpt_response <- hey_chatGPT(full_prompt)
    }

    if (is.null(gpt_response) || is.na(gpt_response) || nchar(gpt_response) == 0) {
      warning(paste("Failed to get a valid GPT response after retries for ID:", current_id, ", Emotion:", emotion))
      gpt_response <- NA_character_
    }

    # Create a new row for the results_df
    # The 'id' here is already a character from 'data$id'
    new_row <- data.frame(
      id = current_id,
      text = current_text,
      output = gpt_response,
      stringsAsFactors = FALSE
    )

    # Append the new row to the results data frame
    results_df <- bind_rows(results_df, new_row)
  }
}

# Display warnings if any occurred
warnings()

# Export the final CSV
write.csv(results_df, "output.csv", row.names = FALSE)

cat("\nProcessing complete. Results saved to 'output.csv'\n")