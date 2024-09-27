# Use a minimal Python image
FROM python:3.10-slim

# Set up working directory
WORKDIR /app

# Copy the entire project into the container
COPY . .

# Install dependencies via apt and pip
RUN apt-get update && apt-get install -y \
    libusb-1.0-0-dev \
    kmod \  # Install kmod to provide modprobe functionality
    python3-usb \
    python3-pil \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install pyhidapi pyusb pillow

# Commented out entrypoint for manual operation
# ENTRYPOINT ["python", "led-badge-11x44.py"]

# Default command
CMD ["/bin/bash"]
