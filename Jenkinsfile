pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds(); buildDiscarder(logRotator(numToKeepStr: '20')) }
  environment {
    IMAGE_NAME = 'devsecops-demo-api'
    LOCAL_REGISTRY = 'localhost:5000'
    APP_HOST_PORT = '18080'
    HEALTH_URL = 'http://host.docker.internal:18080/health'
    GITLEAKS_CONFIG = 'security/gitleaks/.gitleaks.toml'
  }
  stages {
    stage('Checkout & version') {
      steps {
        checkout scm
        script { env.RELEASE_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(12)}"; env.IMAGE_REF = "${env.LOCAL_REGISTRY}/${env.IMAGE_NAME}:${env.RELEASE_VERSION}" }
        sh 'node --version && npm --version && docker version --format "{{.Client.Version}}"'
      }
    }
    stage('Install & unit tests') {
      steps { dir('app') { sh 'npm ci'; sh 'npm test' } }
    }
    stage('SAST / lint') {
      steps { dir('app') { sh 'npm run lint' } }
    }
    stage('Dependency SCA') {
      steps { dir('app') { sh 'npm audit --audit-level=high' } }
    }
    stage('Secret scan') {
      steps { sh 'gitleaks git --redact --config "$GITLEAKS_CONFIG" .' }
    }
    stage('Docker build') {
      steps { sh 'docker build --pull --tag "$IMAGE_REF" --build-arg APP_VERSION="$RELEASE_VERSION" app' }
    }
    stage('Image scan report') {
      steps { sh 'trivy image --config security/trivy/trivy.yaml --severity UNKNOWN,LOW,MEDIUM --format table --exit-code 0 "$IMAGE_REF"' }
    }
    stage('Image vulnerability gate') {
      steps { sh 'trivy image --config security/trivy/trivy.yaml --severity HIGH,CRITICAL --format table --exit-code 1 "$IMAGE_REF"' }
    }
    stage('Push approved image') {
      when { branch 'main' }
      steps { sh 'docker push "$IMAGE_REF"' }
    }
    stage('Deploy & health validation') {
      when { branch 'main' }
      steps { sh 'deployment/scripts/deploy.sh "$IMAGE_REF" "$HEALTH_URL"' }
    }
  }
  post {
    success { echo "Release ${env.IMAGE_REF} passed configured gates and deployment validation." }
    failure { echo "Pipeline failed at or before release ${env.IMAGE_REF}; review stage output." }
    always { echo "Build ${env.BUILD_NUMBER} completed with status ${currentBuild.currentResult}. Jenkins console is the local notification channel." }
  }
}
