pipeline {
    agent { label 'windows' }

    environment {
        DEPLOY_DIR = 'C:\\Tomcat\\webapps\\myapp.war'
        BACKUP_DIR = 'C:\\Tomcat\\rollback'
        SMTP_FAILURE_EMAIL = 'admin@example.com' // Replace with your actual email
    }

    stages {
        stage('Build WAR') {
            steps {
                echo "🔨 Building WAR file..."
                bat 'mvn clean package'
            }
        }

        stage('Backup Existing WAR') {
            steps {
                echo "📦 Backing up current deployed WAR..."
                bat """
                if exist "%DEPLOY_DIR%" (
                    if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
                    for /f %%i in ('powershell -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set timestamp=%%i
                    copy /Y "%DEPLOY_DIR%" "%BACKUP_DIR%\\myapp_!timestamp!.war"
                )
                """
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                echo "🚀 Deploying WAR to Tomcat..."
                script {
                    def warFile = "${env.WORKSPACE}\\target\\myapp.war"
                    bat """
                    copy /Y "${warFile}" "${DEPLOY_DIR}"
                    net stop Tomcat9
                    net start Tomcat9
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {
                echo "🧪 Running smoke test..."
                sleep time: 10, unit: 'SECONDS'
                script {
                    def rawOutput = bat(
                        script: 'powershell -Command "(Invoke-WebRequest http://localhost:9090/myapp/ -UseBasicParsing).StatusCode"',
                        returnStdout: true
                    )
                    def lines = rawOutput.readLines()
                    def statusCode = lines.last().trim()
                    echo "Smoke test returned status code: ${statusCode}"
                    if (statusCode != "200") {
                        error("Smoke test failed! Status code: ${statusCode}")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment succeeded!"
            // Optional: Send success email
            // mail to: "${SMTP_FAILURE_EMAIL}",
            //      subject: "Jenkins Job SUCCESS: ${env.JOB_NAME}",
            //      body: "The deployment was successful."
        }

        failure {
            echo "❌ Deployment failed. Rolling back..."

            bat """
            setlocal ENABLEDELAYEDEXPANSION
            set "ROLLBACK_FILE="
            for /f %%F in ('dir /b /o-d "%BACKUP_DIR%\\myapp_*.war"') do (
                set "ROLLBACK_FILE=%%F"
                goto done
            )
            :done
            if defined ROLLBACK_FILE (
                copy /Y "%BACKUP_DIR%\\!ROLLBACK_FILE!" "%DEPLOY_DIR%"
                net stop Tomcat9
                net start Tomcat9
            ) else (
                echo No rollback file found!
            )
            """

            // Optional: Send failure email
            // mail to: "${SMTP_FAILURE_EMAIL}",
            //      subject: "Jenkins Job FAILED: ${env.JOB_NAME}",
            //      body: "The deployment failed and rollback was triggered."
        }
    }
}
