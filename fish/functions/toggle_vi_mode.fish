function toggle_vi_mode
    if test "$fish_key_bindings" = "fish_vi_key_bindings"
        fish_default_key_bindings
    else
        fish_vi_key_bindings
    end
end
