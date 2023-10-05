# base image
FROM python:3.10

# Set the working directory in the container to /app
WORKDIR /app

# install packages
RUN apt-get update \
    && apt-get upgrade -y

# upgrade pip and install python packages
RUN /usr/local/bin/python -m pip install --upgrade pip \
    && apt-get install -y \
    software-properties-common \
    libgl1-mesa-glx \
    libglib2.0-0

RUN pip install opensoundscape \
    && rm -rf /root/.cache/pip/

# Copy the script into the container at /app
COPY localize_event.py .

# Define environment variable to ensure Python doesn't output bytecode
ENV PYTHONDONTWRITEBYTECODE 1

# Command to run the script
CMD ["python", "./localize_event.py"]
