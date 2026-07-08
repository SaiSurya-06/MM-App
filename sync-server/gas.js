/**
 * Google Apps Script Key-Value Sync Backend
 * 
 * Instructions to deploy:
 * 1. Go to https://script.google.com/ and log in with your Google account.
 * 2. Click "New Project" to open a new script editor.
 * 3. Delete any existing code and paste this entire code block.
 * 4. Click "Save project" (floppy disk icon).
 * 5. Click "Deploy" (blue button at top right) -> "New Deployment".
 * 6. Click the gear icon next to "Select type" and select "Web App".
 * 7. Set the deployment options:
 *    - Description: Money Manager Sync Server
 *    - Execute as: "Me" (your email)
 *    - Who has access: "Anyone"
 * 8. Click "Deploy". Authorize any necessary Google permissions.
 * 9. Copy the generated "Web App URL" (ends in /exec).
 * 10. Paste this URL into the "Custom Sync Server URL" field in the Money Manager app!
 */

function doGet(e) {
  var key = e.parameter.key;
  if (!key) {
    return ContentService.createTextOutput("Error: Missing key parameter")
      .setMimeType(ContentService.MimeType.TEXT);
  }
  
  var val = PropertiesService.getScriptProperties().getProperty(key);
  if (val === null) {
    return ContentService.createTextOutput("404")
      .setMimeType(ContentService.MimeType.TEXT);
  }
  
  return ContentService.createTextOutput(val)
    .setMimeType(ContentService.MimeType.TEXT);
}

function doPost(e) {
  var key = e.parameter.key;
  if (!key) {
    return ContentService.createTextOutput("Error: Missing key parameter")
      .setMimeType(ContentService.MimeType.TEXT);
  }
  
  var val = e.postData.contents;
  if (val === undefined || val === null) {
    return ContentService.createTextOutput("Error: Missing body content")
      .setMimeType(ContentService.MimeType.TEXT);
  }
  
  PropertiesService.getScriptProperties().setProperty(key, val);
  return ContentService.createTextOutput("true")
    .setMimeType(ContentService.MimeType.TEXT);
}
