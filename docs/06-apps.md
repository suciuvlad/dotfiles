# Apps

Every cask + MAS app from [`scripts/Brewfile.optional`](../scripts/Brewfile.optional), grouped. Optional + best-effort: failures during `make brew` don't abort but are summarized at the end.

## Productivity

| App           | What it is                                                                |
|---------------|---------------------------------------------------------------------------|
| `1password`   | Password manager + secrets vault                                          |
| `1password-cli` | `op` CLI for scripted secret access                                     |
| `bartender`   | Hide and reorganize menu bar icons                                        |
| `betterzip`   | Archive previews + flexible compression                                   |
| `chatgpt`     | OpenAI's desktop client                                                   |
| `claude`      | Anthropic's desktop Claude client                                         |
| `fantastical` | Calendar with natural-language event entry                                |
| `obsidian`    | Local-first markdown notes                                                |
| `raycast`     | Keyboard launcher / clipboard / snippets / extension store                |

## Browsers

| App             | What it is                            |
|-----------------|---------------------------------------|
| `brave-browser` | Chromium, ad-block + Tor mode         |
| `firefox`       | Mozilla Firefox                       |

## Communication

| App        | What it is                              |
|------------|-----------------------------------------|
| `discord`  | Voice / text chat                       |
| `signal`   | E2E messenger                           |
| `slack`    | Work chat                               |
| `telegram` | Messenger                               |
| `whatsapp` | WhatsApp desktop                        |
| `zoom`     | Video conferencing                      |

## Dev tools

Editors + terminals + IDEs + API clients.

| App                   | What it is                                              |
|-----------------------|---------------------------------------------------------|
| `alacritty`           | GPU-accelerated terminal (alt to ghostty/iterm2)        |
| `codex`               | OpenAI Codex CLI                                        |
| `cursor`              | AI-first VS Code fork                                   |
| `docker-desktop`      | Docker engine + GUI                                     |
| `ghostty`             | The primary terminal (config in `ghostty/`)             |
| `goland`              | JetBrains Go IDE                                        |
| `iterm2`              | The other terminal (with shell integration via `make iterm`) |
| `sublime-text`        | Text editor                                             |
| `visual-studio-code`  | Microsoft VS Code                                       |

## Design

| App           | What it is                                              |
|---------------|---------------------------------------------------------|
| `figma`       | Collaborative UI design                                 |
| `imagealpha`  | Lossy PNG compressor (alpha-aware)                      |
| `imageoptim`  | Lossless image compressor                               |

## File sync

| App             | What it is                            |
|-----------------|---------------------------------------|
| `dropbox`       | File sync                             |
| `google-drive`  | Google Drive desktop client           |

## Media

| App        | What it is                              |
|------------|-----------------------------------------|
| `spotify`  | Music streaming                         |
| `vlc`      | Plays anything                          |

## System / utilities

| App               | What it is                                          |
|-------------------|-----------------------------------------------------|
| `expressvpn`      | VPN client                                          |
| `folx`            | Download manager                                    |
| `gcloud-cli`      | Google Cloud SDK (CLI inside a `.app` package)      |
| `microsoft-office` | Word, Excel, PowerPoint, Outlook                   |
| `nordvpn`         | VPN client                                          |
| `sip-app`         | Color picker / palette manager                      |

## Fonts

| App                              | What it is                                    |
|----------------------------------|-----------------------------------------------|
| `font-jetbrains-mono-nerd-font`  | Programming font with Nerd Font glyphs (icons in `eza`, `starship`, etc.) |

## Mac App Store (`mas`)

Installed via `mas` CLI (must be signed into the App Store first).

| App        | ID         | What it is                                  |
|------------|------------|---------------------------------------------|
| Todoist    | 585829637  | Task manager                                |

`# mas "Xcode", id: 497799835` is in the file but commented out — uncomment if you want Xcode managed by the Brewfile.
