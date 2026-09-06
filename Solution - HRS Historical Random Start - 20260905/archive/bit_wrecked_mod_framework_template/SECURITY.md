# Security Policy

## Scope

The supported public scope is the reusable framework: its documentation,
templates, blank example, and future source released from the approved public
export. The frozen 4.1.1 reference is historical evidence, not a supported
live installer.

Security reports are useful when they concern unintended file writes, path
escape, unsafe archive extraction, command injection, credential exposure,
network activity, privilege escalation, or a way to modify game files outside
the documented boundary.

Game bugs, balance requests, mod compatibility requests, and requests for new
payload behavior are not security reports.

## Reporting a vulnerability

After the public GitHub repository exists, use its **Private vulnerability
reporting** feature. The repository owner must enable that feature before
announcing the project.

If private reporting is not available, open a minimal public issue requesting
a private reporting channel. Do not include exploit steps, affected local
paths, personal information, saves, credentials, or private logs in that
issue.

The project target is to acknowledge a report within seven days and provide a
triage decision within thirty days. Coordinated disclosure is preferred: give
the maintainer a reasonable chance to reproduce and fix the problem before
public detail is posted.

## Security design boundary

The framework's blank working example must remain transparent and local-only:
no download behavior, no telemetry, no credential collection, no encoded
payloads, no persistence, no privilege-elevation bypass, and no writes outside
its documented user-selected game/mod boundaries.
