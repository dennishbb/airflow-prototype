@Library('EnterpriseSharedLibrary') _

def utils = new org.acme.Utils(this)

node {
  def value_artifactURLs = []
  def isMain = (env.BRANCH_NAME == "main" || env.BRANCH_NAME == "master")
  def shortSha = (env.GIT_COMMIT ?: "dev").take(7)

  try {
    stage("Checkout") {
      // Multibranch + scripted pipeline: you must explicitly checkout
      checkout scm
      sh "git rev-parse HEAD && ls -la"
    }

    stage("Build & Push Image") {
      def imageTag = isMain ? "latest" : shortSha
      def publishIt = isMain

      def imageData = dockerBuildPushImage {
        image = "dennishbb/airflow-prototype"
        tag = imageTag
        publish = publishIt

        // Docker Hub
        registry = "docker.io"
        credentialsId = "docker-registry-creds"

        // Your repo layout
        dockerfile = "docker/Dockerfile"
        context = "."
        build_environment = "Hydra_App"
      }

      echo "Built image: ${imageData.imageRef}"
      echo "Image digest: ${imageData.imageWithSha}"
    }

    stage("Publish Helm Values") {
      value_artifactURLs = uploadHelmValues {
        values_location = "helm"
        registry = "paas-raw-registry"
        groupId = "airflow"
        version = "1.0.0.0"
        redeploy = true
      }

      echo "Helm values artifacts: ${value_artifactURLs}"
    }

  } catch (Exception err) {
    echo err.getMessage()
    currentBuild.result = 'FAILED'
    throw err
  } finally {
    stage("Send Feedback to XLR") {
      utils.sendFeedbackToXLR("", env.IMAGE_WITH_SHA ?: "N/A", value_artifactURLs)
    }
  }
}
