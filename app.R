library(httr)
library(stringr)
library(dplyr)
library(jsonlite) # For parsing JSON responses from the API

# Read the data and rename columns
# IMPORTANT CHANGE: Read 'id' as character to prevent type mismatch with results_df
data <- read.csv("gptraw.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)
data <- data[c(1, 4)] # Select columns 1 and 4
colnames(data) <- c('id', 'text')

# Ensure 'id' column is explicitly character type after reading
data$id <- as.character(data$id)

# Get OpenAI API Key from environment variables
OPENAI_API_KEY <- Sys.getenv("OPENAI_API_KEY")

# Ensure the API key is available
if (OPENAI_API_KEY == "") {
  stop("OPENAI_API_KEY environment variable not set. Please set it before running the script.")
}

# hey_chatGPT function (modified to return a list with output and reasoning)
hey_chatGPT <- function(question_for_gpt) {
  chat_GPT_answer <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    add_headers(Authorization = paste("Bearer", OPENAI_API_KEY)),
    content_type_json(),
    encode = "json",
    body = list(
      model = "o4-mini-2025-04-16", # Changed model to gpt-4o-mini (or gpt-4o)
      # temperature = 0, <- Not supported!
      # CRUCIAL: Request JSON response format
      response_format = list(type = "json_object"),
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
    return(list(output = NA_character_, reasoning = NA_character_)) # Return NAs for both
  }

  # Parse the JSON response
  response_list <- tryCatch({
    fromJSON(content(chat_GPT_answer, "text", encoding = "UTF-8"))
  }, error = function(e) {
    warning(paste("Failed to parse JSON response:", e$message))
    return(NULL)
  })

  if (is.null(response_list) || is.null(response_list$choices) || length(response_list$choices) == 0) {
    return(list(output = NA_character_, reasoning = NA_character_))
  }

  # The message content should now be a JSON string that we need to parse again
  message_content_json_str <- response_list$choices$message$content

  parsed_response <- tryCatch({
    fromJSON(message_content_json_str)
  }, error = function(e) {
    warning(paste("Failed to parse inner JSON content:", e$message, "Raw content:", message_content_json_str))
    return(list(output = NA_character_, reasoning = NA_character_))
  })

  # Extract the specific fields (output and reasoning)
  # Ensure they exist before trying to access them
  output_val <- if (!is.null(parsed_response$output)) as.character(parsed_response$output) else NA_character_
  reasoning_val <- if (!is.null(parsed_response$reasoning)) as.character(parsed_response$reasoning) else NA_character_

  return(list(output = output_val, reasoning = reasoning_val))
}


# Our focus right now is investigating ASCO.
prompts <- list(
  asco = paste0(
    "Responde a la siguiente pregunta en formato JSON, con dos claves: 'output' para la puntuación numérica ",
    "y 'reasoning' para una breve explicación. ",
    "¿En qué medida esta respuesta demuestra asco, en una escala 1-5? Responde sólo con un número: ",
    "cada punto significa algo; 1 siendo 'muy poco o ningún asco', 2 siendo 'un poco de asco', ",
    "3 siendo 'algo de asco', 4 siendo 'bastante asco', y 5 siendo 'mucho asco'. ",
    "Simplemente muestra el número, no especifiques entre paréntesis. ",
    "Haz tu mejor esfuerzo para asignar una puntuación del 1 al 5, incluso si el texto no es claro o muy breve. ",
    "Si no hay cita, no existe, o está vacía, la clave 'output' debe ser exactamente: NA. ",
    "La clave 'reasoning' debe ser una explicación concisa de tu puntuación. ",
    "Aquí está la cita:"
  )
)


# Initialize an empty data frame to store results
results_df <- data.frame(
  id = character(),
  text = character(),
  output = character(),   # To store the score (e.g., "3", "NA")
  reasoning = character(), # To store the reasoning text
  stringsAsFactors = FALSE
)

# Loop over each row of original data
for (i in 1:nrow(data)) {
  current_text <- data[i, "text"]
  current_id <- data[i, "id"]

  for (emotion in names(prompts)) {
    full_prompt <- paste(prompts[[emotion]], current_text)

    cat(paste0("Processing ID: ", current_id, ", Emotion: ", emotion, "\n"))

    # hey_chatGPT now returns a list
    gpt_result <- hey_chatGPT(full_prompt)

    # Retry mechanism for empty or NULL responses (checking both output and reasoning)
    retry_count <- 0
    max_retries <- 3
    while (((is.null(gpt_result$output) || is.na(gpt_result$output) || nchar(gpt_result$output) == 0) &&
            (is.null(gpt_result$reasoning) || is.na(gpt_result$reasoning) || nchar(gpt_result$reasoning) == 0)) &&
           retry_count < max_retries) {
      retry_count <- retry_count + 1
      Sys.sleep(1)
      cat(paste0("  Retrying for ID: ", current_id, ", Emotion: ", emotion, " (Attempt ", retry_count, ")\n"))
      gpt_result <- hey_chatGPT(full_prompt)
    }

    # Assign NA if still no valid response after retries
    if ((is.null(gpt_result$output) || is.na(gpt_result$output) || nchar(gpt_result$output) == 0) &&
        (is.null(gpt_result$reasoning) || is.na(gpt_result$reasoning) || nchar(gpt_result$reasoning) == 0)) {
      warning(paste("Failed to get valid GPT response (output and reasoning) after retries for ID:", current_id, ", Emotion:", emotion))
      gpt_output <- NA_character_
      gpt_reasoning <- NA_character_
    } else {
      gpt_output <- gpt_result$output
      gpt_reasoning <- gpt_result$reasoning
    }

    # Create a new row for the results_df
    new_row <- data.frame(
      id = current_id,
      text = current_text,
      output = gpt_output,
      reasoning = gpt_reasoning,
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