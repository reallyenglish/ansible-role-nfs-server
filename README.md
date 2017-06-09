# ansible-role-nfs-server

Configures NFSv3 server.

# Requirements

None

# Role Variables

## Common role variables across platforms

| Variable | Description | Default |
|----------|-------------|---------|
| `nfs_server_exports_file` | path to `exports(5)`                          | `{{ __nfs_server_exports_file }}` |
| `nfs_server_exports`      | list of settings of exported path (see below) | `[]` |

### `nfs_server_exports`

This variable is a list of `exports(5)`. Each element is a line of the file and
placed into the file in the same order. An example:

```yaml
nfs_server_exports:
  - /usr/local -network 192.168.1.0/24
  - /cdrom -network 192.168.1.0/24
```

See `exports(5)` of your distribution for the format.

## Role variables specific to FreeBSD and OpenBSD

| Variable | Description | Default |
|----------|-------------|---------|
| `nfs_server_mountd_flags` | extra flags to be passed to `mountd(8)` | `{{ __nfs_server_mountd_flags }}` |
| `nfs_server_nfsd_flags`   | extra flags to be passed to `nfsd(8)`   | `{{ __nfs_server_nfsd_flags }}` |
| `nfs_server_rpc_flags`    | extra flags to be passed to RPC process | `{{ __nfs_server_rpc_flags }}` |

## Role variables specific to Debian/Ubuntu

| Variable | Description | Default |
|----------|-------------|---------|
| `nfs_server_nfs_kernel_server_flags`         | dict to override `nfs_server_nfs_kernel_server_flags_default` | `{}` |
| `nfs_server_nfs_kernel_server_flags_default` | dict of defaults of `/etc/default/nfs-kernel-server` | see below |
| `nfs_server_nfs_common_flags`                | dict to override `nfs_server_nfs_common_flags_default` | `{}` |
| `nfs_server_nfs_common_flags_default`        | dict of defaults of `/etc/default/nfs-common` | see below |

### `nfs_server_nfs_kernel_server_flags_default`

```yaml
nfs_server_nfs_kernel_server_flags_default:
  RPCNFSDCOUNT: 8
  RPCNFSDPRIORITY: 0
  RPCMOUNTDOPTS: "--manage-gids"
  NEED_SVCGSSD: ""
  RPCSVCGSSDOPTS: ""
  RPCNFSDOPTS: ""
```

### `nfs_server_nfs_common_flags_default`

```
nfs_server_nfs_common_flags_default:
  STATDOPTS: ""
  NEED_GSSD: ""
```

## Debian

| Variable | Default |
|----------|---------|
| `nfs_server_exports_file` | `/etc/exports` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__nfs_server_exports_file` | `/etc/exports` |
| `__nfs_server_mountd_flags` | `""` |
| `__nfs_server_nfsd_flags` | `""` |
| `__nfs_server_rpc_flags` | `""` |

## OpenBSD

| Variable | Default |
|----------|---------|
| `__nfs_server_exports_file` | `/etc/exports` |
| `__nfs_server_mountd_flags` | `-tun 4` |
| `__nfs_server_nfsd_flags` | `""` |
| `__nfs_server_rpc_flags` | `""` |

# Dependencies

None

# Example Playbook

```yaml
- hosts: localhost
  roles:
    - ansible-role-nfs-server
  vars:
    nfs_server_exports: "{% if ansible_os_family == 'FreeBSD' or ansible_os_family == 'OpenBSD' %}[ '/usr/local -network 192.168.1.0/24' ]{% elif ansible_os_family == 'Debian' %}[ '/usr/local 192.168.1.0/24' ]{% endif %}"
    nfs_server_mountd_flags: "{% if ansible_os_family == 'FreeBSD' %}-r{% endif %}"
    nfs_server_nfsd_flags: -tun 5
    nfs_server_rpc_flags: "{% if ansible_os_family == 'FreeBSD'%}-h {{ ansible_default_ipv4.address }}{% endif %}"

    # Debian
    nfs_server_nfs_kernel_server_flags:
      RPCNFSDCOUNT: 4
```

# License

```
Copyright (c) 2017 Tomoyuki Sakurai <tomoyukis@reallyenglish.com>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <tomoyukis@reallyenglish.com>

This README was created by [qansible](https://github.com/trombik/qansible)
