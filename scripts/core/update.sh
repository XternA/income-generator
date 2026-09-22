#!/bin/sh

CORE_apply_update() {
    _target="$1"
    _rc=0

    if [ -n "$_target" ]; then
        git fetch --depth=1 origin "+refs/tags/$_target:refs/tags/$_target" --force --quiet 2>/dev/null \
            && git reset --hard "$_target" --quiet 2>/dev/null
        _rc=$?
    else
        git fetch --quiet 2>/dev/null && git reset --hard --quiet 2>/dev/null
        _rc=$?
        if [ "$_rc" -eq 0 ]; then
            if git symbolic-ref --quiet --short HEAD >/dev/null 2>&1; then
                git pull --quiet 2>/dev/null
            else
                _branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
                [ -n "$_branch" ] || _branch="origin/main"
                git checkout -B "${_branch#origin/}" "$_branch" --quiet 2>/dev/null
            fi
            _rc=$?
        fi
    fi

    return "$_rc"
}
