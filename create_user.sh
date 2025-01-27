#!/bin/bash

echo "User  Name:  "
read USERNAME

echo "Directory NAME which has only permission to access by user: "
read DIR_NAME

echo "Sudo Access (yes/no): "
read SUDO_ACCESS

# Check if USERNAME is empty
if [ -z "$USERNAME" ]; then
  echo "Please enter a valid user name"
  exit 1
fi

# Add the user
sudo adduser --disabled-password --gecos "" "$USERNAME"

# Create a Directory Path
sudo mkdir -p /home/$USERNAME/$DIR_NAME

# Add the user to that directory
sudo chown $USERNAME:$USERNAME /home/$USERNAME/$DIR_NAME

# Set permissions for that directory (700)
sudo chmod 700 /home/$USERNAME/$DIR_NAME

# Set the default home directory for that user
sudo usermod -d /home/$USERNAME/$DIR_NAME "$USERNAME" -m

# Create the .ssh directory
sudo mkdir -p /home/$USERNAME/.ssh
sudo chown $USERNAME:$USERNAME /home/$USERNAME/.ssh
sudo chmod 700 /home/$USERNAME/.ssh

# Generate SSH key pair
sudo -u "$USERNAME" ssh-keygen -t rsa -b 2048 -f /home/$USERNAME/.ssh/"$USERNAME".pem -N ""

# Set permissions for the private key
sudo chmod 600 /home/$USERNAME/.ssh/"$USERNAME".pem

# Copy the public key to authorized_keys
sudo cat /home/$USERNAME/.ssh/"$USERNAME".pem.pub | sudo tee -a /home/$USERNAME/.ssh/authorized_keys > /dev/null

# Display the contents of the .pem file
echo "Contents of the private key file ($USERNAME.pem):"
sudo cat /home/$USERNAME/.ssh/"$USERNAME".pem

# Ensure the authorized_keys file has the correct permissions
sudo chmod 600 /home/$USERNAME/.ssh/authorized_keys
sudo chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/authorized_keys

# Add user to sudo group if SUDO_ACCESS is "yes"
if [ "$SUDO_ACCESS" == "yes" ]; then
  sudo usermod -aG sudo "$USERNAME"
  echo "$USERNAME has been added to the sudo group."
fi

# Now i need to add the user to sshd_config file

echo "AllowUsers ec2-user $USERNAME" | sudo tee -a /etc/ssh/sshd_config.d/*.conf > /dev/null 

sudo systemctl restart ssh

echo "User  $USERNAME has been created with a directory $DIR_NAME and SSH keys generated."