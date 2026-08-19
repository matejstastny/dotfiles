---
name: remote-hosts
description: how to acess remote computers
---

# remote host access

my remote machines are defined in `~/.config/remote/hosts.toml`, one `[[hosts]]` entry
per machine with fields

## steps

1. Read `~/.config/remote/hosts.toml` and find the entry matching
2. Connect with `sshpass` when a `password` is present:

```bash
sshpass -p '<password>' ssh <user>@<host>
```

If `jump` is set, route through that host with `-J`:

```bash
sshpass -p '<password>' ssh -J <jump_user>@<jump_host> <user>@<host>
```

3. If there's no `password` field, connect with plain `ssh <user>@<host>` (key-based auth)
4. Default to `path` as the working directory on the remote once connected, unless Ellie asks for somewhere else.

Never print the resolved password back to Ellie or into commit messages/logs!
