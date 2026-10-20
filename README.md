# Axi

Axi is a companion for the Mac, and only for the Mac, that helps you manage your documents. It appears as a small animated dot, always above other windows, which you can move anywhere on the screen.

When you ask, Axi looks at what is on screen, archives the document you are viewing (a file, an Outlook email with its attachments, a web page) in a private vault built for search, and turns into a small chat where you can ask questions about the archived documents.

Artificial intelligence comes from OMP, which runs on the same Mac and gives access to Anthropic and every other provider it supports. Without OMP, Axi does not archive and does not answer.

Documents, the index, embeddings and conversations stay on your Mac. They leave the Mac only towards the AI provider configured in OMP and, if configured, Azure Document Intelligence.

## Requirements

- macOS 26
- A Mac with Apple Silicon
- OMP installed on the Mac

## Build locally

1. Clone the repository:

   ```sh
   git clone <repository-url> Axi
   cd Axi
   ```

2. Open `Axi.xcodeproj` in Xcode 26 and run the `Axi` scheme on **My Mac**.

   Or build from the command line, and test each package:

   ```sh
   xcodebuild -project Axi.xcodeproj -scheme Axi -destination 'platform=macOS,arch=arm64' -skipMacroValidation CODE_SIGNING_ALLOWED=NO build
   for package in AxiCore AxiScreen AxiOMP AxiEmbedding AxiVectors; do swift test --package-path "Packages/$package"; done
   ```

   The project uses the `MLXHuggingFaceMacros` macro from `mlx-swift-lm`. The first time you build in Xcode, approve it once with **Trust & Enable**. From the command line, `xcodebuild` needs `-skipMacroValidation`: without it, the build fails in `ComputeTargetDependencyGraph`.

The tests do not need OMP, a network connection or system permissions.

Local builds are signed with an Apple Development certificate of the team set in `DEVELOPMENT_TEAM` in the Xcode project. To build with signing, sign in to Xcode with an Apple ID that belongs to that team (Settings › Accounts) and choose the team in the target's Signing & Capabilities. Signing keeps the permissions granted to Axi (Accessibility, Screen Recording, Automation) valid across rebuilds.

## Continuous integration

GitHub Actions builds and tests the project on a macOS 26 runner with Xcode 26, on every push and pull request. The build is not signed.

## Releases

Pushing a tag such as `v0.1.0` runs `.github/workflows/release.yml`. It builds the Release app on a macOS 26 runner and publishes it as a GitHub Release with a zip for Apple Silicon Macs and its SHA-256 checksum. The app is ad-hoc signed and not notarized, so macOS blocks the first launch: the release notes explain how to open it.

## Publish the repository on GitHub

The repository is local until you publish it. With the [GitHub CLI](https://cli.github.com/), from the project folder:

```sh
gh repo create Axi --public --source . --remote origin --push
```

Or create an empty public repository on GitHub, then run:

```sh
git remote add origin <repository-url>
git push -u origin main
```

## Data

Axi keeps all its data in `~/Library/Application Support/Axi/`: the copies of the documents, the vault database, the embedding model and the OMP sessions of the conversations.

## License

Axi is free software licensed under the [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0). Using Axi is free. Companies interested in a commercial license must contact the author.
