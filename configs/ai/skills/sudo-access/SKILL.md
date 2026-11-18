---
name: sudo-access
description: what to do when a task needs sudo/root access
---

# sudo access

if a command needs sudo, don't run it directly and don't ask me to type a password. use the polkit agent instead, it'll pop a prompt and I accept or deny it right there.

if the polkit prompt gets denied, stop and tell me instead of retrying with another method.

if you know you'll need several sudo steps, batch them into one command (e.g. chain with `&&` or wrap in a single `sudo sh -c '...'`) instead of running sudo separately for each, so I only get prompted once instead of repeatedly.
