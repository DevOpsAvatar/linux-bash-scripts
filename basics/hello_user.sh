#!/bin/bash

# Ask for the user's name
read -p "What is your name? " name
# Get the current time in 12p-hour format
current_time=$(date +"%I:%M %p")
# Greet the user
echo "Hello, $name! The time is $current_time"
