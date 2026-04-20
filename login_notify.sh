#!/bin/bash

# 只在会话建立时触发
if [ "$PAM_TYPE" != "open_session" ]; then
    exit 0
fi

# 1. 获取基础变量
user_name=$PAM_USER
remote_ip=$PAM_RHOST
login_time=$(date +"%Y-%m-%d %H:%M:%S")

# 2. 获取本机信息
local_hostname=$(hostname)
local_ip=$(curl -s --connect-timeout 2 ifconfig.me || echo "未知/内网")

# 3. 飞书 Webhook 地址
webhook=""

geo_info=$(curl -s --connect-timeout 2 "http://ip-api.com/json/${remote_ip}?lang=zh-CN")
address=$(echo $geo_info | grep -oP '(?<="regionName":")[^"]*' || echo "未知地")
city=$(echo $geo_info | grep -oP '(?<="city":")[^"]*' || echo "")

# 4. 构造 JSON Payload
payload=$(cat <<EOF
{
    "msg_type": "post",
    "content": {
        "post": {
            "zh_cn": {
                "title": "🛡️ 服务器登录安全提醒",
                "content": [
                    [
                        { "tag": "text", "text": "登录机器: ${local_hostname} (${local_ip})\n" },
                        { "tag": "text", "text": "登录用户: ${user_name}\n" },
                        { "tag": "text", "text": "客户端IP: ${remote_ip}\n" },
                        { "tag": "text", "text": "登录地点: ${address} ${city}\n" },
                        { "tag": "text", "text": "登录时间: ${login_time}" }
                    ]
                ]
            }
        }
    }
}
EOF
)

# 5. 发送请求
curl -X POST "$webhook" \
     -H 'Content-Type: application/json' \
     -d "$payload"
