#!/bin/sh

printf "Windows-Specific Commands

Usage: igm wsl ${RED}|${NC} igm wsl [command] [option]

[${BLUE}WSL Networking${NC}]
  igm wsl mirror                    Toggle WSL mirrored networking mode (localhost port forwarding).
  igm wsl mirror status             Show current networking mode status.
"
