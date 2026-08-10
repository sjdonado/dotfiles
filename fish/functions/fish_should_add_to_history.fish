# Defining this hook makes fish delegate ALL history decisions here, including
# its built-in "a leading space is not saved" rule, so that rule is reimplemented
# below. Dropping it would silently stop space-prefixed commands from being
# skipped everywhere else.
function fish_should_add_to_history
    # herdr types `claude --resume=<id>` into the pane when it restores a session.
    # That is machine-generated and never worth recalling, and it otherwise fills
    # history with one entry per restored pane.
    string match -qr -- '^\s*claude\s+.*--resume' $argv[1]; and return 1

    # fish's default behavior, restored.
    string match -qr -- '^ ' $argv[1]; and return 1

    return 0
end
