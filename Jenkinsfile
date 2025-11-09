pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven_3.9.6'
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['none', 'dev', 'prod'], description: 'Select target environment for deployment (none = build only)')
    }

    environment {
        PROJECT = "team2"
        APP_PORT = "8085"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📦 Checking out branch: ${env.BRANCH_NAME}"
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${env.BRANCH_NAME}"]],
                    userRemoteConfigs: [[url: 'https://github.com/vking6007/team2project.git']]
                ])
            }
        }

        stage('Initialize Environment Variables') {
            steps {
                script {
                    env.SAFE_BRANCH = env.BRANCH_NAME.replaceAll('/', '-')
                    env.IMAGE_NAME = "${PROJECT}-${env.SAFE_BRANCH}-springboot-app"
                    env.CONTAINER_NAME = "${PROJECT}-${env.SAFE_BRANCH}-springboot-${params.ENVIRONMENT}"

                    // Set host port based on environment
                    if (params.ENVIRONMENT == 'prod') {
                        env.HOST_PORT = "8088"
                        env.DB_HOST = "team_2_prod_postgres"
                        env.DB_NAME = "team_2_prod_db"
                        CRED_ID = "team2_prod_credentials"
                    } else {
                        env.HOST_PORT = "8087"
                        env.DB_HOST = "team_2_dev_postgres"
                        env.DB_NAME = "team_2_db"
                        CRED_ID = "team2_dev_credentials"
                    }

                    env.DB_URL = "jdbc:postgresql://${env.DB_HOST}:5432/${env.DB_NAME}"

                    echo """
                    🌿 Branch: ${env.BRANCH_NAME}
                    📦 Image: ${IMAGE_NAME}
                    🌍 Selected Environment: ${params.ENVIRONMENT}
                    🗄 DB_URL: ${env.DB_URL}
                    """
                }
            }
        }

        stage('Build JAR') {
            steps {
                echo "⚙️ Building Spring Boot JAR..."
                sh 'mvn clean package -DskipTests'
                echo "✅ JAR built successfully"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh "docker build -t ${IMAGE_NAME}:${params.ENVIRONMENT == 'none' ? 'build' : params.ENVIRONMENT} ."
                echo "✅ Docker image built successfully"
            }
        }

        stage('Archive Build Artifacts') {
            steps {
                echo "🗂 Archiving JAR..."
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        // Only deploy when user selected a real environment (dev/prod)
        stage('Stop Previous Container') {
            when {
                expression { return params.ENVIRONMENT != 'none' }
            }
            steps {
                echo "🛑 Stopping old container if running..."
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                """
            }
        }

        stage('Run New Container') {
            when {
                expression { return params.ENVIRONMENT != 'none' }
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: CRED_ID,
                                                      usernameVariable: 'DB_USER',
                                                      passwordVariable: 'DB_PASS')]) {

                        echo "🚀 Deploying ${env.BRANCH_NAME} branch to ${params.ENVIRONMENT}..."

                        sh """
                            if docker ps --format '{{.Ports}}' | grep -q ':${HOST_PORT}->'; then
                              echo '⚠️ Port ${HOST_PORT} in use. Stopping existing container...'
                              docker ps --format '{{.ID}} {{.Ports}}' | grep ':${HOST_PORT}->' | awk '{print \$1}' | xargs -r docker stop
                            fi

                            docker run -d \
                              --name ${CONTAINER_NAME} \
                              --network jenkins-net \
                              -p ${HOST_PORT}:${APP_PORT} \
                              -e SPRING_PROFILES_ACTIVE=${params.ENVIRONMENT} \
                              -e SPRING_DATASOURCE_URL=${DB_URL} \
                              -e SPRING_DATASOURCE_USERNAME=$DB_USER \
                              -e SPRING_DATASOURCE_PASSWORD=$DB_PASS \
                              -e SERVER_PORT=${APP_PORT} \
                              ${IMAGE_NAME}:${params.ENVIRONMENT}
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            when {
                expression { return params.ENVIRONMENT != 'none' }
            }
            steps {
                echo "🕒 Waiting for app startup..."
                sh 'sleep 10'

                echo "🔍 Checking health inside container..."
                sh """
                    RETRIES=12
                    COUNT=0
                    until [ \$COUNT -ge \$RETRIES ]
                    do
                      echo "Attempt \$((COUNT+1)) of \$RETRIES..."
                      if docker exec ${CONTAINER_NAME} curl -fsS http://localhost:${APP_PORT}/actuator/health > /dev/null 2>&1; then
                        echo "✅ Health check passed!"
                        exit 0
                      fi
                      COUNT=\$((COUNT+1))
                      sleep 5
                    done

                    echo "❌ Health check failed after \$RETRIES attempts."
                    docker logs ${CONTAINER_NAME} --tail 300 || true
                    exit 1
                """
            }
        }

        stage('Summary') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'none') {
                        echo """
                        ✅ Build-only mode completed for branch '${env.BRANCH_NAME}'.
                        🔹 Docker image: ${IMAGE_NAME}:build
                        🔹 No container deployed automatically.
                        """
                    } else {
                        echo """
                        ✅ Deployment completed for '${env.BRANCH_NAME}' → ${params.ENVIRONMENT}.
                        🌍 URL: http://168.220.248.40:${HOST_PORT}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline finished successfully for ${env.BRANCH_NAME} (${params.ENVIRONMENT})"
        }
        failure {
            echo "❌ Pipeline failed for ${env.BRANCH_NAME} (${params.ENVIRONMENT})"
        }
    }
}
