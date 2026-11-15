# PR demo media

Make the changed behavior easy to follow: show the starting state, the user's actions and the resulting UI. Prefer a short video for interactions or transitions; use screenshots for states that stand alone. Open-pr requires a demo disposition for functional changes; this capture recipe applies when media demonstrates that behavior. A reproducible command can demonstrate a nonvisual contract. Capture restrictions do not waive verification of the promised behavior.

## Prepare

- Choose a few scenes covering the changed behavior and relevant failure or recovery paths. Use fictional data in a local or authorized test environment. Keep unrelated panels closed; explain a necessary full-width view in its caption.
- For a bug fix, capture comparable before and after evidence using the same screen, data and trigger when feasible. For responsive or visual changes, cover the viewport sizes affected by the change. Exercise materially changed loading, empty, error and permission states when relevant. Name any missing state or baseline rather than presenting a happy-path clip as complete coverage.
- Finish login and fixture setup before recording. Use a fresh browser context when supported by the permitted browser workflow; do not record authentication or reuse personal browsing state for a scripted demo.
- Use the browser or device tools required by the current session. Choose a recorder that captures the UI being demonstrated, including native menus. Browser-only screencasts can omit native select popups; confirm the capture includes them before relying on it. If the required tools cannot capture a scene, report the limitation and provide useful permitted evidence without claiming that scene was recorded.
- For scripted fixtures, use a unique `demo-<pr-or-branch>-<run>` prefix. Fail on a pre-existing fixture rather than overwriting it. Track created IDs from supported creation responses so cleanup targets only this run. Use project-approved fixture helpers rather than assuming an API shape.

## Capture

- Start recording after setup. Demonstrate actions through real clicks, typing, scrolling and keyboard selection. For native selects, show the open menu before choosing an option. Scroll controls into view so the menu is not clipped. Do not set application values through DOM scripts or API calls in place of the interaction being demonstrated.
- Add one short, numbered caption per scene, such as `1 · Starting state`. Use a fixed yellow pill (`#fde047`, dark text, 600 16px system font) at bottom center with enough margin to avoid controls. For web overlays, use `pointer-events: none` and a high z-index. Keep captions legible without covering the outcome. The first caption identifies the PR or branch and relevant setup.
- An optional top-right overlay may show useful observed statistics, such as elapsed time or a measured count. Label units and scope, keep it away from controls, and omit it when no meaningful measurement is available. Never invent telemetry or present an illustrative overlay as application output.
- Injected captions and statistics are presentation overlays only. Keep assertions tied to the application's actual state. Use permitted offline controls for an offline scene and restore connectivity afterward.
- Wait for each real outcome, such as a toast, changed field, saved value or activity entry, then hold it for about 2 to 4 seconds. Scripted demos must fail if the expected application result is wrong; clicks completing successfully are insufficient.
- For screenshots, include enough surrounding UI to establish context and label annotations as annotations. Do not fabricate application states or render a transcript as proof of behavior.

## Optional Linux desktop recording

Use this only when the session permits direct Playwright and desktop automation. It does not override required browser or device tools. Use available dependencies or an approved disposable environment; do not install system packages or change host configuration merely to follow this recipe.

1. Start an owned Xvfb display, for example `Xvfb :99 -screen 0 1440x1080x24 -nolisten tcp`, after checking that the display is free. Set `DISPLAY` for the recording processes only.
2. Launch headed Chromium with `headless: false`, `--window-position=0,0`, `--window-size=1440,1080`, a context with `viewport: null` and locale `en-US`. Type with Playwright's `pressSequentially` and a small delay.
3. Use an ffmpeg build with H.264 encoding; a bundled browser recorder may lack it. Capture the full display so native popups appear:

   ```sh
   ffmpeg -f x11grab -video_size 1440x1080 -framerate 15 -i :99 -c:v libx264 -preset veryfast -pix_fmt yuv420p -crf 26 out.mp4
   ```

4. When native select interaction needs desktop input, focus the owned browser window and use xdotool to click the control, then Down/Return to choose. Translate the control's bounding box to screen coordinates using the actual window origin and browser chrome offset; do not assume viewport coordinates are screen coordinates. Hold the open menu briefly so it is visible in the recording.
5. Keep recorder stdin open and write `q` in a `finally` block; await its exit so the MP4 finalizes. Close only the browser and Xvfb processes created by this run, including after assertion failure.

## Inspect, clean up and attach

- Put fixture deletion and owned-process shutdown in `finally` blocks. Restore changed test settings, remove fixtures by their captured IDs, and query for remaining records with this run's prefix. Confirm zero remain; report cleanup failures without deleting pre-existing data.
- Before attaching, inspect representative frames or an ffmpeg contact sheet, including open native menus and final outcomes. Check readability, pacing, framing and privacy across captions, UI, URLs, notifications and any visible logs. Discard and recapture media containing credentials, verification codes or private data; do not publish it.
- Attach through the supported forge or host attachment mechanism for the authorized PR; with gh, check local help rather than assuming flags are available. For host-owned PR creation, pass supported attachments or references the host can actually access with the body. If attachment is unavailable, report the blocker and retain a safe local artifact without claiming it was delivered. Never insert a placeholder or claim an attachment exists before confirming it in the PR body.
- Under the attachment in `## Demo` or the repository's equivalent section, write one paragraph naming the demonstrated commit SHA, the actual capture method and duration for video, any script-added captions or statistics, the scenes and material limitations. Describe headed Chromium screen recording only when that is what ran. Refresh stale media when a later change alters the behavior shown.
