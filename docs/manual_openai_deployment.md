# Manual OpenAI Model Deployment

Due to conflicts with deprecated models in the Azure deployment system, the GPT model deployment has been removed from the automatic deployment template.

## Instructions for Creating the GPT Model Deployment Manually

1. After the deployment is complete, navigate to the Azure Portal.
2. Go to the OpenAI resource that was created during deployment.
3. Select "Model deployments" from the left navigation.
4. Click "Create new deployment".
5. Select "gpt-4o" (or your preferred model) from the dropdown.
6. Enter "deployment-gpt4o" (or the same name you used in the deployment template) for the deployment name.
7. Select version "2024-11-20" or the latest available version.
8. Set your desired capacity (default is 10 in the template).
9. Click "Create" to deploy the model.

Once the model is deployed, your application should be able to use it without further configuration, as all the necessary environment variables have already been set up during the deployment process.

## Troubleshooting

If you encounter any issues with the OpenAI integration after manually creating the model deployment, please make sure:

1. The model deployment name matches the value specified in the "AzureOpenAIModel" parameter during deployment.
2. The model name matches the value specified in the "AzureOpenAIModelName" parameter during deployment.
3. Your application has the necessary permissions to access the OpenAI resource.
