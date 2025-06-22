# Use an official R runtime as a parent image
FROM r-base:4.5.1

# System Dependencies:
# Install system libraries required by R packages.
# 'libcurl4-openssl-dev' is needed for 'curl' and 'httr'.
# 'libssl-dev' might also be needed directly by 'openssl' or its dependencies.
# 'libxml2-dev' is good practice for 'httr' and other web-related packages.
# 'gdebi-core' and 'libudunits2-dev' are common for other packages,
# but primarily focus on the -dev packages for networking.
# Make sure to clean up the apt cache to reduce image size.
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && \
    rm -rf /var/lib/apt/lists/*

# Install R packages required by your script.
# 'httr', 'stringr', and 'dplyr' are needed.
RUN Rscript -e "install.packages(c('httr', 'stringr', 'dplyr'), repos='https://cloud.r-project.org/')"

# Set the working directory inside the container
WORKDIR /home/app

# Copy the application files into the Docker image.
COPY . .

# Command to run your R script when the container starts.
# Replace 'your_script_name.R' with the actual name of your R script file.
CMD ["Rscript", "app.R"]