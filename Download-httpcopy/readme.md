 IVANTI Files Mirror

This repository uses **wget** to create a local mirror of the IVANTI download directory.

## 📌 Command

```bash
wget.exe --mirror --no-parent -P . https://nas.wuibaille.fr/LeblogOSDdownload/IVANTI/
```

## ✨ Details
- `--mirror` → Enable mirroring (recursive, time-stamping, infinite depth)  
- `--no-parent` → Prevent ascending to parent directory  
- `-P .` → Save files into the current working directory  

