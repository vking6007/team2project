pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven_3.9.6'
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Select target deployment environment')
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
                    // Environment & Branch based naming
                    env.IMAGE_NAME = "${PROJECT}-${env.BRANCH_NAME}-springboot-app"
                    env.CONTAINER_NAME = "${PROJECT}-${env.BRANCH_NAME}-springboot-${params.ENVIRONMENT}"
                    env.HOST_PORT = (params.ENVIRONMENT == 'prod') ? "8088" : "8087"

                    if (params.ENVIRONMENT == 'prod') {
                        env.DB_HOST = "team_2_prod_postgres"
                        env.DB_NAME = "team_2_prod_db"
                        CRED_ID = "team2_prod_credentials"
                    } else {
                        env.DB_HOST = "team_2_dev_postgres"
                        env.DB_NAME = "team_2_db"
                        CRED_ID = "team2_dev_credentials"
                    }

                    env.DB_URL = "jdbc:postgresql://${env.DB_HOST}:5432/${env.DB_NAME}"

                    echo """
                    🌍 Environment: ${params.ENVIRONMENT}
                    🌿 Branch: ${env.BRANCH_NAME}
                    📦 Image: ${env.IMAGE_NAME}
                    🧱 Container: ${env.CONTAINER_NAME}
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
                sh "docker build -t ${IMAGE_NAME}:${params.ENVIRONMENT} ."
            }
        }

        stage('Stop Previous Container') {
            steps {
                echo "🛑 Stopping old container if running..."
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                """
            }
        }

        stage('Run New Container') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: CRED_ID,
                                                      usernameVariable: 'DB_USER',
                                                      passwordVariable: 'DB_PASS')]) {

                        echo "🚀 Deploying ${env.BRANCH_NAME} branch to ${params.ENVIRONMENT} environment..."

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
                        echo "✅ Health check passed inside container."
                        exit 0
                      fi
                      COUNT=\$((COUNT+1))
                      sleep 5
                    done

                    echo "❌ Health check failed after \$RETRIES attempts. Showing container logs:"
                    docker logs ${CONTAINER_NAME} --tail 300 || true
                    exit 1
                """
            }
        }
    }

    post {
        success {
            echo "🎉 Successfully deployed branch '${env.BRANCH_NAME}' to ${params.ENVIRONMENT}!"
            echo "🌍 URL: http://168.220.248.40:${HOST_PORT}"
        }
        failure {
            echo "❌ Deployment failed for branch '${env.BRANCH_NAME}' (${params.ENVIRONMENT})"
            sh 'docker logs ${CONTAINER_NAME} || true'
        }
        always {
            echo "✅ Jenkins Pipeline finished for ${env.BRANCH_NAME} → ${params.ENVIRONMENT}"
        }
    }
}
