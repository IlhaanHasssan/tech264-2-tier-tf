#!/bin/bash
 
#Set MongoDB connecting string
export DB_HOST="mongodb://10.0.3.4:27017/posts"  # CHANGE THIS IF NOT THE SAME DB IP
 
# CD into app directory
echo "Change directory to app"
cd /repo/app
echo "In app directory"
 
# Stop all existing pm2 processes
pm2 stop all
 
# Start app, may have to use sudo
echo "start"
pm2 start app.js
echo "App started with pm2"