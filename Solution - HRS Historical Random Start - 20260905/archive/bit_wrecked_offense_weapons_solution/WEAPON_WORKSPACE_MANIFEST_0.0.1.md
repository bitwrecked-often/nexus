# Offense Weapons Mod 0.0.1 — Workspace Manifest

Status: Framework scaffold only
Source framework: Wasteland Animal Population Tuning 4.1.1
Implementation authorized: No
Release authorized: No

## Purpose

Provide a clean working lane for one unified Offense Weapons mod while leaving
the released Wasteland Animal Population Tuning package untouched.

## Locked design boundary

The future mod will reuse the 4.1.1 point-and-click framework and expose only
exact offensive weapon/effect targets already validated in the current game
configuration. It will use simple independent on/off rows and fixed validated
values. It will not infer universal behavior from a thematic category.

The intended presentation is effect-group headings with exact weapon targets
underneath. Candidate examples include electric, explosive, and burn/fire
behaviors, but no row is approved until its current XML target, baseline,
dependency map, and gameplay evidence are recorded.

## Scaffold contents

The copied framework contains the prior package's GUI, scripts, documentation,
assets, archives, and animal payload as temporary source material. Animal
material is reference-only in this lane and must be replaced or removed before
any weapon release.

## First work chunk

Create a line-item map with:

| Effect heading | Exact target | Source file | XML target | Current value/shape | Baseline value/shape | Dependencies | Evidence status | User row label |
|---|---|---|---|---|---|---|---|---|

Begin with the current spear and shotgun electrical effects, then add explosive
and burn/fire targets only when their exact current configuration and gameplay
evidence support inclusion.

## Do not do yet

* Do not run the copied animal installer as a weapon installer.
* Do not publish the scaffold.
* Do not leave animal-specific rows in a public weapon package.
* Do not edit the released Wasteland source to make weapon changes.
* Do not generalize an effect beyond the exact validated targets.

## Completion gate for 0.0.1

Version `0.0.1` becomes an implementation-ready weapon workspace only after the
line-item map is reviewed and the framework has been relabeled for weapons.
It does not become release-ready until the weapon payload, GUI rows, validator,
install/remove behavior, tests, license metadata, and archives all pass their
own checks.
