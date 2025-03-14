pipeline {
    agent any

    environment {
        AZURE_CREDENTIALS_ID = 'azure-jenkins-creds'
        FUNCTION_APP_NAME = 'myMicroUrlFunctionApp'
        RESOURCE_GROUP = 'myMicroUrlResourceGroup'
        DEPLOYMENT_PACKAGE = "functionapp.zip"
        KEY_VAULT_NAME = 'myMicroUrlKeyVault'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/chandansingh7/micro-url.git'
            }
        }

        stage('Build with Gradle') {
            steps {
                sh './gradlew clean build -x test'
            }
        }

        stage('Package for Deployment') {
            steps {
                sh """
                    mkdir -p deployment
                    cp build/libs/micro-url-0.0.1-SNAPSHOT.jar deployment/
                    cd deployment
                    zip -r ../$DEPLOYMENT_PACKAGE .
                """
            }
        }

        stage('Ensure Function App Exists in Azure') {
            steps {
                script {
                    def exists = sh(script: "az functionapp show -g $RESOURCE_GROUP -n $FUNCTION_APP_NAME --query 'name' -o tsv || echo 'notfound'", returnStdout: true).trim()
                    if (exists == 'notfound') {
                        error("Azure Function App '$FUNCTION_APP_NAME' does not exist in resource group '$RESOURCE_GROUP'. Deploy it first!")
                    }
                }
            }
        }

        stage('Fetch Env Variables from Key Vault and Configure App') {
            steps {
                script {
                    def dbUrl = sh(script: "az keyvault secret show --name db-url --vault-name $KEY_VAULT_NAME --query value -o tsv", returnStdout: true).trim()
                    def dbUsername = sh(script: "az keyvault secret show --name db-username --vault-name $KEY_VAULT_NAME --query value -o tsv", returnStdout: true).trim()
                    def dbPassword = sh(script: "az keyvault secret show --name db-password --vault-name $KEY_VAULT_NAME --query value -o tsv", returnStdout: true).trim()

                    sh """
                        az functionapp config appsettings set -g $RESOURCE_GROUP -n $FUNCTION_APP_NAME --settings \
                            DATABASE_URL='$dbUrl' \
                            DATABASE_USERNAME='$dbUsername' \
                            DATABASE_PASSWORD='$dbPassword'
                    """
                }
            }
        }

        stage('Deploy to Azure Functions') {
            steps {
                sh """
                    az functionapp deployment source config-zip -g $RESOURCE_GROUP -n $FUNCTION_APP_NAME --src $DEPLOYMENT_PACKAGE
                """
            }
        }
    }
}
