@Library('EnterpriseSharedLibrary') _

def utils = new org.acme.Utils(this)

node('ml-cicd') {
  try {
    def isAppDeployment = true
    def application = "airflow-prototype"

    stage("Build & Push Image") {
      if (isAppDeployment) {
        dockerBuildPushImage {
          image = application
          tag = "latest"
          publish = true
          build_environment = "hydra_app"
        }
      }
    }

    stage("Publish Helm Values") {
      uploadHelmValues {
        values_location = "helm"
        registry = "paas-raw-registry"
        groupId = "airflow"
        version = "1.0.0.0"
        redeploy = true
      }
    }

  } catch (Exception err) {
    echo err.getMessage()
    currentBuild.result = 'FAILED'
    throw err
  } finally {
    stage("Send Feedback to XLR") {
      utils.sendFeedbackToXLR("", env.IMAGE_WITH_SHA ?: "N/A", [])
    }
  }
}
