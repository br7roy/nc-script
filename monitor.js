/*
 * Yeelovo 开放账号监控脚本
 * 
 * 功能：定时检查开放账号，有新账号时通知
 * 作者：自动生成
 * 更新：2026-01-31
 * 
 * Surge 配置：
 * [Script]
 * yeelovo_monitor = type=cron,cronexp="* * * * *",wake-system=1,timeout=20,script-path=https://raw.githubusercontent.com/你的用户名/你的仓库/main/monitor.js,script-update-interval=0
 */

const $ = new Env('Yeelovo监控');

// 配置项（从 BoxJS 读取）
const CONFIG = {
  token: $.getdata('yeelovo_token') || '',
  apiUrl: 'https://team.yeelovo.com/api/open-accounts',
  targetUrl: 'https://team.yeelovo.com/redeem/open-accounts',
  checkInterval: $.getdata('yeelovo_interval') || '1', // 检查间隔（分钟）
  alwaysNotify: $.getdata('yeelovo_always_notify') !== 'false', // 总是通知（默认 true）
};

// 主函数
async function main() {
  try {
    // 验证配置
    if (!CONFIG.token) {
      console.log('❌ 未配置 Token，请在 BoxJS 中设置');
      $.msg('Yeelovo监控', '配置错误', '请先在 BoxJS 中配置 Token');
      return;
    }

    console.log('🔍 开始检查开放账号...');
    
    // 发起请求
    const response = await fetchOpenAccounts();
    
    // 解析响应
    if (!response || response.error) {
      throw new Error(response?.error || '请求失败');
    }

    const data = typeof response === 'string' ? JSON.parse(response) : response;
    
    // 检查 items 字段
    const items = data.items || [];
    const total = data.total || 0;
    const rules = data.rules || {};
    
    console.log(`📊 检查结果: items数量=${items.length}, total=${total}`);
    console.log(`📋 规则: 今日剩余次数=${rules.userDailyLimitRemaining}, 积分消耗=${rules.creditCost}`);

    // 判断是否有新账号
    if (items.length > 0) {
      // ✅ 有新账号 - 发送通知并跳转
      const message = `发现 ${items.length} 个开放账号！\n剩余兑换次数: ${rules.userDailyLimitRemaining || 0}`;
      console.log(`✅ ${message}`);
      
      $.msg(
        'Yeelovo 开放账号', 
        '🎉 有新账号可兑换！', 
        message,
        {
          'url': CONFIG.targetUrl,
          'media-url': 'https://team.yeelovo.com/favicon.ico'
        }
      );
    } else {
      // ❌ 暂无账号
      const message = `暂无开放账号\n剩余次数: ${rules.userDailyLimitRemaining || 0}`;
      console.log(`ℹ️ ${message}`);
      
      // 根据配置决定是否通知
      if (CONFIG.alwaysNotify) {
        $.msg('Yeelovo 开放账号', '暂无新账号', message);
      }
    }

    // 检查是否在禁止兑换时段
    if (rules.redeemBlockedNow) {
      console.log(`⏰ ${rules.redeemBlockedMessage}`);
    }

  } catch (error) {
    console.log(`❌ 错误: ${error.message}`);
    $.msg('Yeelovo监控', '运行出错', error.message);
  } finally {
    $.done();
  }
}

// 请求开放账号 API
function fetchOpenAccounts() {
  return new Promise((resolve, reject) => {
    const options = {
      url: CONFIG.apiUrl,
      headers: {
        'authority': 'team.yeelovo.com',
        'accept': 'application/json, text/plain, */*',
        'accept-language': 'zh-CN,zh-Hans;q=0.9',
        'accept-encoding': 'gzip, deflate, br',
        'cache-control': 'no-cache',
        'pragma': 'no-cache',
        'sec-fetch-site': 'same-origin',
        'sec-fetch-mode': 'cors',
        'sec-fetch-dest': 'empty',
        'user-agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
        'referer': 'https://team.yeelovo.com/redeem/open-accounts',
        'x-linuxdo-token': CONFIG.token
      }
    };

    $.get(options, (error, response, body) => {
      if (error) {
        reject(error);
      } else {
        resolve(body);
      }
    });
  });
}

// Surge/Loon/QuantumultX 兼容环境
function Env(name) {
  const isLoon = typeof $loon !== 'undefined';
  const isQuanX = typeof $task !== 'undefined';
  const isSurge = typeof $httpClient !== 'undefined' && !isLoon;
  
  const log = (...args) => console.log(args.join(' '));
  
  const msg = (title, subtitle, message, options = {}) => {
    if (isSurge || isLoon) {
      $notification.post(title, subtitle, message, options);
    } else if (isQuanX) {
      $notify(title, subtitle, message, options);
    }
  };
  
  const getdata = (key) => {
    if (isSurge || isLoon) {
      return $persistentStore.read(key);
    } else if (isQuanX) {
      return $prefs.valueForKey(key);
    }
  };
  
  const get = (options, callback) => {
    if (isSurge || isLoon) {
      $httpClient.get(options, callback);
    } else if (isQuanX) {
      options.method = 'GET';
      $task.fetch(options).then(
        (response) => callback(null, response, response.body),
        (reason) => callback(reason.error, null, null)
      );
    }
  };
  
  const done = (value = {}) => {
    if (isQuanX) return $done(value);
    if (isSurge || isLoon) return $done();
  };
  
  return { name, log, msg, getdata, get, done };
}

// 执行主函数
main();