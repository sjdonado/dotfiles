// Background script for BrowserRedirect Helper extension
// Communicates with Hammerspoon BrowserRedirect spoon

const HAMMERSPOON_URL = 'http://localhost:8080/redirect'; // Default port, will be auto-detected

let hammerspoonPort = null;

// Auto-detect Hammerspoon server port on startup
chrome.runtime.onStartup.addListener(detectHammerspoonPort);
chrome.runtime.onInstalled.addListener(detectHammerspoonPort);

// Listen for navigation events
chrome.webNavigation.onBeforeNavigate.addListener((details) => {
  // Only process main frame navigations (not iframes)
  if (details.frameId === 0) {
    sendUrlToHammerspoon(details.url, details.tabId);
  }
});

// Listen for messages from content script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'interceptUrl') {
    sendUrlToHammerspoon(request.url, sender.tab.id);
    sendResponse({ status: 'sent' });
  } else if (request.action === 'getPort') {
    sendResponse({ port: hammerspoonPort });
  }
});

async function detectHammerspoonPort() {
  // Try common ports where Hammerspoon might be running
  const portsToTry = [8080, 8081, 8082, 3000, 3001, 5000, 8000];

  for (const port of portsToTry) {
    try {
      const response = await fetch(`http://localhost:${port}/redirect`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ test: true })
      });

      if (response.ok) {
        hammerspoonPort = port;
        console.log(`BrowserRedirect: Found Hammerspoon server on port ${port}`);
        return;
      }
    } catch (error) {
      // Port not available, continue trying
    }
  }

  console.log('BrowserRedirect: Could not detect Hammerspoon server');
}

async function sendUrlToHammerspoon(url, tabId) {
  if (!hammerspoonPort) {
    await detectHammerspoonPort();
  }

  if (!hammerspoonPort) {
    console.log('BrowserRedirect: No Hammerspoon server found');
    return;
  }

  try {
    const response = await fetch(`http://localhost:${hammerspoonPort}/redirect`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        url: url,
        tabId: tabId,
        timestamp: Date.now()
      })
    });

    if (response.ok) {
      const result = await response.json();
      if (result.redirect) {
        // Close the current tab since it will be redirected
        chrome.tabs.remove(tabId);
      }
    }
  } catch (error) {
    console.error('BrowserRedirect: Failed to communicate with Hammerspoon:', error);
  }
}

// Periodic health check
setInterval(() => {
  if (hammerspoonPort) {
    fetch(`http://localhost:${hammerspoonPort}/health`)
      .catch(() => {
        console.log('BrowserRedirect: Lost connection to Hammerspoon server');
        hammerspoonPort = null;
      });
  }
}, 30000); // Check every 30 seconds
