#### 版本重要变更日志
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
    - 优化获取进程id，排除所有当前执行脚本产生的额外进程（还有包括执行当前脚本的脚本！！）
        > 直接排除当前进程名，而不是进程id ... | grep -v $0 ...   
        可能还需要排除执行当前进程的进程，如：python脚本执行shell，那么：... | grep -v python ...

* 20191211
    - 新增java应用war包方式的发布
    