// Content script for BrowserRedirect Helper extension
// Intercepts link clicks and form submissions before navigation

(function() {
  'use strict';

  let isProcessing = false;
  const processedUrls = new Set();

  // Function to send URL to background script
  function interceptUrl(url) {
    if (isProcessing || processedUrls.has(url)) {
      return;
    }

    isProcessing = true;
    processedUrls.add(url);

    // Clean up old URLs to prevent memory leak
    if (processedUrls.size > 100) {
      processedUrls.clear();
    }

    chrome.runtime.sendMessage({
      action: 'interceptUrl',
      url: url
    }, (response) => {
      isProcessing = false;
      if (chrome.runtime.lastError) {
        console.error('BrowserRedirect: Error sending URL:', chrome.runtime.lastError);
      }
    });
  }

  // Intercept link clicks
  function handleClick(event) {
    const target = event.target.closest('a[href]');
    if (!target) return;

    const href = target.href;

    // Only intercept http/https URLs
    if (!href || (!href.startsWith('http://') && !href.startsWith('https://'))) {
      return;
    }

    // Don't intercept if it's the same domain
    if (new URL(href).hostname === window.location.hostname) {
      return;
    }

    // Prevent default navigation
    event.preventDefault();
    event.stopPropagation();

    // Send URL to Hammerspoon
    interceptUrl(href);
  }

  // Intercept form submissions that might redirect
  function handleSubmit(event) {
    const form = event.target;
    if (!form.action) return;

    const action = form.action;

    // Only intercept external form submissions
    if (action.startsWith('http://') || action.startsWith('https://')) {
      if (new URL(action).hostname !== window.location.hostname) {
        interceptUrl(action);
      }
    }
  }

  // Monitor for programmatic navigation
  function monitorNavigation() {
    const originalPushState = history.pushState;
    const originalReplaceState = history.replaceState;

    history.pushState = function(state, title, url) {
      if (url && (url.startsWith('http://') || url.startsWith('https://'))) {
        interceptUrl(url);
      }
      return originalPushState.apply(this, arguments);
    };

    history.replaceState = function(state, title, url) {
      if (url && (url.startsWith('http://') || url.startsWith('https://'))) {
        interceptUrl(url);
      }
      return originalReplaceState.apply(this, arguments);
    };

    // Listen for popstate events
    window.addEventListener('popstate', function(event) {
      if (event.state && event.state.url) {
        interceptUrl(event.state.url);
      }
    });
  }

  // Add event listeners
  document.addEventListener('click', handleClick, true);
  document.addEventListener('submit', handleSubmit, true);

  // Monitor for navigation changes
  monitorNavigation();

  // Handle dynamic content - use mutation observer for links added after page load
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      mutation.addedNodes.forEach(function(node) {
        if (node.nodeType === Node.ELEMENT_NODE) {
          // Check if the added node is a link or contains links
          const links = node.matches && node.matches('a[href]') ? [node] :
                       node.querySelectorAll ? node.querySelectorAll('a[href]') : [];

          links.forEach(function(link) {
            link.addEventListener('click', handleClick, true);
          });
        }
      });
    });
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true
  });

  // Clean up on page unload
  window.addEventListener('beforeunload', function() {
    observer.disconnect();
    processedUrls.clear();
  });

  console.log('BrowserRedirect Helper: Content script loaded');
})();
