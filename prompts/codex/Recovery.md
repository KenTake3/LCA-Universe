# LCA Recovery Sprint — Codex Instructions

## Mission

Analyze the salvaged Lucky Core Factory source code and produce a precise recovery plan.

Do not implement missing modules during this task.

## Repository Context

The surviving Roblox Studio scripts are stored in:

- `recovery/studio/MainGuiClient.client.lua`
- `recovery/studio/FactoryEvolution.server.lua`
- `recovery/studio/SessionManager.lua`
- `recovery/studio/SecurityService.lua`

The current Studio place is incomplete.

The following modules appear to be missing:

### ReplicatedStorage.Shared

- Config
- UpgradeDefinitions
- FactoryDefinitions
- QuestDefinitions
- NumberFormatter

### ServerStorage

- ServerDataService

Additional missing dependencies may exist.

## Critical Rule

Do not guess silently.

When exact original values cannot be reconstructed, distinguish between:

1. Required interface
2. Strongly inferred behavior
3. Unknown balance value
4. Recommended safe default

## Required Analysis

Read all four recovered files completely.

Create:

`docs/06_Current_System.md`

The document must contain the following sections.

### 1. Surviving Files

For every recovered file, describe:

- Responsibility
- Public API
- Data read
- Data changed
- RemoteEvents used
- Required ModuleScripts
- Known defects
- Compatibility concerns

### 2. Dependency Map

Show the current flow using a Mermaid diagram.

Include:

- MainGuiClient
- RemoteEvents
- SecurityService
- SessionManager
- FactoryEvolution
- Missing shared definitions
- Missing ServerDataService

### 3. Missing Module Contracts

For each missing module, list the exact required fields and functions.

#### Config

Include every referenced:

- Table
- Key
- Function
- Expected input
- Expected output

#### UpgradeDefinitions

Include:

- `calculateStats`
- `canLevelUp`
- Required upgrade IDs
- Expected returned stats

#### FactoryDefinitions

Include:

- `Stages`
- `getStage`
- `getNextStage`
- `getProgress`
- `calculateStage`

#### QuestDefinitions

Document every value used by MainGuiClient and SessionManager.

#### NumberFormatter

Document:

- `format`
- `formatTime`
- Expected edge-case behavior

#### ServerDataService

Document:

- `syncToClient`
- Required DataSync payload
- Any other inferred responsibilities

### 4. Session Data Schema

Document every field returned by `SessionManager.getDefaultData()`.

For each field include:

- Type
- Default
- Writer
- Reader
- Persistence requirement
- Migration concern

### 5. API Inconsistencies

Identify all old/new API mismatches.

Pay special attention to:

- `getSession(player)` versus `getSession(player.UserId)`
- `session.data` versus `session.Data`
- `session.state` versus `session.DataState`
- `DataLoaded` and `DataLoadFailed`
- DataSync listener requirements
- RemoteEvent payload field names

### 6. Runtime Blockers

List every issue that prevents the current place from running.

Order them by severity.

### 7. Recovery Order

Propose the safest implementation order.

Use this provisional order only if analysis confirms it:

1. Config
2. NumberFormatter
3. UpgradeDefinitions
4. FactoryDefinitions
5. QuestDefinitions
6. ServerDataService
7. SessionManager compatibility fixes
8. SecurityService compatibility fixes
9. FactoryEvolution compatibility fixes
10. MainGuiClient validation
11. Studio integration test

### 8. Unknowns

Clearly list anything that cannot be recovered from the available files.

Do not invent original product IDs, Asset IDs, prices, or production secrets.

## Security Requirements

- Do not add external `require(assetId)`.
- Do not use `GetObjects`, InsertService, or external HTTP code loading.
- Do not add generic `Kick` behavior.
- Do not weaken server authority.
- Do not change DataStore behavior in this analysis task.
- Do not change ProcessReceipt behavior.
- Do not create Roblox source files yet.
- Do not edit anything under `recovery/studio/`.

## Files Allowed to Change

Only:

- `docs/06_Current_System.md`

Do not modify any other file.

## Completion Report

After writing the document, report:

1. File created
2. Confirmed missing modules
3. Newly discovered dependencies
4. Top five runtime blockers
5. Unresolved unknowns
6. Recommended first implementation task

Do not commit or push.