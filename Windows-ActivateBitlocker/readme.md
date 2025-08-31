# 🔐 TPM + BitLocker Automation (Dell/HP)

## 🔧 What it does
- **Enables TPM** in BIOS:
  - **Dell** via `DellBIOSProvider` (optional `-BiosPassword`).
  - **HP** via `root/hp/instrumentedBIOS` (sets *TPM Device* to **Enable**).
- Validates **UEFI** firmware and **no pending reboot** (Windows Update/CBS/etc.).
- Encrypts **C:** with BitLocker (**TPM protector**, XtsAes128, recovery password).
- Optionally encrypts **D:** after C: is fully encrypted (**auto-unlock** on D:).
- **Backs up** C: BitLocker recovery key to **Active Directory**.


