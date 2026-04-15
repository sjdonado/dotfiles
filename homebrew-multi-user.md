# Homebrew Multi-User Setup (Apple Silicon)

Ref: https://gist.github.com/drwhitt/c6a8ccfe21d30f97e7ddae9636a86eb6

## 1. Create `brew` group and add users

```bash
sudo dseditgroup -o create -i 300 brew
sudo dseditgroup -o edit -a USERNAME -t user brew  # repeat per user
```

Verify: `dseditgroup -o checkmember -m USERNAME brew`

## 2. Set group ownership

```bash
sudo chgrp -R brew /opt/homebrew
sudo chmod -R g+w /opt/homebrew
```

## 3. Run `brew doctor` from each user account

Log in as each user in the `brew` group and run `brew doctor`. It will report directories with incorrect ownership:

```
$ brew doctor
Warning: The following directories are not writable by your user:
/opt/homebrew/bin
/opt/homebrew/etc
/opt/homebrew/include
/opt/homebrew/lib
/opt/homebrew/opt
/opt/homebrew/sbin
/opt/homebrew/share
/opt/homebrew/var/homebrew/linked
/opt/homebrew/var/homebrew/locks

You should change the ownership of these directories to your user.
  sudo chown -R $(whoami) /opt/homebrew/bin /opt/homebrew/etc ...
```

**Don't run the `chown` command above.** Instead, as an admin, set ownership to the `brew` group:

```bash
sudo chgrp -R brew /opt/homebrew/bin /opt/homebrew/etc /opt/homebrew/include /opt/homebrew/lib /opt/homebrew/opt /opt/homebrew/sbin /opt/homebrew/share /opt/homebrew/var/homebrew/linked /opt/homebrew/var/homebrew/locks
sudo chmod -R g+w /opt/homebrew/bin /opt/homebrew/etc /opt/homebrew/include /opt/homebrew/lib /opt/homebrew/opt /opt/homebrew/sbin /opt/homebrew/share /opt/homebrew/var/homebrew/linked /opt/homebrew/var/homebrew/locks
```

## 4. Mark Homebrew directories as git safe (run from each non-owner account)

Git refuses to operate in directories owned by another user. Each user (except the one who installed Homebrew) must run this from their own account:

```fish
for dir in /opt/homebrew /opt/homebrew/Library/Taps/*/*; git config --global --add safe.directory $dir; end
```

## 5. Fix cache (run from each user account)

```bash
sudo chgrp -R brew $(brew --cache)
sudo chmod -R g+w $(brew --cache)
```

## 6. Frameworks directory (once, any admin)

```bash
sudo install -d -o $(whoami) -g brew /opt/homebrew/Frameworks
sudo chmod g+w /opt/homebrew/Frameworks
```

## 7. Verify (from each user)

```bash
brew update
brew install hello && brew uninstall hello
```

Log out and back in after adding users to the group.

## Notes

- Re-run step 2 if permissions break after `brew update` or after installing new taps. Git operations and `brew update` can reset permissions on `.git` internals, causing "Permission denied" errors for other users.
- Re-run step 4 after installing new taps. The glob `/opt/homebrew/Library/Taps/*/*` only catches taps that exist at the time it's run — new taps cause `fatal: not in a git directory` errors for other users.
- Casks requiring system-level install still need admin privileges.
