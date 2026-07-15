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

Group write covers normal file changes but not owner-only metadata operations such as preserving timestamps and extended attributes. See [Troubleshooting metadata permission errors](#9-troubleshooting-metadata-permission-errors) if upgrades fail with `utimensat`, `apply2files`, or `rb_file_s_rename`.

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

## 7. Casks (Caskroom + `/Applications`)

Cask installs drop subdirs under `/opt/homebrew/Caskroom` and apps under `/Applications`. Both inherit the installer's umask, so other `brew` group members can't replace them on upgrade/uninstall (`Error: Permission denied @ apply2files`).

Fix existing casks (once, any admin):

```bash
sudo chgrp -R brew /opt/homebrew/Caskroom
sudo chmod -R g+w /opt/homebrew/Caskroom

# Resolve cask app symlinks → real /Applications paths, fix each
find /opt/homebrew/Caskroom -maxdepth 3 -name '*.app' -type l -exec readlink {} \; \
  | while read t; do [ -e "$t" ] && sudo chgrp -R brew "$t" && sudo chmod -R g+w "$t"; done
```

Prevent recurrence — set `umask 002` in each brew user's shell rc so new files land group-writable:

```fish
# ~/.config/fish/config.fish
umask 002
```

```bash
# ~/.bashrc or ~/.zshrc
umask 002
```

Re-run the `find` block after installing new casks until every user's `umask` is `002`.

## 8. Verify (from each user)

```bash
brew update
brew install hello && brew uninstall hello
```

Log out and back in after adding users to the group.

## 9. Troubleshooting metadata permission errors

Errors such as these mean the formula or staging directory belongs to another Homebrew user:

```text
Permission denied @ rb_file_s_rename
Permission denied @ apply2files
cp: utimensat: ... Permission denied
```

`chgrp brew` and `chmod g+w` are not enough for these operations. Homebrew preserves timestamps and extended attributes, which require ownership or the macOS ACL permissions `writeattr` and `writeextattr`.

Stop other Homebrew processes, then paste this Fish function. Pass the failing formula name, for example `brew_repair_permissions fontconfig`. It repairs existing entries, adds inheritable permissions for future entries, removes only that formula's failed staging directory, and retries the upgrade.

```fish
function brew_repair_permissions
    if test (count $argv) -ne 1
        echo "usage: brew_repair_permissions FORMULA" >&2
        return 2
    end

    set -l formula $argv[1]
    set -l prefix (brew --prefix)
    set -l dir_acl 'group:brew allow add_file,add_subdirectory,delete_child,writeattr,writeextattr,file_inherit,directory_inherit'
    set -l file_acl 'group:brew allow writeattr,writeextattr'

    sudo chgrp -R brew $prefix
    sudo chmod -R g+rwX $prefix
    sudo find $prefix -type d -exec chmod +a $dir_acl '{}' +
    sudo find $prefix -type f -exec chmod +a $file_acl '{}' +

    rm -rf "$prefix/var/homebrew/tmp/.cellar/$formula"
    brew upgrade $formula
end

brew_repair_permissions fontconfig
functions --erase brew_repair_permissions
```

The ACL applies only to members of the trusted `brew` group. The directory ACL inherits into newly created files and subdirectories, avoiding ownership changes between Homebrew users.

## Notes

- Re-run step 2 if permissions break after `brew update` or after installing new taps. Git operations and `brew update` can reset permissions on `.git` internals, causing "Permission denied" errors for other users.
- Re-run step 2 if `brew update` fails under `/opt/homebrew/Library/Taps/*/*/.git`, such as `FETCH_HEAD: Permission denied` or `TMP_FETCH_FAILURES: Permission denied`.
- Re-run step 4 after installing new taps. The glob `/opt/homebrew/Library/Taps/*/*` only catches taps that exist at the time it's run — new taps cause `fatal: not in a git directory` errors for other users.
- Re-run the lock-directory part of step 3 if you see `Error: Permission denied @ rb_sysopen - /opt/homebrew/var/homebrew/locks/*.formula.lock`. This means a lock file was created without group write permission, usually by a shell with `umask 022`.
- Re-run step 7 after any user with `umask 022` installs a cask. Quit the app first if it's running (`osascript -e 'quit app "Name"'`) — `brew` can't replace an in-use binary.
- Casks requiring system-level install still need admin privileges.
