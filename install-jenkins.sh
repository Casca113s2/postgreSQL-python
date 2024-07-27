#!/bin/bash

### Variables ###
JAVA_JDK_VERSION="jdk-17.0.11"
JAVA_JDK_URL="https://download.oracle.com/java/17/archive/${JAVA_JDK_VERSION}_linux-x64_bin.tar.gz"
JAVA_BASE_DIR="/opt/jdk"

JENKINS_VERSION="2.452.3"
JENKINS_WAR_URL="https://updates.jenkins.io/download/war/${JENKINS_VERSION}/jenkins.war"
JENKINS_WAR_DIR="/opt/jenkins"
JENKINS_CLI_URL="https://jenkins.cascabase.online/jnlpJars/jenkins-cli.jar"
JENKINS_CLI_DIR="/opt/jenkins"
JENKINS_HOME_BASE="/jenkins"

PLUGINS_FILE="plugins.txt"

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
#sudo mkdir -p ${JENKINS_CLI_DIR} # In case .war and .jar have a different path 

# Download Jenkins WAR file if it doesn't already exist
if [ ! -f ${JENKINS_WAR_DIR}/jenkins.war ]; then
    sudo wget ${JENKINS_WAR_URL} -O ${JENKINS_WAR_DIR}/jenkins.war
fi

# Download Jenkins CLI JAR file if it doesn't already exist
if [ ! -f ${JENKINS_CLI_DIR}/jenkins-cli.jar ]; then
    sudo wget ${JENKINS_CLI_URL} -O ${JENKINS_CLI_DIR}/jenkins-cli.jar
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

  
  # Read the initial admin password
  local admin_pass=$(sudo cat ${instance_dir}/secrets/initialAdminPassword)

  # Install plugins
  install_plugins ${port} ${admin_pass}
}

### Setup plugins for jenkins ###
install_plugins() {
  local port=$1
  local admin_pass=$2

  IFS=$'\n' # set the Internal Field Separator to newline
  for plugin in $(cat "$PLUGINS_FILE")
    do
      # Clean up plugin name to remove special characters like '\r'
      plugin_name=$(echo $plugin | tr -d '\r')

      # Print debug information
      echo "Installing plugin: ${plugin_name}"

      # Install the plugin
      sudo java -jar ${JENKINS_CLI_DIR}/jenkins-cli.jar -auth admin:${admin_pass} -s http://localhost:${port}/jenkins_${port} install-plugin ${plugin_name} || {
        echo "Failed to install plugin: ${plugin_name}"
        continue
      }
    done

  # Restart Jenkins to apply plugin changes
  echo "Restarting Jenkins service on port ${port}..."
  sudo systemctl restart jenkins_${port}.service
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
