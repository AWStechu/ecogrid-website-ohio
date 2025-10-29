#!/bin/bash

echo "🔧 Updating CodeBuild project to use blue-green buildspec..."

# Get the CodeBuild project name (assuming it's part of the pipeline)
PROJECT_NAME="ecogrid-3stage-pipeline-Build"

# Update the CodeBuild project to use buildspec-bg.yml
aws codebuild update-project \
  --name $PROJECT_NAME \
  --source type=CODEPIPELINE,buildspec=buildspec-bg.yml \
  --region us-east-1

echo "✅ CodeBuild project updated to use buildspec-bg.yml"
echo "🔄 The next pipeline execution will use the blue-green deployment process"
