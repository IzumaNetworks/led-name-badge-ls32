# Define variables
IMAGE_NAME=izumanetworks/led-name-badge
VERSION=latest
BUILDER_NAME=mybuilder
OUTPUT_DIR=output
REMOTE_DIR=/root/led

# Ensure prerequisites are met
.PHONY: preqs
preqs:
	set -e
	# Check if buildx is available, if not, install it
	@if ! docker buildx version > /dev/null 2>&1; then \
		echo "Docker Buildx not found. Please ensure Docker Buildx is installed."; \
		exit 1; \
	fi
	# Create the builder if it doesn't exist
	@if ! docker buildx inspect $(BUILDER_NAME) > /dev/null 2>&1; then \
		docker buildx create --name $(BUILDER_NAME) --use; \
		docker buildx inspect --bootstrap; \
	fi
	# Ensure we're using the right builder
	@docker buildx use $(BUILDER_NAME)
	@echo "Ready to 'make build'"

# Build images for Linux platforms only
.PHONY: build
build: preqs output
	docker buildx build --builder $(BUILDER_NAME) --platform linux/amd64 -t $(IMAGE_NAME):$(VERSION)-amd64 --load .
	docker buildx build --builder $(BUILDER_NAME) --platform linux/arm64 -t $(IMAGE_NAME):$(VERSION)-arm64 --load .
	mkdir -p $(OUTPUT_DIR)
	docker save -o $(OUTPUT_DIR)/led-name-badge-amd64.tar $(IMAGE_NAME):$(VERSION)-amd64
	docker save -o $(OUTPUT_DIR)/led-name-badge-arm64.tar $(IMAGE_NAME):$(VERSION)-arm64
	@echo "Images saved to $(OUTPUT_DIR)/"

# SSH and SCP the tar files to the remote machine
.PHONY: scp
scp: 
	@read -p "Enter the SSH destination (e.g., user@hostname): " REMOTE; \
	ARCH=$$(ssh $$REMOTE 'uname -m'); \
	echo "Remote architecture is $$ARCH"; \
	if [ "$$ARCH" = "x86_64" ]; then \
		echo "Sending amd64 image"; \
		ssh $$REMOTE 'mkdir -p $(REMOTE_DIR)'; \
		scp $(OUTPUT_DIR)/led-name-badge-amd64.tar $$REMOTE:$(REMOTE_DIR)/; \
		ssh $$REMOTE 'docker load -i $(REMOTE_DIR)/led-name-badge-amd64.tar'; \
	elif [ "$$ARCH" = "aarch64" ]; then \
		echo "Sending arm64 image"; \
		ssh $$REMOTE 'mkdir -p $(REMOTE_DIR)'; \
		scp $(OUTPUT_DIR)/led-name-badge-arm64.tar $$REMOTE:$(REMOTE_DIR)/; \
		ssh $$REMOTE 'docker load -i $(REMOTE_DIR)/led-name-badge-arm64.tar'; \
	else \
		echo "Unsupported architecture: $$ARCH"; \
		exit 1; \
	fi;
	@echo "Image has been transferred and loaded on the remote machine."

# Clean up
.PHONY: clean
clean:
	set -e
	-docker buildx rm $(BUILDER_NAME) || true
	-docker rmi $(IMAGE_NAME):$(VERSION)-amd64 || true
	-docker rmi $(IMAGE_NAME):$(VERSION)-arm64 || true
	rm -rf $(OUTPUT_DIR)
