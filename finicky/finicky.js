export default {
  defaultBrowser: "Safari",
  handlers: [
    {
      match: ["localhost*"],
      browser: "Chromium",
    },
    {
      match: ["*autarc.energy"],
      browser: "Chromium",
    },
    {
      match: ["*fly.dev"],
      browser: "Chromium",
    },
  ],
};
