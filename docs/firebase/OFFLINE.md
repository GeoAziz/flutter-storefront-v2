# Offline-first Strategy (Sprint 1)

This document outlines the offline-first approach used in Sprint 1.

Goals
- Continue to serve product lists and wishlist/comparison data while offline
- Queue writes locally and synchronize when connectivity returns
- Keep conflict resolution simple (last-write-wins) for initial rollout

Implementation Notes
1. Firestore offline persistence
   - Enabled by default in `FirebaseService.initialize()` via `persistenceEnabled: true`.
   - Firestore will cache reads and queue writes while offline.

2. Local queue for writes
   - For critical writes (e.g., wishlist add/remove), prefer local Hive updates first (current implementation).
   - Enqueue network sync operations and attempt to apply them when `syncStatusProvider` indicates online.

3. Conflict resolution
   - Sprint 1 uses last-write-wins (timestamp-based) to keep implementation simple.
   - For Phase 7, consider merge strategies or operational transforms for collaborative data.

4. UX
   - Provide visual sync indicator via `syncStatusProvider` (placeholder). When offline, show small toast or banner.

Testing
- Use the Firebase Emulator Suite to simulate offline conditions by stopping network connectivity or temporarily stopping emulator and verifying queued writes are applied on reconnect.

Limitations
- This sprint favors a pragmatic, low-risk offline design. Advanced conflict resolution and merge rules are planned for Phase 7.
