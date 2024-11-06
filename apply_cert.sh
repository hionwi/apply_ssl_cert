function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}


echo -E ""
LOGD "******使用说明******"
LOGI "该脚本将使用Acme脚本申请证书,使用时需保证:"
LOGI "1.知晓Cloudflare 注册邮箱"
LOGI "2.知晓Cloudflare Global API Key"
LOGI "3.域名已通过Cloudflare进行解析到当前服务器"
LOGI "4.该脚本申请证书默认安装路径为/root/cert目录"
confirm "我已确认以上内容[y/n]" "y"
if [ $? -eq 0 ]; then
    cd ~
    LOGI "安装Acme脚本"
    curl https://get.acme.sh | sh
    if [ $? -ne 0 ]; then
        LOGE "安装acme脚本失败"
        exit 1
    fi
    CF_Domain=""
    CF_GlobalKey=""
    CF_AccountEmail=""
    certPath=/root/cert
    if [ ! -d "$certPath" ]; then
        mkdir $certPath
    else
        rm -rf $certPath
        mkdir $certPath
    fi
    LOGD "请设置域名:"
    read -p "Input your domain here:" CF_Domain
    LOGD "你的域名设置为:${CF_Domain}"
    LOGD "请设置API密钥:"
    read -p "Input your key here:" CF_GlobalKey
    LOGD "你的API密钥为:${CF_GlobalKey}"
    LOGD "请设置注册邮箱:"
    read -p "Input your email here:" CF_AccountEmail
    LOGD "你的注册邮箱为:${CF_AccountEmail}"
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    if [ $? -ne 0 ]; then
        LOGE "修改默认CA为Lets'Encrypt失败,脚本退出"
        exit 1
    fi
    export CF_Key="${CF_GlobalKey}"
    export CF_Email=${CF_AccountEmail}
    ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
    if [ $? -ne 0 ]; then
        LOGE "证书签发失败,脚本退出"
        exit 1
    else
        LOGI "证书签发成功,安装中..."
    fi
    ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} --ca-file /root/cert/ca.cer \
    --cert-file /root/cert/${CF_Domain}.cer --key-file /root/cert/${CF_Domain}.key \
    --fullchain-file /root/cert/fullchain.cer --force
    if [ $? -ne 0 ]; then
        LOGE "证书安装失败,脚本退出"
        exit 1
    else
        LOGI "证书安装成功,开启自动更新..."
    fi
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    if [ $? -ne 0 ]; then
        LOGE "自动更新设置失败,脚本退出"
        ls -lah cert
        chmod 755 $certPath
        exit 1
    else
        LOGI "证书已安装且已开启自动更新,具体信息如下"
        ls -lah cert
        chmod 755 $certPath
    fi
else
     exit 1
fi
