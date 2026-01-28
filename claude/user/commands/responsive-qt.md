---
description: Implement timer-based UI refresh pattern for responsive PyQt6 applications
argument-hint: [optional-timer-interval-ms]
model: sonnet
---

Implement the timer-based UI refresh pattern to keep PyQt6 applications responsive under high-frequency data updates.

## Core Principles

Apply these architectural patterns to decouple the data layer from the presentation layer:

### 1. Data Layer (Real-Time Storage)
- Store incoming data immediately in thread-safe data structures
- **Never emit Qt signals from high-frequency event handlers** (WebSocket callbacks, timers, sensors)
- Use locks (`threading.Lock`) to protect shared data structures
- Keep data layer methods simple: just store, no UI logic

### 2. Presentation Layer (Throttled Rendering)
- Use `QTimer` to refresh UI at fixed rate (default: 20 FPS = 50ms interval, or use $1 if provided)
- Timer callback reads latest data from data layer in batches
- Apply change detection: only update widgets if values actually changed
- Keep timer interval human-perceptible (16-100ms range recommended)

### 3. Implementation Pattern

**Data Manager** (thread-safe storage):
```python
class DataManager(QObject):
    def __init__(self):
        super().__init__()
        self._lock = threading.Lock()
        self._data = {}

    def update_data(self, key, value):
        """Store data immediately, no signals."""
        with self._lock:
            self._data[key] = value
            # ❌ NO self.dataUpdated.emit() here!

    def get_data(self, key):
        """Thread-safe read."""
        with self._lock:
            return self._data.get(key)
```

**UI Widget** (timer-based refresh):
```python
class MyWidget(QWidget):
    def __init__(self, data_manager):
        super().__init__()
        self.data_manager = data_manager

        # Timer-based refresh
        self.ui_refresh_timer = QTimer()
        self.ui_refresh_timer.timeout.connect(self._refresh_ui)
        self.ui_refresh_timer.start(50)  # 20 FPS

    def _refresh_ui(self):
        """Batch-update UI at controlled rate."""
        for item in self.items:
            new_value = self.data_manager.get_data(item.key)
            self._update_if_changed(item.widget, new_value)

    def _update_if_changed(self, widget, new_value):
        """Change detection to avoid unnecessary repaints."""
        if widget.text() != new_value:
            widget.setText(new_value)
```

## Your Task

1. **Analyze the codebase:**
   - Identify high-frequency event sources (WebSocket handlers, timers, callbacks)
   - Find signal emissions in event handlers (search for `.emit()` in callback methods)
   - Locate UI update code triggered by these signals

2. **Refactor data layer:**
   - Remove signal emissions from high-frequency event handlers
   - Ensure thread-safe data storage (use `threading.Lock` or `QMutex`)
   - Keep data updates real-time (store immediately, just don't trigger UI)

3. **Refactor presentation layer:**
   - Remove signal-slot connections that trigger UI updates
   - Add `QTimer` with appropriate interval (default 50ms, or $1 if provided)
   - Implement `_refresh_ui()` method that batch-reads data and updates widgets
   - Add change detection to minimize repaints

4. **Verify improvements:**
   - Test with high-frequency data (100+ updates/sec)
   - Confirm UI remains responsive (no freezing, smooth interactions)
   - Verify no data loss (all updates stored, just rendered in batches)

## Red Flags to Fix

- ❌ `.emit()` called inside WebSocket `on_message()` callbacks
- ❌ UI updates (`.setText()`, `.setItem()`, `.update()`) in signal handlers connected to high-frequency sources
- ❌ No timer-based refresh mechanism
- ❌ Missing change detection (updating widgets even when values unchanged)
- ❌ Status bar updated more than 1-2 times per second

## Success Criteria

- ✅ UI updates at fixed rate (<=20 FPS) regardless of data rate
- ✅ No signal emissions from high-frequency event sources
- ✅ Data layer completely decoupled from presentation layer
- ✅ Change detection implemented to minimize repaints
- ✅ Application remains responsive under 100+ updates/sec load

## Example Files to Modify

Look for patterns like:
- `*_manager.py`, `*_handler.py` - Data layer, remove `.emit()` calls
- `*_widget.py`, `*_tab.py`, `main_window.py` - UI layer, add timer-based refresh
- Signal connections like `obj.dataUpdated.connect(self._update_ui)` - Remove and replace with timer

After implementation, explain the changes and performance impact to the user.
