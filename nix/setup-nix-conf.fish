#!/usr/bin/env fish
# Generates /etc/nix/nix.custom.conf with secrets from 1Password

set -l token (op read "op://Personal/Nix GitHub Token/password" 2>/dev/null)
if test $status -ne 0
    echo "Failed to read token from 1Password. Is 'op' signed in?"
    return 1
end

printf 'substituters = https://mirrors.nju.edu.cn/nix-channels/store?priority=10 https://mirror.sjtu.edu.cn/nix-channels/store?priority=20 https://mirrors.ustc.edu.cn/nix-channels/store?priority=30 https://cache.nixos.org?priority=40 https://install.determinate.systems?priority=50
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
access-tokens = github.com=%s
max-substitution-jobs = 256
http-connections = 256
connect-timeout = 5
stalled-download-timeout = 60
narinfo-cache-negative-ttl = 0
keep-outputs = true
auto-optimise-store = true
' $token | sudo tee /etc/nix/nix.custom.conf >/dev/null

echo "nix.custom.conf updated."
