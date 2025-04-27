#!/bin/bash

# Function to start iperf3 server
start_iperf3_server() {
  echo "Starting iperf3 server..."
  iperf3 -s &
  SERVER_PID=$!
  echo "iperf3 server started with PID $SERVER_PID"
}

# Function to stop iperf3 server
stop_iperf3_server() {
  echo "Stopping iperf3 server..."
  kill $SERVER_PID
  echo "iperf3 server stopped."
}

# Function to check if iperf3 server is running
check_server() {
  ps aux | grep "iperf3 -s" | grep -v grep
}

# Function to test TCP bandwidth
test_bandwidth_tcp() {
  echo "Testing TCP bandwidth on localhost..."
  iperf3 -c 127.0.0.1 -t 10
}

# Function to test UDP latency
test_latency_udp() {
  echo "Testing UDP latency on localhost..."
  iperf3 -c 127.0.0.1 -u -t 10
}

# Function to test bandwidth with UDP at 10 Mbps
test_bandwidth() {
  echo "Testing bandwidth with UDP at 10 Mbps..."
  iperf3 -c 127.0.0.1 -u -b 10M -t 10
}

# Function to run a basic ping test
run_ping_test() {
  echo "Running ping test on localhost..."
  ping -c 10 127.0.0.1
}

# Function to kill existing iperf3 process if any
kill_existing_iperf3() {
  echo "Killing existing iperf3 process if any..."
  fuser -k 5201/tcp
}

# Function to check for iperf3 installation
check_iperf3_installed() {
  if ! command -v iperf3 &> /dev/null
  then
    echo "iperf3 is not installed. Installing..."
    apt-get update && apt-get install -y iperf3
  else
    echo "iperf3 is already installed."
  fi
}

# Function to check for root privileges
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
  fi
}

# Function to apply network optimizations
apply_network_optimizations() {
  echo "Applying network optimizations..."

  # Set TCP congestion control to BBR (Bottleneck Bandwidth and Round-trip propagation time)
  sysctl -w net.ipv4.tcp_congestion_control=bbr
  echo "TCP Congestion Control set to BBR."

  # Increase the TCP buffer sizes to improve throughput and reduce latency
  sysctl -w net.core.rmem_max=16777216
  sysctl -w net.core.wmem_max=16777216
  sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
  sysctl -w net.ipv4.tcp_wmem="4096 87380 16777216"
  echo "Increased TCP buffer sizes."

  # Disable TCP Delayed Acknowledgments
  sysctl -w net.ipv4.tcp_delack_min=0
  echo "TCP Delayed Acknowledgments disabled."

  # Enable TCP fast open (if supported)
  sysctl -w net.ipv4.tcp_fastopen=3
  echo "TCP Fast Open enabled."

  # Increase the default TCP socket receive buffer
  sysctl -w net.core.rmem_default=16777216
  sysctl -w net.core.wmem_default=16777216
  echo "Increased default TCP socket buffer sizes."

  # Disable offloading features on the network interface (e.g., TSO, GSO)
  ethtool -K eth0 tso off gso off
  echo "Disabled offloading features on the network interface."

  # Disable ICMP rate limiting
  sysctl -w net.ipv4.icmp_ratelimit=0
  sysctl -w net.ipv4.icmp_ratemask=0
  echo "Disabled ICMP rate limiting."

  # Adjust other kernel parameters for improved network performance
  sysctl -w net.ipv4.tcp_fin_timeout=15
  sysctl -w net.ipv4.tcp_tw_reuse=1
  sysctl -w net.ipv4.tcp_max_tw_buckets=2000
  echo "Other kernel parameters adjusted."
}

# Main logic
echo "Script started..."

# Check if running as root
check_root

# Check if iperf3 is installed
check_iperf3_installed

# Kill any existing iperf3 process
kill_existing_iperf3

# Apply network optimizations
apply_network_optimizations

# Start iperf3 server
start_iperf3_server

# Wait for the server to initialize
sleep 2

# Check if iperf3 server is running
if ! check_server; then
  echo "iperf3 server failed to start. Exiting..."
  exit 1
fi

# Run TCP bandwidth test
test_bandwidth_tcp

# Run UDP latency test
test_latency_udp

# Run bandwidth test with 10 Mbps UDP
test_bandwidth

# Run ping test
run_ping_test

# Stop the iperf3 server
stop_iperf3_server

# Final completion message
echo "Script completed."
