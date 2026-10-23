# IndexNow 配置

- 域名：`yunguidaohang.com`
- Key：`012d4e118ee74f9f8d5a08cc336699de`
- Key 文件：`/012d4e118ee74f9f8d5a08cc336699de.txt`
- Key URL：`https://yunguidaohang.com/012d4e118ee74f9f8d5a08cc336699de.txt`
- URL 来源：`sitemap.xml`

默认运行只做配置预检，不会向外部接口提交：

```powershell
powershell -ExecutionPolicy Bypass -File .\submit_indexnow.ps1
```

网站部署完成，确认线上 Key URL 可访问后再提交：

```powershell
powershell -ExecutionPolicy Bypass -File .\submit_indexnow.ps1 -Submit
```

提交结果会写入 `indexnow-submit.log`。
