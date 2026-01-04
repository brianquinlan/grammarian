import os
import sys
import subprocess
import shlex

def main():
    service_name = "grammarian"
    region = "us-central1"
    
    # Check if PROJECT_ID is provided
    project_id = os.environ.get("PROJECT_ID")
    if not project_id:
        print("Error: PROJECT_ID environment variable is not set.")
        if sys.platform == "win32":
            print("Please set it using: $env:PROJECT_ID='your-project-id'")
        else:
            print("Please set it using: export PROJECT_ID=your-project-id")
        sys.exit(1)

    print("-" * 64)
    print(f"Deploying {service_name} to project {project_id} in region {region}")
    print("-" * 64)

    # Submit the build to Cloud Build
    print("Step 1: Building container image...")
    image_tag = f"gcr.io/{project_id}/{service_name}"
    build_cmd = ["gcloud", "builds", "submit", "--tag", image_tag]
    
    try:
        subprocess.run(build_cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error building container image: {e}")
        sys.exit(1)

    # Deploy to Cloud Run
    print("Step 2: Deploying to Cloud Run...")
    deploy_cmd = [
        "gcloud", "run", "deploy", service_name,
        "--image", image_tag,
        "--region", region,
        "--platform", "managed",
        "--allow-unauthenticated"
    ]

    try:
        subprocess.run(deploy_cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error deploying to Cloud Run: {e}")
        sys.exit(1)

    print("-" * 64)
    print("Deployment complete!")

if __name__ == "__main__":
    main()
