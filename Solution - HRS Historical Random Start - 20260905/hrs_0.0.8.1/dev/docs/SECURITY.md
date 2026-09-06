# Security Policy

## Current Support Status

Historical Random Start - Alpha 6 Method is an unpublished design project with no gameplay
payload. No released version is currently supported.

Relevant security issues include unintended or out-of-bound writes, path
escape, command injection, unsafe archive handling, credential exposure,
hidden network activity, privilege escalation, tampered dependencies,
unverifiable binaries, or behavior that modifies game files outside the
documented boundary. Balance and feature requests are not security reports.

## Reporting

After a public repository exists, enable its private vulnerability-reporting
facility before announcing releases and identify that route here. Until then,
contact the project steward privately. If only a public issue route exists,
request a private channel without posting exploit steps, credentials, private
paths, saves, or logs.

Target response times are seven days for acknowledgment and thirty days for a
triage decision. These are targets, not warranties. Coordinated disclosure is
preferred.

## Security Boundary

The released design must be local, transparent, least-privileged, and explicit
about writes. It must not collect credentials, include telemetry, conceal
payloads, bypass privilege controls, download executable content, modify
Harmony, invoke developer/cheat mode, or write outside approved mod-owned
locations. See `n0182.md`.
