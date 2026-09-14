# Long-running processes

Use `pty_spawn` instead of shell backgrounding or fixed `sleep` polling for interactive commands, servers, watchers, and commands that may outlive a normal shell call. Set `notifyOnExit` for finite jobs, keep the returned session ID, use `pty_read` for output, `pty_write` for input, and `pty_kill` to stop the session. After spawning with `notifyOnExit`, continue independent work and wait for the `<pty_exited>` message instead of polling only for completion.
