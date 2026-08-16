// Finicky is the default browser: it receives every link the system opens, from
// Ghostty or anywhere else, and routes it by destination.
//
// Nothing here reaches Safari directly. LaunchServices opens Safari in a new
// window for every externally opened URL, whatever AppleWindowTabbingMode and
// Safari's TabCreationPolicy say, and going through Finicky does not change that:
// measured, a link through Finicky still lands in a new window. Scripted tab
// creation is the only thing that produces a tab, so the default is SafariTab, an
// AppleScript app built by macos.sh from macos/safari-tab.applescript that adds a
// tab to Safari's front window.

export default {
  options: {
    // No menu bar icon: this is plumbing, there is nothing to click.
    hideIcon: true,
    // Stay resident. Relaunching per link is what makes Finicky flash to the
    // front while it resolves one.
    keepRunning: true,
    checkForUpdates: false,
    logRequests: true,
  },

  defaultBrowser: { name: "co.donado.safaritab", appType: "bundleId" },

  rewrite: [
    {
      // A pull request belongs in Linear's review UI. linear.review keeps the
      // owner/repo/pull/number path and redirects to linear.app/review, so
      // swapping the host is the whole rewrite.
      //
      // It has to go through the browser rather than straight to the Linear app:
      // handing the app a bare URL skips the redirect that resolves which
      // workspace the review belongs to, and it fails with "Authentication error,
      // this workspace does not exist". Opened in the browser, the redirect runs
      // and Linear hands off to the app itself.
      match: /^https:\/\/github\.com\/[^/]+\/[^/]+\/pull\/\d+/,
      url: (url) => `https://linear.review${url.pathname}${url.search}${url.hash}`,
    },
  ],

  handlers: [
    {
      // Local dev servers and Cloudflare preview deployments go to Helium, keeping
      // Safari's session and extensions out of whatever is being tested.
      match: [
        /^https?:\/\/(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])(:\d+)?(\/|$)/,
        /^https?:\/\/([^/]+\.)?(pages|workers)\.dev(\/|$)/,
      ],
      browser: "net.imput.helium",
    },
  ],
};
