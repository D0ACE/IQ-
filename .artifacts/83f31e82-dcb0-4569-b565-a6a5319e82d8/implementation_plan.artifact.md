# Global Fix for Deprecations and Unused Imports

This plan addresses project-wide deprecation warnings and unused imports to improve code quality and align with the latest Flutter/Dart standards.

## Proposed Changes

### 1. Fix `withOpacity` Deprecation
Replace all occurrences of `.withOpacity(value)` with `.withValues(alpha: value)`. This is required to avoid precision loss in newer Flutter versions.

### 2. Fix `DropdownButtonFormField` Deprecation
Replace `value:` with `initialValue:` in `DropdownButtonFormField` widgets. As per Flutter v3.33.0+, `initialValue` is the preferred way to set the starting value.

### 3. Remove Unused Imports
Identify and remove all unused import statements across the project to clean up the codebase.

---

## Affected Components

### [Component Name]

#### [MODIFY] Multiple Files
I will perform a global search and replace for the following patterns:
- `\.withOpacity\((.*?)\)` -> `.withValues(alpha: $1)`
- `DropdownButtonFormField<.*?>\(\s*value:` -> `DropdownButtonFormField<...>(initialValue:` (Surgical replacement)

I will also run analysis on each modified file to identify and remove unused imports.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no new warnings or errors are introduced.
- Verify that the app still compiles successfully.

### Manual Verification
- Check key pages (Customer Detail, Customer List, Onboarding) to ensure colors (opacity) and dropdowns are still functioning correctly.
