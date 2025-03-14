## DOCKR 快速上手

本手册从简单的SpringBoot程序镜像编写入手，逐步讲解常用的docker知识和命令，争取通过一份文档快速帮助初学者立马上手docker并参与到日常开发、问题定位和基础环境运维的工作日常中。

### **一、Dockerfile构建思路和基础模板**

        构建基于ARM架构JDK8的Docker镜像来运行Spring Boot程序, 默认已有程序包如：com-trs-cost.jar。

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

        以下是基于 **ARM架构JDK8** 直接运行现有Spring Boot程序 `com-trs-cost.jar` 的Dockerfile内容：

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
# COPY --chown=springuser:springuser target/com-trs-cost.jar /app/com-trs-cost.jar
COPY target/com-trs-cost.jar /app/com-trs-cost.jar

# 优化ARM架构的JVM参数
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"

# 优化SPringBoot程序启动参数
ENV SPRING_OPTS="--spring.profiles.active=local --debug "

# 暴露Spring Boot默认端口
EXPOSE 18188

# 启动命令
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/com-trs-cost.jar $SPRING_OPTS"]
```

---

### **二、Dockerfile使用说明**

1. **文件结构要求**  
   将 `com-trs-cost.jar` 放在与Dockerfile同级目录的 `target` 子目录中：
   
   ```
   ├── Dockerfile
   └── target/
       └── com-trs-cost.jar
   ```

2. **构建镜像**  
   
   ```bash
   docker build -t trs-cost-app:1.0 --platform linux/arm64 .
   ```

3. **运行容器**  
   
   ```bash
   docker run -d \
     --platform linux/arm64 \
     -p 18183:18188\
     --memory=2g \
     --name trs-cost \
     trs-cost-app:1.0
   ```

        注： 18183 为容器外宿主机上监听的端口号，18188为docker内监听的端口号

---

### **三、关键配置说明**

| 配置项         | 说明                                                         |
| ----------- | ---------------------------------------------------------- |
| **基础镜像**    | `arm64v8/eclipse-temurin:8-jdk-jammy` 官方ARM64 JDK8镜像       |
| **时区配置**    | 解决容器内时间与宿主机不一致问题（可删除`TZ`相关配置若不需时区同步）                       |
| **JVM参数优化** | `UseContainerSupport`自动适配容器内存限制，`UseG1GC`为ARM推荐垃圾回收器       |
| **非root用户** | 避免使用root权限运行容器，提升安全性                                       |
| **平台指定**    | `--platform linux/arm64` 确保在非ARM设备上构建时正确交叉编译（如macOS M系列芯片） |

---

### **四、验证方法**

1. **检查容器架构**  
   
   ```bash
   docker exec trs-cost uname -m
   # 应输出：aarch64
   ```

2. **查看JVM版本**  
   
   ```bash
   docker exec trs-cost java -version
   # 应输出ARM架构的JDK8信息
   ```

3. **监控应用日志**  
   
   ```bash
   docker logs -f trs-cost
   ```

---

### **五、扩展配置建议**

1. **健康检查**  
   添加HTTP健康检查（需应用实现健康检查端点）：
   
   ```dockerfile
   HEALTHCHECK --interval=30s --timeout=3s \
     CMD curl -f http://localhost:8080/actuator/health || exit 1
   ```

2. **配置文件挂载**  
   若需要外部化配置，可挂载配置文件：
   
   ```bash
   docker run -v /path/to/config:/app/config trs-cost-app:1.0
   ```

3. **性能监控**  
   添加JMX监控支持：
   
   ```dockerfile
   ENV JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9010 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
   EXPOSE 9010
   ```

### **六、EXPOSE详解**

DOCKER FILE中EXPOSE主要用于：

• 说明容器使用的端口，作为镜像的文档。
• 在使用-P时自动分配主机端口。
• 在容器间通信时，帮助Docker配置网络。

        在 Dockerfile 中，`EXPOSE` 指令的作用是**声明容器在运行时将监听的网络端口**。它的核心功能是为镜像提供**文档化说明**和**协作基础**，但本身**不会直接开放端口到宿主机**。以下是详细解析：

---

#### 6.1 核心作用解析

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

### 文档声明

> 1. 文档适用时间范围：本文的编写截止日期为` 2025年03月14日`，如果后续`docke`r发生了大的更新内容，可能部分内容存在不适用的情况，建议读者以变化的态度学习和使用本文档的知识点。
> 
> 2. 如发现内容存在错误或不适用的情况，可以通知作者修订或参与提交更新内容。