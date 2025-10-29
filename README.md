# EcoGrid Dynamics Website

A 3-tier web application for EcoGrid Dynamics showcasing go-green initiatives with CI/CD pipeline.

## Architecture

- **Frontend**: Flask web application with responsive design
- **Backend**: Python Flask API with database integration
- **Database**: AWS RDS MySQL
- **Infrastructure**: AWS ECS Fargate with Application Load Balancer

## CI/CD Pipeline

- **Source**: GitHub repository
- **Build**: AWS CodeBuild / GitHub Actions
- **Deploy**: AWS CodeDeploy Blue-Green to ECS Fargate
- **Container Registry**: Amazon ECR

## Features

- Home page with green initiatives showcase
- Projects page with upcoming environmental projects
- Volunteer registration form with database integration
- Responsive design optimized for all devices

## Deployment

The application automatically deploys to AWS when code is pushed to the main branch.


**Live URL**: http://whatsnewcustomer.com/                                                                             
**Second Live URL**: http://ecogrid-alb-492743554.us-east-1.elb.amazonaws.com

## Local Development

```bash
pip install -r requirements.txt
python app.py
```

Visit http://localhost:5000 to view the application locally.
