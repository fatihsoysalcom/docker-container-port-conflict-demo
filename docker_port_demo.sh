#!/bin/bash

# This script demonstrates basic Docker container management and port conflict resolution.

CONTAINER_NAME_1="my-nginx-app-1"
CONTAINER_NAME_2="my-nginx-app-2"
HOST_PORT_1=8080
HOST_PORT_2=8081
DOCKER_IMAGE="nginx:alpine"

# --- Helper Functions ---

# Check if Docker daemon is running
check_docker_status() {
    if ! docker info > /dev/null 2>&1; then
        echo "Error: Docker daemon is not running or not accessible."
        echo "Please start Docker and try again."
        exit 1
    fi
}

# Stop and remove a container if it exists
cleanup_container() {
    local name=$1
    echo "--- Cleaning up existing container: $name ---"
    docker stop "$name" > /dev/null 2>&1
    docker rm "$name" > /dev/null 2>&1
    echo "Cleaned up $name (if it existed)."
}

# --- Main Script ---

echo "--- Docker Container Management and Port Conflict Demo ---"
check_docker_status

# 1. Clean up any previous runs
cleanup_container "$CONTAINER_NAME_1"
cleanup_container "$CONTAINER_NAME_2"
echo ""

# 2. Run the first Nginx container
echo "--- Step 1: Running '$CONTAINER_NAME_1' on host port $HOST_PORT_1 ---"
# This command runs an Nginx container, mapping its internal port 80 to the host's $HOST_PORT_1.
docker run -d --name "$CONTAINER_NAME_1" -p "$HOST_PORT_1":80 "$DOCKER_IMAGE"
if [ $? -eq 0 ]; then
    echo "Container '$CONTAINER_NAME_1' started successfully."
else
    echo "Failed to start '$CONTAINER_NAME_1'."
    exit 1
fi
echo ""
sleep 2 # Give container a moment to start

# 3. Attempt to run a second container on the *same* host port to demonstrate conflict
echo "--- Step 2: Attempting to run '$CONTAINER_NAME_2' on the *same* host port $HOST_PORT_1 ---"
echo "This is expected to fail due to port conflict."
# Trying to map the same host port will result in an error, demonstrating a port conflict.
docker run -d --name "$CONTAINER_NAME_2" -p "$HOST_PORT_1":80 "$DOCKER_IMAGE"
if [ $? -ne 0 ]; then
    echo "SUCCESS: As expected, '$CONTAINER_NAME_2' failed to start due to port conflict on $HOST_PORT_1."
    echo "This illustrates the 'port çakışması' (port conflict) mentioned in the article."
else
    echo "UNEXPECTED: '$CONTAINER_NAME_2' started on $HOST_PORT_1. This should not happen."
    cleanup_container "$CONTAINER_NAME_2" # Clean up if it somehow started
fi
echo ""
sleep 1

# 4. Run the second container on a *different* host port to resolve the conflict
echo "--- Step 3: Running '$CONTAINER_NAME_2' on a *different* host port $HOST_PORT_2 to resolve conflict ---"
# By using a different host port, we resolve the port conflict.
docker run -d --name "$CONTAINER_NAME_2" -p "$HOST_PORT_2":80 "$DOCKER_IMAGE"
if [ $? -eq 0 ]; then
    echo "Container '$CONTAINER_NAME_2' started successfully on $HOST_PORT_2."
    echo "This demonstrates a solution to 'port çakışması' (port conflict)."
else
    echo "Failed to start '$CONTAINER_NAME_2' on $HOST_PORT_2."
    exit 1
fi
echo ""
sleep 2 # Give container a moment to start

# 5. List running containers
echo "--- Step 4: Listing currently running Docker containers ---"
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}"
echo ""

# 6. Instructions to access
echo "--- Access Instructions ---"
echo "You can now access the Nginx instances:"
echo "  - First Nginx: http://localhost:$HOST_PORT_1"
echo "  - Second Nginx: http://localhost:$HOST_PORT_2"
echo "Press Enter to stop and remove containers..."
read -r

# 7. Clean up all containers
echo "--- Step 5: Cleaning up all containers ---"
cleanup_container "$CONTAINER_NAME_1"
cleanup_container "$CONTAINER_NAME_2"
echo "All demo containers have been stopped and removed."
echo "Demo finished."
