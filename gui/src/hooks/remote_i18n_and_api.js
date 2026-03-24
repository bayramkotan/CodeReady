// ============================================================================
// CodeReady GUI — i18n additions for SSH Remote feature
// Merge into gui/src/i18n/translations.js
// ============================================================================

export const remoteTranslations = {
  en: {
    // Target selector
    target: 'Target',
    this_machine: 'This machine',
    add_remote: 'Add remote host',
    connecting: 'Connecting',
    connected: 'Connected',
    disconnected: 'Disconnected',

    // Add host modal
    add_remote_host: 'Add Remote Host',
    label: 'Label',
    hostname_ip: 'Hostname / IP',
    username: 'Username',
    port: 'Port',
    authentication: 'Authentication',
    key_path: 'Key path',
    password: 'Password',
    cancel: 'Cancel',
    connect_and_save: 'Connect & Save',
    remove_host: 'Remove',

    // Remote operations
    remote_scan_started: 'Scanning remote machine...',
    remote_install_started: 'Installing on remote machine...',
    remote_profile_started: 'Applying profile on remote machine...',
    remote_bootstrap: 'Copying CodeReady to remote...',
    remote_cleanup: 'Cleaning up remote temp files...',
    ssh_connection_failed: 'SSH connection failed',
    ssh_auth_failed: 'Authentication failed',
    remote_os_detected: 'Remote OS: {os}',

    // Banner
    mode_local: 'Local',
    mode_remote: 'SSH Remote',
  },

  tr: {
    // Hedef secici
    target: 'Hedef',
    this_machine: 'Bu bilgisayar',
    add_remote: 'Uzak makine ekle',
    connecting: 'Baglaniyor',
    connected: 'Bagli',
    disconnected: 'Baglanti kesildi',

    // Makine ekleme modali
    add_remote_host: 'Uzak Makine Ekle',
    label: 'Etiket',
    hostname_ip: 'Hostname / IP',
    username: 'Kullanici adi',
    port: 'Port',
    authentication: 'Kimlik dogrulama',
    key_path: 'Anahtar yolu',
    password: 'Sifre',
    cancel: 'Iptal',
    connect_and_save: 'Baglan ve Kaydet',
    remove_host: 'Kaldir',

    // Uzak islemler
    remote_scan_started: 'Uzak makine taraniyor...',
    remote_install_started: 'Uzak makineye kuruluyor...',
    remote_profile_started: 'Uzak makinede profil uygulaniyor...',
    remote_bootstrap: 'CodeReady uzak makineye kopyalaniyor...',
    remote_cleanup: 'Gecici dosyalar temizleniyor...',
    ssh_connection_failed: 'SSH baglantisi basarisiz',
    ssh_auth_failed: 'Kimlik dogrulama basarisiz',
    remote_os_detected: 'Uzak OS: {os}',

    // Banner
    mode_local: 'Yerel',
    mode_remote: 'SSH Uzak',
  },
};


// ============================================================================
// useApi.js — SSH endpoint additions
// Merge into gui/src/hooks/useApi.js
// ============================================================================

/*
Add these to the existing useApi hook's method map:

// --- SSH Remote endpoints ---
ssh_connect:    Tauri → invoke('ssh_connect', { host })
                Web   → POST /api/ssh/connect  body: { host }

ssh_disconnect: Tauri → invoke('ssh_disconnect')
                Web   → POST /api/ssh/disconnect

ssh_scan:       Tauri → invoke('ssh_scan', { script_content })
                Web   → POST /api/ssh/scan  body: { script_content }

ssh_install:    Tauri → invoke('ssh_install', { script_content, items })
                Web   → POST /api/ssh/install  body: { script_content, items }

ssh_profile:    Tauri → invoke('ssh_profile', { script_content, profile_num })
                Web   → POST /api/ssh/profile  body: { script_content, profile_num }

get_saved_hosts: Tauri → invoke('get_saved_hosts')
                 Web   → GET /api/ssh/hosts

save_host:      Tauri → invoke('save_host', host)
                Web   → POST /api/ssh/hosts/save  body: host

remove_host:    Tauri → invoke('remove_host', { label })
                Web   → DELETE /api/ssh/hosts/:label
*/

// Example integration in useApi.js:
export function useApiSshExtension(isTauri, invoke, apiBase) {
  return {
    async sshConnect(host) {
      if (isTauri) {
        return await invoke('ssh_connect', { host });
      } else {
        const res = await fetch(`${apiBase}/api/ssh/connect`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ host }),
        });
        if (!res.ok) throw new Error(await res.text());
        return await res.json();
      }
    },

    async sshDisconnect() {
      if (isTauri) {
        return await invoke('ssh_disconnect');
      } else {
        await fetch(`${apiBase}/api/ssh/disconnect`, { method: 'POST' });
      }
    },

    async sshScan(scriptContent) {
      if (isTauri) {
        return await invoke('ssh_scan', { script_content: scriptContent });
      } else {
        const res = await fetch(`${apiBase}/api/ssh/scan`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ script_content: scriptContent }),
        });
        if (!res.ok) throw new Error(await res.text());
        return await res.json();
      }
    },

    async sshInstall(scriptContent, items) {
      if (isTauri) {
        return await invoke('ssh_install', { script_content: scriptContent, items });
      } else {
        const res = await fetch(`${apiBase}/api/ssh/install`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ script_content: scriptContent, items }),
        });
        if (!res.ok) throw new Error(await res.text());
        return await res.json();
      }
    },

    async getSavedHosts() {
      if (isTauri) {
        return await invoke('get_saved_hosts');
      } else {
        const res = await fetch(`${apiBase}/api/ssh/hosts`);
        return await res.json();
      }
    },

    async saveHost(host) {
      if (isTauri) {
        return await invoke('save_host', host);
      } else {
        await fetch(`${apiBase}/api/ssh/hosts/save`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(host),
        });
      }
    },

    async removeHost(label) {
      if (isTauri) {
        return await invoke('remove_host', { label });
      } else {
        await fetch(`${apiBase}/api/ssh/hosts/${encodeURIComponent(label)}`, {
          method: 'DELETE',
        });
      }
    },
  };
}
