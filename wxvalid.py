from flask import Flask, request, abort
import hashlib
import os

app = Flask(__name__)

# 从环境变量或直接定义你的Token
# 推荐从环境变量获取，更安全 гибкий
# export WECHAT_TOKEN="your_token_here"
WECHAT_TOKEN = os.environ.get('WECHAT_TOKEN', 'gIJgxn8n38ahudzcj') # 替换成你在微信公众号后台设置的Token

if WECHAT_TOKEN == 'your_default_token':
    print("警告：请将 WECHAT_TOKEN 替换为你在微信公众号后台设置的真实Token，")
    print("或者设置环境变量 WECHAT_TOKEN。")

# 设置监听端口
PORT = 8988

@app.route('/index', methods=['GET', 'POST'])
def wechat_callback():
    """
    处理微信公众号的服务器配置验证和后续消息/事件推送。
    """
    if request.method == 'GET':
        # 微信服务器配置验证
        signature = request.args.get('signature')
        timestamp = request.args.get('timestamp')
        nonce = request.args.get('nonce')
        echostr = request.args.get('echostr')

        print("\n--- 收到微信服务器配置验证请求 (GET) ---")
        print(f"Signature: {signature}")
        print(f"Timestamp: {timestamp}")
        print(f"Nonce: {nonce}")
        print(f"Echostr: {echostr}")
        print(f"配置的Token: {WECHAT_TOKEN}")

        if not all([signature, timestamp, nonce, echostr]):
            print("缺少必要的参数。")
            abort(400) # Bad Request

        # 1. 将 token、timestamp、nonce 三个参数进行字典序排序
        tmp_arr = [WECHAT_TOKEN, timestamp, nonce]
        tmp_arr.sort()

        # 2. 将三个参数字符串拼接成一个字符串进行 sha1 加密
        tmp_str = "".join(tmp_arr)
        hashed_str = hashlib.sha1(tmp_str.encode('utf-8')).hexdigest()

        # 3. 获得加密后的字符串可与 signature 对比
        if hashed_str == signature:
            print("Token 验证成功！返回 echostr。")
            return echostr
        else:
            print("Token 验证失败！")
            return "Validation Failed", 403 # Forbidden
    elif request.method == 'POST':
        # 处理微信推送的普通消息或事件
        # 这里只是一个占位符，实际开发中需要解析XML/JSON请求体
        # 并根据消息类型进行不同的处理（如回复用户消息等）

        print("\n--- 收到微信消息/事件推送请求 (POST) ---")
        request_data = request.data.decode('utf-8') # 获取原始请求体
        print(f"请求头:")
        for header, value in request.headers.items():
            print(f"  {header}: {value}")
        print(f"请求 Body:\n{request_data}")

        # 简单的示例如（在收到消息时，你可以选择回复“ok”或者XML格式的消息）
        # 微信公众号的POST请求通常期望XML格式的回复，这里为了方便起见，
        # 如果是首次验证，直接返回'ok'也可以。
        # 但在接收消息时，直接返回'ok'可能会导致用户看到“该公众号暂时无法提供服务”
        # 正确的做法是返回微信定义的XML格式回复，例如回复一条文本消息。
        
        # 为了演示和满足原问题“HTTP响应body返回'ok'”，我们仍然返回'ok'
        # 但请注意，这不符合微信消息推送的完整回复要求。
        # 完整的回复通常会是 XML 格式，例如：
        # <xml>
        #   <ToUserName><![CDATA[fromUser]]></ToUserName>
        #   <FromUserName><![CDATA[toUser]]></FromUserName>
        #   <CreateTime>12345678</CreateTime>
        #   <MsgType><![CDATA[text]]></MsgType>
        #   <Content><![CDATA[您好！我收到了您的消息。]]></Content>
        # </xml>
        return 'ok' # 响应微信服务器，表示已收到消息

if __name__ == '__main__':
    # 0.0.0.0 表示监听所有可用的网络接口，包括 localhost (127.0.0.1) 和局域网 IP
    print(f"Flask HTTP 服务正在本地所有接口 (0.0.0.0) 的端口 {PORT} 上监听...")
    print(f"请将微信公众号测试账号的 URL 设置为: http://你的公网IP或域名:{PORT}/index")
    print(f"并将 Token 设置为: {WECHAT_TOKEN}")
    print("按 Ctrl+C 停止服务。")
    app.run(host='0.0.0.0', port=PORT, debug=True) # debug=True 会提供更详细的错误信息

