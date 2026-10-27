# Xcode 27 and Objective-C Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the original Swift app with Xcode 27 and provide an independent Objective-C equivalent.

**Architecture:** Keep the Swift app at root. Copy resources into OC and translate the application using Cocoa and Security, separating JWT encoding from APNs requests and UI.

**Tech Stack:** AppKit, Objective-C ARC, Foundation, Security, Xcode 27.1.

**Spec:** docs/superpowers/specs/2026-10-28-objective-c-design.md

## Global Constraints
- macOS 12.0 minimum, no third party dependencies.
- Preserve existing Storyboard outlets/actions and UI.
- Local commits only, after verification.

## Review Focus
- Malformed/truncated DER must return errors without out-of-bounds reads.
- ECDSA integers must be padded to exactly 32 bytes each.
- APNs rejection must never display success.
- Storyboard Objective-C classes must resolve without Swift module names.
- Temporary generated keys must never enter commits.

### Task 1: Swift compatibility
- [x] Change all deployment targets to 12.0 and replace deprecated Data initializer.
- [x] Build Debug and Release without overrides; expect BUILD SUCCEEDED.
- [x] Document compatibility and commit.

### Task 2: Objective-C core
- [ ] Write command-line behavioral tests for JWT cryptographic verification, invalid PEM/DER, leading-zero and short ECDSA integers, request headers and response status.
- [ ] Run tests before implementation to confirm missing core.
- [ ] Implement `P8JWT` tokenWithKeyID:teamID:privateKey:date:error: and rawSignatureFromDER:error:; bounded DER parsing and Security ES256 signing.
- [ ] Implement `APNsClient` requestWithToken:topic:deviceToken:payload:baseURL:error: and resultForResponse:data:error:.
- [ ] Run behavioral tests; expect zero failures.

### Task 3: Independent OC app
- [ ] Copy resources and generate a standalone Objective-C Xcode project.
- [ ] Implement AppDelegate/main and MainViewController with original outlet/action names.
- [ ] Compile Debug and Release, static analyze, verify storyboard bindings.
- [ ] Update README with build/test commands and limitations; review diff and commit.

## Progress
- Baseline: original deployment 10.15 fails on Xcode 27.1; command-line override 12.0 builds successfully.
- Decision: work on a feature branch in the shared checkout to keep delivered files visible in the user's workspace.

- Task 1: Debug/Release builds passed on Xcode 27.1; only Xcode AppIntents metadata warning remains (this app does not use AppIntents).
