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

## Lanzaboote (Secure Boot)

**`framework`: done, 2026-09-30.** Secure Boot is enrolled and enforced
(`sbctl status` shows `Setup Mode: Disabled`, `Secure Boot: Enabled`), both
NixOS and Windows confirmed booting cleanly under enforcement. Bootloader
decision made along the way: standardized on `systemd-boot` (required for
Lanzaboote; also NixOS's modern default and handles Windows dual-boot natively
via boot-entry auto-discovery, no `os-prober` needed) over GRUB's themed
graphical menu, which is mutually exclusive with Secure Boot. Plymouth (the
animated boot *splash*, independent of bootloader choice) deliberately
deferred — not started.

Implementation notes:
- `framework` has a split-ESP layout (200M Windows-shared ESP at `/efi`, 2G
  `XBOOTLDR` at `/boot`) that mainline Lanzaboote doesn't support yet. Using
  `github:sarunint/lanzaboote/xbootldr` (PR
  [nix-community/lanzaboote#456](https://github.com/nix-community/lanzaboote/pull/456),
  unmerged as of 2026-09-30) as the flake input instead of upstream — switch
  back to upstream once that PR lands in a release. It auto-detects
  `boot.loader.systemd-boot.xbootldrMountPoint`, no extra config needed beyond
  keeping that option set.
- Keys enrolled with `sbctl enroll-keys --microsoft --firmware-builtin` — the
  `--microsoft` flag is what keeps Windows bootable; `--firmware-builtin`
  keeps Framework's pre-provisioned OEM keys.
- BIOS steps (Insyde-based, Framework 13 AMD): F2 (not F12) at boot → Security
  → Secure Boot → Administer Secure Boot → "Erase All Secure Boot Settings"
  to enter Setup Mode before enrolling; separately, "Enforce Secure Boot" →
  Enabled *after* enrolling to actually turn enforcement on (enrolling keys
  alone doesn't flip that switch). If anything goes wrong, F2 pressed before
  booting any device always returns to this same menu with a factory-restore
  option — recoverable, not a brick risk.
- `sbctl verify` reports every Microsoft boot file as "not signed" — expected,
  not a problem. It only tracks files signed with *our* key; Microsoft's
  files keep their own original signature, validated via the enrolled
  Microsoft cert, a separate trust path. Only our own
  `EFI/Boot/bootx64.efi` and `EFI/systemd/systemd-bootx64.efi` need to show
  signed. `EFI/systemd/systemd-boot-fallbackx64.efi` (a leftover self-backup
  from plain systemd-boot, pre-Lanzaboote) shows unsigned too — harmless,
  nothing in the boot chain references it.

**`legion`: not started, parked** (explicitly deferred). Blocked on migrating
off GRUB to `systemd-boot` first — Lanzaboote doesn't support GRUB at all.
Unlike `framework`, `legion` has a single unified `/boot` partition (no
XBOOTLDR split), so once migrated it may not need the XBOOTLDR fork at
all — but that depends on that partition actually being large enough
(un-verified; would need `lsblk` run on `legion` itself, which this session
has no direct access to).
