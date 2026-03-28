.pragma library

/**
 * Shared modal registry for mutual exclusivity.
 *
 * Services register themselves on Component.onCompleted;
 * when any modal opens, closeOthers() hides all others.
 * Because .pragma library creates one instance per QML engine,
 * the array is shared across all importers.
 */

var _modals = []

function register(key, isOpen, hide) {
    for (var i = 0; i < _modals.length; i++) {
        if (_modals[i].key === key) {
            _modals[i] = { key: key, isOpen: isOpen, hide: hide }
            return
        }
    }
    _modals.push({ key: key, isOpen: isOpen, hide: hide })
}

function closeOthers(activeKey) {
    for (var i = 0; i < _modals.length; i++) {
        if (_modals[i].key !== activeKey && _modals[i].isOpen())
            _modals[i].hide()
    }
}
