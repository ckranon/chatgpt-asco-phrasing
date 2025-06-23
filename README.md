# Emotion Encoding with OpenAI GPT-4o-mini

This project uses the OpenAI GPT-4o-mini model to encode the emotion of **'disgust' (asco)** from textual data. It processes a CSV file containing text snippets, sends them to the OpenAI API for scoring and reasoning, and then saves the results to a new CSV file.

## Why is this Useful?

In research, particularly in fields like social sciences, psychology, or digital humanities, analyzing large volumes of text for emotional content can be incredibly time-consuming and prone to human bias. This program offers an **automated, scalable, and consistent method** for:

  * **Efficient Emotion Detection:** Quickly process thousands or millions of text entries to identify the degree of 'disgust' present.
  * **Reduced Manual Effort:** Automate a task that would otherwise require significant human labor.
  * **Standardized Scoring:** Leverage a powerful AI model to apply a consistent scoring rubric (1-5 scale) across all texts, minimizing inter-rater variability.
  * **Contextual Reasoning:** Get a brief explanation (reasoning) for each score. This provides valuable insights into why the AI assigned a particular rating, which can help with qualitative analysis and model interpretation.
  * **Scalability:** Easily scale up the analysis to very large datasets, which is often unfeasible with manual methods.

This automation allows researchers to focus on higher-level analysis and interpretation of results, rather than the tedious task of manual content coding.

-----

## Prerequisites

Before you start, make sure you have:

1.  **Docker installed** on your Mac.
2.  An **OpenAI API Key**.

-----

## Step-by-Step Guide

### 1\. Clone the Repository

First, you'll need to clone this GitHub repository to your local machine. Open your Terminal and run:

```bash
git clone https://github.com/ckranon/chatgpt-asco-phrasing.git
cd chatgpt-asco-phrasing
```

### 2\. Install Docker on macOS

1.  Go to the official Docker Desktop download page for macOS: [https://docs.docker.com/desktop/install/mac-install/](https://docs.docker.com/desktop/install/mac-install/)
2.  Download the **Docker Desktop `.dmg` file**.
3.  **Drag the Docker icon** to your Applications folder.
4.  **Launch Docker Desktop** from your Applications folder. You might need to grant it necessary permissions.

-----

### 3\. Set Up Your Project

1.  **Place Your Data:**

      * Place your input CSV file, named **`gptraw.csv`**, directly into the cloned `chatgpt-asco-phrasing` directory.
      * Ensure `gptraw.csv` has at least two columns: the first column should be `id`, and the fourth column should be `text`. The R script expects this specific structure.

2.  **OpenAI API Key:** You'll need to set your OpenAI API key as an environment variable.

      * **Recommended:** Create a **`.env` file** in the `chatgpt-asco-phrasing` directory (the same one containing `docker-compose.yml` and `app.R`).
        ```
        OPENAI_API_KEY="your_openai_api_key_here"
        ```
        **Replace** `"your_openai_api_key_here"` with your actual OpenAI API key.

-----

### 4\. Build and Run the Docker Container

1.  **Open your Terminal:** Make sure you are in the `chatgpt-asco-phrasing` directory (you should be if you followed step 1).

2.  **Build the Docker Image:** This command will build the Docker image based on the `Dockerfile`. This might take a few minutes the first time, as it downloads the R base image and installs necessary R packages.

    ```bash
    docker-compose build
    ```

3.  **Run the Docker Container:** This command will start the container and execute your R script. The `OPENAI_API_KEY` will be automatically picked up from your `.env` file by `docker-compose`.

    ```bash
    docker-compose up -d
    ```

    You'll see output in your terminal as the R script processes each row of your `gptraw.csv` file and interacts with the OpenAI API.

4.  **Monitor Progress:** The script will print messages like "Processing ID: X, Emotion: asco" to show its progress.

5.  **Output File:** Once the script completes, a new CSV file named **`output.csv`** will be created in your `chatgpt-asco-phrasing` directory. This file will contain the original `id` and `text`, along with the `output` score (1-5 or NA) and the `reasoning` provided by GPT.

Run this code snippet to get the final output.

    ```bash
    docker cp asco-encoding-app:/home/app/output.csv .
    ```
-----

```bash
.
├── app.R
├── docker-compose.yml
├── dockerfile
├── gptraw.csv
├── README.md
└── trials
    ├── first-output.csv
    └── second-output.csv

```

Files for rebuild
