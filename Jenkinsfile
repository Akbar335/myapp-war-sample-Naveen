pipeline {
    agent any

    environment {
        DEPLOY_DIR = 'C:\\Tomcat\\webapps\\myapp.war'
        BACKUP_DIR = 'C:\\Tomcat\\rollback'
        WORKSPACE = "${env.WORKSPACE}"
        WAR_FILE = "${env.WORKSPACE}\\target\\myapp.war"
        SMTP_FAILURE_EMAIL = 'admin@example.com' // Replace with your actual email
    }

    stages {
        stage('Build WAR') {
            steps {
                echo "Building WAR file..."
                bat 'mvn clean package'
            }
        }

        stage('Backup Existing WAR') {
            steps {
                echo "Backing up current deployed WAR..."
                bat """
                if exist "${DEPLOY_DIR}" (
                    if not exist "${BACKUP_DIR}" mkdir "${BACKUP_DIR}"
                    copy /Y "${DEPLOY_DIR}" "${BACKUP_DIR}\\myapp_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.war"
                )
                """
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                echo "Deploying WAR to Tomcat..."
                bat """
                copy /Y "${WAR_FILE}" "${DEPLOY_DIR}"
                net stop Tomcat9
                net start Tomcat9
                """
            }
        }

        stage('Smoke Test') {
            steps {
                echo "Running smoke test..."
                sleep time: 10, unit: 'SECONDS'
                script {
                    def response = bat(script: 'powershell -Command "(Invoke-WebRequest http://localhost:9090/myapp/ -UseBasicParsing).StatusCode"', returnStdout: true).trim()
                    if (response != '200') {
                        error "Smoke test failed! Status code: ${response}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment succeeded!"
            // Optional email on success
            // mail to: "${SMTP_FAILURE_EMAIL}",
            //      subject: "Jenkins Job SUCCESS: ${env.JOB_NAME}",
            //      body: "The deployment was successful."
        }

        failure {
            echo "❌ Deployment failed. Rolling back..."

            bat """
            setlocal ENABLEDELAYEDEXPANSION
            set "ROLLBACK_FILE="
            for /f %%F in ('dir /b /o-d "${BACKUP_DIR}\\myapp_*.war"') do (
                set "ROLLBACK_FILE=%%F"
                goto done
            )
            :done
            if defined ROLLBACK_FILE (
                copy /Y "${BACKUP_DIR}\\!ROLLBACK_FILE!" "${DEPLOY_DIR}"
                net stop Tomcat9
                net start Tomcat9
            )
            """

            // Optional failure notification
            // mail to: "${SMTP_FAILURE_EMAIL}",
            //      subject: "Jenkins Job FAILED: ${env.JOB_NAME}",
            //      body: "The deployment failed and rollback was triggered."
        }
    }
}
