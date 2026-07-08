# Money Manager Sync Server

This directory contains the files needed to run your own Key-Value sync server for the Money Manager app, completely free.

Using a custom sync server offers:
1. **100% Privacy**: Your financial ledgers are only synced through your own private database.
2. **Reliability**: No ISP blocking or rate limit issues from shared public endpoints.

---

## Method 1: Google Apps Script (Recommended - 100% Free & No Setup)

Google Apps Script runs in the Google Cloud for free under your own Google account. It requires zero server maintenance.

1. Open [Google Apps Script](https://script.google.com/) and log in with your Google account.
2. Click **New Project**.
3. Open `gas.js` in this directory, copy its entire contents, and paste them into the script editor (replacing any existing code).
4. Click the **Save** (floppy disk) icon.
5. Click **Deploy** -> **New Deployment**.
6. Select **Web App** as the deployment type (click the gear icon to select it if not shown).
7. Configure:
   - **Execute as**: "Me" (your Google account)
   - **Who has access**: "Anyone"
8. Click **Deploy**. Authorize Google permissions.
9. Copy the generated **Web App URL** (e.g., `https://script.google.com/macros/s/xxxx/exec`).
10. Open the Money Manager app, go to **Partner Sharing** -> **Custom Sync Server** (under Advanced settings), paste the URL, and click **Save**.

---

## Method 2: Self-hosted Node.js Server

You can host the Node.js Express server on any free hosting service (like Render, Railway, fly.io) or run it locally.

### Local setup:
1. Make sure you have [Node.js](https://nodejs.org/) installed.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the server:
   ```bash
   npm start
   ```
4. Expose the server (using localtunnel or ngrok if testing across networks) and use the endpoint URL in the app settings.
