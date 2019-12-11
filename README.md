## 发布系统远程服务端执行脚本

#### 项目介绍
本项目主要实现在远程服务器上执行 java 应用的部分发布功能（主要是发布阶段后期的功能。要构建完整的发布系统流程需要结合 devops-fe（网页客户端，非必须） 和 devops-py）。

---
#### 脚本与执行流程
###### 通用脚本说明
* common.sh
> 通用工具类：linux进程获取与杀死；统一日志处理
* shutdown.sh
> 通用停止进程脚本

###### 重新发布应用（包括发布新的应用、回滚应用）
restart.sh
> - 备份旧的发布包
> - 停止应用
> - 部署新的发布包
> - 启动应用
> - 查看启动日志和应用日志

###### 停止应用
shutdown.sh
> - 停止应用
> - 查看停机日志和应用日志

###### 重启应用（包括启动应用）
reboot.sh
> - 停止应用
> - 启动应用
> - 查看启动日志和应用日志

###### 回滚应用（暂时废弃，由"重新发布应用"支持）
rollback.sh
> - 备份旧的发布包
> - 停止应用
> - 部署回滚包
> - 启动应用
> - 查看启动日志和应用日志

---
#### 脚本编写要点
* 待执行脚本（包括间接执行脚本）具有可执行的权限（使可用./执行）；
* 确保存在对应的文件夹或文件，并有权限读取或写入，如：web 发布文件目录、backup 备份目录、*.*ar 待发布文件或待回滚文件、配置文件、输出日志文件等；
* 传入参数判断（为空校验；数据类型校验；每次都能CD到正确的目录；将要杀死的进程数目<=1等）；
* 优雅停机（先尝试优雅停机，失败再强制停机）；
* 敏感、重要操作多方面确认（如：cd 对文件夹的访问权限、cp -f 覆盖、rm -rf 删除、杀死进程前的进程ID确认等）；
* 注意备份数据（jar、config）和查看日志（应用服务器embedded tomcat日志、java应用日志）；
* 杀死进程注意排除执行新进程的当前脚本本身（grep -v $0/grep -v python/...）

---
#### TODO LIST
* 通过 wget 或 curl 等工具获取远程配置到本地（下载文件名区别于进程名）[本条以及注释都是避免获取进程id收到干扰\]；
* 除运行 java 应用外，还支持 nodejs、静态文件、前端 vuejs 等的发布（目前已经由 devops-py 实现，远程服务器只需接收执行命令即可）；
* 快速回滚，而不是根据commitId重新打包执行发布流程（直接使用历史备份文件）；
* ……
