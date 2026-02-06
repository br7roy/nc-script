/*
 * Yeelovo Token 自动捕获脚本
 * 
 * 功能：访问 https://team.yeelovo.com/redeem/open-accounts 时自动捕获并保存 token
 * 
 * Surge 配置：
 * [Script]
 * yeelovo_token_capture = type=http-request,pattern=^https:\/\/team\.yeelovo\.com\/api\/open-accounts,requires-body=0,max-size=0,script-path=https://raw.githubusercontent.com/br7roy/nc-script/main/capture-token.js
 */

const $ = new Env('Yeelovo Token捕获');

// 获取请求头
const headers = $request.headers;
const token = headers['x-linuxdo-token'] || headers['X-Linuxdo-Token'];

if (token) {
  // 保存到 BoxJS
  const saved = $.setdata(token, 'yeelovo_token');
  
  if (saved) {
    console.log('✅ Token 已自动保存');
    console.log(`Token: ${token.substring(0, 20)}...`);
    
    // 发送通知
    $.msg('Yeelovo 监控', 'Token 已更新', '已自动保存最新的登录凭证');
  } else {
    console.log('❌ Token 保存失败');
  }
} else {
  console.log('⚠️ 未找到 x-linuxdo-token');
}

$.done({});

// Surge/Loon/QuantumultX 兼容环境
function Env(name) {
  const isLoon = typeof $loon !== 'undefined';
  const isQuanX = typeof $task !== 'undefined';
  const isSurge = typeof $httpClient !== 'undefined' && !isLoon;
  
  const msg = (title, subtitle, message) => {
    if (isSurge || isLoon) {
      $notification.post(title, subtitle, message);
    } else if (isQuanX) {
      $notify(title, subtitle, message);
    }
  };
  
  const setdata = (val, key) => {
    if (isSurge || isLoon) {
      return $persistentStore.write(val, key);
    } else if (isQuanX) {
      return $prefs.setValueForKey(val, key);
    }
    return false;
  };
  
  const done = (value = {}) => {
    if (isQuanX) return $done(value);
    if (isSurge || isLoon) return $done(value);
  };
  
  return { name, msg, setdata, done };
}
