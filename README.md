# logic-app-http-download

This repo contains the artifacts necessary to deploy:
* a Python Flask web app to a Azure Web App that serves out files and the file listing from the /files directory.
* an Azure Key Vault that contains a certifcate that can be used for client certificate authentication to the web application
* an Azure Storage Account to store files from the web application
* an Azure Logic App that uses the created certificate to:
  1. get the file listing from the Python web application
  1. download those files to the create blob storage account
