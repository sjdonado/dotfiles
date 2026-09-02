# On-device transcription model for Anarlog

Anarlog transcribes locally through whisper.cpp when its **Transcription -> Model being used** provider is set to **On-device file**. That provider takes a path to a ggml `.bin`; the model is not bundled and not downloaded by the app, so it has to exist on disk first.

## The model in use

`ggml-large-v3-turbo.bin` from [ggerganov/whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp), kept beside the app's own data:

```
~/Library/Application Support/anarlog/models/stt/ggml-large-v3-turbo.bin
1624555275 bytes
sha256 1fc70f774d38eb169993ac391eea357ef47c88757ef72ee5943879b7e8e2bc69
```

`models/` already exists for the app's local LLM, so the transcription model goes in a sibling `stt/`. That keeps it inside the directory the app would delete if it were uninstalled, rather than leaving a 1.6 GB orphan somewhere else.

Full fp16 rather than a quantized build. Turbo is already a distillation of large-v3 down to four decoder layers, so it is fast on Apple silicon without a second lossy step; quantizing on top trades accuracy for memory that a 32 GB machine is not short of. The smaller builds are `ggml-large-v3-turbo-q8_0.bin` (874 MB) and `-q5_0.bin` (574 MB) in the same repository, same URL pattern.

## Install it on a new machine

```sh
mkdir -p ~/Library/Application\ Support/anarlog/models/stt
cd ~/Library/Application\ Support/anarlog/models/stt
curl -L --fail --progress-bar \
  -o ggml-large-v3-turbo.bin.part \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin
shasum -a 256 ggml-large-v3-turbo.bin.part   # compare with the sha256 above
mv ggml-large-v3-turbo.bin.part ggml-large-v3-turbo.bin
```

Download to `.part` and rename only after the checksum matches. A truncated transfer or an error page saved under the real name looks like a working model until the app tries to load it. `head -c 4` on a valid file reads `ggml`.

Not scripted in `macos.sh`: it is 1.6 GB fetched from a third party, which is a slow and rarely repeated step, and the setup script stays runnable offline.

## Point the app at it

Selecting the file is manual, in **Transcription -> Choose a .bin model**. `cmd+shift+G` in the open dialog accepts a typed path.

There is no way around the dialog. The `anarlog` CLI exposes only `auth`, `doctor`, `meetings`, `proposals`, and `mcp`, with no settings command, and the app writes the provider choice into its own `store.json` when the file is chosen. Editing that file by hand means guessing at a schema the app owns.
