# Things to figure out later

## Hibernate on framework (Ryzen AI 300 / Krackan) — parked 2026-09-30

Hibernate (`systemctl hibernate`) is unreliable to the point of being disabled
(`systemd.sleep.settings.Sleep.AllowHibernation = false` in
`nixos/hosts/framework/configuration.nix`, mirrored live in
`/etc/nixos/configuration.nix`). Two distinct, non-deterministic firmware-level
failure modes observed, neither traceable to our own config:

1. **Post-write abort.** Kernel successfully compresses and writes the full
   hibernation image, then aborts right at the final platform power-off with
   `PM: hibernation: Wakeup event detected during hibernation, rolling back.`
   No real poweroff ever happens; boot continues normally.
2. **Pre-write abort.** Kernel never gets as far as writing an image at all —
   aborts during the initial ACPI S4 validation roundtrip itself
   (`ACPI: PM: Preparing to enter system sleep state S4` →
   `Saving platform NVS memory` → `Restoring platform NVS memory` →
   `Waking up from system sleep state S4`, all within the same boot, no
   `Compressing and saving image data` lines at all). No explicit error is
   logged for this one.

Already ruled out / tried:
- `resume_offset` / `resume=` device mismatch — confirmed correct
  (`nvme0n1p6` = `259:6`, matches `btrfs inspect-internal map-swapfile`).
- Swapfile not `NODATACOW` — fixed via `btrfs filesystem mkswapfile`, offset
  recomputed and stable, write itself succeeds when it gets that far.
- ACPI wakeup sources (`GPP0/1/3/5`, `NHI0/1` — PCIe expansion-card slots +
  Thunderbolt) — disabled via `/proc/acpi/wakeup`, no change, both failure
  modes still occur.
- `/sys/power/pm_test` — confirmed `[none]`, not a kernel debug artifact.
- BIOS/EC firmware — `fwupdmgr` confirms already at the latest available
  version (04.02).
- Kernel version downgrade — not attempted; Framework's own NixOS install
  guide explicitly recommends staying on the latest kernel, so this cuts
  against that advice.
- `pm_async=0` (documented, A/B-tested community workaround for a known
  AGESA/PMFW "Infinity Fabric sync flood" on device-resume race — see
  [Framework Community thread](https://community.frame.work/t/hibernate-resume-failures-on-framework-13-amd-ryzen-ai-300-krackan-a-b-tested-workaround-pm-async-0/83040))
  — applied live, fixes failure mode 1's known mechanism in theory, but our
  most recent test still hit failure mode 2 (pre-write abort), so it's
  unconfirmed whether it actually helps here. Not persisted into config since
  hibernate is fully disabled anyway.

Revisit when:
- A NixOS/kernel update lands that specifically addresses Framework 13 AMD AI
  300 series S4 issues (watch
  [NixOS/nixpkgs#413932](https://github.com/NixOS/nixpkgs/issues/413932) and
  [NixOS/nixos-hardware#1348](https://github.com/NixOS/nixos-hardware/issues/1348)).
  Same as [community reports of frequent resume failures/corruption](https://community.frame.work/t/frequent-graphical-corruption-and-failure-to-resume-after-hibernate-framework-13-ai-370-fedora-43/77613)
  on this exact hardware family — general immaturity, not just us.
- Worth posting our own logs to the Framework community thread above (the
  pre-write abort looks like a distinct failure mode not yet documented
  there) if we want outside help diagnosing it further.
- If revisited: re-add `boot.resumeDevice`/`resume_offset` (recompute fresh —
  don't reuse `14037369`, it'll be stale by then), re-enable
  `AllowHibernation`, and reapply `pm_async=0` via
  `systemd.tmpfiles.rules = [ "w /sys/power/pm_async - - - - 0" ];` (there is
  no kernel cmdline flag for this one).

## Lanzaboote (Secure Boot) — both systems

Get Secure Boot back on for both `legion` and `framework` via Lanzaboote.
Needs the flake-based setup either way (already true now that both hosts live
in this repo) — not started yet.
