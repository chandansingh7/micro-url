FROM jenkins/jenkins:lts

# Switch to root user to install dependencies
USER root

# Install required packages
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    gnupg \
    software-properties-common \
    unzip \
    maven \
    nodejs \
    npm

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Azure Functions Core Tools
RUN npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Ensure correct permissions for Jenkins
RUN chown -R jenkins:jenkins /var/jenkins_home

# Switch back to Jenkins user
USER jenkins

# Expose Jenkins port
EXPOSE 8089

# Start Jenkins
CMD ["jenkins.sh"]

