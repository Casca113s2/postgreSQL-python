#!/bin/bash

### Variables ###
JAVA_JDK_VERSION="jdk-17.0.11"
JAVA_JDK_URL="https://download.oracle.com/java/17/archive/${JAVA_JDK_VERSION}_linux-x64_bin.tar.gz"
JAVA_BASE_DIR="/opt/jdk"
JENKINS_VERSION="2.452.3"
JENKINS_WAR_URL="https://updates.jenkins.io/download/war/${JENKINS_VERSION}/jenkins.war"
JENKINS_BASE_DIR="/opt/jenkins"
JENKINS_HOME_BASE="/jenkins"

### Enable debugging ###
set -x

### Install Frontconfig ###
sudo apt install -y fontconfig

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
sudo mkdir -p ${JENKINS_WAR_DIR}

# Download Jenkins WAR file if it doesn't already exist
if [ ! -f ${JENKINS_WAR_DIR}/jenkins.war ]; then
    sudo wget ${JENKINS_WAR_URL} -O ${JENKINS_WAR_DIR}/jenkins.war
fi

# Function to set up Jenkins instance
setup_jenkins_instance() {
  local port=$1
  local instance_dir="${JENKINS_HOME_BASE}/jenkins_${port}"

  # Create the instance directory
  sudo mkdir -p ${instance_dir}

  # Change permissions to ensure the Jenkins user can access it
  sudo chown -R $(whoami):$(whoami) ${instance_dir}
  sudo chmod -R 755 ${instance_dir}

  # Create systemd service file
  sudo bash -c "cat > /etc/systemd/system/jenkins_${port}.service <<EOF
[Unit]
Description=Jenkins Continuous Integration Server on port ${port}
Requires=network.target
After=network.target

[Service]
Type=notify
NotifyAccess=main
User=$(whoami)
Group=$(whoami)
Environment=\"JENKINS_HOME=${instance_dir}\"
ExecStart=/usr/bin/java -jar ${JENKINS_WAR_DIR}/jenkins.war --httpPort=${port} --prefix=\"/jenkins_${port}\"
Restart=on-failure
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF"

  # Reload systemd to apply the new service file
  sudo systemctl daemon-reload
  sudo systemctl enable jenkins_${port}.service
  sudo systemctl start jenkins_${port}.service

  # Setup plugins for jenkins
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
