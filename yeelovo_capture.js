// Capture x-linuxdo-token from request headers and save to key "yeelovo_token"
// Usage:
// - Add MITM for team.yeelovo.com (yeelovo.sgmodule 已包含)
// - Add a request script rule (示例见下方) to run this on the target URL
// - 在浏览器打开 https://team.yeelovo.com/redeem/open-accounts 时脚本会抓取并保存 token

(function () {
  const getHeader = (h) => {
    if (!$request || !$request.headers) return null;
    return $request.headers[h] || $request.headers[h.toLowerCase()] || null;
  };

  const token = getHeader('x-linuxdo-token') || getHeader('X-Linuxdo-Token');
  if (!token) {
    // 没有找到 token，结束
    if (typeof $done === 'function') $done({});
    return;
  }

  const KEY = 'yeelovo_token';
  // 写入持久存储，兼容 Surge / Quantumult X / Loon 等环境
  try {
    if (typeof $persistentStore !== 'undefined' && $persistentStore.write) {
      $persistentStore.write(token, KEY);
    } else if (typeof $prefs !== 'undefined' && $prefs.setValueForKey) {
      $prefs.setValueForKey(token, KEY);
    } else if (typeof $persistentData !== 'undefined' && $persistentData.write) {
      $persistentData.write(token, KEY);
    } else {
      // 兼容旧 API
      if (typeof $store !== 'undefined' && $store.write) $store.write(token, KEY);
    }
  } catch (e) {
    // 忽略写入错误（环境差异）
    console.log('写入持久化存储失败：' + e);
  }

  // 通知用户（可选）
  try {
    if (typeof $notify === 'function') $notify('Yeelovo', 'Token 已保存', token);
    else if (typeof $notification !== 'undefined' && $notification.post) $notification.post('Yeelovo', 'Token 已保存', token);
  } catch (e) {}

  if (typeof $done === 'function') $done({});
})();
