## DOCKR 快速上手

本手册从简单的SpringBoot程序镜像编写入手，逐步讲解常用的docker知识和命令，争取通过一份文档快速帮助初学者立马上手docker并参与到日常开发、问题定位和基础环境运维的工作日常中。

### **一、Dockerfile构建思路和基础模板**

        构建基于ARM架构JDK8的Docker镜像来运行Spring Boot程序, 默认已有程序包如：com-ray-app.jar。

        基础镜像,ARM架构的JDK8，常见的选项有Eclipse Temurin或Amazon Corretto。下面的Dokerfile中选择arm64v8的Eclipse Temurin 8 JDK镜像，因为它广泛使用且稳定。

        如果需要考虑安全性，避免以root用户运行容器。只需要创建非root用户，并在运行时切换到这个用户，下面的Dockerfile中注释掉了该部分，可按需开放、修改。

        时区设置，当应用需要处理时间相关的功能时。考虑常常开发的软件系统为国产化系统，这里默认设置时区为Asia/Shanghai，可以根据需要调整。

        JVM参数优化，如需定制化内存管理和垃圾回收。使用UseContainerSupport和MaxRAMPercentage可以让JVM根据容器内存限制自动调整堆大小，这在容器化环境中非常有用。另外，G1垃圾收集器适合大多数场景，尤其是在ARM架构上表现良好。

        端口暴露和启动命令的基本配置，确保容器正确暴露端口并使用正确的JAR文件名启动应用。

        最后，验证步骤需要检查镜像是否正确构建，以及容器是否正常运行。使用docker build和docker run命令，并检查日志和进程状态。

        注意，必须将JAR文件放在与Dockerfile相同的目录下的target目录中，否则构建会失败。另外，如果需要其他JVM参数，可以调整JAVA_OPTS环境变量。

综上Dockerfile的步骤：

> 1. 选择基础镜像
> 
> 2. 设置工作目录
> 
> 3. 配置时区
> 
> 4. 创建用户
> 
> 5. 复制JAR文件
> 
> 6. 设置环境变量
> 
> 7. 暴露端口
> 
> 8. 定义启动命令

        以下是基于 **ARM架构JDK8** 直接运行现有Spring Boot程序 `com-ray-app.jar` 的Dockerfile内容：

```dockerfile
# 使用ARM架构的JDK 8作为基础镜像
FROM arm64v8/eclipse-temurin:8-jdk-jammy

# 设置工作目录
WORKDIR /app

# 配置时区（可选）
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建非root用户（安全最佳实践）
# RUN useradd -ms /bin/bash springuser
# USER springuser

# 复制本地JAR文件到镜像中（假设JAR文件位于当前目录的target子目录下）
# COPY --chown=springuser:springuser target/com-ray-app.jar /app/com-ray-app.jar
COPY target/com-ray-app.jar /app/com-ray-app.jar

# 优化ARM架构的JVM参数
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"

# 优化SPringBoot程序启动参数
ENV SPRING_OPTS="--spring.profiles.active=local --debug "

# 暴露Spring Boot默认端口
EXPOSE 18188

# 启动命令
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/com-ray-app.jar $SPRING_OPTS"]
```

---

### **二、Dockerfile使用说明**

1. **文件结构要求**  
   将 `com-ray-app.jar` 放在与Dockerfile同级目录的 `target` 子目录中：
   
   ```
   ├── Dockerfile
   └── target/
       └── com-ray-app.jar
   ```

2. **构建镜像**  
   
   ```bash
   docker build -t com-ray-app:1.0 --platform linux/arm64 .
   ```
   
   注： docker build 命令最后面有一个半角的点符号，表示当前目录，为必要参数。

3. **运行容器**  
   
   ```bash
   docker run -d \
     --platform linux/arm64 \
     -p 18183:18188\
     --memory=2g \
     --name com-ray-app \
     com-ray-app:1.0
   ```

        注： 18183 为容器外宿主机上监听的端口号，18188为docker内监听的端口号

---

### **三、Dockerfile 关键配置说明**

| 配置项         | 说明                                                         |
| ----------- | ---------------------------------------------------------- |
| **基础镜像**    | `arm64v8/eclipse-temurin:8-jdk-jammy` 官方ARM64 JDK8镜像       |
| **时区配置**    | 解决容器内时间与宿主机不一致问题（可删除`TZ`相关配置若不需时区同步）                       |
| **JVM参数优化** | `UseContainerSupport`自动适配容器内存限制，`UseG1GC`为ARM推荐垃圾回收器       |
| **非root用户** | 避免使用root权限运行容器，提升安全性                                       |
| **平台指定**    | `--platform linux/arm64` 确保在非ARM设备上构建时正确交叉编译（如macOS M系列芯片） |

---

### **四、镜像验证方法**

1. **检查容器架构**  
   
   ```bash
   docker exec com-ray-app uname -m
   # 应输出：aarch64
   ```

2. **查看JVM版本**  
   
   ```bash
   docker exec com-ray-app java -version
   # 应输出ARM架构的JDK8信息
   ```

3. **监控应用日志**  
   
   ```bash
   docker logs -f com-ray-app
   ```

---

### **五、容器扩展配置建议**

1. **健康检查**  
   添加HTTP健康检查（需应用实现健康检查端点）：
   
   ```dockerfile
   HEALTHCHECK --interval=30s --timeout=3s \
     CMD curl -f http://localhost:8080/actuator/health || exit 1
   ```

2. **配置文件挂载**  
   若需要外部化配置，可挂载配置文件：
   
   ```bash
   docker run -v /path/to/config:/app/config com-ray-app:1.0
   ```

3. **性能监控**  
   添加JMX监控支持：
   
   ```dockerfile
   ENV JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9010 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
   EXPOSE 9010
   ```

### **六、Dockerfile EXPOSE详解**

DOCKER FILE中EXPOSE主要用于：

• 说明容器使用的端口，作为镜像的文档。
• 在使用-P时自动分配主机端口。
• 在容器间通信时，帮助Docker配置网络。

        在 Dockerfile 中，`EXPOSE` 指令的作用是**声明容器在运行时将监听的网络端口**。它的核心功能是为镜像提供**文档化说明**和**协作基础**，但本身**不会直接开放端口到宿主机**。以下是详细解析：

---

#### 6.1 EXPOSE核心作用解析

##### 6.1.1. **文档化说明（关键作用）**

```dockerfile
EXPOSE 80/tcp
EXPOSE 443
```

   • **开发者约定**：明确告知镜像使用者“此容器会使用哪些端口”，类似API文档
   • **元数据记录**：端口信息会被写入镜像元数据，可通过 `docker inspect` 查看
   • **最佳实践**：即使你知道端口号，也应通过 `EXPOSE` 显式声明，提高镜像可维护性

##### 6.1.2. **协作基础（网络互联）**

   • 当容器通过 `--network` 连接到**自定义Docker网络**时：
     ```bash
     # 创建自定义网络
     docker network create mynet

     # 启动容器（假设镜像已EXPOSE 80）
     docker run -d --name web --network mynet my-web-app
    
     # 另一个容器可通过端口80访问web服务（无需手动映射端口）
     docker run --rm --network mynet curlimages/curl curl http://web:80
     ```

   • **自动服务发现**：Docker会为 `EXPOSE` 的端口生成网络规则，允许容器间直接通信

##### 6.1.3. **与 `-P` 参数的协作**

```bash
# 自动将EXPOSE的端口映射到宿主机随机高端口
docker run -d -P my-web-app

# 查看实际映射
docker port <container-id>
# 输出示例：80/tcp -> 0.0.0.0:32768
```

   • **动态端口分配**：宿主机端口从 **32768-60999** 范围内自动选择
   • **适用场景**：快速测试、多实例部署避免端口冲突

---

#### 6.2 常见误区澄清

#### ❌ 错误认知：`EXPOSE` 会直接开放端口到宿主机

   • **真相**：`EXPOSE` 本身不开放任何宿主机端口！必须配合以下方式之一：

     # 方式1：显式映射 (-p)
     docker run -p 80:80 my-web-app
     ```
    
     # 方式2：自动映射 (-P)
     docker run -P my-web-app
     ```

#### ✅ 正确理解：`EXPOSE` 是“声明”而非“操作”

| 指令/参数                  | 作用域   | 持久化 | 实际网络效果       |
| ---------------------- | ----- | --- | ------------ |
| `EXPOSE` in Dockerfile | 镜像层面  | ✔️  | 仅记录元数据       |
| `-p` / `--publish`     | 容器运行时 | ❌   | 直接配置端口映射     |
| `-P`                   | 容器运行时 | ❌   | 根据EXPOSE自动映射 |

---

#### 6.3 高级使用场景

##### 6.3.1 场景1：多协议支持

```dockerfile
EXPOSE 53/udp   # DNS服务
EXPOSE 161/udp  # SNMP监控
EXPOSE 80/tcp   # HTTP
```

##### 6.3.2 场景2：组合端口声明

```dockerfile
# 合并声明（TCP为默认协议）
EXPOSE 80 443 8080
# 等效于
EXPOSE 80/tcp 443/tcp 8080/tcp
```

##### 6.3.3 场景3：Kubernetes 集成

   • Kubernetes 会读取 `EXPOSE` 信息：

     ```yml
     # Service配置自动抓取容器端口
     ports:
       # 对应EXPOSE的值
       - containerPort: 80

---

#### 6.4 最佳实践建议

1. **必写原则**：只要容器监听端口，就在 Dockerfile 中写 `EXPOSE`

2. **协议明确**：对 UDP 端必须显式标注 `/udp`

3. **版本控制**：端口变更时及时更新 `EXPOSE` 声明

4. **组合使用**：
   
   ```bash
   # 开发环境：使用-P快速测试 自动分配端口
   docker run -d -P --name dev my-web-app
   # 查看实际映射
   docker port <container-id>
   # 输出示例：80/tcp -> 0.0.0.0:32768
   
   # 生产环境：精确控制端口
   docker run -d -p 80:80 -p 443:443 --name prod my-web-app
   ```

---

通过 `EXPOSE` 的正确使用，可以使 Docker 镜像：  
✅ 更易维护 ✅ 更安全（避免无意识暴露端口） ✅ 更易集成到编排系统（如 Kubernetes）

### **七、Docker网络**

#### 7.1 核心概念

##### 7.1.1 网络模式解析

> Docker 提供五种基础网络模式：
> 
> - **bridge**（默认）：通过虚拟网桥实现容器间通信 
> - **host**：直接使用宿主机网络栈，无隔离 
> - **overlay**：跨主机容器组网的集群方案 
> - **macvlan**：为容器分配物理网卡特性 
> - **none**：完全禁用网络栈 

##### 7.1.2 网络驱动选择

| 驱动类型    | 适用场景    | 性能损耗 |
| ------- | ------- | ---- |
| bridge  | 单机容器通信  | 低    |
| overlay | 跨主机容器组网 | 中    |
| macvlan | 物理网络直通  | 最低   |

---

#### 7.2 核心操作命令

##### 7.2.1 `docker run` 网络配置

1) **基础语法**：
   
   ```bash
   docker run [OPTIONS] --network=<模式> [镜像]
   ```

2) **常用配置参数**：
   
   ```bash
   # 端口映射（NAT）
   -p 8080:80
   
   # 指定网络模式
   --network=my_bridge
   
   # 指定容器IP（需自定义网络）
   --ip 172.18.0.10
   
   # 主机名映射
   --hostname web01
   
   # DNS配置
   --dns 8.8.8.8
   ```

3) **典型用例**：
   
   ```bash
   # 在自定义网络启动Web服务
   docker run -d --name webapp \
   --network prod_net \
   -p 8080:3000 \
   --dns 223.5.5.5 \
   my_web:latest
   ```

##### 7.2.2 `docker network` 管理命令

1) **网络生命周期管理**：
   
   ```bash
   # 创建自定义桥接网络
   docker network create --driver=bridge \
   --subnet=172.18.0.0/24 \
   --gateway=172.18.0.1 \
   prod_net
   
   # 查看网络拓扑
   docker network inspect prod_net
   
   # 容器动态接入网络
   docker network connect backup_net webapp
   
   # 清理未使用网络
   docker network prune
   ```

2) **高级技巧**：
   
   1) 使用 `--attachable` 参数创建支持动态接入的网络 
   2) 通过 `docker network connect --alias db` 设置网络别名 
   3) 组合使用 `--ip-range` 和 `--subnet` 精确控制IP分配 

---

#### 7.3 实战场景：电商微服务网络配置

##### 7.3.1 环境需求

- 前端服务（2个实例）
- 订单服务（需连接MySQL）
- MySQL数据库（仅限内部访问）
- Redis缓存（跨主机访问）

##### 7.3.2 实施步骤

```bash
# 创建业务网络
docker network create --driver=bridge \
  --subnet=10.5.0.0/24 \
  ecommerce_net

# 启动数据库（仅内部访问）
docker run -d --name mysql \
  --network ecommerce_net \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:8.0

# 启动带端口映射的前端
docker run -d --name frontend-1 \
  --network ecommerce_net \
  -p 80:8080 \
  frontend:prod

# 创建跨主机网络
docker network create --driver=overlay \
  --attachable \
  redis_cluster
```

##### 7.3.3 验证方法

```bash
# 检查服务发现
docker exec -it frontend-1 ping mysql

# 测试跨主机通信
docker run --rm --network redis_cluster \
  redis-tool check-cluster
```

---

#### 7.4 常见问题排查指南

##### 7.4.1 容器无法访问外网

1) **现象**：
   
   ```bash
   docker exec webapp curl https://api.example.com
   # 返回 "Could not resolve host"
   ```

2) **解决方案**：
   
   1) 检查容器DNS配置：
      
      ```bash
      docker inspect webapp | grep Dns
      ```
   
   2) 验证宿主机网络策略：
      
      ```bash
      iptables -t nat -L DOCKER
      ```
   
   3) 重建网络时保留已分配IP 

##### 7.4.2 端口映射失效

1) **典型场景**：
   
   ```bash
   docker run -p 3306:3306 mysql
   # 宿主机端口无监听
   ```

2) **排查步骤**：
   
   1) 确认容器进程监听0.0.0.0：
      
      ```bash
      docker exec mysql netstat -tulnp
      ```
   
   2) 检查防火墙规则：
      
      ```bash
      firewall-cmd --list-all | grep docker
      ```
   
   3) 验证NAT规则：
      
      ```bash
      iptables -t nat -nvL DOCKER
      ```

##### 7.4.3 跨网络通信失败

1) **错误示例**：
   
   ```bash
   docker exec frontend-1 ping redis-node
   # ping: redis-node: Name or service not known
   ```

2) **解决方法**：
   
   1) 确认容器在同一网络：
      
      ```bash
      docker network inspect ecommerce_net
      ```
   
   2) 使用完整域名进行访问：
      
      ```bash
      redis-node.redis_cluster
      ```
   
   3) 更新服务发现配置 

#### 7.5 最佳实践建议

##### 7.5.1 **生产环境网络规划**：

- 业务流量使用 overlay 网络
- 管理流量使用独立 bridge 网络
- 数据库使用 macvlan 直连物理网络 

##### 7.5.2 **安全策略**：

```bash
# 创建隔离网络
docker network create --internal secure_net

# 限制网络访问
docker network connect --ip 10.20.30.40 secure_net app
```

##### 7.5.3 **性能优化**：

- 设置 `--mtu=9000` 支持巨型帧 
- 使用 `--ipv6` 启用双栈支持
- 调整 `com.docker.network.driver.mtu` 参数 

### 文档声明

> 1. 文档适用时间范围：本文的编写截止日期为` 2025年03月14日`，如果后续`docke`r发生了大的更新内容，可能部分内容存在不适用的情况，建议读者以变化的态度学习和使用本文档的知识点。
> 
> 2. 如发现内容存在错误或不适用的情况，可以通知作者修订或参与提交更新内容。