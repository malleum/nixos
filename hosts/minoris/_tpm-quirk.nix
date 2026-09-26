# This Dell has a TPM that does not work and never will. The firmware publishes
# an ACPI TPM2 table but leaves the CRB command window claimed by something
# else, so the driver cannot take it:
#
#   tpm_crb MSFT0101:00: error -EBUSY: can't request region for resource [mem 0xdfbb6000-0xdfbb9fff]
#   tpm_crb MSFT0101:00: probe with driver tpm_crb failed with error -16
#   ima: No TPM chip found, activating TPM-bypass!
#
# so /dev/tpm0 and /dev/tpmrm0 never appear. systemd has no way to know that.
# `tpm2.target` is a synchronisation point that sits inside `sysinit.target` and
# `Wants` both device units, so every boot parks on those two jobs for the full
# DefaultDeviceTimeoutSec -- 90 seconds -- before giving up. It happens twice,
# once under the initrd's systemd and once under stage 2's:
#
#   Startup finished in 8.9s (firmware) + 5.0s (loader) + 1.0s (kernel)
#                     + 1min 33s (initrd) + 1min 42s (userspace) = 3min 30s
#   graphical.target reached after 1min 38s in userspace
#     └─greetd.service @1min 38.278s
#       └─ ... └─sysinit.target @1min 31.775s
#                └─tpm2.target @1min 31.771s
#
# Three minutes of a three-and-a-half minute boot, on a machine whose entire
# job is to show a clock, and behind a silent console (see modules/services/
# hjem.nix) it is indistinguishable from a box that did not come up at all.
#
# Masking the two device units makes the `Wants` fail immediately instead of
# waiting. `Wants` is not `Requires`, so tpm2.target still activates and
# sysinit proceeds; nothing on this host uses a TPM -- no LUKS, no measured
# boot, no sd-pcrlock -- so there is nothing left to want one.
#
# Not `security.tpm2.enable = false` (already off, and unrelated) and not
# blacklisting tpm_crb: the wait is systemd expecting a device node, not the
# module trying and failing to load, so neither touches it.
#
# If the TPM is ever fixed in a BIOS update, delete this file.
{
  boot.initrd.systemd.units = {
    "dev-tpm0.device".enable = false;
    "dev-tpmrm0.device".enable = false;
  };

  systemd.units = {
    "dev-tpm0.device".enable = false;
    "dev-tpmrm0.device".enable = false;
  };
}
