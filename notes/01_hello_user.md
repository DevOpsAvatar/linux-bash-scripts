# 01 - Hello User Script

## Purpose
This script demonstrates how to interact with a user in Bash:
-Accept input
-Store values in variables
-Use system commands ('date')
-Print a formatted message

---

## Script code
'''bash
#!/bin/bash

#Ask for the user's name
read -p "What is your name? " name

#Get the current time in 12-hour format
current_time=$(date +"%I:%M %p")

#Greet the user
echo "Hello, $name! The time is $current _time"
