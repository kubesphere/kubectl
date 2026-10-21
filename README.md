## kubectl docker image

Minimal image for operating Kubernetes clusters: `kubectl`, `helm` (with the
`helm-mapkubeapis` plugin) and `kustomize`, plus the network troubleshooting
toolset from [nicolaka/netshoot](https://github.com/nicolaka/netshoot) so the same
image can be used for debugging nodes, pods and CNI connectivity.

```bash
docker run -it --rm --net=host --pid=host --privileged kubesphere/kubectl:latest
```

### Bundled tools

| Category | Tools |
|----------|-------|
| Kubernetes | `kubectl`, `helm`, `kustomize`, `calicoctl`, `ctop`, `grpcurl` |
| Network | `tcpdump`, `tshark`, `termshark`, `nmap`, `netcat`, `socat`, `conntrack`, `iperf3`, `mtr`, `trip` (trippy), `ipvsadm`, `ipset`, `nftables`, `iptables` |
| DNS / DHCP | `dig`, `drill`, `fping`, `dhcping`, `swaks` |
| HTTP / TLS | `curl`, `wget`, `httpie`, `openssl`, `fortio`, `websocat` |
| Tracing | `strace`, `ltrace`, `ngrep`, `tcptraceroute`, `iftop`, `iptraf-ng` |

`tcpdump`, `tshark` and `termshark` need `NET_ADMIN`/`NET_RAW` capabilities and,
for host traffic, `--net=host --pid=host`.

### Notes

- The container keeps running as a no-op when started without a command, so it can
  be used as a long-lived debug pod; run `kubectl exec -it <pod> -- bash` (or `zsh`)
  to get a shell.
- `trippy` and `swaks` come from Alpine `edge/testing`; they are installed through a
  pinned `@edge` repository so the rest of the image stays on the stable Alpine branch.
