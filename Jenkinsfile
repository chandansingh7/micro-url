pipeline {
    agent any

    environment {
        AZURE_CREDENTIALS_ID = 'azure-jenkins-creds'  // Replace with the actual Jenkins credential ID
        FUNCTION_APP_NAME = 'myMicroUrlFunctionApp'   // Your Azure Function App Name
        RESOURCE_GROUP = 'myMicroUrlResoucreGroup'    // Your Azure Resource Group Name
    }

    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/chandansingh7/micro-url.git'  // Your actual GitHub repository
            }
        }

        stage('Build with Gradle') {
            steps {
                sh './gradlew clean build -x test'  // Skip tests for faster builds; remove '-x test' if needed
            }
        }

        stage('Deploy to Azure Functions') {
            steps {
                withAzureCLI(credentialsId: AZURE_CREDENTIALS_ID) {
                    sh """
                        func azure functionapp publish $FUNCTION_APP_NAME \
                        --resource-group $RESOURCE_GROUP --java
                    """
                }
            }
        }
    }
}
