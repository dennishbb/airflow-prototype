@Library('EnterpriseSharedLibrary') _

def utils = new org.acme.Utils(this)

node {
  def value_artifactURLs = []
  def application = "airflow-prototype"

  // Only push on main by default (best practice for multibranch)
  def isMain = (env.BRANCH_NAME == "main" || env.BRANCH_NAME == "master")
  def shortSha = (env.GIT_COMMIT ?: "dev").take(7)

  try {

    stage("Debug Workspace") {
      sh """
        set -eux
        pwd
        ls -la
        ls -la docker || true
        find . -maxdepth 3 -type f -name Dockerfile -print
        git rev-parse HEAD || true
        git status || true
      """
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

        dockerfile = "docker/Dockerfile"
        context = "."
        build_environment = "hydra_app"
      }

      echo "Image built: ${imageData.imageRef}"
      echo "Image with digest: ${imageData.imageWithSha}"
    }

    stage("Publish Helm Values") {
      value_artifactURLs = uploadHelmValues {
        values_location = "helm"
        registry = "paas-raw-registry"
        groupId = "airflow"
        version = "1.0.0.0"
        redeploy = true
      }

      echo "Helm values published: ${value_artifactURLs}"
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
