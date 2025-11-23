<img align="right" width="128" height="128" alt="icon_60pt@3x" src="https://github.com/user-attachments/assets/888bd7f7-9d0a-4cff-8d10-016480fdb9f9" />

<div align="left">

GPA Calculator
=====================
calculate SHSID's curriculum GPAs with ease

---

### What's new
- Adapted to **SHSID's new 2025-2026 curriculum**
- Overhauled hard-coded presets with a dynamic system using `plist`s
  - this way, the course curriculum could be updated without having to update the app itself
  - curriculum stored [here](https://github.com/willuhd/gparesources/) and accessed via gh-proxy/EdgeOne internally
  - the app auto-checks for any valid curriculum updates at startup. If it fails, it will use the latest cached version which is Winter 2025
- Overhauled UI with module selection improvements
  - instead of having many module choices for G11, there are now 2: IB and everything else
  - the course logic is much smarter, allowing you to choose your modules dynamically
- Still kept Michel's legendary GPA algorithm and grades 6-8. 😎

---

### Demo

<img width="207" height="448" alt="IMG_2106" src="https://github.com/user-attachments/assets/336db09c-e193-4673-8c1a-a25fff714278" />
<img width="207" height="448" alt="IMG_2107" src="https://github.com/user-attachments/assets/fdf59915-74ab-4558-9ec8-625d33eaa7a6" />

---

Auto-update at startup, so GPA Calc stays updated without needing an App Store update

Refined Module logic, adding intuitive selection and full coverage for grades 6-12

The new GPA Calc is just as accurate, while being improved all around. 

---

<div align="center">

> original made with ❤️ by michelg
>
> new changes made by willuhd
