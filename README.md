<img align="right" width="128" height="128" alt="icon_60pt@3x" src="https://github.com/user-attachments/assets/888bd7f7-9d0a-4cff-8d10-016480fdb9f9" />

<div align="left">

GPA Calculator
=====================
calculate SHSID's curriculum GPAs with ease

---

### What's new
- Adapted to **SHSID's new 2025-2026 curriculum** using weights from the official course catalog
- Overhauled hard-coded presets with a dynamic system using `plist`s
  - this way, the course curriculum could be updated without having to update the app itself
  - curriculum stored [here](https://github.com/willuhd/gparesources/) and accessed via gh-proxy/EdgeOne internally
  - the app auto-checks for any valid curriculum updates at startup and changes the UI dynamically. If it fails, it will use the latest cached version
- Overhauled UI with module selection improvements
  - combined all multi-module G11 courses into one course
  - IB track is one course for G11/G12 universally
- Addressed a bug in the GPA algorithm's normalization, so now the full GPA for each course combination is always 4.5
- Improved viewing logic to automatically use selectors instead of sliders if the screen width is too small

---

### Screenshots

<img width="207" height="448" alt="IMG_2106" src="https://github.com/user-attachments/assets/336db09c-e193-4673-8c1a-a25fff714278" />
<img width="207" height="448" alt="IMG_2107" src="https://github.com/user-attachments/assets/fdf59915-74ab-4558-9ec8-625d33eaa7a6" />

---

The new GPA Calc is just as accurate, while being improved all around. 

---

<div align="center">

> original made with ❤️ by michelg
>
> new changes made by willuhd
