#!/bin/bash

### Variables ###
JAVA_JDK_VERSION="jdk-17.0.11"
JAVA_JDK_URL="https://download.oracle.com/java/17/archive/${JAVA_JDK_VERSION}_linux-x64_bin.tar.gz"
JAVA_BASE_DIR="/opt/jdk"
JENKINS_VERSION="2.452.3"
JENKINS_WAR_URL="https://updates.jenkins.io/download/war/${JENKINS_VERSION}/jenkins.war"
JENKINS_BASE_DIR="/opt/jenkins"

### Enable debugging ###
set -x

### Install Frontconfig ###
sudo apt install fontconfig

### Install Java ###
# Download jdk .tar.gz file
if [ ! -f ${JAVA_JDK_VERSION}_linux-x64_bin.tar.gz ]; then
	sudo wget "${JAVA_JDK_URL}"
fi

# Create jdk directory
sudo mkdir ${JAVA_BASE_DIR}

# Extract tar.gz file
sudo tar -xzf ${JAVA_JDK_VERSION}_linux-x64_bin.tar.gz -C /opt/jdk

# Update alternatives so the command java point to the new jdk
sudo update-alternatives --install /bin/java java /opt/jdk/${JAVA_JDK_VERSION}/bin/java 100

# Update alternatives so the command javac point to the new jdk
sudo update-alternatives --install /bin/javac javac /opt/jdk/${JAVA_JDK_VERSION}/bin/javac 100

### Install Jenkins ###
# Function to set up Jenkins instance
setup_jenkins_instance() {
  local port=$1
  local instance_dir="${BASE_DIR}/jenkins_${port}"

  # Create the instance directory
  sudo mkdir -p ${instance_dir}

  # Download Jenkins WAR file if it doesn't already exist
  if [ ! -f ${instance_dir}/jenkins.war ]; then
  	sudo wget -O ${instance_dir}/jenkins.war ${JENKINS_WAR_URL}
  fi

  # Change permissions to ensure the Jenkins user can access it
  sudo chown -R $(whoami):$(whoami) ${instance_dir}
  sudo chmod -R 755 ${instance_dir}

  # Start Jenkins instance on the specified port with a context path
  nohup java -jar ${instance_dir}/jenkins.war --httpPort=${port} --prefix="/jenkins" &> ${instance_dir}/jenkins.log &
  
  # Inform the user that Jenkins is starting
  echo "Jenkins is being started from ${instance_dir}/jenkins.war on port ${port}. Logs can be found in ${instance_dir}/jenkins.log"
}

# Check if at least one port number is provided
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 port1 [port2 ... portN]"
  exit 1
fi

# Loop through each provided port number
for port in "$@"; do
  setup_jenkins_instance ${port}
done

### Setup service file ###


### Setup user privileges ###


### Setup plugins for jenkins ###
