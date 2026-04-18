# VoiceType Public Launch Guide

This guide is written for a non-technical founder or creator who wants to make VoiceType publicly available in a clean, professional way.

## The Easiest Path

The simplest launch path is:

1. Put the code on GitHub.
2. Upload the finished `.dmg` file to a GitHub Release.
3. Link to that GitHub Release from your website.

That is enough to make VoiceType public.

You do **not** need a complicated app store setup for `v0.1`.

## What "Live" Means Here

For this project, "live" means:

- people can visit a public GitHub repository
- people can read what the app does
- people can download the app
- people can install it on their Mac

That is a real launch.

## Recommended Launch Setup For v0.1

Use this stack:

- **Code host:** GitHub
- **Download host:** GitHub Releases
- **Project page:** your personal website
- **Installer file:** `VoiceType.dmg`

This is the fastest and most professional path for a personal software project.

## What To Publish

Before you publish, make sure you have:

- the GitHub repository
- the finished `README.md`
- the `VoiceType.dmg` file
- 2 screenshots of the app
- a short release note for `v0.1`

Also make sure your public instructions explain the first-launch macOS warning clearly if the app is not yet notarized.

## Step-By-Step: How To Make It Public

### 1. Create the GitHub repository

Create a new public repository on GitHub called `voicetype`.

Upload:

- the code
- the README
- the license
- screenshots if you want them in the repo

### 2. Create a Release on GitHub

On GitHub, there is a Releases section for every repository.

Create a new release and:

- set the version to `v0.1.0`
- give it a title like `VoiceType v0.1`
- write a short description of what the app does
- upload `VoiceType.dmg`

Once that release is published, people can download the app from a clean public page.

### 3. Add it to your website

On your personal site, create a `Projects` section and add VoiceType with:

- the name
- a one-sentence description
- one screenshot
- a `Download` button linked to the GitHub Release
- a `Source Code` button linked to the GitHub repo

That is enough for a polished first launch.

### 4. Explain the project clearly

Your public description should be short and direct:

> VoiceType is a local voice-to-text app for Mac, built for writers and journalists who want a fast, private way to turn speech into text.

### 5. Keep the promise narrow

Do not oversell `v0.1`.

The best framing is:

- it is local
- it is fast
- it is simple
- it is useful now

Then mention future features separately under "Coming Soon."

## DMG Or App File?

Use a `.dmg`.

Why:

- it is the normal Mac installation format
- it gives people a drag-to-Applications workflow
- it keeps the install experience tidy

The macOS warning is not caused by the DMG itself. That warning happens because the app has not yet gone through Apple's full signing and notarization process.

If you shipped the `.app` by itself, users could still see the same warning.

## Recommended Install Instructions

Use a short version anywhere you link the download:

1. Download the DMG
2. Open it
3. Drag VoiceType into Applications
4. In Applications, Control-click VoiceType and choose Open
5. Click Open again

After the first launch, VoiceType should open normally.

## Best Next Upgrade After Launch

If you want the app to feel more polished for a wider audience, the next major upgrade is:

- proper Apple Developer signing and notarization

Why that matters:

- macOS trusts the app more easily
- users see fewer warnings
- the install experience feels more professional

This is worth doing, but it does **not** have to block the first public preview.

## Suggested Public Copy

### One-line description

VoiceType is a local Mac dictation app for writers, journalists, and anyone who thinks better out loud.

### Short paragraph

VoiceType is a lightweight voice-to-text app that runs locally on your Mac. It is designed for drafting notes, outlines, articles, and long thoughts with minimal friction. Press record, speak naturally, and copy the resulting text into the document you are working on.

### v0.1 highlights

- local transcription
- floating capture pad
- simple menu bar workflow
- global hotkey
- built for writing, not meetings

### Coming soon

- direct insertion into active apps
- cleaner transcript modes
- better export and file workflows

## If You Want Help From Me Next

The best next steps I can do for you are:

1. prepare the final GitHub release notes
2. write the website copy for the `Projects` page
3. help you create the exact GitHub repo structure and publish flow
4. help you package a cleaner screenshot set for launch
