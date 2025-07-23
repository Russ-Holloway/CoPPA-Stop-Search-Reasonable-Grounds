# Check OpenAI Model Deployments
# This script checks if OpenAI models are properly deployed and ready

param(
    [Parameter(Mandatory=$true)]
    [string]$OpenAIEndpoint,
    
    [Parameter(Mandatory=$true)]
    [string]$OpenAIKey,
    
    [Parameter(Mandatory=$false)]
    [string]$EmbeddingDeploymentName = "text-embedding-ada-002",
    
    [Parameter(Mandatory=$false)]
    [string]$GptDeploymentName = "gpt-4o"
)

Write-Host "🔍 Checking OpenAI Model Deployments..." -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

$headers = @{
    "api-key" = $OpenAIKey
    "Content-Type" = "application/json"
}

# Function to check deployment status
function Test-OpenAIDeployment {
    param($deploymentName, $modelType)
    
    Write-Host "📋 Checking $modelType deployment: $deploymentName" -ForegroundColor Yellow
    
    try {
        # Get deployment info
        $deploymentUri = "$OpenAIEndpoint/openai/deployments/$deploymentName`?api-version=2023-05-15"
        $deployment = Invoke-RestMethod -Uri $deploymentUri -Headers $headers -Method GET
        
        Write-Host "  ✅ Deployment exists" -ForegroundColor Green
        Write-Host "  📊 Status: $($deployment.properties.provisioningState)" -ForegroundColor $(if($deployment.properties.provisioningState -eq 'Succeeded') {'Green'} else {'Yellow'})
        Write-Host "  🏷️ Model: $($deployment.model)" -ForegroundColor Gray
        Write-Host "  📈 Capacity: $($deployment.sku.capacity)" -ForegroundColor Gray
        
        if ($deployment.properties.provisioningState -eq "Succeeded") {
            # Test the deployment with a simple request
            Write-Host "  🧪 Testing deployment..." -ForegroundColor Yellow
            
            if ($modelType -eq "Embedding") {
                $testUri = "$OpenAIEndpoint/openai/deployments/$deploymentName/embeddings?api-version=2023-05-15"
                $testBody = @{
                    input = "test"
                } | ConvertTo-Json
                
                $testResponse = Invoke-RestMethod -Uri $testUri -Headers $headers -Method POST -Body $testBody
                Write-Host "  ✅ Embedding test successful - got $($testResponse.data[0].embedding.Count) dimensions" -ForegroundColor Green
            }
            elseif ($modelType -eq "Chat") {
                $testUri = "$OpenAIEndpoint/openai/deployments/$deploymentName/chat/completions?api-version=2023-05-15"
                $testBody = @{
                    messages = @(
                        @{
                            role = "user"
                            content = "Hello"
                        }
                    )
                    max_tokens = 5
                } | ConvertTo-Json -Depth 3
                
                $testResponse = Invoke-RestMethod -Uri $testUri -Headers $headers -Method POST -Body $testBody
                Write-Host "  ✅ Chat completion test successful" -ForegroundColor Green
            }
            
            return $true
        }
        else {
            Write-Host "  ⚠️ Deployment not ready - State: $($deployment.properties.provisioningState)" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "  ❌ Error checking deployment: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Check connection to OpenAI service
Write-Host "🔗 Testing OpenAI service connection..." -ForegroundColor Cyan
try {
    $deploymentsUri = "$OpenAIEndpoint/openai/deployments?api-version=2023-05-15"
    $allDeployments = Invoke-RestMethod -Uri $deploymentsUri -Headers $headers -Method GET
    Write-Host "✅ OpenAI service connection successful" -ForegroundColor Green
    Write-Host "📊 Total deployments found: $($allDeployments.data.Count)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Failed to connect to OpenAI service: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check specific deployments
$embeddingReady = Test-OpenAIDeployment -deploymentName $EmbeddingDeploymentName -modelType "Embedding"
$gptReady = Test-OpenAIDeployment -deploymentName $GptDeploymentName -modelType "Chat"

# List all available deployments
Write-Host ""
Write-Host "📋 All Available Deployments:" -ForegroundColor Cyan
foreach ($deployment in $allDeployments.data) {
    $status = if ($deployment.properties.provisioningState -eq 'Succeeded') { "✅" } else { "⚠️" }
    Write-Host "  $status $($deployment.id) - $($deployment.model) ($($deployment.properties.provisioningState))" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "📊 Deployment Readiness Summary:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Embedding Model ($EmbeddingDeploymentName): $(if($embeddingReady){'✅ Ready'}else{'❌ Not Ready'})" -ForegroundColor $(if($embeddingReady){'Green'}else{'Red'})
Write-Host "Chat Model ($GptDeploymentName): $(if($gptReady){'✅ Ready'}else{'❌ Not Ready'})" -ForegroundColor $(if($gptReady){'Green'}else{'Red'})

if ($embeddingReady -and $gptReady) {
    Write-Host ""
    Write-Host "🎉 All OpenAI deployments are ready for use!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "⚠️ Some deployments are not ready. Wait for provisioning to complete." -ForegroundColor Yellow
    exit 1
}
