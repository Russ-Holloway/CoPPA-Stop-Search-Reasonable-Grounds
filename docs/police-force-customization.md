# Police Force Customization Guide

## Overview
CoPPA now supports environment variable-based customization for police force branding. This allows Azure administrators to easily update police force logos and taglines without modifying the application code.

## Environment Variables

### UI_POLICE_FORCE_LOGO
- **Purpose**: Sets the police force logo displayed in the header (admin-only visible)
- **Format**: URL or base64 data URL
- **Example**: `UI_POLICE_FORCE_LOGO=https://your-storage.blob.core.windows.net/images/force-logo.png`
- **Default**: Falls back to the default force logo if not set

### UI_POLICE_FORCE_TAGLINE
- **Purpose**: Sets a custom tagline for the police force (admin-only visible)
- **Format**: Plain text string
- **Example**: `UI_POLICE_FORCE_TAGLINE=Serving and Protecting Our Community`
- **Default**: No tagline shown if not set

## Admin-Only Visibility
Both the police force logo and tagline are only visible to users with admin permissions. This ensures that:
- Regular users see the standard CoPPA interface
- Administrators can see the customized police force branding
- The interface remains consistent for most users while allowing force-specific customization

## Azure Configuration

### Through Azure App Service Configuration
1. Navigate to your Azure App Service
2. Go to **Configuration** > **Application settings**
3. Add the following settings:
   - Name: `UI_POLICE_FORCE_LOGO`
   - Value: Your logo URL
   - Name: `UI_POLICE_FORCE_TAGLINE`
   - Value: Your custom tagline

### Through Azure Key Vault (Recommended for security)
1. Store the logo URL and tagline in Azure Key Vault
2. Reference them in your App Service configuration:
   - `UI_POLICE_FORCE_LOGO=@Microsoft.KeyVault(SecretUri=https://your-keyvault.vault.azure.net/secrets/force-logo/)`
   - `UI_POLICE_FORCE_TAGLINE=@Microsoft.KeyVault(SecretUri=https://your-keyvault.vault.azure.net/secrets/force-tagline/)`

### Through Azure Container Apps (if using containers)
1. Go to your Container App
2. Navigate to **Configuration** > **Environment variables**
3. Add the environment variables as described above

## Image Hosting Options

### Option 1: Azure Blob Storage (Recommended)
1. Upload your logo to Azure Blob Storage
2. Make the blob publicly accessible
3. Use the blob URL as the `UI_POLICE_FORCE_LOGO` value

### Option 2: Base64 Encoded Image
1. Convert your logo to base64
2. Use a data URL format: `data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...`
3. Set this as the `UI_POLICE_FORCE_LOGO` value

### Option 3: CDN or External URL
1. Host your logo on a CDN or external service
2. Use the full URL as the `UI_POLICE_FORCE_LOGO` value

## Example Configuration

```bash
# Example environment variables
UI_POLICE_FORCE_LOGO=https://yourstorageaccount.blob.core.windows.net/images/police-logo.png
UI_POLICE_FORCE_TAGLINE=Metropolitan Police - Working Together for a Safer London
```

## Security Considerations

1. **Logo URLs**: Ensure logo URLs are accessible from your application's network
2. **Key Vault**: Use Azure Key Vault for sensitive configuration values
3. **HTTPS**: Always use HTTPS URLs for external image hosting
4. **Access Control**: Verify that only authorized administrators can modify these settings

## Troubleshooting

### Logo Not Displaying
- Verify the URL is accessible from your application
- Check that the image format is supported (PNG, JPG, SVG)
- Ensure the user has admin permissions

### Tagline Not Showing
- Confirm the environment variable is set correctly
- Verify the user has admin permissions
- Check that the variable contains valid text

### Changes Not Reflecting
- Restart your Azure App Service after changing environment variables
- Clear browser cache if testing locally
- Verify the environment variables are properly set in Azure

## Support

For technical support with environment variable configuration, please contact your Azure administrator or refer to the Azure documentation for your specific hosting service.
