// Capture x-linuxdo-token from request headers and save to key "yeelovo_token"
// Compatible with Surge / Quantumult X / Loon / Shadowrocket environments
// This script logs headers, tries multiple persistence APIs, then reads back to verify.

(function () {
  const KEY = 'yeelovo_token';
  const headers = (typeof $request !== 'undefined' && $request.headers) ? $request.headers : {};
  const getHeader = (name) => headers[name] || headers[name.toLowerCase()] || null;
  const token = getHeader('x-linuxdo-token') || getHeader('X-Linuxdo-Token') || getHeader('X-LinuxDo-Token');

  console.log('[yeelovo_capture] triggered, headers=', JSON.stringify(headers));

  if (!token) {
    console.log('[yeelovo_capture] no x-linuxdo-token in request headers');
    if (typeof $done === 'function') $done({});
    return;
  }

  let wrote = false;
  const tryWrite = (fn, label) => {
    try {
      const res = fn();
      console.log(`[yeelovo_capture] write attempt ${label} => OK`);
      wrote = wrote || true;
    } catch (e) {
      console.log(`[yeelovo_capture] write attempt ${label} => ERROR: ${e}`);
    }
  };

  // Surge
  if (typeof $persistentStore !== 'undefined' && $persistentStore.write) {
    tryWrite(() => $persistentStore.write(token, KEY), '$persistentStore.write');
  }

  // Quantumult X
  if (!wrote && typeof $prefs !== 'undefined') {
    if ($prefs.setValueForKey) {
      tryWrite(() => $prefs.setValueForKey(token, KEY), '$prefs.setValueForKey');
    } else if ($prefs.write) {
      tryWrite(() => $prefs.write(token, KEY), '$prefs.write');
    }
  }

  // Loon / others
  if (!wrote && typeof $persistentData !== 'undefined' && $persistentData.write) {
    tryWrite(() => $persistentData.write(token, KEY), '$persistentData.write');
  }

  // Generic $store
  if (!wrote && typeof $store !== 'undefined' && $store.write) {
    tryWrite(() => $store.write(token, KEY), '$store.write');
  }

  // Some task APIs
  if (!wrote && typeof $task !== 'undefined' && $task.store) {
    try {
      if ($task.store.set) { $task.store.set(KEY, token); console.log('[yeelovo_capture] $task.store.set OK'); wrote = true; }
    } catch (e) {
      console.log('[yeelovo_capture] $task.store.set ERROR: ' + e);
    }
  }

  // Read back using various read APIs to verify
  let readBack = null;
  try {
    if (typeof $persistentStore !== 'undefined' && $persistentStore.read) readBack = $persistentStore.read(KEY);
  } catch (e) { console.log('[yeelovo_capture] read $persistentStore.read error: ' + e); }
  try {
    if (!readBack && typeof $prefs !== 'undefined') {
      if ($prefs.getValueForKey) readBack = $prefs.getValueForKey(KEY);
      else if ($prefs.valueForKey) readBack = $prefs.valueForKey(KEY);
      else if ($prefs.read) readBack = $prefs.read(KEY);
    }
  } catch (e) { console.log('[yeelovo_capture] read $prefs error: ' + e); }
  try {
    if (!readBack && typeof $persistentData !== 'undefined' && $persistentData.read) readBack = $persistentData.read(KEY);
  } catch (e) { console.log('[yeelovo_capture] read $persistentData.error: ' + e); }
  try {
    if (!readBack && typeof $store !== 'undefined' && $store.read) readBack = $store.read(KEY);
  } catch (e) { console.log('[yeelovo_capture] read $store.error: ' + e); }

  console.log('[yeelovo_capture] token=' + token + ' readBack=' + readBack + ' wrote=' + wrote);

  // Notify user (various notification APIs)
  try {
    const title = 'Yeelovo Token 捕获';
    const sub = wrote ? 'Token 已尝试保存' : 'Token 保存尝试失败';
    const body = `token: ${token}\nreadBack: ${readBack}`;
    if (typeof $notification !== 'undefined' && $notification.post) {
      $notification.post(title, sub, body);
    } else if (typeof $notify === 'function') {
      $notify(title, sub, body);
    } else if (typeof $notification === 'function') {
      $notification(title, sub, body);
    } else if (typeof $done === 'function') {
      // no notify API, fallback to console
      console.log('[yeelovo_capture] no notify API available');
    }
  } catch (e) {
    console.log('[yeelovo_capture] notify error: ' + e);
  }

  if (typeof $done === 'function') $done({});
})();
