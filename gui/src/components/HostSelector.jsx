// ============================================================================
// CodeReady GUI — HostSelector.jsx
// Add to gui/src/components/
// ============================================================================

import { useState, useEffect } from 'react';
import { useI18n } from '../hooks/useI18n';
import { useApi } from '../hooks/useApi';

export default function HostSelector({ onTargetChange }) {
  const { t } = useI18n();
  const api = useApi();

  const [target, setTarget] = useState('localhost');
  const [savedHosts, setSavedHosts] = useState([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [connecting, setConnecting] = useState(false);
  const [connectedHost, setConnectedHost] = useState(null);
  const [error, setError] = useState('');

  // New host form
  const [newHost, setNewHost] = useState({
    label: '',
    host: '',
    user: '',
    port: 22,
    authType: 'key',
    keyPath: '~/.ssh/id_ed25519',
    password: '',
  });

  // Load saved hosts on mount
  useEffect(() => {
    loadSavedHosts();
  }, []);

  async function loadSavedHosts() {
    try {
      const hosts = await api.call('get_saved_hosts');
      setSavedHosts(hosts || []);
    } catch {
      // No saved hosts yet
    }
  }

  async function handleTargetChange(value) {
    setTarget(value);
    setError('');

    if (value === 'localhost') {
      // Disconnect if connected
      if (connectedHost) {
        try { await api.call('ssh_disconnect'); } catch {}
        setConnectedHost(null);
      }
      onTargetChange({ type: 'local' });
    } else if (value === 'add-new') {
      setShowAddModal(true);
    } else {
      // Connect to saved host
      const host = savedHosts.find(h => h.label === value);
      if (host) {
        await connectToHost(host);
      }
    }
  }

  async function connectToHost(host) {
    setConnecting(true);
    setError('');

    try {
      const result = await api.call('ssh_connect', { host });
      setConnectedHost(host);
      onTargetChange({ type: 'remote', host, remoteOs: result });
    } catch (err) {
      setError(err.message || 'Connection failed');
      setTarget('localhost');
      onTargetChange({ type: 'local' });
    } finally {
      setConnecting(false);
    }
  }

  async function handleAddHost(e) {
    e.preventDefault();

    const hostConfig = {
      label: newHost.label || newHost.host,
      host: newHost.host,
      user: newHost.user || 'root',
      port: parseInt(newHost.port) || 22,
      auth: newHost.authType === 'key'
        ? { type: 'key', path: newHost.keyPath }
        : newHost.authType === 'agent'
          ? { type: 'agent' }
          : { type: 'password', password: newHost.password },
    };

    // Try connecting first
    setConnecting(true);
    try {
      await connectToHost(hostConfig);

      // Save if connection succeeded
      await api.call('save_host', hostConfig);
      await loadSavedHosts();

      setTarget(hostConfig.label);
      setShowAddModal(false);
      setNewHost({ label: '', host: '', user: '', port: 22, authType: 'key', keyPath: '~/.ssh/id_ed25519', password: '' });
    } catch (err) {
      setError(err.message || 'Connection failed');
    } finally {
      setConnecting(false);
    }
  }

  async function handleRemoveHost(label) {
    try {
      await api.call('remove_host', { label });
      await loadSavedHosts();
      if (target === label) {
        setTarget('localhost');
        onTargetChange({ type: 'local' });
      }
    } catch {}
  }

  return (
    <div className="host-selector">
      {/* Target Dropdown */}
      <div className="flex items-center gap-2">
        <span className="text-xs text-gray-500 uppercase tracking-wider">
          {t('target')}
        </span>

        <select
          value={target}
          onChange={(e) => handleTargetChange(e.target.value)}
          disabled={connecting}
          className="bg-codeready-surface border border-codeready-border rounded px-3 py-1.5 text-sm font-mono text-codeready-text focus:border-teal-500 focus:outline-none"
        >
          <option value="localhost">
            🖥 {t('this_machine')} (localhost)
          </option>

          {savedHosts.map(h => (
            <option key={h.label} value={h.label}>
              🌐 {h.label} ({h.user}@{h.host}:{h.port})
            </option>
          ))}

          <option value="add-new">
            + {t('add_remote')}...
          </option>
        </select>

        {/* Connection status indicator */}
        {connecting && (
          <span className="text-xs text-yellow-400 animate-pulse">
            {t('connecting')}...
          </span>
        )}
        {connectedHost && !connecting && (
          <span className="text-xs text-green-400 flex items-center gap-1">
            <span className="w-2 h-2 bg-green-400 rounded-full inline-block" />
            {t('connected')}
          </span>
        )}
      </div>

      {/* Error message */}
      {error && (
        <div className="mt-1 text-xs text-red-400">{error}</div>
      )}

      {/* Add Remote Host Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
          <div className="bg-codeready-bg border border-codeready-border rounded-lg p-6 w-[440px] max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-mono text-teal-400 mb-4">
              {t('add_remote_host')}
            </h3>

            <div className="space-y-3">
              {/* Label */}
              <div>
                <label className="block text-xs text-gray-500 mb-1">{t('label')}</label>
                <input
                  type="text"
                  placeholder="e.g. dev-server"
                  value={newHost.label}
                  onChange={(e) => setNewHost({ ...newHost, label: e.target.value })}
                  className="w-full bg-codeready-surface border border-codeready-border rounded px-3 py-2 text-sm font-mono text-codeready-text focus:border-teal-500 focus:outline-none"
                />
              </div>

              {/* Host */}
              <div>
                <label className="block text-xs text-gray-500 mb-1">{t('hostname_ip')} *</label>
                <input
                  type="text"
                  placeholder="192.168.1.50 or myserver.com"
                  value={newHost.host}
                  onChange={(e) => setNewHost({ ...newHost, host: e.target.value })}
                  required
                  className="w-full bg-codeready-surface border border-codeready-border rounded px-3 py-2 text-sm font-mono text-codeready-text focus:border-teal-500 focus:outline-none"
                />
              </div>

              {/* User + Port */}
              <div className="flex gap-3">
                <div className="flex-1">
                  <label className="block text-xs text-gray-500 mb-1">{t('username')}</label>
                  <input
                    type="text"
                    placeholder="root"
                    value={newHost.user}
                    onChange={(e) => setNewHost({ ...newHost, user: e.target.value })}
                    className="w-full bg-codeready-surface border border-codeready-border rounded px-3 py-2 text-sm font-mono text-codeready-text focus:border-teal-500 focus:outline-none"
                  />
                </div>
                <div className="w-24">
                  <label className="block text-xs text-gray-500 mb-1">{t('port')}</label>
                  <input
                    type="number"
                    value={newHost.port}
                    onChange={(e) => setNewHost({ ...newHost, port: e.target.value })}
                    className="w-full bg-codeready-surface border border-codeready-border rounded px-3 py-2 text-sm font-mono text-codeready-text focus:border-teal-500 focus:outline-none"
                  />
                </div>
              </div>

              {/* Auth Type */}
              <div>
                <label className="block text-xs text-gray-500 mb-1">{t('authentication')}</label>
                <div className="flex gap-2">
                  {['key', 'agent', 'password'].map(type => (
                    <button
                      key={type}
                      onClick={() => setNewHost({ ...newHost, authType: type })}
                      className={`px-3 py-1.5 text-xs font-mono rounded border transition-colors ${
                        newHost.authType === type
                          ? 'bg-teal-600/30 border-teal-500 text-teal-300'
                          : 'bg-codeready-surface border-codeready-border text-gray-400 hover:border-gray-500'
                      }`}
                    >
                      {type === 'key' ? 'SSH Key' : type === 'agent' ? 'Agent' : 'Password'}
                    </button>
                  ))}
                </div>
              </div>

              {/* Key path (if key auth) */}
              {newHost.authType === 'key' && (
                <div>
                  <label className="block text-xs text-gray-500 mb-1">{t('key_path')}</label>
                  <input
                    type="text"
                    value={newHost.keyPath}
                    onChange={(e) => setNewHost({ ...newHost, keyPath: e.target.value })}
                    className="w-full bg-codeready-surface border border-codeready-border rounded px-3 py-2 text-sm font-mono text-codeready-text focus:border-teal-500 focus:outline-none"
                  />
                </div>
              )}

              {/* Password (if password auth) */}
              {newHost.authType === 'password' && (
                <div>
                  <label className="block text-xs text-gray-500 mb-1">{t('password')}</label>
                  <input
                    type="password"
                    value={newHost.password}
                    onChange={(e) => setNewHost({ ...newHost, password: e.target.value })}
                    className="w-full bg-codeready-surface border border-codeready-border rounded px-3 py-2 text-sm font-mono text-codeready-text focus:border-teal-500 focus:outline-none"
                  />
                </div>
              )}

              {/* Error in modal */}
              {error && (
                <div className="text-xs text-red-400 bg-red-400/10 rounded p-2">
                  {error}
                </div>
              )}
            </div>

            {/* Actions */}
            <div className="flex justify-end gap-2 mt-6">
              <button
                onClick={() => { setShowAddModal(false); setError(''); setTarget('localhost'); }}
                className="px-4 py-2 text-sm text-gray-400 hover:text-gray-200 transition-colors"
              >
                {t('cancel')}
              </button>
              <button
                onClick={handleAddHost}
                disabled={!newHost.host || connecting}
                className="px-4 py-2 text-sm bg-teal-600 hover:bg-teal-500 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {connecting ? t('connecting') + '...' : t('connect_and_save')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
