## Gruvbox Dark theme

if [[ "$COLOR_SCHEME" == "gruvbox" ]]; then
    # Base surfaces (Gruvbox Dark)
    export BASE=0xff282828    # bg0
    export SURFACE=0xff3c3836 # bg1
    export OVERLAY=0xff504945 # bg2
    export MUTED=0xff665c54   # bg3
    export SUBTLE=0xff7c6f64  # gray

    # Text & accents
    export TEXT=0xffebdbb2     # fg
    export CRITICAL=0xfffb4934 # red
    export NOTICE=0xfffabd2f   # yellow
    export WARN=0xfffe8019     # orange
    export SELECT=0xff83a598   # blue
    export GLOW=0xff8ec07c     # aqua
    export ACTIVE=0xffd3869b   # purple

    # Highlight tiers
    export HIGH_LOW=0xff282828
    export HIGH_MED=0xff3c3836
    export HIGH_HIGH=0xff504945

    # Misc
    export BLACK=0xff1d2021
    export TRANSPARENT=0x00000000

    # General bar colors
    export BAR_COLOR=0x80282828
    export BORDER_COLOR=0x80504945
    export ICON_COLOR=$TEXT
    export LABEL_COLOR=$TEXT

    export POPUP_BACKGROUND_COLOR=0xbe3c3836
    export POPUP_BORDER_COLOR=$HIGH_MED

    export SHADOW_COLOR=$TEXT
fi
