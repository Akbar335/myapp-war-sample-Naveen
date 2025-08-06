pipeline {
    agent any

    environment {
        TOMCAT_WEBAPPS = 'C:\\Tomcat\\webapps'
        BACKUP_DIR = 'C:\\Tomcat\\backup'
        WAR_FILE = 'target\\myapp.war'
        DEPLOY_DIR = "${TOMCAT_WEBAPPS}\\myapp.war"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: 'github-token', url: 'https://github.com/korupon/myapp-war-sample.git'
            }
        }

        stage('Build WAR') {
            steps {
                bat 'mvn clean package'
            }
        }

        stage('Backup & Deploy Locally') {
            steps {
                script {
                    def timestamp = new Date().format("yyyyMMdd_HHmmss")
                    def backupFile = "${BACKUP_DIR}\\myapp_${timestamp}.war"

                    bat """
                    if not exist "${BACKUP_DIR}" mkdir "${BACKUP_DIR}"
                    if exist "${DEPLOY_DIR}" (
                        copy /Y "${DEPLOY_DIR}" "${backupFile}"
                        del /Q "${DEPLOY_DIR}"
                    )
                    copy /Y "${WAR_FILE}" "${DEPLOY_DIR}"
                    """
                }
            }
        }

        stage('Restart Tomcat') {
            steps {
                bat 'net stop Tomcat9'
                sleep time: 5, unit: 'SECONDS'
                bat 'net start Tomcat9'
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    def response = bat(script: 'curl -s -o nul -w "%%{http_code}" http://localhost:8080/myapp/', returnStdout: true).trim()
                    if (response != "200") {
                        error "Smoke test failed with HTTP $response"
                    } else {
                        echo "✅ Smoke test passed: HTTP $response"
                    }
                }
            }
        }
    }

    post {
        success {
            emailext(
                to: 'devops-team@example.com',
                subject: "✅ Local Deployment Successful: myapp.war",
                body: "Deployment to local Tomcat succeeded on Windows."
            )
        }

        failure {
            script {
                echo '❌ Deployment failed. Attempting rollback...'
                bat """
                set ROLLBACK_FILE=
                for /f %%F in ('dir /b /o-d "${BACKUP_DIR}\\myapp_*.war"') do (
                    set ROLLBACK_FILE=%%F
                    goto done
                )
                :done
                if defined ROLLBACK_FILE (
                    copy /Y "${BACKUP_DIR}\\%ROLLBACK_FILE%" "${DEPLOY_DIR}"
                    net stop Tomcat9
                    net start Tomcat9
                )
                """
            }
            emailext(
                to: 'devops-team@example.com',
                subject: "❌ Local Deployment Failed: myapp.war",
                body: "Deployment or smoke test failed. Rollback attempted."
            )
        }
    }
}
