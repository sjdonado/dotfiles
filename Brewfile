# Homebrew installs what is macOS-specific: GUI applications, system libraries,
# and CLIs with no cross-platform equivalent. Everything a Linux box needs too
# lives in mise.toml instead, so it is declared once and versioned once.
#
# Removed from here when mise took them over: bat, node, fd, fzf, ripgrep, uv,
# worktrunk, pnpm, bun, ttt, opencode, codex. Dropping the line does not
# uninstall anything, so on a machine provisioned before this change run
# `brew uninstall` for them once, or keep both and let PATH order decide.
#
# Most of the CLIs left here do have a mise backend (act, awscli, caddy, cmake,
# cloudflared, duckdb, flyctl, gh, git-lfs, golangci-lint, grpcurl, mailpit,
# mkcert, pipx, staticcheck, stripe-cli, supabase, bombardier, curlie and more).
# They stay on Homebrew anyway: none of them is needed on the Linux box, moving
# them saves no shell code, and some are not the same tool under the same name
# (mise's `coreutils` is uutils, not GNU). The split is by platform, not by
# which package manager happens to be able.
tap "amberframework/micrate", trusted: true
tap "coder/coder", trusted: true
tap "grafana/grafana", trusted: true
tap "ory/tap", trusted: true
tap "rjyo/moshi", trusted: true
tap "supabase/tap", trusted: true
tap "tunneltodev/tap", trusted: true
tap "xcodesorg/made"
# Run your GitHub Actions locally
brew "act"
# Mozilla CA certificate store
brew "ca-certificates"
# Installs everything in mise.toml: the cross-platform half of this setup
brew "mise"
# Cryptography and SSL/TLS Toolkit
brew "openssl@3"
# Official Amazon AWS command-line interface
brew "awscli"
# Get/set bluetooth power and discoverable state
brew "blueutil"
# Cross-platform HTTP benchmarking tool
brew "bombardier"
# Powerful, enterprise-ready, open source web server with automatic HTTPS
brew "caddy"
# Library for manipulating PNG images
brew "libpng"
# Low-level library for pixel manipulation
brew "pixman"
# Vector graphics library with cross-device output support
brew "cairo"
# Tool for emulating mouse and keyboard events
brew "cliclick"
# CLI tool for Cloudflare Workers
brew "cloudflare-wrangler"
# Cloudflare Tunnel client (formerly Argo Tunnel)
brew "cloudflared"
# Cross-platform make
brew "cmake"
# Dependency manager for Cocoa projects
brew "cocoapods"
# GNU File, Shell, and Text utilities
brew "coreutils"
# Package compiler and linker metadata toolkit
brew "pkgconf"
# Fast and statically typed, compiled language with Ruby-like syntax
brew "crystal"
# Power of curl, ease of use of httpie
brew "curlie"
# Pack, ship and run any application as a lightweight container
brew "docker", link: false
# Docker CLI plugin for extended build capabilities with BuildKit
brew "docker-buildx"
# Isolated development environments using Docker
brew "docker-compose"
# Embeddable SQL OLAP Database Management System
brew "duckdb"
# Select default apps for documents and URL schemes on macOS
brew "duti"
# User-friendly command-line shell for UNIX-like operating systems
brew "fish"
# Command-line tools for fly.io services
brew "flyctl"
# GNU awk utility
brew "gawk"
# Library and utilities for processing GIFs
brew "giflib"
# GitHub command-line tool
brew "gh"
# Syntax-highlighting pager for git and diff output
brew "git-delta"
# Git extension for versioning large files
brew "git-lfs"
# GNU implementation of the famous stream editor
brew "gnu-sed"
# GNU Transport Layer Security (TLS) Library
brew "gnutls"
# Fast linters runner for Go
brew "golangci-lint"
# Like cURL, but for gRPC
brew "grpcurl"
# OpenType text shaping engine
brew "harfbuzz"
# Agent multiplexer that lives in your terminal
brew "herdr"
# Improved top (interactive process viewer)
brew "htop"
# Image manipulation library
brew "jpeg"
# Library for interacting with JSON
brew "jsoncpp"
# Lightweight application-protocol for resource-constrained devices
brew "libcoap"
# Postgres C API library
brew "libpq"
# Framework for layout and rendering of i18n text
brew "pango"
# Library to render SVG files using Cairo
brew "librsvg"
# Next-gen compiler infrastructure
brew "llvm"
# Powerful, lightweight programming language
brew "lua"
# Package manager for the Lua programming language
brew "luarocks"
# Keep your Mac's application settings in sync
brew "mackup"
# Web and API based SMTP testing
brew "mailpit"
# Simple tool to make locally trusted development certificates
brew "mkcert"
# Deep clean and optimize your Mac
brew "mole"
# Remote terminal application
brew "mosh"
# Ambitious Vim-fork focused on extensibility and agility
brew "neovim"
# Port scanning utility for large networks
brew "nmap"
# Libraries for security-enabled client and server applications
brew "nss"
# Development kit for the Java programming language
brew "openjdk"
# Development kit for the Java programming language
brew "openjdk@11"
# Development kit for the Java programming language
brew "openjdk@17"
# 7-Zip (high compression file archiver) implementation
brew "p7zip"
# Execute binaries from Python packages in isolated environments
brew "pipx"
# PDF rendering library (based on the xpdf-3.0 code base)
brew "poppler"
# Monitor data's progress through a pipe
brew "pv"
# Interpreted, interactive, object-oriented programming language
brew "python@3.12"
# Ruby version manager
brew "rbenv"
# Rust toolchain installer
brew "rustup"
# Fast and accurate code counter with complexity and COCOMO estimates
brew "scc"
# Display and control your Android device
brew "scrcpy"
# Penetration testing for SQL injection and database servers
brew "sqlmap"
# State of the art linter for the Go programming language
brew "staticcheck"
# Command-line tool for Stripe
brew "stripe-cli"
# SMTP command-line test tool
brew "swaks"
# User interface to the TELNET protocol
brew "telnet"
# Anonymizing overlay network for TCP
brew "tor"
# Display directories as trees (with optional color/HTML output)
brew "tree"
# Watch files and take action when they change
brew "watchman"
# Command-line XML and HTML beautifier and content extractor
brew "xq"
# Programming language designed for robustness, optimality, and clarity
brew "zig"
# Programming language designed for robustness, optimality, and clarity
brew "zig@0.15"
# Database migration tool written in Crystal
brew "amberframework/micrate/micrate", trusted: true
# Grafana Cloud CLI
brew "grafana/grafana/gcx", trusted: true
# Use Ory from your terminal!
brew "ory/tap/cli", trusted: true
# Portable daemon + CLI that bridges AI coding agents to the Moshi mobile app
brew "rjyo/moshi/moshi-hook", trusted: true
# Supabase CLI
brew "supabase/tap/supabase", trusted: true
# Password manager that keeps all passwords secure behind one password
cask "1password"
# Command-line interface for 1Password
cask "1password-cli"
# Command-line tools for building and debugging Android apps
cask "android-commandlinetools"
# Display management tool
cask "betterdisplay"
# Web browser
cask "firefox"
# Set of tools to manage resources and applications hosted on Google Cloud
cask "gcloud-cli"
# Terminal emulator that uses platform-native UI and GPU acceleration
cask "ghostty"
# Chromium-based web browser
cask "helium-browser"
# App to manage software development and track bugs
cask "linear"
# Reverse proxy, secure introspectable tunnels to localhost
cask "ngrok"
# VPN client for secure internet access and private browsing
cask "nordvpn"
# App to write, plan, collaborate, and get organised
cask "notion"
# Replacement for Docker Desktop
cask "orbstack"
# Team communication and collaboration software
cask "slack"
# Native database client for many database types
cask "tablepro"
# Mesh VPN based on WireGuard
cask "tailscale-app"
# Desktop client for Telegram messenger
cask "telegram-desktop"
# REST, GraphQL and gRPC client
cask "yaak"
go "github.com/air-verse/air"
go "github.com/bootdotdev/bootdev"
go "github.com/golangci/golangci-lint/v2/cmd/golangci-lint"
go "github.com/pressly/goose/v3/cmd/goose"
go "zen-habit/server"
