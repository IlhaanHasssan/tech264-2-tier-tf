#!/bin/bash

# Update Linux sources list
echo "Updating sources list..."
sudo apt-get update -y
echo "Done updating packages!"

# Upgrade any packages available
echo "Upgrading installed packages..."
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
echo "Done upgrading packages!"

# Install Nginx
echo "Installing Nginx..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install nginx -y
echo "Done installing nginx!"

# creates a basic configuration for Nginx to listen on port 80 and forward requests to the application running on port 3000.
sudo sed -i 's|try_files $uri $uri/ =404;|proxy_pass http://localhost:3000;|' /etc/nginx/sites-available/default


# Test Nginx configuration for syntax errors
echo "Testing Nginx configuration..."
if sudo nginx -t; then
    echo "Nginx configuration is valid. Restarting Nginx..."
    sudo systemctl restart nginx
    echo "Nginx has been restarted."
else
    echo "Nginx configuration has errors. Please fix them before restarting."
fi

echo "Nginx reverse proxy setup is complete."

# Install Node.js v20
echo "Installing Node.js v20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
echo "Done installing node js!"

# Check Node.js version
echo "Checking Node.js version..."
node -v
echo "Done checking node version!"

# Defining environment variable
echo "Defining environment variable..."
export DB_HOST=mongodb://10.0.3.4:27017/posts
printenv DB_HOST
echo "Done defining env variable!"


# Cloning GitHub repository
echo "Cloning GitHub repository..."
git clone https://github.com/IlhaanHasssan/tech264-sparta-app.git repo
echo "Done cloning GitHub!"

# Changing directories to the app folder
echo "Changing directories to the app folder..."
cd repo/app
echo "Done changing directories into app!"

# Install PM2 globally
echo "Installing PM2..."
npm install -g pm2
echo "Done PM2 install!"

# Installing app packages and dependencies
echo "Installing app packages and dependencies..."
npm install
echo "Done NPM install!"

echo Running the app with PM2...
pm2 stop all  # Stops any previously running processes
pm2 start app.js --name "app"
echo Done running app with PM2!
#checks 
pm2 list

# Finished
echo "Provisioning complete. The app is running and will automatically restart on failure or reboot."
