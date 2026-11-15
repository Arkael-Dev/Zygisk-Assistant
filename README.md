# Zygisk-Assistant (Arkael-Dev fork)

Fork of [snake-4/Zygisk-Assistant](https://github.com/snake-4/Zygisk-Assistant) — a Zygisk module that aims to hide the existence of root and Zygisk.

## Credits

- **[@snake-4](https://github.com/snake-4)** — original creator and owner of the [Zygisk-Assistant](https://github.com/snake-4/Zygisk-Assistant) project. All native (C++) hide-root/hide-Zygisk logic in `module/jni/` originates from their work. MIT license retained, see `LICENSE`.
- **@arqzey** — author of the WebUI layer, per-app config, and additional resetprop/SuSFS-based hide-root logic (`module/template/{apply.sh,common_func.sh,webroot,...}`) adapted into this fork.
- **Arkael-Dev** — maintainer of this fork; added extended unmount coverage (SUSFS/APatch/LSPosed/SukiSU) and integrated the WebUI into the build pipeline.

## About

A Zygisk module to hide root from KernelSU, Magisk, APatch, and KernelSU Next (+ZygiskNext/ReZygisk), with a WebUI (ID/EN), per-app configuration, and logging.

## License

Distributed under the MIT License. See `LICENSE` for more information, and the upstream repo for the original copyright by @snake-4.
