# Greengrass Nucleus Lite: v2.4.0 → v2.6.0

Bumps the Greengrass Nucleus Lite ("GGL") version pulled by the installer scripts from
`v2.4.0` to `v2.6.0` (latest release, published 2026-06-19 by
[aws-greengrass/aws-greengrass-lite](https://github.com/aws-greengrass/aws-greengrass-lite)).

Nucleus Classic (Java) is not version-pinned in this repo — it's installed via a script
the /IOTCONNECT Web UI generates at device-creation time, so it's unaffected.

### Files changed
- `installer/ubuntu/device-setup.sh`
- `installer/imx/device-setup.sh`
- `installer/openstlinux/device-setup.sh`

Just the release tag in the `wget` URL, same as prior GGL bumps (e.g. `db4024e`,
`27fe21c`). No other files reference the GGL version, and no SDK code changed — the SDK
only talks to Nucleus through the standard `awsiotsdk` IPC client
(`aws.greengrass.ipc.mqttproxy` / `pubsub`), which is unchanged in this release range.

## What's new (from [upstream release notes](https://github.com/aws-greengrass/aws-greengrass-lite/blob/main/RELEASE_NOTES.md))

**v2.5.0**
- PKCS#11 (HSM) support for keys/certs; TPM-backed keys now work with fleet provisioning.
- Fixed a v2.4.0 fleet-provisioning regression (MQTT v3 → v5 protocol change).
- Fixed a v2.4.0 regression where recipe artifact permissions weren't owned by the
  correct component user.

**v2.5.1**
- `SubscribeToConfigurationUpdate` only fires on an actual value change now.
- Fixed deployment source ARN being overwritten by unrelated deployments.
- Fixed HTTP artifact download retries not triggering on 5xx/429.

**v2.6.0**
- Components now restart automatically on a config-only deployment change.
- Component status changes report immediately instead of being delayed.
- Fixed a race condition between component startup and the TES HTTP server.
- Fixed re-executed continuous deployments getting stuck.

No breaking changes to `config.yaml`, the IPC contract, or the `.deb` dependency list
between v2.4.0 and v2.6.0 — confirmed by diffing `dpkg-deb -I` output for both `.deb`
packages (`Depends:` is identical) and by downloading the `v2.6.0` zip to confirm the
`aws-greengrass-lite-*-Linux.deb` naming the scripts glob for is unchanged.

## /IOTCONNECT backend impact

None required. Devices still connect straight to AWS IoT Core over MQTT — the backend
never talks to Nucleus Lite directly — and the /IOTCONNECT protocol, telemetry format,
and connection-kit/cert format are all untouched by this update.

Worth knowing for testing, not a backend change: since v2.6.0, components restart
automatically on a config-only deployment, which they didn't reliably do before.

## Before merging

No physical Greengrass device available in this environment to deploy to, so verify on
real hardware or a Nucleus Lite VM:
- Fresh install via `installer/ubuntu/device-setup.sh` on Ubuntu 24.04 reaches
  **Connected** in /IOTCONNECT.
- `examples/basic-demo` deploys and sends telemetry / receives a command.
- In-place upgrade from a running v2.4.0 device (rather than fresh image) still works —
  the scripts already stop `greengrass-lite.target` and remove/reinstall the package.
