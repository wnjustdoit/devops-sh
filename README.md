## 发布系统远程服务端执行脚本

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
* 待执行脚本具有可执行的权限（使可用./执行）；
* 传入参数判断（为空校验；数据类型校验；每次都能CD到正确的目录；将要杀死的进程数目<=1等）；
* 固有数据的完整性（存在待发布/回滚的包；存在对应的配置文件等）；
* 优雅停机（先尝试优雅停机，失败再强制停机）；
* 敏感、重要操作多方面确认（如cp -f覆盖、rm -rf、杀死进程前的进程ID确认等）；
* 注意备份数据（jar、config）和查看日志（应用服务器embedded tomcat日志、java应用日志）

---
#### 版本重大变更日志
* 未知日期
    - 获取进程id时，排除当前进程的儿子进程
    - 优化发布成功的标识
        > 获取最新时间的成功日志
* 未知日期
    - 获取进程id排除当前进程的所有子孙进程（父进程为1的进程待观察？）
        > 循环递归结合自定义map查找
* 未知日期
    - 通过引入配置文件变量，避免获取进程id的复杂性
        > 注意命令行配置文件名称的命名要区别于进程名称
* 20191031
    - 优化获取进程id，排除所有当前执行脚本产生的额外进程
        > 直接排除当前进程名，而不是进程id ... | grep -v $0 ...

---
#### 其他想法
* 通过wget或curl等工具获取远程配置到本地（下载文件名区别于进程名）；
* 除运行jar包的java应用外，还支持nodejs、静态文件的发布
